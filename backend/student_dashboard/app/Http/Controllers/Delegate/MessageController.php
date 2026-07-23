<?php

namespace App\Http\Controllers\Delegate;

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

        if (!$user->isCurrentClassDelegate()) {
            $conversations = collect();

            return view('delegate.messages.index', compact('conversations'))
                ->with('warning', 'هذا الحساب ليس المندوب الأكاديمي الحالي لهذه الدفعة.');
        }

        // Get all conversations where delegate is this user
        $conversations = Conversation::where('delegate_id', $user->id)
            ->with(['student', 'lastMessage'])
            ->orderByDesc('last_message_at')
            ->get();

        return view('delegate.messages.index', compact('conversations'));
    }

    /**
     * Show a specific conversation with messages.
     */
    public function show($id)
    {
        $user = Auth::user();

        if (!$user->isCurrentClassDelegate()) {
            return redirect()->route('delegate.messages.index')
                ->with('error', 'هذا الحساب ليس المندوب الأكاديمي الحالي لهذه الدفعة.');
        }

        // Get the conversation
        $conversation = Conversation::where('delegate_id', $user->id)
            ->with('student')
            ->findOrFail($id);

        // Mark all messages as read
        $conversation->markAsReadFor($user->id);

        // Get messages
        $messages = $conversation->messages()->with('sender')->get();

        // Get all conversations for sidebar
        $conversations = Conversation::where('delegate_id', $user->id)
            ->with(['student', 'lastMessage'])
            ->orderByDesc('last_message_at')
            ->get();

        return view('delegate.messages.index', compact('conversations', 'conversation', 'messages'));
    }

    /**
     * Start a new conversation with a student.
     */
    public function create(Request $request)
    {
        $user = Auth::user();

        if (!$user->isCurrentClassDelegate()) {
            return redirect()->route('delegate.messages.index')
                ->with('error', 'هذا الحساب ليس المندوب الأكاديمي الحالي لهذه الدفعة.');
        }

        // Get students in this delegate's level/major
        $students = User::whereIn('role', ['student', 'delegate'])
            ->where('major_id', $user->major_id)
            ->where('level_id', $user->level_id)
            ->orderBy('name')
            ->get();

        return view('delegate.messages.create', compact('students'));
    }

    /**
     * Start conversation with selected student.
     */
    public function store(Request $request)
    {
        $request->validate([
            'student_id' => 'required|exists:users,id',
        ]);

        $user = Auth::user();

        if (!$user->isCurrentClassDelegate()) {
            return redirect()->route('delegate.messages.index')
                ->with('error', 'هذا الحساب ليس المندوب الأكاديمي الحالي لهذه الدفعة.');
        }

        // Verify student is in delegate's level/major
        $student = User::where('id', $request->student_id)
            ->whereIn('role', ['student', 'delegate'])
            ->where('major_id', $user->major_id)
            ->where('level_id', $user->level_id)
            ->first();

        if (!$student) {
            return back()->with('error', 'الطالب غير موجود');
        }

        // Get or create conversation
        $conversation = Conversation::getOrCreate($student->id, $user->id);

        return redirect()->route('delegate.messages.show', $conversation->id);
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

        if (!$user->isCurrentClassDelegate()) {
            return redirect()->route('delegate.messages.index')
                ->with('error', 'هذا الحساب ليس المندوب الأكاديمي الحالي لهذه الدفعة.');
        }

        $conversation = Conversation::where('delegate_id', $user->id)->findOrFail($id);

        // Create the message
        Message::create([
            'conversation_id' => $conversation->id,
            'sender_id' => $user->id,
            'receiver_id' => $conversation->student_id,
            'subject' => '',
            'body' => $request->body,
            'type' => 'delegate_to_student',
        ]);

        // Update conversation timestamp
        $conversation->update(['last_message_at' => now()]);

        return redirect()->route('delegate.messages.show', $conversation->id);
    }
}
