<?php

namespace App\Models\Clinical;

use Illuminate\Database\Eloquent\Model;

class ChecklistItem extends Model
{
    protected $fillable = ['checklist_id', 'parent_id', 'description', 'marks', 'sort_order'];

    public function checklist()
    {
        return $this->belongsTo(EvaluationChecklist::class, 'checklist_id');
    }

    public function subItems()
    {
        return $this->hasMany(self::class, 'parent_id')->orderBy('sort_order');
    }

    public function parentContext()
    {
        return $this->belongsTo(self::class, 'parent_id');
    }
}
