<?php

namespace App\Http\Controllers\Delegate\Clinical;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Clinical\ClinicalSubDelegation;
use Illuminate\Support\Facades\Auth;

class SubDelegationController extends Controller
{
    public function index()
    {
        if (!Auth::user()->isClinicalDelegate()) {
            abort(403, 'Unauthorized action. Only main Clinical Delegates can manage sub-delegations.');
        }

        $delegator = Auth::user();
        
        $subDelegations = ClinicalSubDelegation::with('student')
            ->where('delegator_id', $delegator->id)
            ->latest()
            ->paginate(15);

        // Fetch students only from the same cohort as the delegator
        $students = User::where('role', 'student')
            ->where('id', '!=', $delegator->id)
            ->where('university_id', $delegator->university_id)
            ->where('college_id', $delegator->college_id)
            ->where('major_id', $delegator->major_id)
            ->where('level_id', $delegator->level_id)
            ->get(['id', 'name', 'university_id', 'major_id', 'level_id']); 

        return view('delegate.clinical.delegations.index', compact('subDelegations', 'students'));
    }

    public function store(Request $request)
    {
        if (!Auth::user()->isClinicalDelegate()) {
            abort(403);
        }

        $request->validate([
            'student_id' => 'required|exists:users,id',
            'duration_hours' => 'required|integer|min:1|max:168', // up to 1 week
        ]);

        $delegator = Auth::user();
        $student = User::findOrFail($request->student_id);

        // Security check: Student must be in the same cohort
        if (
            $student->university_id !== $delegator->university_id ||
            $student->college_id !== $delegator->college_id ||
            $student->major_id !== $delegator->major_id ||
            $student->level_id !== $delegator->level_id
        ) {
            return redirect()->back()->with('error', 'عذراً لا يمكنك منح صلاحية لطالب من دفعة أو تخصص مختلف.');
        }

        $exists = ClinicalSubDelegation::where('delegator_id', Auth::id())
            ->where('student_id', $request->student_id)
            ->where('is_revoked', false)
            ->where(function ($query) {
                $query->whereNull('expires_at')
                      ->orWhere('expires_at', '>', now());
            })->exists();

        if ($exists) {
            return redirect()->back()->with('error', 'هذا الطالب لديه صلاحية فعالة حالياً ولم تنتهي بعد.');
        }

        ClinicalSubDelegation::create([
            'delegator_id' => Auth::id(),
            'student_id' => $request->student_id,
            'expires_at' => now()->addHours((int) $request->duration_hours),
            'is_revoked' => false,
        ]);

        return redirect()->route('delegate.clinical.delegations.index')
            ->with('success', 'تم منح الصلاحية كـ (مندوب فرعي) للطالب بنجاح.');
    }

    public function revoke(ClinicalSubDelegation $delegation)
    {
        if (!Auth::user()->isClinicalDelegate() || $delegation->delegator_id !== Auth::id()) {
            abort(403);
        }

        $delegation->update(['is_revoked' => true]);

        return redirect()->route('delegate.clinical.delegations.index')
            ->with('success', 'تم سحب الصلاحية من الطالب وإيقافه فوراً.');
    }
}
