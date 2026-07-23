<?php

namespace App\Http\Controllers\Delegate;

use App\Http\Controllers\Controller;
use App\Models\DoctorConversation;
use App\Models\DoctorMessage;
use App\Models\User;
use App\Models\Academic\Subject;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class DoctorChatController extends Controller
{
    /**
     * Display conversations list with doctors.
     */
    public function index()
    {
        $user = Auth::user();

        // Get all conversations for this delegate
        $conversations = DoctorConversation::where('delegate_id', $user->id)
            ->with(['doctor', 'lastMessage'])
            ->orderByDesc('last_message_at')
            ->get();

        return view('delegate.doctor_chat.index', compact('conversations'));
    }

    /**
     * Show a specific conversation with messages.
     */
    public function show($id)
    {
        $user = Auth::user();

        // Get the conversation
        $conversation = DoctorConversation::where('delegate_id', $user->id)
            ->with('doctor')
            ->findOrFail($id);

        // Mark all messages as read
        $conversation->markAsReadFor($user->id);

        // Get messages
        $messages = $conversation->messages()->with('sender')->get();

        // Get all conversations for sidebar
        $conversations = DoctorConversation::where('delegate_id', $user->id)
            ->with(['doctor', 'lastMessage'])
            ->orderByDesc('last_message_at')
            ->get();

        return view('delegate.doctor_chat.index', compact('conversations', 'conversation', 'messages'));
    }

    /**
     * Start a new conversation with a doctor.
     */
    public function create()
    {
        $user = Auth::user();

        // Get subjects for this delegate's major/level
        $subjects = Subject::where('major_id', $user->major_id)
            ->where('level_id', $user->level_id)
            ->with('doctor')
            ->get();

        // Get unique doctors from subjects
        $doctors = $subjects->pluck('doctor')->filter()->unique('id');

        return view('delegate.doctor_chat.create', compact('doctors'));
    }

    /**
     * Start conversation with selected doctor.
     */
    public function store(Request $request)
    {
        $request->validate([
            'doctor_id' => 'required|exists:users,id',
        ]);

        $user = Auth::user();

        // Get or create conversation
        $conversation = DoctorConversation::getOrCreate($user->id, $request->doctor_id);

        return redirect()->route('delegate.doctor-chat.show', $conversation->id);
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

        $conversation = DoctorConversation::where('delegate_id', $user->id)->findOrFail($id);

        // Create the message
        DoctorMessage::create([
            'conversation_id' => $conversation->id,
            'sender_id' => $user->id,
            'body' => $request->body,
        ]);

        // Update conversation timestamp
        $conversation->update(['last_message_at' => now()]);

        return redirect()->route('delegate.doctor-chat.show', $conversation->id);
    }
}
