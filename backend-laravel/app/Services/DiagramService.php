<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;
use App\Models\Diagram;
use App\Models\Project;
use App\Services\PlanService;
use App\Services\AIService;

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
        $planService = app(PlanService::class);

        // Check diagram limit
        $canGenerate = $planService->canGenerateDiagram($user);

        if (!$canGenerate['allowed']) {
            abort(403, $canGenerate['reason']);
        }

        // Check diagram type
        if (
            !$planService->canUseDiagramType(
                $user,
                $data['type'] ?? 'auto'
            )
        ) {
            abort(
                403,
                'This diagram type is not available on your current plan. Please upgrade.'
            );
        }

        $project = Project::findOrFail($data['project_id']);

        if ($project->user_id !== $user->id) {
            abort(403);
        }

        $diagram = $project->diagrams()->create([
            'name'       => $data['name'] ?? 'Untitled',
            'input_text' => $data['input_text'],
            'type'       => $data['type'] ?? 'auto',
            'status'     => 'processing',
        ]);

        try {

            $result = app(AIService::class)->generateDiagram(
                $data['input_text'],
                $data['type'] ?? 'auto'
            );

            Log::info('AI Result:', $result);

            $cleanCode = $result['diagram_code'];

            $cleanCode = str_replace(
                ['```mermaid', '```'],
                '',
                $cleanCode
            );

            $cleanCode = trim($cleanCode);

            if (str_starts_with(ltrim($cleanCode), 'mindmap')) {

                $lines = explode("\n", $cleanCode);

                $fixed = ['mindmap'];

                $rootAdded = false;

                foreach ($lines as $line) {

                    $trimmed = trim($line);

                    if (
                        $trimmed === 'mindmap' ||
                        $trimmed === ''
                    ) {
                        continue;
                    }

                    if (str_contains($trimmed, 'root((')) {

                        if (!$rootAdded) {
                            $fixed[] = '  ' . $trimmed;
                            $rootAdded = true;
                        }

                        continue;
                    }

                    $fixed[] = $line;
                }

                if (!$rootAdded) {
                    array_splice(
                        $fixed,
                        1,
                        0,
                        ['  root((System))']
                    );
                }
                $cleanCode = implode("\n", $fixed);
            } else {

                $cleanCode = preg_replace(
                    '/^(classDiagram\s*)+/i',
                    'classDiagram' . PHP_EOL,
                    $cleanCode
                );

                $cleanCode = preg_replace(
                    '/^(erDiagram\s*)+/i',
                    'erDiagram' . PHP_EOL,
                    $cleanCode
                );

                $cleanCode = preg_replace(
                    '/\s*\*-+>>\s*/',
                    ' --> ',
                    $cleanCode
                );

                $cleanCode = preg_replace(
                    '/\s*--\*\s*/',
                    ' *-- ',
                    $cleanCode
                );
            }

            $diagram->update([
                'diagram_code' => $cleanCode,
                'type'         => $result['type'] ?? $data['type'],
                'status'       => 'done',
            ]);

            // Increment usage
            $planService->incrementDiagramUsage($user);
        } catch (\Exception $e) {

            Log::error('AI Error: ' . $e->getMessage());

            $diagram->update([
                'status' => 'failed'
            ]);
        }

        return $diagram;
    }
}
