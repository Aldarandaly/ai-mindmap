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
            $this->diagramService->getProjectDiagrams($project, $request->user())
        );
    }

    public function show(Request $request, Diagram $diagram)
    {
        return response()->json(
            $this->diagramService->getDiagram($diagram, $request->user())
        );
    }

    public function generate(Request $request)
    {
        $request->validate([
            'project_id' => 'required|exists:projects,id',
            'name'       => 'nullable|string|max:255',
            'input_text' => 'required|string',
            'type'       => 'nullable|in:class,erd,mindmap,auto,usecase,activity,sequence,context,state,dfd,gantt',
        ]);

        $diagram = $this->diagramService->generate($request->all(), $request->user());

        return response()->json($diagram, 201);
    }

    public function recent(Request $request)
    {
        $diagrams = $request->user()
            ->projects()
            ->with('diagrams')
            ->get()
            ->pluck('diagrams')
            ->flatten()
            ->sortByDesc('created_at')
            ->take(20)
            ->values();

        return response()->json($diagrams);
    }
}
