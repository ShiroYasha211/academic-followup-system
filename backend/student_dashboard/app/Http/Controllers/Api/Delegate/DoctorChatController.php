<?php

namespace App\Http\Controllers\Api\Delegate;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Http\Controllers\Api\Delegate\DelegateApiController;
use App\Models\DoctorConversation;
use App\Models\DoctorMessage;
use App\Models\User;
use App\Enums\UserRole;
use Illuminate\Support\Facades\Validator;

class DoctorChatController extends DelegateApiController
{
    /**
     * Display a listing of conversations with doctors.
     */
    public function index(Request $request)
    {
        $delegate = $request->user();

        $conversations = DoctorConversation::where('delegate_id', $delegate->id)
            ->with(['doctor:id,name,avatar,role', 'lastMessage'])
            ->orderByDesc('last_message_at')
            ->get();

        return $this->success([
            'conversations' => $conversations,
        ], 'تم جلب المحادثات مع الدكاترة بنجاح');
    }

    /**
     * Display the specified conversation with messages.
     */
    public function show(Request $request, string $id)
    {
        $delegate = $request->user();

        $conversation = DoctorConversation::where('delegate_id', $delegate->id)
            ->with('doctor:id,name,avatar,role')
            ->find($id);

        if (!$conversation) {
            // Check if $id is doctorId (fallback)
            $conversation = DoctorConversation::where('delegate_id', $delegate->id)
                ->where('doctor_id', $id)
                ->first();
            
            if (!$conversation) {
                return $this->error('المحادثة غير موجودة', 404);
            }
        }

        // Mark as read
        $conversation->markAsReadFor($delegate->id);

        $messages = $conversation->messages()
            ->with('sender:id,name,avatar,role')
            ->get()
            ->map(fn (DoctorMessage $message) => $this->messagePayload($message, $delegate->id));

        return $this->success([
            'conversation' => $conversation,
            'messages' => $messages
        ], 'تم جلب رسائل المحادثة بنجاح');
    }

    /**
     * Store a newly created message to a doctor.
     */
    public function store(Request $request)
    {
        $delegate = $request->user();

        $validator = Validator::make($request->all(), [
            'doctor_id' => 'required_without:conversation_id|exists:users,id',
            'conversation_id' => 'required_without:doctor_id|exists:doctor_conversations,id',
            'content' => 'required|string',
        ]);

        if ($validator->fails()) {
            return $this->error('بيانات غير صالحة', 422, $validator->errors());
        }

        if ($request->conversation_id) {
            $conversation = DoctorConversation::where('delegate_id', $delegate->id)->find($request->conversation_id);
        } else {
            // Start or continue conversation
            $doctor = User::where('id', $request->doctor_id)
                ->where('role', UserRole::DOCTOR)
                ->first();

            if (!$doctor) {
                return $this->error('الدكتور غير موجود', 404);
            }

            $conversation = DoctorConversation::getOrCreate($delegate->id, $doctor->id);
        }

        if (!$conversation) {
            return $this->error('المحادثة غير موجودة', 404);
        }

        $message = DoctorMessage::create([
            'conversation_id' => $conversation->id,
            'sender_id' => $delegate->id,
            'body' => $request->input('content'),
        ]);

        $conversation->update(['last_message_at' => now()]);

        return $this->success($this->messagePayload($message->load('sender:id,name,avatar,role'), $delegate->id), 'تم إرسال الرسالة بنجاح', 201);
    }

    /**
     * Get a list of doctors teaching the delegate's batch to start a conversation.
     */
    public function eligibleDoctors(Request $request)
    {
        $delegate = $request->user();

        // 1. Get subjects for this delegate's scope
        $subjects = \App\Models\Academic\Subject::where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->with('doctor:id,name,avatar,role')
            ->get();

        // 2. Extract unique doctors
        $doctors = $subjects->pluck('doctor')
            ->filter()
            ->unique('id')
            ->values();

        return $this->success($doctors, 'تم جلب قائمة الدكاترة بنجاح');
    }

    private function messagePayload(DoctorMessage $message, int $currentUserId): array
    {
        return [
            'id' => $message->id,
            'conversation_id' => $message->conversation_id,
            'sender_id' => $message->sender_id,
            'body' => $message->body,
            'read_at' => $message->read_at,
            'created_at' => $message->created_at,
            'updated_at' => $message->updated_at,
            'sender' => $message->sender,
            'is_mine' => (int) $message->sender_id === $currentUserId,
        ];
    }
}
