<?php

namespace App\Services;

use App\Models\Quiz\Quiz;
use App\Models\StudentNotification;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Collection;

class QuizNotificationService
{
    private const STUDENT_ROLES = ['student', 'delegate', 'practical_delegate'];

    public function notifyIfEnabled(Quiz $quiz): void
    {
        $quizId = $quiz->id;

        dispatch(static function () use ($quizId) {
            $quiz = Quiz::find($quizId);
            if (! $quiz) {
                return;
            }

            $quiz->loadMissing(['subject', 'targets']);

            if (! $quiz->notify_students || $quiz->status === 'draft' || $quiz->status === 'closed') {
                return;
            }

            app(QuizNotificationService::class)->notify($quiz);
        })->afterResponse();
    }

    public function notify(Quiz $quiz): int
    {
        $quiz->loadMissing(['subject', 'targets', 'creator']);

        $students = $this->targetStudents($quiz);
        $sent = 0;

        foreach ($students as $student) {
            $exists = StudentNotification::where('user_id', $student->id)
                ->where('type', 'quiz')
                ->where('data->quiz_id', $quiz->id)
                ->exists();

            if ($exists) {
                continue;
            }

            StudentNotification::create([
                'user_id' => $student->id,
                'college_id' => $student->college_id,
                'sender_id' => $quiz->created_by,
                'batch_id' => 'quiz-' . $quiz->id,
                'type' => 'quiz',
                'title' => $quiz->is_competition ? 'مسابقة جديدة' : 'كويز جديد',
                'message' => $this->messageFor($quiz),
                'data' => [
                    'quiz_id' => $quiz->id,
                    'subject_id' => $quiz->subject_id,
                    'creator_type' => $quiz->creator_type,
                    'is_competition' => (bool) $quiz->is_competition,
                    'starts_at' => $quiz->scheduled_at?->toIso8601String(),
                    'closes_at' => $quiz->closes_at?->toIso8601String(),
                    'screen' => 'quizzes',
                    'target_screen' => 'quizzes',
                ],
            ]);

            $sent++;
        }

        return $sent;
    }

    public function targetStudents(Quiz $quiz): Collection
    {
        if ($quiz->is_competition) {
            return $this->competitionStudents($quiz);
        }

        return $this->subjectStudents($quiz);
    }

    private function subjectStudents(Quiz $quiz): Collection
    {
        $subject = $quiz->subject;

        if (! $subject) {
            return collect();
        }

        return User::query()
            ->whereIn('role', self::STUDENT_ROLES)
            ->where('major_id', $subject->major_id)
            ->where('level_id', $subject->level_id)
            ->orderBy('id')
            ->get();
    }

    private function competitionStudents(Quiz $quiz): Collection
    {
        $targets = $quiz->targets;

        $query = User::query()
            ->whereIn('role', self::STUDENT_ROLES);

        if ($targets->isEmpty()) {
            return $query->orderBy('id')->get();
        }

        if ($targets->contains(fn ($target) => ! $target->university_id
            && ! $target->college_id
            && ! $target->major_id
            && ! $target->level_id)) {
            return $query->orderBy('id')->get();
        }

        $query->where(function (Builder $outer) use ($targets) {
            foreach ($targets as $target) {
                $outer->orWhere(function (Builder $inner) use ($target) {
                    if ($target->university_id) {
                        $inner->where('university_id', $target->university_id);
                    }

                    if ($target->college_id) {
                        $inner->where('college_id', $target->college_id);
                    }

                    if ($target->major_id) {
                        $inner->where('major_id', $target->major_id);
                    }

                    if ($target->level_id) {
                        $inner->where('level_id', $target->level_id);
                    }
                });
            }
        });

        return $query->orderBy('id')->get();
    }

    private function messageFor(Quiz $quiz): string
    {
        $title = $quiz->title;

        if ($quiz->is_competition) {
            return "تمت إضافة مسابقة جديدة: {$title}. يمكنك فتحها من صفحة الكويزات.";
        }

        $subjectName = $quiz->subject?->name;

        return $subjectName
            ? "تمت إضافة كويز جديد في مادة {$subjectName}: {$title}. يمكنك فتحه من صفحة الكويزات."
            : "تمت إضافة كويز جديد: {$title}. يمكنك فتحه من صفحة الكويزات.";
    }
}
