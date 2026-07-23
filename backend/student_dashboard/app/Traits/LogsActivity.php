<?php

namespace App\Traits;

use App\Models\ActivityLog;

trait LogsActivity
{
    /**
     * تسجيل نشاط إنشاء
     */
    protected function logCreate(string $modelType, $model, ?string $description = null): void
    {
        ActivityLog::log(
            action: 'create',
            modelType: $modelType,
            modelId: $model->id ?? null,
            modelName: $model->name ?? $model->title ?? null,
            description: $description ?? "تم إنشاء {$modelType} جديد"
        );
    }

    /**
     * تسجيل نشاط تعديل
     */
    protected function logUpdate(string $modelType, $model, ?string $description = null): void
    {
        ActivityLog::log(
            action: 'update',
            modelType: $modelType,
            modelId: $model->id ?? null,
            modelName: $model->name ?? $model->title ?? null,
            description: $description ?? "تم تعديل {$modelType}"
        );
    }

    /**
     * تسجيل نشاط حذف
     */
    protected function logDelete(string $modelType, $model, ?string $description = null): void
    {
        ActivityLog::log(
            action: 'delete',
            modelType: $modelType,
            modelId: $model->id ?? null,
            modelName: $model->name ?? $model->title ?? null,
            description: $description ?? "تم حذف {$modelType}"
        );
    }

    /**
     * تسجيل نشاط تفعيل
     */
    protected function logActivate(string $modelType, $model, ?string $description = null): void
    {
        ActivityLog::log(
            action: 'activate',
            modelType: $modelType,
            modelId: $model->id ?? null,
            modelName: $model->name ?? $model->title ?? null,
            description: $description ?? "تم تفعيل {$modelType}"
        );
    }

    /**
     * تسجيل نشاط تعطيل
     */
    protected function logDeactivate(string $modelType, $model, ?string $description = null): void
    {
        ActivityLog::log(
            action: 'deactivate',
            modelType: $modelType,
            modelId: $model->id ?? null,
            modelName: $model->name ?? $model->title ?? null,
            description: $description ?? "تم تعطيل {$modelType}"
        );
    }

    /**
     * تسجيل نشاط عام
     */
    protected function logActivity(string $action, string $modelType, $model = null, ?string $description = null): void
    {
        ActivityLog::log(
            action: $action,
            modelType: $modelType,
            modelId: $model->id ?? null,
            modelName: $model->name ?? $model->title ?? null,
            description: $description
        );
    }
}
