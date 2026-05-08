<?php
namespace App\Jobs;

use App\Models\Diagram;
use App\Models\AiRequest;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class GenerateDiagramJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public $diagram;

    public function __construct(Diagram $diagram)
    {
        $this->diagram = $diagram;
    }

    public function handle(): void
    {
        try {

            $this->diagram->update([
                'status' => 'processing'
            ]);

            // request data
            $payload = [
                'text' => $this->diagram->prompt,
                'type' => $this->diagram->type
            ];

            // save ai request
            $aiRequest = AiRequest::create([
                'diagram_id' => $this->diagram->id,
                'request_payload' => $payload,
                'status' => 'processing'
            ]);

            // call fastapi
            $response = Http::timeout(120)->post(
                'http://127.0.0.1:8000/generate',
                $payload
            );

            if ($response->successful()) {

                $result = $response->json();

                // update diagram
                $this->diagram->update([
                    'status' => 'completed',
                    'diagram_data' => json_encode($result)
                ]);

                // update ai request
                $aiRequest->update([
                    'response_payload' => $result,
                    'status' => 'completed'
                ]);

            } else {

                $this->diagram->update([
                    'status' => 'failed'
                ]);

                $aiRequest->update([
                    'status' => 'failed',
                    'response_payload' => [
                        'error' => $response->body()
                    ]
                ]);
            }

        } catch (\Exception $e) {

            Log::error($e->getMessage());

            $this->diagram->update([
                'status' => 'failed'
            ]);
        }
    }
}