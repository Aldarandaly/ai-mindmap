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
        $project = Project::findOrFail($data['project_id']);

        if ($project->user_id !== $user->id) {
            abort(403);
        }

        $diagram = $project->diagrams()->create([
            'input_text' => $data['input_text'],
            'type' => $data['type'] ?? 'auto',
            'status' => 'processing'
        ]);

        $result = app(AIService::class)->generateDiagram(
            $data['input_text'],
            $data['type'] ?? 'auto'
        );

        $diagram->update([
            'diagram_code' => $result['diagram_code'],
            'status' => 'done'
        ]);

        return $diagram;
    }
}
