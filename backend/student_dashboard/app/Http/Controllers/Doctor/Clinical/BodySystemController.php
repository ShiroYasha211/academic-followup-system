<?php

namespace App\Http\Controllers\Doctor\Clinical;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Clinical\BodySystem;
use Illuminate\Support\Facades\Auth;

class BodySystemController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $user = Auth::user();
        $hiddenIds = $user->hiddenBodySystems()->pluck('body_systems.id')->toArray();

        $query = BodySystem::where(function ($q) use ($user, $hiddenIds) {
            // Global constants not hidden by the doctor
            $q->whereNull('doctor_id');
            if (!empty($hiddenIds)) {
                $q->whereNotIn('id', $hiddenIds);
            }
        })->orWhere('doctor_id', $user->id)->latest();

        if ($request->filled('search')) {
            $query->where('name', 'like', '%' . $request->search . '%');
        }
        $systems = $query->paginate(10)->withQueryString();
        return view('doctor.clinical.body_systems.index', compact('systems'));
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        return view('doctor.clinical.body_systems.create');
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000'
        ]);

        $validated['doctor_id'] = Auth::id(); // Assign to current doctor

        BodySystem::create($validated);

        return redirect()->route('doctor.clinical.body-systems.index')->with('success', 'تم إضافة الجهاز المرضي بنجاح.');
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(string $id)
    {
        $user = Auth::user();
        $bodySystem = BodySystem::where(function ($q) use ($user) {
            $q->whereNull('doctor_id')->orWhere('doctor_id', $user->id);
        })->findOrFail($id);

        return view('doctor.clinical.body_systems.edit', compact('bodySystem'));
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000'
        ]);

        $user = Auth::user();
        $bodySystem = BodySystem::where(function ($q) use ($user) {
            $q->whereNull('doctor_id')->orWhere('doctor_id', $user->id);
        })->findOrFail($id);

        if (is_null($bodySystem->doctor_id)) {
            // Editing a global constant -> hide the global one and create a personal one
            $user->hiddenBodySystems()->syncWithoutDetaching([$bodySystem->id]);

            $validated['doctor_id'] = $user->id;
            BodySystem::create($validated);

            return redirect()->route('doctor.clinical.body-systems.index')->with('success', 'تم إنشاء نسخة مخصصة من الجهاز العام بنجاح.');
        } else {
            // Updating their own custom constant
            $bodySystem->update($validated);
            return redirect()->route('doctor.clinical.body-systems.index')->with('success', 'تم تعديل الجهاز المرضي بنجاح.');
        }
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        $user = Auth::user();
        $bodySystem = BodySystem::where(function ($q) use ($user) {
            $q->whereNull('doctor_id')->orWhere('doctor_id', $user->id);
        })->findOrFail($id);

        // Prevent deletion if it has cases attached by THIS doctor
        if ($bodySystem->cases()->where('doctor_id', $user->id)->exists()) {
            return back()->with('error', 'لا يمكن إخفاء/حذف هذا الجهاز لوجود حالات سريرية خاصة بك مرتبطة به.');
        }

        if (is_null($bodySystem->doctor_id)) {
            // Deleting a global constant -> simply hide it
            $user->hiddenBodySystems()->syncWithoutDetaching([$bodySystem->id]);
            return redirect()->route('doctor.clinical.body-systems.index')->with('success', 'تم إخفاء الجهاز العام من قائمتك بنجاح.');
        } else {
            // Deleting their own constant -> actually delete
            $bodySystem->delete();
            return redirect()->route('doctor.clinical.body-systems.index')->with('success', 'تم مسح الجهاز المرضي المخصص بنجاح.');
        }
    }

    /**
     * Restore standard hidden body systems.
     */
    public function restoreDefaults()
    {
        Auth::user()->hiddenBodySystems()->detach();
        return redirect()->route('doctor.clinical.body-systems.index')->with('success', 'تم استرداد الأجهزة المرضية الأساسية بنجاح.');
    }
}
