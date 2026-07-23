<?php

namespace App\Http\Controllers\Delegate;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Reminder;
use Illuminate\Support\Facades\Auth;

class ReminderController extends Controller
{
    public function index(Request $request)
    {
        $delegate = Auth::user();
        $filter = $request->get('filter', 'upcoming');

        $query = Reminder::where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id);

        if ($filter === 'upcoming') {
            $query->where('notify_at', '>=', now())
                ->orderBy('event_date', 'asc');
        } elseif ($filter === 'past') {
            $query->where('notify_at', '<', now())
                ->orderBy('event_date', 'desc');
        } else {
            $query->orderBy('event_date', 'asc');
        }

        $reminders = $query->paginate(10);

        $stats = [
            'total' => Reminder::where('major_id', $delegate->major_id)->where('level_id', $delegate->level_id)->count(),
            'upcoming' => Reminder::where('major_id', $delegate->major_id)->where('level_id', $delegate->level_id)->where('notify_at', '>=', now())->count(),
            'past' => Reminder::where('major_id', $delegate->major_id)->where('level_id', $delegate->level_id)->where('notify_at', '<', now())->count(),
        ];

        return view('delegate.reminders.index', compact('reminders', 'filter', 'stats'));
    }

    public function store(Request $request)
    {
        $delegate = Auth::user();

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'event_date' => 'required|date',
            'notify_at' => 'required|date',
        ]);

        Reminder::create([
            'title' => $validated['title'],
            'description' => $validated['description'],
            'event_date' => $validated['event_date'],
            'notify_at' => $validated['notify_at'],
            'major_id' => $delegate->major_id,
            'level_id' => $delegate->level_id,
            'created_by' => $delegate->id,
        ]);

        return redirect()->back()->with('success', 'تم جدولة التذكير بنجاح.');
    }

    public function update(Request $request, Reminder $reminder)
    {
        $delegate = Auth::user();

        if ($reminder->created_by != $delegate->id) {
            abort(403);
        }

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'event_date' => 'required|date',
            'notify_at' => 'required|date',
        ]);

        $reminder->update($validated);

        return redirect()->back()->with('success', 'تم تحديث التذكير.');
    }

    public function destroy(Reminder $reminder)
    {
        $delegate = Auth::user();

        if ($reminder->created_by != $delegate->id) {
            abort(403);
        }

        $reminder->delete();

        return redirect()->back()->with('success', 'تم حذف التذكير.');
    }
}
