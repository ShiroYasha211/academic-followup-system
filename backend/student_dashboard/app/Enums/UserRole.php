<?php

namespace App\Enums;

enum UserRole: string
{
    case ADMIN = 'admin';
    case DOCTOR = 'doctor';
    case DELEGATE = 'delegate';
    case PRACTICAL_DELEGATE = 'practical_delegate';
    case STUDENT = 'student';
    case ADMINISTRATIVE = 'administrative';

    public function label(): string
    {
        return match ($this) {
            self::ADMIN => 'Admin',
            self::DOCTOR => 'Doctor',
            self::DELEGATE => 'Class Delegate',
            self::PRACTICAL_DELEGATE => 'Practical Delegate',
            self::STUDENT => 'Student',
            self::ADMINISTRATIVE => 'College Admin',
        };
    }
}
