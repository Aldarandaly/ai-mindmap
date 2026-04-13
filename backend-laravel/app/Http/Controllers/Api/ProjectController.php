<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Project;
use App\Services\ProjectService;
use Illuminate\Http\Request;

class ProjectController extends Controller
{
    // service layer
    protected $projectService;
    public function __construct(ProjectService $projectService)
    {
        $this->projectService = $projectService;
    }

    public function index(Request $request)
    {
        return response()->json(
            $this->projectService->getUserProjects($request->user())
        );
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255'
        ]);

        return response()->json(
            $this->projectService->createProject($request->user(), $request->name),
            201
        );
    }

    public function show(Request $request, Project $project)
    {
        return response()->json(
            $this->projectService->getProject($project, $request->user())
        );
    }
}
