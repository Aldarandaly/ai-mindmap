<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;

class AIService
{
    public function generateDiagram($text, $type = 'auto')
    {
        $response = Http::post('http://127.0.0.1:8001/api/generate', [
            'text' => $text,
            'type' => $type ?? 'class',
            'mode' => 'generate', 
        ]);

        dd([
            'status' => $response->status(),
            'body' => $response->body(),
        ]);
    }

    // TEST
    // public function generateDiagram($text, $type = 'auto')
    // {
    //     // MOCK RESPONSE
    //     return [
    //         "diagram_code" => "classDiagram\nUser --> Project\nProject --> Diagram",
    //         "type" => $type
    //     ];
    // }
}
