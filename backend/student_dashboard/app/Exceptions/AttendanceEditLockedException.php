<?php

namespace App\Exceptions;

use RuntimeException;

class AttendanceEditLockedException extends RuntimeException
{
    public function __construct(
        string $message = 'تعديل سجل الحضور مغلق. يرجى إرسال طلب فتح التعديل إلى الأدمن الرئيسي.',
        protected array $context = []
    ) {
        parent::__construct($message, 403);
    }

    public function context(): array
    {
        return $this->context;
    }
}
