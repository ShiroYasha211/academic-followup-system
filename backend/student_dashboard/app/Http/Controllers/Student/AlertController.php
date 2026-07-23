<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AlertController extends Controller
{
    public function index()
    {
        $student = Auth::user();

        // Fetch all notifications for the user
        // We filter by type to only show absence warnings (or show all if we want generic alerts)
        // Using built-in Laravel 'notifications' relationship on User model
        $alerts = $student->notifications()
            ->latest()
            ->paginate(10);

        return view('student.alerts.index', compact('alerts'));
    }

    public function markAsRead($id)
    {
        $notification = Auth::user()->notifications()->findOrFail($id);
        $notification->markAsRead();
        return redirect()->back()->with('success', 'تم تحديد التنبيه كمقروء.');
    }
}
