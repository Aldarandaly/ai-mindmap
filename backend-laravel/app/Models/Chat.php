<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Chat extends Model
{
    protected $fillable = [
        'project_id',
        'role',
        'message',
    ];

    public function project()
    {
        return $this->belongsTo(Project::class);
    }
}
