<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;

class AIService
{
    public function generateDiagram($text, $type = 'auto')
    {
        $response = Http::post('http://127.0.0.1:8003/api/generate', [
            'text' => $text,
            'type' => $type ?? 'auto',
            'mode' => 'generate',
        ]);

        if ($response->successful()) {
            return $response->json();
        }

        throw new \Exception('AI service error: ' . $response->body());
    }
}