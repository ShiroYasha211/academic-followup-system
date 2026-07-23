<?php

namespace App\Http\Controllers\Doctor;

use App\Http\Controllers\Controller;
use App\Models\DoctorConversation;
use App\Models\DoctorMessage;
use App\Models\User;
use App\Models\Academic\Subject;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class DoctorMessageController extends Controller
{
    /**
     * Display conversations list with delegates.
     */
    public function index()
    {
        $user = Auth::user();

        // Get all conversations for this doctor
        $conversations = DoctorConversation::where('doctor_id', $user->id)
            ->with(['delegate', 'lastMessage'])
            ->orderByDesc('last_message_at')
            ->get();

        return view('doctor.messages.index', compact('conversations'));
    }

    /**
     * Show a specific conversation with messages.
     */
    public function show($id)
    {
        $user = Auth::user();

        // Get the conversation
        $conversation = DoctorConversation::where('doctor_id', $user->id)
            ->with('delegate')
            ->findOrFail($id);

        // Mark all messages as read
        $conversation->markAsReadFor($user->id);

        // Get messages
        $messages = $conversation->messages()->with('sender')->get();

        // Get all conversations for sidebar
        $conversations = DoctorConversation::where('doctor_id', $user->id)
            ->with(['delegate', 'lastMessage'])
            ->orderByDesc('last_message_at')
            ->get();

        return view('doctor.messages.index', compact('conversations', 'conversation', 'messages'));
    }

    /**
     * Start a new conversation with a delegate.
     */
    public function create()
    {
        $user = Auth::user();

        // Get subjects assigned to this doctor
        $subjects = Subject::where('doctor_id', $user->id)->get();

        // Get delegates from those subjects' majors/levels
        $delegates = User::where('role', 'delegate')
            ->whereIn('major_id', $subjects->pluck('major_id'))
            ->whereIn('level_id', $subjects->pluck('level_id'))
            ->get();

        return view('doctor.messages.create', compact('delegates'));
    }

    /**
     * Start conversation with selected delegate.
     */
    public function store(Request $request)
    {
        $request->validate([
            'delegate_id' => 'required|exists:users,id',
        ]);

        $user = Auth::user();

        // Get or create conversation
        $conversation = DoctorConversation::getOrCreate($request->delegate_id, $user->id);

        return redirect()->route('doctor.messages.show', $conversation->id);
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

        $conversation = DoctorConversation::where('doctor_id', $user->id)->findOrFail($id);

        // Create the message
        DoctorMessage::create([
            'conversation_id' => $conversation->id,
            'sender_id' => $user->id,
            'body' => $request->body,
        ]);

        // Update conversation timestamp
        $conversation->update(['last_message_at' => now()]);

        return redirect()->route('doctor.messages.show', $conversation->id);
    }
}
