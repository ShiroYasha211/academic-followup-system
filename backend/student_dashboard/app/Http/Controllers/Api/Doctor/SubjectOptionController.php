<?php

namespace App\Http\Controllers\Api\Doctor;

use App\Models\Academic\Subject;
use Illuminate\Http\Request;

class SubjectOptionController extends DoctorApiController
{
    public function index(Request $request)
    {
        $subjects = Subject::where('doctor_id', $request->user()->id)
            ->with(['major:id,name', 'level:id,name'])
            ->orderBy('name')
            ->get(['id', 'name', 'code', 'major_id', 'level_id']);

        return $this->success([
            'subjects' => $subjects,
        ]);
    }
}
