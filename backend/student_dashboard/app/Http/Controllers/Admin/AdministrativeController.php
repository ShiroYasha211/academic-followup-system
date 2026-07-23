<?php

namespace App\Http\Controllers\Admin;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\Academic\College;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class AdministrativeController extends Controller
{
    /**
     * Display a listing of administrative users.
     */
    public function index()
    {
        $administratives = User::query()
            ->where(function ($query) {
                $query->where('role', UserRole::ADMINISTRATIVE)
                    ->orWhere(function ($doctorQuery) {
                        $doctorQuery->where('role', UserRole::DOCTOR)
                            ->where('administrative_access', true);
                    });
            })
            ->with('college')
            ->latest()
            ->paginate(10);

        return view('admin.administratives.index', compact('administratives'));
    }

    /**
     * Administrative accounts are no longer created directly.
     */
    public function create()
    {
        return redirect()
            ->route('admin.administratives.index')
            ->with('info', 'Administrative access is granted from the Doctors page. Create or edit a doctor account and enable administrative access there.');
    }

    /**
     * Administrative accounts are no longer created directly.
     */
    public function store(Request $request)
    {
        return redirect()
            ->route('admin.administratives.index')
            ->with('error', 'Direct administrative account creation is disabled. Promote a doctor from the Doctors page instead.');
    }

    /**
     * Show the form for editing the specified legacy administrative user.
     */
    public function edit(User $administrative)
    {
        if ($administrative->role !== UserRole::ADMINISTRATIVE) {
            abort(404);
        }

        $colleges = College::orderBy('name')->get();

        return view('admin.administratives.edit', [
            'administrative' => $administrative,
            'colleges' => $colleges,
        ]);
    }

    /**
     * Update the specified legacy administrative user in storage.
     */
    public function update(Request $request, User $administrative)
    {
        if ($administrative->role !== UserRole::ADMINISTRATIVE) {
            abort(404);
        }

        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users,email,' . $administrative->id,
            'password' => ['nullable', 'confirmed', Password::defaults()],
            'college_id' => 'required|exists:colleges,id',
            'status' => 'required|in:active,inactive',
        ]);

        $administrative->update([
            'name' => $request->name,
            'email' => $request->email,
            'college_id' => $request->college_id,
            'status' => $request->status,
        ]);

        if ($request->filled('password')) {
            $administrative->update([
                'password' => Hash::make($request->password),
            ]);
        }

        ActivityLog::log(
            'update',
            'User',
            $administrative->id,
            $administrative->name,
            "Updated legacy administrative account: {$administrative->name}"
        );

        return redirect()
            ->route('admin.administratives.index')
            ->with('success', 'Legacy administrative account updated successfully.');
    }

    /**
     * Remove the specified legacy administrative user from storage.
     */
    public function destroy(User $administrative)
    {
        if ($administrative->role !== UserRole::ADMINISTRATIVE) {
            abort(404);
        }

        $name = $administrative->name;
        $administrative->delete();

        ActivityLog::log(
            'delete',
            'User',
            null,
            $name,
            "Deleted legacy administrative account: {$name}"
        );

        return redirect()
            ->route('admin.administratives.index')
            ->with('success', 'Legacy administrative account deleted successfully.');
    }
}
