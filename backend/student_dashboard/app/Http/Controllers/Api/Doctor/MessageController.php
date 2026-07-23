<?php

namespace App\Http\Controllers\Api\Doctor;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\DoctorConversation;
use App\Models\DoctorMessage;
use App\Models\User;
use App\Models\Academic\Subject;

class MessageController extends DoctorApiController
{
    protected function eligibleDelegatesQuery()
    {
        $doctor = Auth::user();
        $subjectScopes = Subject::where('doctor_id', $doctor->id)
            ->get(['major_id', 'level_id']);

        if ($subjectScopes->isEmpty()) {
            return User::whereRaw('1 = 0');
        }

        return User::whereIn('role', ['delegate', 'practical_delegate'])
            ->where(function ($query) use ($subjectScopes) {
                foreach ($subjectScopes as $scope) {
                    $query->orWhere(function ($inner) use ($scope) {
                        $inner->where('major_id', $scope->major_id)
                            ->where('level_id', $scope->level_id);
                    });
                }
            });
    }

    /** GET /api/doctor/messages */
    public function index()
    {
        $conversations = DoctorConversation::where('doctor_id', Auth::id())
            ->with([
                'delegate:id,name,student_number,role,major_id,level_id',
                'delegate.major:id,name',
                'delegate.level:id,name',
                'lastMessage'
            ])
            ->orderByDesc('last_message_at')
            ->get()
            ->map(fn($c) => [
                'id' => $c->id,
                'delegate' => $c->delegate ? [
                    'id' => $c->delegate->id,
                    'name' => $c->delegate->name,
                    'student_number' => $c->delegate->student_number,
                    'role' => $this->roleValue($c->delegate),
                    'major' => $c->delegate->major?->name,
                    'level' => $c->delegate->level?->name,
                ] : null,
                'last_message' => $c->lastMessage?->body,
                'last_message_is_mine' => $c->lastMessage?->sender_id === Auth::id(),
                'last_message_at' => $c->last_message_at,
                'unread_count' => $c->messages()->where('sender_id', '!=', Auth::id())->whereNull('read_at')->count(),
            ]);

        return $this->success($conversations);
    }

    /** GET /api/doctor/messages/delegates */
    public function delegates(Request $request)
    {
        $delegates = $this->eligibleDelegatesQuery()
            ->when($request->filled('search'), function ($query) use ($request) {
                $search = $request->search;
                $query->where(function ($inner) use ($search) {
                    $inner->where('name', 'like', "%{$search}%")
                        ->orWhere('student_number', 'like', "%{$search}%");
                });
            })
            ->with(['major:id,name', 'level:id,name'])
            ->orderBy('name')
            ->get(['id', 'name', 'student_number', 'role', 'major_id', 'level_id'])
            ->map(fn($d) => [
                'id' => $d->id,
                'name' => $d->name,
                'student_number' => $d->student_number,
                'role' => $this->roleValue($d),
                'major' => $d->major?->name,
                'level' => $d->level?->name,
            ]);

        return $this->success($delegates);
    }

    /** GET /api/doctor/messages/{conversation} */
    public function show($id)
    {
        $conversation = DoctorConversation::where('doctor_id', Auth::id())
            ->with('delegate:id,name,student_number,role')
            ->findOrFail($id);

        $conversation->markAsReadFor(Auth::id());

        $messages = $conversation->messages()->with('sender:id,name')->get()->map(fn($m) => [
            'id' => $m->id,
            'body' => $m->body,
            'sender' => $m->sender ? ['id' => $m->sender->id, 'name' => $m->sender->name] : null,
            'is_mine' => $m->sender_id === Auth::id(),
            'is_read' => $m->read_at !== null,
            'created_at' => $m->created_at,
        ]);

        return $this->success([
            'conversation' => [
                'id' => $conversation->id,
                'delegate' => $conversation->delegate ? [
                    'id' => $conversation->delegate->id,
                    'name' => $conversation->delegate->name,
                    'student_number' => $conversation->delegate->student_number,
                    'role' => $this->roleValue($conversation->delegate),
                ] : null,
            ],
            'messages' => $messages,
        ]);
    }

    /** POST /api/doctor/messages */
    public function store(Request $request)
    {
        $request->validate(['delegate_id' => 'required|exists:users,id']);

        $delegate = $this->eligibleDelegatesQuery()
            ->whereKey($request->delegate_id)
            ->first();

        if (! $delegate) {
            return $this->error('المندوب المحدد خارج نطاق موادك.', 403);
        }

        $conversation = DoctorConversation::getOrCreate($request->delegate_id, Auth::id());

        return $this->success(['conversation_id' => $conversation->id], 'تم إنشاء المحادثة.', 201);
    }

    /** POST /api/doctor/messages/{conversation}/send */
    public function send(Request $request, $id)
    {
        $request->validate(['body' => 'required|string|max:2000']);

        $conversation = DoctorConversation::where('doctor_id', Auth::id())->findOrFail($id);

        $message = DoctorMessage::create([
            'conversation_id' => $conversation->id,
            'sender_id' => Auth::id(),
            'body' => $request->body,
        ]);

        $conversation->update(['last_message_at' => now()]);

        return $this->success([
            'id' => $message->id,
            'body' => $message->body,
            'created_at' => $message->created_at,
        ], 'تم إرسال الرسالة.');
    }

    public function delegateInfo($id)
    {
        $conversation = DoctorConversation::where('doctor_id', Auth::id())
            ->findOrFail($id);

        $delegate = User::with(['major:id,name', 'level:id,name', 'college:id,name'])
            ->findOrFail($conversation->delegate_id);

        $otherDelegates = User::whereIn('role', ['delegate', 'practical_delegate'])
            ->where('college_id', $delegate->college_id)
            ->where('id', '!=', $delegate->id)
            ->where('status', 'active')
            ->with(['major:id,name', 'level:id,name'])
            ->get()
            ->map(fn($d) => [
                'id' => $d->id,
                'name' => $d->name,
                'student_number' => $d->student_number,
                'role' => $this->roleValue($d),
                'major' => $d->major?->name,
                'level' => $d->level?->name,
            ]);

        return $this->success([
            'delegate' => [
                'id' => $delegate->id,
                'name' => $delegate->name,
                'student_number' => $delegate->student_number,
                'role' => $this->roleValue($delegate),
                'email' => $delegate->email,
                'college' => $delegate->college?->name,
                'major' => $delegate->major?->name,
                'level' => $delegate->level?->name,
            ],
            'other_delegates' => $otherDelegates,
        ]);
    }

    private function roleValue(User $user): string
    {
        return $user->role instanceof \BackedEnum
            ? $user->role->value
            : (string) $user->role;
    }
}
