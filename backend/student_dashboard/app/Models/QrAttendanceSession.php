<?php

namespace App\Models;

use App\Enums\UserRole;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Collection;
use Illuminate\Support\Str;

class QrAttendanceSession extends Model
{
    public const PARTICIPANT_ROLES = [
        UserRole::STUDENT,
        UserRole::DELEGATE,
        UserRole::PRACTICAL_DELEGATE,
    ];

    protected $fillable = [
        'subject_id',
        'delegate_id',
        'date',
        'title',
        'lecture_number',
        'current_token',
        'token_expires_at',
        'status',
    ];

    protected $casts = [
        'date' => 'date',
        'token_expires_at' => 'datetime',
    ];

    public function subject()
    {
        return $this->belongsTo(\App\Models\Academic\Subject::class);
    }

    public function delegate()
    {
        return $this->belongsTo(User::class, 'delegate_id');
    }

    public function verifications()
    {
        return $this->hasMany(QrAttendanceVerification::class, 'qr_attendance_session_id');
    }

    public function rotateToken(): string
    {
        $newToken = Str::random(48) . bin2hex(random_bytes(8));
        $this->current_token = $newToken;
        $this->token_expires_at = Carbon::now()->addSeconds($this->rotationSeconds());
        $this->save();

        return $newToken;
    }

    public function rotationSeconds(): int
    {
        $seconds = (int) ($this->subject?->major?->college?->qr_rotation_seconds ?? 30);

        return max(5, $seconds);
    }

    public function isTokenValid(string $token): bool
    {
        return $this->current_token === $token
            && $this->token_expires_at->isFuture()
            && $this->status === 'active';
    }

    public function isActive(): bool
    {
        return $this->status === 'active';
    }

    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    public function createVerificationSnapshot(): void
    {
        if ($this->verifications()->exists()) {
            return;
        }

        $subject = $this->subject;
        if (!$subject) {
            return;
        }

        $students = User::query()
            ->whereIn('role', self::PARTICIPANT_ROLES)
            ->where('major_id', $subject->major_id)
            ->where('level_id', $subject->level_id)
            ->orderBy('name')
            ->get(['id']);

        if ($students->isEmpty()) {
            return;
        }

        $presentStudentIds = Attendance::query()
            ->where('qr_attendance_session_id', $this->id)
            ->where('status', Attendance::STATUS_PRESENT)
            ->pluck('student_id')
            ->unique()
            ->values();

        $missingScanStudents = $students
            ->whereNotIn('id', $presentStudentIds)
            ->pluck('id')
            ->values();

        $sampledPresentStudents = $this->selectVerificationSample($presentStudentIds);

        $rows = [];

        foreach ($missingScanStudents as $studentId) {
            $rows[] = [
                'qr_attendance_session_id' => $this->id,
                'student_id' => $studentId,
                'verification_type' => 'missing_scan',
                'verification_status' => 'pending',
                'created_at' => now(),
                'updated_at' => now(),
            ];
        }

        foreach ($sampledPresentStudents as $studentId) {
            $rows[] = [
                'qr_attendance_session_id' => $this->id,
                'student_id' => $studentId,
                'verification_type' => 'sample_check',
                'verification_status' => 'pending',
                'created_at' => now(),
                'updated_at' => now(),
            ];
        }

        if (!empty($rows)) {
            QrAttendanceVerification::insert($rows);
        }
    }

    public function buildVerificationPayload(): array
    {
        $verificationRows = $this->verifications()
            ->with('student:id,name,student_number,gender')
            ->get();

        $missingScan = $verificationRows
            ->where('verification_type', 'missing_scan')
            ->values();

        $sampleCheck = $verificationRows
            ->where('verification_type', 'sample_check')
            ->values();

        return [
            'summary' => [
                'missing_scan_count' => $missingScan->count(),
                'sample_check_count' => $sampleCheck->count(),
                'total_verification_count' => $verificationRows->count(),
            ],
            'missing_scan_students' => $missingScan->map(fn (QrAttendanceVerification $verification) => $this->mapVerificationRow($verification))->values(),
            'sample_check_students' => $sampleCheck->map(fn (QrAttendanceVerification $verification) => $this->mapVerificationRow($verification))->values(),
        ];
    }

    protected function selectVerificationSample(Collection $presentStudentIds): Collection
    {
        if ($presentStudentIds->isEmpty()) {
            return collect();
        }

        $sampleSize = max(1, (int) ceil($presentStudentIds->count() * 0.20));

        return $presentStudentIds
            ->sortBy(fn ($studentId) => sprintf('%u', crc32($this->id . '-' . $studentId)))
            ->take($sampleSize)
            ->values();
    }

    protected function mapVerificationRow(QrAttendanceVerification $verification): array
    {
        return [
            'id' => $verification->id,
            'student_id' => $verification->student_id,
            'name' => $verification->student?->name,
            'student_number' => $verification->student?->student_number,
            'gender' => $verification->student?->gender,
            'verification_type' => $verification->verification_type,
            'verification_status' => $verification->verification_status,
        ];
    }
}
