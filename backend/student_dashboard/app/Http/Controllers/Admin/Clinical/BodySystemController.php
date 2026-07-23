<?php

namespace App\Http\Controllers\Admin\Clinical;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Clinical\BodySystem;

class BodySystemController extends Controller
{
    public function index(Request $request)
    {
        // Admin only manages global constants (where doctor_id is null)
        $query = BodySystem::whereNull('doctor_id')->latest();
        
        if ($request->filled('search')) {
            $query->where('name', 'like', '%' . $request->search . '%');
        }
        
        $systems = $query->paginate(10)->withQueryString();
        return view('admin.clinical.body_systems.index', compact('systems'));
    }

    public function create()
    {
        return view('admin.clinical.body_systems.create');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000'
        ]);

        $validated['doctor_id'] = null; // Explicitly null for global constants
        BodySystem::create($validated);

        return redirect()->route('admin.clinical.body-systems.index')->with('success', 'تم إضافة الجهاز المرضي العام بنجاح.');
    }

    public function edit(string $id)
    {
        $bodySystem = BodySystem::whereNull('doctor_id')->findOrFail($id);
        return view('admin.clinical.body_systems.edit', compact('bodySystem'));
    }

    public function update(Request $request, string $id)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000'
        ]);

        $bodySystem = BodySystem::whereNull('doctor_id')->findOrFail($id);
        $bodySystem->update($validated);

        return redirect()->route('admin.clinical.body-systems.index')->with('success', 'تم تعديل الجهاز المرضي العام بنجاح.');
    }

    public function destroy(string $id)
    {
        $bodySystem = BodySystem::whereNull('doctor_id')->findOrFail($id);

        if ($bodySystem->cases()->exists()) {
            return back()->with('error', 'لا يمكن حذف هذا الجهاز العام لوجود حالات سريرية مرتبطة به.');
        }

        $bodySystem->delete();
        return redirect()->route('admin.clinical.body-systems.index')->with('success', 'تم مسح الجهاز المرضي العام بنجاح.');
    }
}
