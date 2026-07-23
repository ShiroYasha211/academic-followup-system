<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class MessageController extends Controller
{
    /**
     * Display conversations list.
     */
    public function index()
    {
        $user = Auth::user();

        // Get delegate for this student
        $delegate = User::currentClassDelegateFor($user);

        $conversations = collect();

        if ($delegate) {
            $conversations = Conversation::where('student_id', $user->id)
                ->where('delegate_id', $delegate->id)
                ->with(['delegate', 'lastMessage'])
                ->orderByDesc('last_message_at')
                ->get();
        }

        return view('student.messages.index', compact('conversations', 'delegate'));
    }

    /**
     * Show a specific conversation with messages.
     */
    public function show($id)
    {
        $user = Auth::user();

        // Get delegate for this student
        $delegate = User::currentClassDelegateFor($user);

        if (!$delegate) {
            return redirect()->route('student.messages.index')
                ->with('error', 'لا يوجد مندوب نشط لدفعتك حالياً');
        }

        // Get the conversation
        $conversation = Conversation::where('student_id', $user->id)
            ->where('delegate_id', $delegate->id)
            ->with('delegate')
            ->findOrFail($id);

        // Mark all messages as read
        $conversation->markAsReadFor($user->id);

        // Get messages
        $messages = $conversation->messages()->with('sender')->get();

        // Get all conversations for sidebar
        $conversations = Conversation::where('student_id', $user->id)
            ->where('delegate_id', $delegate->id)
            ->with(['delegate', 'lastMessage'])
            ->orderByDesc('last_message_at')
            ->get();

        return view('student.messages.index', compact('conversations', 'conversation', 'messages', 'delegate'));
    }

    /**
     * Start a new conversation with delegate.
     */
    public function start()
    {
        $user = Auth::user();

        // Get delegate for this student
        $delegate = User::currentClassDelegateFor($user);

        if (!$delegate) {
            return redirect()->route('student.messages.index')
                ->with('error', 'لا يوجد مندوب لشعبتك حالياً');
        }

        // Get or create conversation
        $conversation = Conversation::getOrCreate($user->id, $delegate->id);

        return redirect()->route('student.messages.show', $conversation->id);
    }

    /**
     * Send a message in a conversation.
     */
    public function send(Request $request, $id)
    {
        $request->validate([
            'body' => 'required|string|max:2000',
        ]);

        $user = Auth::user();

        $delegate = User::currentClassDelegateFor($user);

        if (!$delegate) {
            return redirect()->route('student.messages.index')
                ->with('error', 'لا يوجد مندوب نشط لدفعتك حالياً');
        }

        $conversation = Conversation::where('student_id', $user->id)
            ->where('delegate_id', $delegate->id)
            ->findOrFail($id);

        // Create the message
        Message::create([
            'conversation_id' => $conversation->id,
            'sender_id' => $user->id,
            'receiver_id' => $conversation->delegate_id,
            'subject' => '',
            'body' => $request->body,
            'type' => 'student_to_delegate',
        ]);

        // Update conversation timestamp
        $conversation->update(['last_message_at' => now()]);

        return redirect()->route('student.messages.show', $conversation->id);
    }
}
