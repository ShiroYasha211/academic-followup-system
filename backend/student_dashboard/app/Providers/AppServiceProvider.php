<?php

namespace App\Providers;

use Illuminate\Pagination\Paginator;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Paginator::useBootstrapFive();

        \App\Models\Attendance::observe(\App\Observers\AttendanceObserver::class);
        \App\Models\Academic\Assignment::observe(\App\Observers\AssignmentObserver::class);
        \App\Models\Announcement::observe(\App\Observers\AnnouncementObserver::class);
        \App\Models\DoctorAnnouncement::observe(\App\Observers\DoctorAnnouncementObserver::class);
        \App\Models\CourseResource::observe(\App\Observers\ResourceObserver::class);
        \App\Models\Message::observe(\App\Observers\MessageObserver::class);
        \App\Models\DoctorMessage::observe(\App\Observers\DoctorMessageObserver::class);
        \App\Models\StudentNotification::observe(\App\Observers\StudentNotificationObserver::class);
        \App\Models\User::observe(\App\Observers\UserObserver::class);
    }
}
