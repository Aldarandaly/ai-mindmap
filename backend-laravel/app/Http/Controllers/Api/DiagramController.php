<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Project;
use App\Models\Diagram;
use App\Services\AIService;
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

    public function edit(Request $request)
    {
        $request->validate([
            'current_code' => 'required|string',
            'message'      => 'required|string',
            'type'         => 'required|string',
            'history'      => 'nullable|array',
        ]);

        $response = app(AIService::class)->editDiagram(
            $request->current_code,
            $request->message,
            $request->type,
            $request->history ?? []
        );

        return response()->json($response);
    }

    public function update(Request $request, $id)
    {
        $diagram = \App\Models\Diagram::findOrFail($id);

        if ($diagram->project->user_id !== $request->user()->id) {
            abort(403);
        }

        $diagram->update([
            'diagram_code' => $request->diagram_code,
        ]);

        return response()->json($diagram);
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

    public function destroy(Request $request, Diagram $diagram)
    {
        if ($diagram->project->user_id !== $request->user()->id) {
            abort(403);
        }
        $diagram->delete();
        return response()->json(['message' => 'Diagram deleted successfully']);
    }
}
