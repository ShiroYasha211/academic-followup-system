<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class DesktopPairingCode extends Model
{
    protected $fillable = [
        'user_id',
        'workspace',
        'subject_id',
        'attendance_date',
        'session_title',
        'lecture_number',
        'code',
        'device_name',
        'expires_at',
        'used_at',
    ];

    protected $casts = [
        'attendance_date' => 'date',
        'expires_at' => 'datetime',
        'used_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function subject()
    {
        return $this->belongsTo(\App\Models\Academic\Subject::class);
    }

    public function scopeUsable(Builder $query): Builder
    {
        return $query
            ->whereNull('used_at')
            ->where('expires_at', '>', now());
    }

    public function isUsable(): bool
    {
        return is_null($this->used_at) && $this->expires_at?->isFuture();
    }

    public function consume(?string $deviceName = null): void
    {
        $this->forceFill([
            'used_at' => now(),
            'device_name' => $deviceName ?: $this->device_name,
        ])->save();
    }

    public static function generateUniqueCode(): string
    {
        $alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

        do {
            $code = collect(range(1, 8))
                ->map(fn () => $alphabet[random_int(0, strlen($alphabet) - 1)])
                ->implode('');
        } while (static::query()->where('code', $code)->exists());

        return $code;
    }

    public static function normalizeCode(string $code): string
    {
        return Str::upper(preg_replace('/[^A-Z0-9]/', '', $code));
    }

    public function formattedCode(): string
    {
        return substr($this->code, 0, 4) . '-' . substr($this->code, 4, 4);
    }
}
