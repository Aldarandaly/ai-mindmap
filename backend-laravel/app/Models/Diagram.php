<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Diagram extends Model
{
    protected $fillable = ['project_id', 'input_text', 'diagram_code', 'type', 'status'];

    public function project()
    {
        return $this->belongsTo(Project::class);
    }

    public function aiRequests()
    {
        return $this->hasMany(AiRequest::class);
    }
}
