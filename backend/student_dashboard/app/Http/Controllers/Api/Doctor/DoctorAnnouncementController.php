<?php

namespace App\Http\Controllers\Api\Doctor;

use App\Models\Academic\Subject;
use App\Models\DoctorAnnouncement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;

class DoctorAnnouncementController extends DoctorApiController
{
    public function index(Request $request)
    {
        $doctor = Auth::user();
        $type = $request->get('type', 'all');

        $announcements = DoctorAnnouncement::forDoctor($doctor->id)
            ->ofType($type)
            ->with('subject')
            ->latest()
            ->paginate(20);

        $announcements->getCollection()->transform(fn ($announcement) => $this->serialize($announcement));

        return response()->json([
            'success' => true,
            'message' => 'تم جلب إعلانات الدكتور بنجاح',
            'data' => $announcements->items(),
            'filters' => [
                'subjects' => Subject::where('doctor_id', $doctor->id)
                    ->orderBy('name')
                    ->get(['id', 'name']),
            ],
            'pagination' => [
                'current_page' => $announcements->currentPage(),
                'last_page' => $announcements->lastPage(),
                'per_page' => $announcements->perPage(),
                'total' => $announcements->total(),
            ],
        ]);
    }

    public function store(Request $request)
    {
        $doctor = Auth::user();

        $validated = $request->validate([
            'subject_id' => 'required|exists:subjects,id',
            'type' => 'required|in:announcement,warning,quiz_alert',
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'attachment' => 'nullable|file|max:10240',
            'published_at' => 'nullable|date',
        ]);

        Subject::where('id', $validated['subject_id'])
            ->where('doctor_id', $doctor->id)
            ->firstOrFail();

        $data = [
            'doctor_id' => $doctor->id,
            'subject_id' => $validated['subject_id'],
            'type' => $validated['type'],
            'title' => $validated['title'],
            'content' => $validated['content'],
            'published_at' => $validated['published_at'] ?? now(),
            'is_published' => empty($validated['published_at']) || now()->gte($validated['published_at']),
        ];

        if ($request->hasFile('attachment')) {
            $file = $request->file('attachment');
            $data['attachment_path'] = $file->store('doctor-announcements', 'public');
            $data['attachment_name'] = $file->getClientOriginalName();
        }

        $announcement = DoctorAnnouncement::create($data);

        return $this->success($this->serialize($announcement->load('subject')), 'تم إنشاء الإعلان بنجاح.', 201);
    }

    public function show($id)
    {
        $announcement = DoctorAnnouncement::where('doctor_id', Auth::id())
            ->with('subject')
            ->findOrFail($id);

        return $this->success($this->serialize($announcement), 'تم جلب الإعلان بنجاح.');
    }

    public function update(Request $request, $id)
    {
        $announcement = DoctorAnnouncement::where('doctor_id', Auth::id())->findOrFail($id);

        $validated = $request->validate([
            'subject_id' => 'sometimes|exists:subjects,id',
            'type' => 'sometimes|in:announcement,warning,quiz_alert',
            'title' => 'sometimes|string|max:255',
            'content' => 'sometimes|string',
            'attachment' => 'nullable|file|max:10240',
            'published_at' => 'nullable|date',
        ]);

        if (isset($validated['subject_id'])) {
            Subject::where('id', $validated['subject_id'])
                ->where('doctor_id', Auth::id())
                ->firstOrFail();
        }

        $announcement->fill($validated);
        $announcement->is_published = empty($validated['published_at']) || now()->gte($validated['published_at'] ?? $announcement->published_at);

        if ($request->hasFile('attachment')) {
            if ($announcement->attachment_path) {
                Storage::disk('public')->delete($announcement->attachment_path);
            }

            $file = $request->file('attachment');
            $announcement->attachment_path = $file->store('doctor-announcements', 'public');
            $announcement->attachment_name = $file->getClientOriginalName();
        }

        $announcement->save();

        return $this->success($this->serialize($announcement->load('subject')), 'تم تحديث الإعلان بنجاح.');
    }

    public function destroy($id)
    {
        $announcement = DoctorAnnouncement::where('doctor_id', Auth::id())->findOrFail($id);

        if ($announcement->attachment_path) {
            Storage::disk('public')->delete($announcement->attachment_path);
        }

        $announcement->delete();

        return $this->success(null, 'تم حذف الإعلان بنجاح.');
    }

    protected function serialize(DoctorAnnouncement $announcement): array
    {
        return array_merge($announcement->toArray(), [
            'attachment_url' => $announcement->attachment_path
                ? asset('storage/' . $announcement->attachment_path)
                : null,
        ]);
    }
}
