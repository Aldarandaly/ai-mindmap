<?php

namespace App\Services;

class ProjectService
{
    public function getUserProjects($user)
    {
        return $user->projects;
    }

    public function createProject($user, $name)
    {
        return $user->projects()->create([
            'name' => $name
        ]);
    }

    public function getProject($project, $user)
    {
        if ($project->user_id !== $user->id) {
            abort(403);
        }

        return $project;
    }
}
