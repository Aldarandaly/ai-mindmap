<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Project;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class ChatController extends Controller
{
    public function index(Request $request, Project $project)
    {
        if ($project->user_id !== $request->user()->id) {
            abort(403);
        }
        return response()->json($project->chats()->orderBy('created_at')->get());
    }

    public function send(Request $request, Project $project)
    {
        if ($project->user_id !== $request->user()->id) {
            abort(403);
        }

        $request->validate([
            'message' => 'required|string'
        ]);

        // Save user message
        $project->chats()->create([
            'role'    => 'user',
            'message' => $request->message,
        ]);

        // Get chat history for context
        $history = $project->chats()
            ->orderBy('created_at')
            ->get()
            ->map(fn($c) => ['role' => $c->role, 'message' => $c->message])
            ->toArray();

        // Send to Python AI
        try {
            $response = Http::post('http://127.0.0.1:8003/api/chat', [
                'message' => $request->message,
                'history' => $history,
                'project_name' => $project->name,
            ]);

            $aiReply = $response->json('reply') ?? 'Sorry, I could not process that.';
        } catch (\Exception $e) {
            $aiReply = 'AI service is unavailable. Please try again.';
        }

        // Save AI message
        $aiMessage = $project->chats()->create([
            'role'    => 'ai',
            'message' => $aiReply,
        ]);

        return response()->json([
            'reply' => $aiReply,
            'message' => $aiMessage,
        ]);
    }
}