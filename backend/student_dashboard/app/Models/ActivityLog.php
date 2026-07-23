<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ActivityLog extends Model
{
    protected $fillable = [
        'user_id',
        'user_name',
        'action',
        'model_type',
        'model_id',
        'model_name',
        'description',
        'old_values',
        'new_values',
        'ip_address',
    ];

    protected $casts = [
        'old_values' => 'array',
        'new_values' => 'array',
    ];

    /**
     * المستخدم الذي قام بالعملية
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * تسجيل نشاط جديد
     */
    public static function log(
        string $action,
        string $modelType,
        ?int $modelId = null,
        ?string $modelName = null,
        ?string $description = null,
        ?array $oldValues = null,
        ?array $newValues = null
    ): self {
        $user = auth()->user();

        return self::create([
            'user_id' => $user?->id,
            'user_name' => $user?->name ?? 'System',
            'action' => $action,
            'model_type' => $modelType,
            'model_id' => $modelId,
            'model_name' => $modelName,
            'description' => $description,
            'old_values' => $oldValues,
            'new_values' => $newValues,
            'ip_address' => request()->ip(),
        ]);
    }

    /**
     * الحصول على وصف العملية بالعربية
     */
    public function getActionLabelAttribute(): string
    {
        return match ($this->action) {
            'create' => 'إنشاء',
            'update' => 'تعديل',
            'delete' => 'حذف',
            'activate' => 'تفعيل',
            'deactivate' => 'تعطيل',
            'login' => 'تسجيل دخول',
            'logout' => 'تسجيل خروج',
            'export' => 'تصدير',
            'bulk_activate' => 'تفعيل جماعي',
            'bulk_deactivate' => 'تعطيل جماعي',
            'bulk_delete' => 'حذف جماعي',
            default => $this->action
        };
    }

    /**
     * الحصول على نوع النموذج بالعربية
     */
    public function getModelTypeLabelAttribute(): string
    {
        return match ($this->model_type) {
            'User' => 'مستخدم',
            'University' => 'جامعة',
            'College' => 'كلية',
            'Major' => 'تخصص',
            'Level' => 'مستوى',
            'Term' => 'فصل دراسي',
            'Subject' => 'مادة',
            'Attendance' => 'حضور',
            'Student' => 'طالب',
            'Doctor' => 'دكتور',
            'Delegate' => 'مندوب',
            default => $this->model_type
        };
    }

    /**
     * الحصول على لون العملية
     */
    public function getActionColorAttribute(): string
    {
        return match ($this->action) {
            'create' => '#10b981',
            'update' => '#3b82f6',
            'delete', 'bulk_delete' => '#ef4444',
            'activate', 'bulk_activate' => '#22c55e',
            'deactivate', 'bulk_deactivate' => '#f59e0b',
            'login' => '#8b5cf6',
            'logout' => '#6b7280',
            'export' => '#06b6d4',
            default => '#64748b'
        };
    }
}
