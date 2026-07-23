<?php

namespace App\Services;

use App\Models\Academic\University;
use App\Models\Academic\College;
use App\Models\Academic\Major;
use App\Models\Academic\Level;
use App\Models\Academic\Term;
use App\Models\Academic\Semester;
use App\Models\Academic\Subject;
use Illuminate\Database\Eloquent\Collection;

class AcademicService
{
    // --- University Operations ---

    public function getAllUniversities(): Collection
    {
        return University::with('colleges')->get();
    }

    public function createUniversity(array $data): University
    {
        return University::create($data);
    }

    public function updateUniversity(University $university, array $data): bool
    {
        return $university->update($data);
    }

    public function deleteUniversity(University $university): ?bool
    {
        return $university->delete();
    }

    // --- College Operations ---

    public function createCollege(University $university, array $data): College
    {
        return $university->colleges()->create($data);
    }

    public function deleteCollege(College $college): ?bool
    {
        return $college->delete();
    }

    public function updateCollege(College $college, array $data): bool
    {
        return $college->update($data);
    }

    // --- Major Operations ---

    public function createMajor(College $college, array $data): Major
    {
        return $college->majors()->create($data);
    }

    public function updateMajor(Major $major, array $data): bool
    {
        return $major->update($data);
    }

    // --- Level Operations ---

    public function createLevel(Major $major, array $data): Level
    {
        return $major->levels()->create($data);
    }

    // --- Term Operations ---

    public function createTerm(Level $level, array $data): Term
    {
        return $level->terms()->create($data);
    }

    // --- Semester Operations ---

    public function createSemester(Term $term, array $data): Semester
    {
        return $term->semesters()->create($data);
    }

    // --- Subject Operations ---

    public function updateSubject(Subject $subject, array $data): bool
    {
        return $subject->update($data);
    }
}
