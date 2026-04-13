<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Project;
use App\Models\Diagram;
use App\Jobs\GenerateDiagramJob;
use Illuminate\Http\Request;

class DiagramController extends Controller
{
    public function index(Request $request, Project $project)
    {
        if ($project->user_id !== $request->user()->id) abort(403);
        return response()->json($project->diagrams);
    }

    public function show(Request $request, Diagram $diagram)
    {
        if ($diagram->project->user_id !== $request->user()->id) abort(403);
        return response()->json($diagram);
    }

    public function generate(Request $request)
    {
        $request->validate([
            'project_id' => 'required|exists:projects,id',
            'input_text' => 'required|string',
            'type' => 'nullable|in:class,erd,mindmap,auto',
        ]);

        $project = Project::findOrFail($request->project_id);
        if ($project->user_id !== $request->user()->id) abort(403);

        $diagram = $project->diagrams()->create([
            'input_text' => $request->input_text,
            'type' => $request->type ?? 'auto',
            'status' => 'pending'
        ]);

        GenerateDiagramJob::dispatch($diagram);

        return response()->json($diagram, 201);
    }
}
