<?php

namespace App\Jobs;

use App\Models\Diagram;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
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
        $this->diagram->update(['status' => 'processing']);
        
        // TODO: Call Python FastAPI service here
        Log::info("Simulating AI diagram generation for diagram {$this->diagram->id}");
    }
}
