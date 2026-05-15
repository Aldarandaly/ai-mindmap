<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Project;
use Illuminate\Http\Request;

class ChatController extends Controller
{
    public function index(Project $project)
    {
        return response()->json($project->chats);
    }
    public function send(Request $request, Project $project)
    {
        $request->validate([
            'message' => 'required|string'
        ]);

        // Save user message
        $userMessage = $project->chats()->create([
            'role' => 'user',
            'message' => $request->message,
        ]);

        // Python 
        $aiReply = "AI response here";

        // Save AI message
        $aiMessage = $project->chats()->create([
            'role' => 'ai',
            'message' => $aiReply,
        ]);

        return response()->json([
            'user' => $userMessage,
            'ai' => $aiMessage,
        ]);
    }
}
