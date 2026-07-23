<?php

namespace App\Http\Controllers\Api\Administrative;

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Http\Request;

class DashboardController extends AdministrativeApiController
{
    public function index()
    {
        $college = $this->college();

        return $this->success([
            'college' => [
                'id' => $college->id,
                'name' => $college->name,
                'absence_deprivation_percentage' => $college->absence_deprivation_percentage,
                'excuses_deadline_days' => $college->excuses_deadline_days,
                'excuse_receiver' => $college->excuse_receiver,
            ],
            'stats' => [
                'doctors_count' => User::where('college_id', $college->id)->where('role', UserRole::DOCTOR)->count(),
                'delegates_count' => User::where('college_id', $college->id)->whereIn('role', [UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE])->count(),
                'students_count' => User::where('college_id', $college->id)->whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])->count(),
            ],
            'quick_links' => [
                'notifications' => url('/api/administrative/notifications'),
                'delegates' => url('/api/administrative/delegates'),
                'reports' => url('/api/administrative/reports'),
                'settings' => url('/api/administrative/settings'),
            ],
        ]);
    }

    public function settings()
    {
        $college = $this->college();

        return $this->success([
            'id' => $college->id,
            'name' => $college->name,
            'absence_deprivation_percentage' => $college->absence_deprivation_percentage,
            'excuses_deadline_days' => $college->excuses_deadline_days,
            'excuse_receiver' => $college->excuse_receiver,
        ]);
    }

    public function updateSettings(Request $request)
    {
        $validated = $request->validate([
            'absence_deprivation_percentage' => 'required|integer|min:1|max:100',
            'excuses_deadline_days' => 'required|integer|min:1|max:30',
        ]);

        $college = $this->college();
        $college->update($validated);

        return $this->success([
            'id' => $college->id,
            'absence_deprivation_percentage' => $college->absence_deprivation_percentage,
            'excuses_deadline_days' => $college->excuses_deadline_days,
        ], 'تم تحديث إعدادات الكلية بنجاح');
    }
}
