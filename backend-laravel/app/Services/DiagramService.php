<?php

namespace App\Services;

use App\Jobs\GenerateDiagramJob;
use App\Models\Diagram;
use App\Models\Project;

class DiagramService
{
    public function getProjectDiagrams(Project $project, $user)
    {
        if ($project->user_id !== $user->id) {
            abort(403);
        }

        return $project->diagrams;
    }

    public function getDiagram(Diagram $diagram, $user)
    {
        if ($diagram->project->user_id !== $user->id) {
            abort(403);
        }

        return $diagram;
    }

    public function generate($data, $user)
    {
        // 1. get project
        $project = Project::findOrFail($data['project_id']);

        // 2. check ownership
        if ($project->user_id !== $user->id) {
            abort(403);
        }

        // 3. create diagram
        $diagram = $project->diagrams()->create([
            'input_text' => $data['input_text'],
            'type' => $data['type'] ?? 'auto',
            'status' => 'pending'
        ]);

        // 4. dispatch job
        GenerateDiagramJob::dispatch($diagram);

        return $diagram;
    }
}
