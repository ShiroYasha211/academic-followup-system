<?php

namespace App\Http\Controllers\Doctor\Clinical;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Clinical\TrainingCenter;

class TrainingCenterController extends Controller
{
    public function index(Request $request)
    {
        $query = TrainingCenter::latest();
        if ($request->filled('search')) {
            $query->where('name', 'like', '%' . $request->search . '%')
                ->orWhere('location', 'like', '%' . $request->search . '%');
        }
        $centers = $query->paginate(10)->withQueryString();
        return view('doctor.clinical.training_centers.index', compact('centers'));
    }

    public function create()
    {
        return view('doctor.clinical.training_centers.create');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'location' => 'nullable|string|max:255',
            'description' => 'nullable|string|max:1000'
        ]);

        TrainingCenter::create($validated);

        return redirect()->route('doctor.clinical.training-centers.index')->with('success', 'تم إضافة المركز التدريبي بنجاح.');
    }

    public function show(string $id)
    {
        // Not used
    }

    public function edit(string $id)
    {
        $trainingCenter = TrainingCenter::findOrFail($id);
        return view('doctor.clinical.training_centers.edit', compact('trainingCenter'));
    }

    public function update(Request $request, string $id)
    {
        $trainingCenter = TrainingCenter::findOrFail($id);

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'location' => 'nullable|string|max:255',
            'description' => 'nullable|string|max:1000'
        ]);

        $trainingCenter->update($validated);

        return redirect()->route('doctor.clinical.training-centers.index')->with('success', 'تم تحديث المركز التدريبي بنجاح.');
    }

    public function destroy(string $id)
    {
        $trainingCenter = TrainingCenter::findOrFail($id);

        // Prevent deletion if it has cases
        if ($trainingCenter->cases()->exists()) {
            return back()->with('error', 'لا يمكن حذف هذا المركز لوجود حالات سريرية مرتبطة به.');
        }

        $trainingCenter->delete();
        return redirect()->route('doctor.clinical.training-centers.index')->with('success', 'تم مسح المركز التدريبي بنجاح.');
    }
}
