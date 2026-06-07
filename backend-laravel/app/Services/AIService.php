<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;

class AIService
{
    public function generateDiagram($text, $type = 'auto')
    {
        $response = Http::timeout(120)->post('http://127.0.0.1:8003/api/generate', [
            'text' => $text,
            'type' => $type ?? 'auto',
            'mode' => 'generate',
        ]);

        if ($response->successful()) {
            return $response->json();
        }

        throw new \Exception('AI service error: ' . $response->body());
    }
    public function editDiagram(string $code, string $message, string $type, array $history): array
    {
        $response = Http::post(env('PYTHON_API_URL') . '/api/edit', [
            'current_code' => $code,
            'message'      => $message,
            'type'         => $type,
            'history'      => $history,
        ]);

        return $response->json();
    }
}
