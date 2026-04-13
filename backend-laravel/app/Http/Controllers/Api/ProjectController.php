<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Project;
use Illuminate\Http\Request;

class ProjectController extends Controller
{
    public function index(Request $request)
    {
        return response()->json($request->user()->projects);
    }

    public function store(Request $request)
    {
        $request->validate(['name' => 'required|string|max:255']);
        $project = $request->user()->projects()->create($request->only('name'));
        return response()->json($project, 201);
    }

    public function show(Request $request, Project $project)
    {
        if ($project->user_id !== $request->user()->id) {
            abort(403);
        }
        return response()->json($project);
    }
}
