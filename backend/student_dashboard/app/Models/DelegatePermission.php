<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DelegatePermission extends Model
{
    protected $fillable = ['user_id', 'resource', 'action', 'granted_by'];

    /**
     * All available resources and their Arabic labels.
     */
    public const RESOURCES = [
        'students'  => 'الطلاب',
        'subjects'  => 'المواد الدراسية',
        'schedules' => 'جداول المحاضرات',
        'exams'     => 'جداول الاختبارات',
    ];

    /**
     * All available actions and their Arabic labels.
     */
    public const ACTIONS = [
        'create' => 'إضافة',
        'update' => 'تعديل',
        'delete' => 'حذف',
    ];

    /**
     * Resource icons for UI.
     */
    public const RESOURCE_ICONS = [
        'students'  => 'fa-solid fa-user-graduate',
        'subjects'  => 'fa-solid fa-book',
        'schedules' => 'fa-solid fa-calendar-alt',
        'exams'     => 'fa-solid fa-file-alt',
    ];

    /**
     * The delegate user who owns this permission.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * The admin who granted this permission.
     */
    public function grantor()
    {
        return $this->belongsTo(User::class, 'granted_by');
    }
}
