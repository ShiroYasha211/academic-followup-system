<?php

namespace App\Models;

use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Database\Eloquent\SoftDeletes;
use Laravel\Sanctum\HasApiTokens;
use App\Enums\UserRole;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int,string>
     */
    protected $fillable = [
        'name',
        'gender',
        'email',
        'password',
        'role',
        'is_system_owner',
        'administrative_access',
        'status',
        'student_number',
        'university_id',
        'college_id',
        'major_id',
        'level_id',
        'balance',
        'subscribed_until',
        'auto_renew',
        'assignment_sort_by',
        'allowed_secondary_devices',
    ];

    /**
     * The attributes that should be hidden for arrays.
     *
     * @var array<int,string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Casts.
     *
     * @var array<string,string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'role' => UserRole::class,
        'is_system_owner' => 'boolean',
        'gender' => 'string',
        'administrative_access' => 'boolean',
        'balance' => 'decimal:2',
        'subscribed_until' => 'datetime',
        'auto_renew' => 'boolean',
        'allowed_secondary_devices' => 'integer',
    ];

    /**
     * Check if the user has an active subscription.
     */
    public function isSubscribed(): bool
    {
        if ($this->role === UserRole::ADMIN) {
            return true;
        }

        return $this->subscribed_until && $this->subscribed_until->isFuture();
    }

    public function isSystemOwner(): bool
    {
        return (bool) $this->is_system_owner;
    }

    public function canManageSystemOwners(): bool
    {
        return $this->isSystemOwner();
    }

    public function isProtectedFrom(?self $actor): bool
    {
        return $this->isSystemOwner() && !$actor?->canManageSystemOwners();
    }

    public function scopeVisibleToAdmin($query, ?self $viewer)
    {
        if (!$viewer?->canManageSystemOwners()) {
            $query->where('is_system_owner', false);
        }

        return $query;
    }

    /**
     * Cards used by this user.
     */
    public function usedCards()
    {
        return $this->hasMany(Card::class, 'used_by_id');
    }

    public function flashcardUserSetting()
    {
        return $this->hasOne(FlashcardUserSetting::class);
    }

    /**
     * Check if the user has a given role.
     */
    public function hasRole(UserRole|string $role): bool
    {
        if (is_string($role)) {
            return $this->role->value === $role;
        }
        return $this->role === $role;
    }

    /**
     * Check whether this doctor can access the administrative workspace.
     */
    public function isDoctorWithAdministrativeAccess(): bool
    {
        return $this->role === UserRole::DOCTOR && (bool) $this->administrative_access;
    }

    /**
     * Check whether the user can access the doctor workspace.
     */
    public function canAccessDoctorWorkspace(): bool
    {
        return in_array($this->role, [UserRole::DOCTOR, UserRole::ADMINISTRATIVE], true);
    }

    /**
     * Check whether the user can access the administrative workspace.
     */
    public function canAccessAdministrativeWorkspace(): bool
    {
        return $this->role === UserRole::ADMINISTRATIVE || $this->isDoctorWithAdministrativeAccess();
    }

    /**
     * Check whether the user can access the delegate workspace.
     *
     * This centralizes the practical-delegate identity so legacy
     * clinical assignments and explicit practical_delegate roles
     * behave the same from the application's perspective.
     */
    public function canAccessDelegateWorkspace(): bool
    {
        return in_array($this->role, [UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE, UserRole::ADMIN], true)
            || $this->hasClinicalDelegateAssignment();
    }

    /**
     * Check whether the user can access the student workspace.
     */
    public function canAccessStudentWorkspace(): bool
    {
        return in_array($this->role, [UserRole::STUDENT, UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE], true)
            || $this->hasClinicalDelegateAssignment();
    }

    /**
     * Resolve the active academic delegate for a student's batch.
     */
    public static function currentClassDelegateFor(User $student): ?self
    {
        return self::query()
            ->where('role', UserRole::DELEGATE)
            ->when($student->college_id, fn ($query) => $query->where('college_id', $student->college_id))
            ->where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->where('status', 'active')
            ->orderByDesc('updated_at')
            ->orderByDesc('id')
            ->first();
    }

    public function isCurrentClassDelegate(): bool
    {
        $delegate = self::currentClassDelegateFor($this);

        return $delegate && (int) $delegate->id === (int) $this->id;
    }

    public function canAccessClinicalWorkspace(): bool
    {
        if ($this->major?->has_clinical) {
            return true;
        }

        if ($this->role === UserRole::DOCTOR) {
            return $this->subjects()
                ->whereHas('major', function ($query) {
                    $query->where('has_clinical', true);
                })
                ->exists();
        }

        return false;
    }

    /**
     * Return all workspaces available to the user.
     */
    public function availableWorkspaces(): array
    {
        $workspaces = [];

        if ($this->canAccessDoctorWorkspace()) {
            $workspaces[] = 'doctor';
        }

        if ($this->canAccessAdministrativeWorkspace()) {
            $workspaces[] = 'administrative';
        }

        return array_values(array_unique($workspaces));
    }

    /**
     * Return the default workspace for redirects.
     */
    public function preferredWorkspace(): string
    {
        if ($this->role === UserRole::ADMINISTRATIVE) {
            return 'administrative';
        }

        if ($this->role === UserRole::DOCTOR) {
            return 'doctor';
        }

        if ($this->isPracticalDelegate()) {
            return UserRole::PRACTICAL_DELEGATE->value;
        }

        return $this->role->value;
    }
    public function university()
    {
        return $this->belongsTo(\App\Models\Academic\University::class);
    }

    public function college()
    {
        return $this->belongsTo(\App\Models\Academic\College::class);
    }

    public function major()
    {
        return $this->belongsTo(\App\Models\Academic\Major::class);
    }

    public function level()
    {
        return $this->belongsTo(\App\Models\Academic\Level::class);
    }

    /**
     * المواد التي يدرسها الدكتور.
     */
    public function subjects()
    {
        return $this->hasMany(\App\Models\Academic\Subject::class, 'doctor_id');
    }

    public function dailyLogsAsStudent()
    {
        return $this->hasMany(\App\Models\Clinical\StudentDailyLog::class, 'student_id');
    }

    /**
     * Students and delegates that belong to a doctor's clinical teaching scope.
     *
     * Students and all delegate types are matched by the doctor's subject
     * major+level. Practical delegate assignments are also level-scoped.
     */
    public function scopeInDoctorClinicalScope($query, int $doctorId)
    {
        $doctorSubjects = \App\Models\Academic\Subject::where('doctor_id', $doctorId)
            ->select('major_id', 'level_id')
            ->distinct()
            ->get();

        if ($doctorSubjects->isEmpty()) {
            return $query->whereRaw('1 = 0');
        }

        return $query->where(function ($outer) use ($doctorSubjects) {
            $outer->where(function ($scope) use ($doctorSubjects) {
                $scope->whereIn('role', [
                    UserRole::STUDENT,
                    UserRole::DELEGATE,
                    UserRole::PRACTICAL_DELEGATE,
                ])->where(function ($academicScope) use ($doctorSubjects) {
                    foreach ($doctorSubjects as $subject) {
                        $academicScope->orWhere(function ($query) use ($subject) {
                            $query->where('major_id', $subject->major_id)
                                ->where('level_id', $subject->level_id);
                        });
                    }
                });
            });

            $outer->orWhereHas('clinicalDelegateAssignment', function ($assignmentScope) use ($doctorSubjects) {
                $assignmentScope->where(function ($academicScope) use ($doctorSubjects) {
                    foreach ($doctorSubjects as $subject) {
                        $academicScope->orWhere(function ($query) use ($subject) {
                            $query->where('major_id', $subject->major_id)
                                ->where('level_id', $subject->level_id);
                        });
                    }
                });
            });
        });
    }

    /**
     * Get the attendances for the student.
     */
    public function attendances()
    {
        return $this->hasMany(\App\Models\Attendance::class, 'student_id');
    }

    /**
     * Get the grades for the student.
     */
    public function grades()
    {
        return $this->hasMany(\App\Models\Grade::class, 'student_id');
    }

    public function devices()
    {
        return $this->hasMany(UserDevice::class);
    }

    public function studentDevices()
    {
        return $this->hasMany(StudentDevice::class, 'student_id');
    }

    public function activeStudentDevices()
    {
        return $this->hasMany(StudentDevice::class, 'student_id')->where('is_active', true);
    }

    public function primaryStudentDevice()
    {
        return $this->hasOne(StudentDevice::class, 'student_id')->where('is_primary', true);
    }

    public function studentDeviceRequests()
    {
        return $this->hasMany(StudentDeviceRequest::class, 'student_id');
    }

    /**
     * Get the student notes.
     */
    public function studentNotes()
    {
        return $this->hasMany(\App\Models\StudentNote::class, 'student_id');
    }

    // --- Clinical Constants Customizations (For Doctors) ---
    
    public function customClinicalDepartments()
    {
        return $this->hasMany(\App\Models\Clinical\ClinicalDepartment::class, 'doctor_id');
    }

    public function hiddenClinicalDepartments()
    {
        return $this->belongsToMany(\App\Models\Clinical\ClinicalDepartment::class, 'doctor_hidden_departments', 'doctor_id', 'department_id')->withTimestamps();
    }

    public function customBodySystems()
    {
        return $this->hasMany(\App\Models\Clinical\BodySystem::class, 'doctor_id');
    }

    public function hiddenBodySystems()
    {
        return $this->belongsToMany(\App\Models\Clinical\BodySystem::class, 'doctor_hidden_body_systems', 'doctor_id', 'body_system_id')->withTimestamps();
    }

    public function hiddenChecklists()
    {
        return $this->belongsToMany(\App\Models\Clinical\EvaluationChecklist::class, 'doctor_hidden_checklists', 'doctor_id', 'checklist_id')->withTimestamps();
    }

    /**
     * Check if the user is assigned as a clinical delegate.
     */
    public function clinicalDelegateAssignment()
    {
        return $this->hasOne(\App\Models\ClinicalDelegate::class, 'student_id');
    }

    public function hasClinicalDelegateAssignment(): bool
    {
        if ($this->relationLoaded('clinicalDelegateAssignment')) {
            return $this->clinicalDelegateAssignment !== null;
        }

        return $this->clinicalDelegateAssignment()->exists();
    }

    /**
     * Unified practical delegate identity.
     *
     * A user is considered a practical delegate if they explicitly carry
     * the role or if they still rely on the legacy clinical assignment row.
     */
    public function isPracticalDelegate(): bool
    {
        return $this->role === UserRole::PRACTICAL_DELEGATE || $this->hasClinicalDelegateAssignment();
    }

    public function isClinicalDelegate(): bool
    {
        return $this->hasClinicalDelegateAssignment();
    }

    public function receivedSubDelegations()
    {
        return $this->hasMany(\App\Models\Clinical\ClinicalSubDelegation::class, 'student_id');
    }

    public function isClinicalSubDelegate()
    {
        return $this->receivedSubDelegations()
            ->where('is_revoked', false)
            ->where(function ($query) {
                $query->whereNull('expires_at')
                      ->orWhere('expires_at', '>', now());
            })->exists();
    }

    public function canAccessClinicalDelegateWorkspace(): bool
    {
        return $this->isClinicalDelegate() || $this->isClinicalSubDelegate();
    }

    /**
     * Permissions relationship.
     */
    public function permissions()
    {
        return $this->belongsToMany(Permission::class);
    }

    /**
     * Check if user has a specific granular permission.
     */
    public function hasPermission(string $slug): bool
    {
        return $this->permissions()->where('slug', $slug)->exists();
    }

    /**
     * Grant a permission to the user.
     */
    public function givePermission(string $slug): void
    {
        $permission = Permission::where('slug', $slug)->first();
        if ($permission) {
            $this->permissions()->syncWithoutDetaching([$permission->id]);
        }
    }

    /**
     * Revoke a permission from the user.
     */
    public function revokePermission(string $slug): void
    {
        $permission = Permission::where('slug', $slug)->first();
        if ($permission) {
            $this->permissions()->detach($permission->id);
        }
    }

    /**
     * Get the transactions for the user.
     */
    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }

    /**
     * Record a financial transaction and update balance.
     */
    public function recordTransaction($amount, $type, $action, $description, $reference = null, $metadata = null)
    {
        return \Illuminate\Support\Facades\DB::transaction(function () use ($amount, $type, $action, $description, $reference, $metadata) {
            $balanceBefore = $this->balance;
            
            // Adjust balance
            if ($amount > 0) {
                $this->increment('balance', $amount);
            } elseif ($amount < 0) {
                $this->decrement('balance', abs($amount));
            }
            
            $this->refresh();
            $balanceAfter = $this->balance;

            return $this->transactions()->create([
                'amount' => $amount,
                'type' => $type,
                'action' => $action,
                'description' => $description,
                'balance_before' => $balanceBefore,
                'balance_after' => $balanceAfter,
                'reference_id' => $reference ? $reference->id : null,
                'reference_type' => $reference ? get_class($reference) : null,
                'metadata' => $metadata,
            ]);
        });
    }

    /**
     * Grade Delegation Relationships.
     */
    public function gradePermissions()
    {
        return $this->hasMany(\App\Models\GradePermission::class, 'authorized_user_id');
    }

    public function delegatedGradeCategories()
    {
        return $this->belongsToMany(\App\Models\GradeCategory::class, 'grade_permissions', 'authorized_user_id', 'category_id')->withTimestamps();
    }

    public function delegatedGradeHelperTasks()
    {
        return $this->hasMany(\App\Models\DelegateGradeDelegation::class, 'helper_user_id');
    }

    public function issuedGradeHelperTasks()
    {
        return $this->hasMany(\App\Models\DelegateGradeDelegation::class, 'delegated_by_id');
    }

    /**
     * جلسات التحضير الخاصة بالدكتور (عبر المواد التي يدرسها).
     */
    public function qrSessions()
    {
        return $this->hasManyThrough(
            \App\Models\QrAttendanceSession::class,
            \App\Models\Academic\Subject::class,
            'doctor_id',   // المفتاح الأجنبي في جدول المواد
            'subject_id',  // المفتاح الأجنبي في جدول جلسات التحضير
            'id',          // المفتاح المحلي في جدول المستخدمين
            'id'           // المفتاح المحلي في جدول المواد
        );
    }

    // ─── Delegate Permissions System ───

    /**
     * Get all delegate permissions for this user.
     */
    public function delegatePermissions()
    {
        return $this->hasMany(\App\Models\DelegatePermission::class);
    }

    /**
     * Get a simple array of delegate permissions strings (e.g., ["students.create", "students.delete"]).
     */
    public function getAllDelegatePermissionsAttribute(): array
    {
        return $this->delegatePermissions()
            ->get(['resource', 'action'])
            ->map(fn($p) => "{$p->resource}.{$p->action}")
            ->toArray();
    }

    /**
     * Check if user has a specific delegate permission.
     */
    public function hasDelegatePermission(string $resource, string $action): bool
    {
        return $this->delegatePermissions()
            ->where('resource', $resource)
            ->where('action', $action)
            ->exists();
    }

    /**
     * Grant all default delegate permissions.
     */
    public function grantAllDelegatePermissions(int $grantedBy): void
    {
        $excluded = [
            'students.update',
            'students.delete',
            'exams.update',
        ];

        foreach (\App\Models\DelegatePermission::RESOURCES as $resource => $label) {
            foreach (\App\Models\DelegatePermission::ACTIONS as $action => $actionLabel) {
                if (in_array("{$resource}.{$action}", $excluded, true)) {
                    continue;
                }

                \App\Models\DelegatePermission::firstOrCreate(
                    ['user_id' => $this->id, 'resource' => $resource, 'action' => $action],
                    ['granted_by' => $grantedBy]
                );
            }
        }
    }

    /**
     * Revoke all delegate permissions.
     */
    public function revokeDelegatePermissions(): void
    {
        $this->delegatePermissions()->delete();
    }

    // ─── Flashcard / One Line Shot ───

    /**
     * Get all flashcard packs belonging to this user.
     */
    public function flashcardPacks()
    {
        return $this->hasMany(FlashcardPack::class);
    }

    // ─── Stars Currency System ───

    /**
     * Get all star transactions for this user.
     */
    public function starTransactions()
    {
        return $this->hasMany(StarTransaction::class);
    }

    public function doctorStarWallet()
    {
        return $this->hasOne(DoctorStarWallet::class, 'doctor_id');
    }

    /**
     * Add stars to this user's balance.
     */
    public function addStars(int $amount, string $type, ?int $grantedBy = null, ?string $description = null, ?object $reference = null): StarTransaction
    {
        $this->increment('stars_balance', $amount);
        $this->increment('total_stars_earned', $amount);

        return StarTransaction::create([
            'user_id'        => $this->id,
            'granted_by'     => $grantedBy,
            'type'           => $type,
            'amount'         => $amount,
            'balance_after'  => $this->fresh()->stars_balance,
            'description'    => $description,
            'reference_type' => $reference ? get_class($reference) : null,
            'reference_id'   => $reference?->id,
        ]);
    }

    /**
     * Deduct stars from this user's balance.
     */
    public function deductStars(int $amount, string $type, ?int $grantedBy = null, ?string $description = null): StarTransaction
    {
        $amount = abs($amount);
        $this->decrement('stars_balance', min($amount, $this->stars_balance));

        return StarTransaction::create([
            'user_id'       => $this->id,
            'granted_by'    => $grantedBy,
            'type'          => $type,
            'amount'        => -$amount,
            'balance_after' => $this->fresh()->stars_balance,
            'description'   => $description,
        ]);
    }

    /**
     * Gift stars to another user.
     */
    public function giftStars(User $recipient, int $amount, ?string $description = null): bool
    {
        app(\App\Services\StudentStarGiftService::class)
            ->gift($this, $recipient, $amount, $description);
        return true;
    }
}

