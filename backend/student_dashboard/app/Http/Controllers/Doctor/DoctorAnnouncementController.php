<?php

namespace App\Http\Controllers\Doctor;

use App\Http\Controllers\Controller;
use App\Models\DoctorAnnouncement;
use App\Models\Academic\Subject;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;

class DoctorAnnouncementController extends Controller
{
    /**
     * Display a list of the doctor's announcements.
     */
    public function index(Request $request)
    {
        $doctor = Auth::user();
        $type = $request->get('type', 'all');

        $announcements = DoctorAnnouncement::forDoctor($doctor->id)
            ->ofType($type)
            ->latest()
            ->paginate(12);

        $subjects = Subject::where('doctor_id', $doctor->id)->get();

        return view('doctor.announcements.index', compact('announcements', 'subjects', 'type'));
    }

    /**
     * Show the form for creating a new announcement.
     */
    public function create()
    {
        $doctor = Auth::user();
        $subjects = Subject::where('doctor_id', $doctor->id)->get();

        return view('doctor.announcements.create', compact('subjects'));
    }

    /**
     * Store a newly created announcement.
     */
    public function store(Request $request)
    {
        $doctor = Auth::user();

        $validated = $request->validate([
            'subject_id'   => 'required|exists:subjects,id',
            'type'         => 'required|in:announcement,warning,quiz_alert',
            'title'        => 'required|string|max:255',
            'content'      => 'required|string',
            'attachment'   => 'nullable|file|max:10240',
            'published_at' => 'nullable|date',
        ]);

        // Verify the doctor owns this subject
        $subject = Subject::where('id', $validated['subject_id'])
            ->where('doctor_id', $doctor->id)
            ->firstOrFail();

        $data = [
            'doctor_id'    => $doctor->id,
            'subject_id'   => $validated['subject_id'],
            'type'         => $validated['type'],
            'title'        => $validated['title'],
            'content'      => $validated['content'],
            'published_at' => $validated['published_at'] ?? now(),
            'is_published' => empty($validated['published_at']) || now()->gte($validated['published_at']),
        ];

        // Handle attachment
        if ($request->hasFile('attachment')) {
            $file = $request->file('attachment');
            $path = $file->store('doctor-announcements', 'public');
            $data['attachment_path'] = $path;
            $data['attachment_name'] = $file->getClientOriginalName();
        }

        DoctorAnnouncement::create($data);

        return redirect()->route('doctor.announcements.index')
            ->with('success', 'تم إنشاء الإعلان بنجاح.');
    }

    /**
     * Show the form for editing the specified announcement.
     */
    public function edit(DoctorAnnouncement $announcement)
    {
        $doctor = Auth::user();

        // Ensure ownership
        if ($announcement->doctor_id !== $doctor->id) {
            abort(403);
        }

        $subjects = Subject::where('doctor_id', $doctor->id)->get();

        return view('doctor.announcements.edit', compact('announcement', 'subjects'));
    }

    /**
     * Update the specified announcement.
     */
    public function update(Request $request, DoctorAnnouncement $announcement)
    {
        $doctor = Auth::user();

        if ($announcement->doctor_id !== $doctor->id) {
            abort(403);
        }

        $validated = $request->validate([
            'subject_id'   => 'required|exists:subjects,id',
            'type'         => 'required|in:announcement,warning,quiz_alert',
            'title'        => 'required|string|max:255',
            'content'      => 'required|string',
            'attachment'   => 'nullable|file|max:10240',
            'published_at' => 'nullable|date',
        ]);

        // Verify subject ownership
        Subject::where('id', $validated['subject_id'])
            ->where('doctor_id', $doctor->id)
            ->firstOrFail();

        $announcement->fill([
            'subject_id'   => $validated['subject_id'],
            'type'         => $validated['type'],
            'title'        => $validated['title'],
            'content'      => $validated['content'],
            'published_at' => $validated['published_at'] ?? $announcement->published_at,
            'is_published' => empty($validated['published_at']) || now()->gte($validated['published_at']),
        ]);

        // Handle attachment update
        if ($request->hasFile('attachment')) {
            // Delete old attachment
            if ($announcement->attachment_path) {
                Storage::disk('public')->delete($announcement->attachment_path);
            }
            $file = $request->file('attachment');
            $announcement->attachment_path = $file->store('doctor-announcements', 'public');
            $announcement->attachment_name = $file->getClientOriginalName();
        }

        $announcement->save();

        return redirect()->route('doctor.announcements.index')
            ->with('success', 'تم تحديث الإعلان بنجاح.');
    }

    /**
     * Remove the specified announcement.
     */
    public function destroy(DoctorAnnouncement $announcement)
    {
        $doctor = Auth::user();

        if ($announcement->doctor_id !== $doctor->id) {
            abort(403);
        }

        if ($announcement->attachment_path) {
            Storage::disk('public')->delete($announcement->attachment_path);
        }

        $announcement->delete();

        return redirect()->route('doctor.announcements.index')
            ->with('success', 'تم حذف الإعلان بنجاح.');
    }
}
