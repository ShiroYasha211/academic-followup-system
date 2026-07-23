<?php

namespace App\Http\Controllers\Api\Student;

use Illuminate\Http\Request;

class ReportController extends StudentApiController
{
    /**
     * Export attendance report as PDF.
     */
    public function attendancePdf(Request $request)
    {
        // For API, returning the URL to the web route might be easiest,
        // since downloading PDFs directly through an API response (Base64 or Binary)
        // is often handled via a separate direct-download URL in mobile apps.
        
        $url = route('student.reports.attendance-pdf');

        return $this->success([
            'export_url' => $url,
            'message' => 'يرجى استخدام هذا الرابط مع إرسال التوكن (Bearer Token) كـ Header أو Cookie لتحميل تقرير الحضور كملف PDF.',
        ]);
    }

    /**
     * Export grades report as PDF.
     */
    public function gradesPdf(Request $request)
    {
        $url = route('student.reports.grades-pdf');

        return $this->success([
            'export_url' => $url,
            'message' => 'يرجى استخدام هذا الرابط مع إرسال التوكن لتحميل كشف الدرجات كملف PDF.',
        ]);
    }

    /**
     * Export exam schedule as PDF.
     */
    public function examsPdf(Request $request)
    {
        $url = route('student.reports.exams-pdf');

        return $this->success([
            'export_url' => $url,
            'message' => 'يرجى استخدام هذا الرابط مع إرسال التوكن لتحميل جدول الاختبارات كملف PDF.',
        ]);
    }
}
