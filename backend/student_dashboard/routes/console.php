<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;


use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Schedule::command('attendance:remind-deadlines')->dailyAt('09:00');
Schedule::command('assignment:remind-deadlines')->dailyAt('09:00');
Schedule::command('study:send-reminders')->everyMinute()->withoutOverlapping();
