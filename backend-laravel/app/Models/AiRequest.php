<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AiRequest extends Model
{
    protected $fillable = ['diagram_id', 'request_payload', 'response_payload', 'status'];

    protected $casts = [
        'request_payload' => 'array',
        'response_payload' => 'array',
    ];

    public function diagram()
    {
        return $this->belongsTo(Diagram::class);
    }
}
