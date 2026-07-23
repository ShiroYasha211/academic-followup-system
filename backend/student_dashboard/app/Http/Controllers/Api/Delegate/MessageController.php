<?php

namespace App\Http\Controllers\Api\Delegate;

use App\Enums\UserRole;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class MessageController extends DelegateApiController
{
    /**
     * Display a listing of conversations.
     */
    public function index(Request $request)
    {
        $delegate = $request->user();

        if (!$delegate->isCurrentClassDelegate()) {
            return $this->success([
                'conversations' => [],
            ], 'هذا الحساب ليس المندوب الأكاديمي الحالي لهذه الدفعة.');
        }

        $conversations = Conversation::where('delegate_id', $delegate->id)
            ->with(['student:id,name,avatar', 'lastMessage'])
            ->orderByDesc('last_message_at')
            ->get();

        return $this->success([
            'conversations' => $conversations,
        ], 'تم جلب المحادثات بنجاح');
    }

    /**
     * Display the specified conversation with messages.
     */
    public function show(Request $request, string $id)
    {
        $delegate = $request->user();

        if (!$delegate->isCurrentClassDelegate()) {
            return $this->error('هذا الحساب ليس المندوب الأكاديمي الحالي لهذه الدفعة.', 403);
        }

        $conversation = Conversation::where('delegate_id', $delegate->id)
            ->with('student:id,name,avatar')
            ->find($id);

        if (!$conversation) {
            $conversation = Conversation::where('delegate_id', $delegate->id)
                ->where('student_id', $id)
                ->first();

            if (!$conversation) {
                return $this->error('المحادثة غير موجودة', 404);
            }
        }

        $conversation->markAsReadFor($delegate->id);

        $messages = $conversation->messages()
            ->with('sender:id,name,avatar,role')
            ->get()
            ->map(fn (Message $message) => $this->messagePayload($message, $delegate->id));

        return $this->success([
            'conversation' => $conversation,
            'messages' => $messages,
        ], 'تم جلب رسائل المحادثة بنجاح');
    }

    /**
     * Store a newly created message.
     */
    public function store(Request $request)
    {
        $delegate = $request->user();

        if (!$delegate->isCurrentClassDelegate()) {
            return $this->error('هذا الحساب ليس المندوب الأكاديمي الحالي لهذه الدفعة.', 403);
        }

        $validator = Validator::make($request->all(), [
            'student_id' => 'required_without:conversation_id|exists:users,id',
            'conversation_id' => 'required_without:student_id|exists:conversations,id',
            'content' => 'required|string',
        ]);

        if ($validator->fails()) {
            return $this->error('بيانات غير صالحة', 422, $validator->errors());
        }

        if ($request->conversation_id) {
            $conversation = Conversation::where('delegate_id', $delegate->id)
                ->find($request->conversation_id);
        } else {
            $student = User::where('id', $request->student_id)
                ->whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
                ->where('major_id', $delegate->major_id)
                ->where('level_id', $delegate->level_id)
                ->first();

            if (!$student) {
                return $this->error('لا يمكنك مراسلة هذا المستخدم', 403);
            }

            $conversation = Conversation::getOrCreate($student->id, $delegate->id);
        }

        if (!$conversation) {
            return $this->error('المحادثة غير موجودة', 404);
        }

        $message = Message::create([
            'conversation_id' => $conversation->id,
            'sender_id' => $delegate->id,
            'receiver_id' => $conversation->student_id,
            'subject' => '',
            'body' => $request->input('content'),
            'type' => 'delegate_to_student',
        ]);

        $conversation->update(['last_message_at' => now()]);

        return $this->success(
            $this->messagePayload($message->load('sender:id,name,avatar,role'), $delegate->id),
            'تم إرسال الرسالة بنجاح',
            201
        );
    }

    /**
     * Get a list of students in the delegate's batch to start a conversation.
     */
    public function eligibleStudents(Request $request)
    {
        $delegate = $request->user();

        if (!$delegate->isCurrentClassDelegate()) {
            return $this->success([], 'هذا الحساب ليس المندوب الأكاديمي الحالي لهذه الدفعة.');
        }

        $students = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->where('id', '!=', $delegate->id)
            ->select('id', 'name', 'university_id', 'avatar')
            ->orderBy('name')
            ->get();

        return $this->success($students, 'تم جلب قائمة الطلاب بنجاح');
    }

    private function messagePayload(Message $message, int $currentUserId): array
    {
        return [
            'id' => $message->id,
            'conversation_id' => $message->conversation_id,
            'sender_id' => $message->sender_id,
            'receiver_id' => $message->receiver_id,
            'subject' => $message->subject,
            'body' => $message->body,
            'type' => $message->type,
            'read_at' => $message->read_at,
            'created_at' => $message->created_at,
            'updated_at' => $message->updated_at,
            'sender' => $message->sender,
            'is_mine' => (int) $message->sender_id === $currentUserId,
        ];
    }
}
