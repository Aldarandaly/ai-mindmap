<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;

class AIService
{
    // public function generateDiagram($text, $type = 'auto')
    // {
    //     $response = Http::post('http://127.0.0.1:8000/generate-diagram', [
    //         'text' => $text,
    //         'type' => $type,
    //     ]);

    //     return $response->json();
    // }
    public function generateDiagram($text, $type = 'auto')
    {
        // MOCK RESPONSE
        return [
            "diagram_code" => "classDiagram\nUser --> Project\nProject --> Diagram",
            "type" => $type
        ];
    }
}
