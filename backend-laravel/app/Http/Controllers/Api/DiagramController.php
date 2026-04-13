<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Project;
use App\Models\Diagram;
use Illuminate\Http\Request;
use App\Services\DiagramService;

class DiagramController extends Controller
{
    protected $diagramService;

    public function __construct(DiagramService $diagramService)
    {
        $this->diagramService = $diagramService;
    }

    public function index(Request $request, Project $project)
    {
        return response()->json(
            $this->DiagramService->getProjectDiagrams($project, $request->user())
        );
    }

    public function show(Request $request, Diagram $diagram)
    {
        return response()->json(
            $this->DiagramService->getDiagram($diagram, $request->user())
        );
    }

    public function generate(Request $request)
    {
        $request->validate([
            'project_id' => 'required|exists:projects,id',
            'input_text' => 'required|string',
            'type' => 'nullable|in:class,erd,mindmap,auto',
        ]);

        $diagram = $this->DiagramService->generate($request->all(), $request->user());

        return response()->json($diagram, 201);
    }
}
