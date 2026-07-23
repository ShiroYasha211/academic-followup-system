<?php

namespace App\Models;

use App\Models\Academic\Subject;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CourseResource extends Model
{
    use HasFactory;

    protected $fillable = [
        'subject_id',
        'created_by',
        'title',
        'file_path',
        'file_type',
        'category',
        'sub_category',
        'custom_category_type',
        'description',
        'unit_coordinator',
        'lecturer_name',
        'clinical_unit',
        'semester_info',
        'visibility',
    ];

    public function subject()
    {
        return $this->belongsTo(Subject::class);
    }

    public function uploader()
    {
        return $this->belongsTo(User::class, 'created_by')->withTrashed();
    }

    public function getCategoryTextAttribute()
    {
        $categories = [
            'lectures' => 'محاضرات',
            'lecture' => 'محاضرة',
            'summaries' => 'ملخصات',
            'quizzes' => 'كويزات',
            'exams' => 'نماذج اختبارات',
            'references' => 'مراجع',
            'other' => 'أخرى',
        ];

        return $categories[$this->category] ?? $this->category;
    }

    public function getFullCategoryTextAttribute()
    {
        $text = $this->category_text;
        
        if ($this->category === 'lectures' && $this->sub_category) {
            $subs = [
                'theoretical' => 'نظري',
                'practical' => 'عملي',
                'seminar' => 'سمنار',
                'other' => $this->custom_category_type ?: 'أخرى',
            ];
            $subText = $subs[$this->sub_category] ?? $this->sub_category;
            $text .= " ({$subText})";
        }
        
        return $text;
    }

    // Scopes
    public function scopeFilter($query, $filters)
    {
        return $query->when($filters['search'] ?? null, function ($q, $search) {
            $q->where(function($sq) use ($search) {
                $sq->where('title', 'like', "%{$search}%")
                  ->orWhereHas('subject', function ($uq) use ($search) {
                      $uq->where('name', 'like', "%{$search}%");
                  });
            });
        })->when($filters['major_id'] ?? null, function ($q, $id) {
            $q->whereHas('subject', fn($s) => $s->where('major_id', $id));
        })->when($filters['level_id'] ?? null, function ($q, $id) {
            $q->whereHas('subject', fn($s) => $s->where('level_id', $id));
        })->when($filters['subject_id'] ?? null, function ($q, $id) {
            $q->where('subject_id', $id);
        })->when($filters['category'] ?? null, function ($q, $cat) {
            $q->where('category', $cat);
        })->when($filters['sub_category'] ?? null, function ($q, $sub) {
            $q->where('sub_category', $sub);
        })->when($filters['semester_info'] ?? null, function ($q, $sem) {
            $q->where('semester_info', $sem);
        })->when($filters['lecturer_name'] ?? null, function ($q, $name) {
            $q->where('lecturer_name', $name);
        })->when($filters['file_type'] ?? null, function ($q, $type) {
            if ($type === 'pdf') $q->where('file_type', 'pdf');
            elseif (in_array($type, ['powerpoint', 'ppt', 'pptx'], true)) $q->whereIn('file_type', ['ppt', 'pptx']);
            elseif (in_array($type, ['word', 'doc', 'docx'], true)) $q->whereIn('file_type', ['doc', 'docx']);
            elseif (in_array($type, ['excel', 'xls', 'xlsx'], true)) $q->whereIn('file_type', ['xls', 'xlsx']);
            elseif (in_array($type, ['images', 'jpg', 'jpeg', 'png'], true)) $q->whereIn('file_type', ['jpg', 'jpeg', 'png']);
            elseif (in_array($type, ['compressed', 'zip', 'rar'], true)) $q->whereIn('file_type', ['zip', 'rar']);
        })->when($filters['uploader_role'] ?? null, function ($q, $role) {
            $q->whereHas('uploader', fn($u) => $u->where('role', $role));
        })->when($filters['year'] ?? null, function ($q, $year) {
            $q->byYear($year);
        });
    }

    public function scopeByYear($query, $year)
    {
        // Assuming year is like "2024", we look at created_at
        // Academic year usually starts in Sept and ends in June/Aug.
        // Simple approximation: Year 2024 covers 2024-01 to 2024-12 ? 
        // Or User selects "2023-2024"? 
        // For now, let's assume filtering by simple YYYY of created_at
        return $query->whereYear('created_at', $year);
    }

    public function scopePopular($query)
    {
        return $query->orderBy('downloads_count', 'desc');
    }
}
