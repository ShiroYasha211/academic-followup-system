<?php

namespace App\Http\Controllers\Api\Admin;

use App\Enums\UserRole;
use App\Models\ActivityLog;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class AdministrativeController extends AdminApiController
{
    /**
     * Display a listing of legacy administrative users.
     */
    public function index(Request $request)
    {
        $query = User::where('role', UserRole::ADMINISTRATIVE)
            ->with(['university', 'college'])
            ->latest();

        if ($request->search) {
            $query->where(function ($q) use ($request) {
                $q->where('name', 'like', "%{$request->search}%")
                    ->orWhere('email', 'like', "%{$request->search}%");
            });
        }

        if ($request->college_id) {
            $query->where('college_id', $request->college_id);
        }

        return $this->paginated($query->paginate($request->per_page ?? 10));
    }

    /**
     * Direct administrative account creation is disabled.
     */
    public function store(Request $request)
    {
        return $this->error('Direct administrative account creation is disabled. Create a doctor account and set administrative_access=true instead.', 422);
    }

    /**
     * Display the specified legacy administrative user.
     */
    public function show(User $administrative)
    {
        if ($administrative->role !== UserRole::ADMINISTRATIVE) {
            return $this->error('User is not a legacy administrative account.', 404);
        }

        return $this->success($administrative->load(['university', 'college']));
    }

    /**
     * Update the specified legacy administrative user.
     */
    public function update(Request $request, User $administrative)
    {
        if ($administrative->role !== UserRole::ADMINISTRATIVE) {
            return $this->error('User is not a legacy administrative account.', 404);
        }

        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users,email,' . $administrative->id,
            'password' => ['nullable', 'confirmed', Password::defaults()],
            'college_id' => 'required|exists:colleges,id',
            'status' => 'required|in:active,inactive',
        ]);

        $college = \App\Models\Academic\College::findOrFail($request->college_id);

        $administrative->update([
            'name' => $request->name,
            'email' => $request->email,
            'college_id' => $request->college_id,
            'university_id' => $college->university_id,
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
            "Updated legacy administrative account via API: {$administrative->name}"
        );

        return $this->success($administrative->fresh()->load('college'), 'Legacy administrative account updated successfully.');
    }

    /**
     * Remove the specified legacy administrative user.
     */
    public function destroy(User $administrative)
    {
        if ($administrative->role !== UserRole::ADMINISTRATIVE) {
            return $this->error('User is not a legacy administrative account.', 404);
        }

        $name = $administrative->name;
        $administrative->delete();

        ActivityLog::log(
            'delete',
            'User',
            null,
            $name,
            "Deleted legacy administrative account via API: {$name}"
        );

        return $this->success(null, 'Legacy administrative account deleted successfully.');
    }
}
