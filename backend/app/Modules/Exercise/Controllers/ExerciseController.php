<?php

namespace App\Modules\Exercise\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Exercise\Services\ExerciseService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ExerciseController extends Controller
{
    public function __construct(private ExerciseService $exerciseService) {}

    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'category'   => 'sometimes|string',
            'pathology'  => 'sometimes|string',
            'difficulty' => 'sometimes|in:beginner,moderate,advanced',
            'search'     => 'sometimes|string|max:100',
            'per_page'   => 'sometimes|integer|min:5|max:100',
        ]);

        return response()->json([
            'success' => true,
            'data'    => $this->exerciseService->listExercises($filters),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name'                => 'required|string|max:255',
            'category'            => 'sometimes|in:strengthening,mobility,stability,cardio,neurological,proprioception,hydrotherapy,breathing,other',
            'pathology_tags'      => 'sometimes|array',
            'difficulty'          => 'sometimes|in:beginner,moderate,advanced',
            'description'         => 'sometimes|string',
            'technique_cue'       => 'sometimes|string',
            'verbal_cue'          => 'sometimes|string|max:500',
            'contraindications'   => 'sometimes|string',
            'video_url'           => 'sometimes|url|max:500',
            'thumbnail_url'       => 'sometimes|url|max:500',
            'default_sets'        => 'sometimes|integer|min:1|max:20',
            'default_reps'        => 'sometimes|string|max:20',
            'default_duration_min'=> 'sometimes|integer|min:1|max:120',
        ]);

        return response()->json([
            'success' => true,
            'data'    => $this->exerciseService->createExercise($request->user(), $validated),
        ], 201);
    }

    public function complete(Request $request, int $phaseExerciseId): JsonResponse
    {
        $validated = $request->validate([
            'completed_date'    => 'sometimes|date|before_or_equal:today',
            'sets_done'         => 'sometimes|integer|min:0',
            'reps_done'         => 'sometimes|string|max:20',
            'pain_during'       => 'sometimes|numeric|min:0|max:10',
            'pain_after'        => 'sometimes|numeric|min:0|max:10',
            'patient_feedback'  => 'sometimes|string|max:500',
            'completion_status' => 'sometimes|in:done,partial,skipped',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Exercise logged.',
            'data'    => $this->exerciseService->completeExercise($request->user(), $phaseExerciseId, $validated),
        ], 201);
    }

    public function aiModify(Request $request, int $phaseExerciseId): JsonResponse
    {
        $validated = $request->validate([
            'feedback'     => 'required|string|max:500',
            'pain_during'  => 'sometimes|numeric|min:0|max:10',
            'pain_after'   => 'sometimes|numeric|min:0|max:10',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'AI modification generated.',
            'data'    => $this->exerciseService->aiModifyExercise($request->user(), $phaseExerciseId, $validated),
        ]);
    }
}

class RehabPlanController extends Controller
{
    public function __construct(private ExerciseService $exerciseService) {}

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'patient_id'          => 'required|integer|exists:patient_profiles,id',
            'title'               => 'sometimes|string|max:255',
            'condition'           => 'sometimes|string|max:255',
            'total_phases'        => 'sometimes|integer|min:2|max:6',
            'start_date'          => 'sometimes|date',
            'estimated_end_date'  => 'sometimes|date|after:start_date',
            'plan_notes'          => 'sometimes|string',
        ]);

        return response()->json([
            'success' => true,
            'data'    => $this->exerciseService->createRehabPlan($request->user(), $validated),
        ], 201);
    }

    public function show(Request $request, int $planId): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data'    => $this->exerciseService->getRehabPlan($planId, $request->user()),
        ]);
    }

    public function advancePhase(Request $request, int $planId): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Phase advanced.',
            'data'    => $this->exerciseService->advancePhase($request->user(), $planId),
        ]);
    }

    public function addExercise(Request $request, int $planId): JsonResponse
    {
        $validated = $request->validate([
            'exercise_id'        => 'required|integer|exists:exercises,id',
            'phase_number'       => 'sometimes|integer|min:1',
            'sets'               => 'sometimes|integer|min:1|max:20',
            'reps'               => 'sometimes|string|max:20',
            'duration_min'       => 'sometimes|integer|min:1|max:120',
            'frequency_per_week' => 'sometimes|integer|min:1|max:7',
            'progression_note'   => 'sometimes|string',
            'caution_note'       => 'sometimes|string',
        ]);

        return response()->json([
            'success' => true,
            'data'    => $this->exerciseService->addExerciseToPhase($request->user(), $planId, $validated),
        ], 201);
    }
}
