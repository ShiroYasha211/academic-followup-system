<?php

namespace App\Http\Controllers\Api\Student;

use Illuminate\Http\Request;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;

class MessageController extends StudentApiController
{
    /**
     * Display conversations list.
     */
    public function index(Request $request)
    {
        $user = $request->user();

        $delegate = User::currentClassDelegateFor($user);

        $conversations = collect();

        if ($delegate) {
            $conversations = Conversation::where('student_id', $user->id)
                ->where('delegate_id', $delegate->id)
                ->with(['delegate:id,name', 'lastMessage'])
                ->orderByDesc('last_message_at')
                ->get()
                ->map(function (Conversation $conversation) use ($user) {
                    $conversation->setAttribute('unread_count', $conversation->unreadCountFor($user->id));
                    return $conversation;
                });
        }

        $unreadCount = $conversations->sum(function (Conversation $conversation) {
            return (int) $conversation->getAttribute('unread_count');
        });

        return $this->success([
            'delegate' => $delegate ? ['id' => $delegate->id, 'name' => $delegate->name] : null,
            'unread_count' => $unreadCount,
            'conversations' => $conversations,
        ]);
    }

    /**
     * Show a specific conversation with messages.
     */
    public function show(Request $request, $id)
    {
        $user = $request->user();

        $delegate = User::currentClassDelegateFor($user);

        if (!$delegate) {
            return $this->error('لا يوجد مندوب نشط لدفعتك حالياً', 404);
        }

        $conversation = Conversation::where('student_id', $user->id)
            ->where('delegate_id', $delegate->id)
            ->with('delegate:id,name')
            ->findOrFail($id);

        $conversation->markAsReadFor($user->id);

        $messages = $conversation->messages()
            ->with('sender:id,name,role')
            ->orderBy('created_at', 'asc')
            ->get();

        return $this->success([
            'conversation' => $conversation,
            'messages' => $messages,
        ]);
    }

    /**
     * Start a new conversation with delegate.
     */
    public function start(Request $request)
    {
        $user = $request->user();

        $delegate = User::currentClassDelegateFor($user);

        if (!$delegate) {
            return $this->error('لا يوجد مندوب لشعبتك حالياً', 404);
        }

        $conversation = Conversation::getOrCreate($user->id, $delegate->id);

        return $this->success([
            'conversation_id' => $conversation->id,
            'message' => 'تم بدء أو فتح المحادثة بنجاح.',
        ]);
    }

    /**
     * Send a message in a conversation.
     */
    public function send(Request $request, $id)
    {
        $request->validate([
            'body' => 'required|string|max:2000',
        ]);

        $user = $request->user();

        $delegate = User::currentClassDelegateFor($user);

        if (!$delegate) {
            return $this->error('لا يوجد مندوب نشط لدفعتك حالياً', 404);
        }

        $conversation = Conversation::where('student_id', $user->id)
            ->where('delegate_id', $delegate->id)
            ->findOrFail($id);

        $message = Message::create([
            'conversation_id' => $conversation->id,
            'sender_id' => $user->id,
            'receiver_id' => $conversation->delegate_id,
            'subject' => '',
            'body' => $request->body,
            'type' => 'student_to_delegate',
        ]);

        $conversation->update(['last_message_at' => now()]);

        return $this->success([
            'message_id' => $message->id,
            'body' => $message->body,
            'created_at' => $message->created_at,
        ], 'تم إرسال الرسالة بنجاح.');
    }
}
