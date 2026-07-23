<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;

class RegistrationRequestController extends Controller
{
    /**
     * Display a listing of the pending registration requests.
     */
    public function index(Request $request)
    {
        // Get all users with 'pending' status
        $pendingRequests = User::where('status', 'pending')
            ->visibleToAdmin($request->user())
            ->with(['university', 'college', 'major', 'level'])
            ->latest()
            ->paginate(15);

        return view('admin.registration_requests.index', compact('pendingRequests'));
    }

    /**
     * Approve the registration request.
     */
    public function approve(User $user)
    {
        $this->abortIfProtected($user);

        if ($user->status !== 'pending') {
            return back()->with('error', 'هذا الحساب ليس قيد المراجعة.');
        }

        $user->update(['status' => 'active']);

        return back()->with('success', "تم اعتماد حساب {$user->name} بنجاح.");
    }

    /**
     * Reject the registration request by deleting the user.
     */
    public function reject(User $user)
    {
        $this->abortIfProtected($user);

        if ($user->status !== 'pending') {
            return back()->with('error', 'هذا الحساب ليس قيد المراجعة.');
        }

        // Hard delete since it was never approved, or soft delete if preferred.
        // We'll use forceDelete() to completely wipe the rejected request to allow them to re-register later.
        $user->forceDelete();

        return back()->with('success', "تم رفض وحذف حساب {$user->name} بنجاح.");
    }

    protected function abortIfProtected(User $user): void
    {
        if ($user->isProtectedFrom(auth()->user())) {
            abort(404);
        }
    }
}
