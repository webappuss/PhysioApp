<?php

namespace App\Modules\Exercise\Services;

use App\Modules\Auth\Models\User;
use App\Shared\Services\AuditLogger;
use App\Shared\Services\ClaudeAdapter;
use Illuminate\Support\Facades\DB;

class ExerciseService
{
    public function __construct(
        private AuditLogger  $auditLogger,
        private ClaudeAdapter $claudeAdapter,
    ) {}

    public function listExercises(array $filters): array
    {
        $query = DB::table('exercises')->where('is_active', true);

        if ($category = $filters['category'] ?? null) {
            $query->where('category', $category);
        }
        if ($pathology = $filters['pathology'] ?? null) {
            $query->whereJsonContains('pathology_tags', $pathology);
        }
        if ($difficulty = $filters['difficulty'] ?? null) {
            $query->where('difficulty', $difficulty);
        }
        if ($search = $filters['search'] ?? null) {
            $query->where('name', 'like', "%{$search}%");
        }

        return $query->orderBy('name')->paginate($filters['per_page'] ?? 20)->toArray();
    }

    public function createExercise(User $user, array $data): array
    {
        $id = DB::table('exercises')->insertGetId([
            'name'               => $data['name'],
            'category'           => $data['category'] ?? null,
            'pathology_tags'     => isset($data['pathology_tags']) ? json_encode($data['pathology_tags']) : null,
            'difficulty'         => $data['difficulty'] ?? null,
            'description'        => $data['description'] ?? null,
            'technique_cue'      => $data['technique_cue'] ?? null,
            'verbal_cue'         => $data['verbal_cue'] ?? null,
            'contraindications'  => $data['contraindications'] ?? null,
            'video_url'          => $data['video_url'] ?? null,
            'thumbnail_url'      => $data['thumbnail_url'] ?? null,
            'default_sets'       => $data['default_sets'] ?? 3,
            'default_reps'       => $data['default_reps'] ?? '10-12',
            'default_duration_min'=> $data['default_duration_min'] ?? null,
            'created_by'         => $user->id,
            'created_at'         => now(),
        ]);

        $this->auditLogger->log($user, 'create_exercise', 'exercises', $id);

        return (array) DB::table('exercises')->find($id);
    }

    public function getRehabPlan(int $planId, User $user): array
    {
        $plan = DB::table('rehab_plans')->find($planId);
        abort_if(! $plan, 404, 'Rehab plan not found.');

        $phases = DB::table('rehab_phases')
            ->where('plan_id', $planId)
            ->orderBy('phase_number')
            ->get();

        foreach ($phases as &$phase) {
            $phase->exercises = DB::table('phase_exercises')
                ->join('exercises', 'phase_exercises.exercise_id', '=', 'exercises.id')
                ->where('phase_exercises.phase_id', $phase->id)
                ->where('phase_exercises.is_active', true)
                ->select('phase_exercises.*', 'exercises.name', 'exercises.category', 'exercises.thumbnail_url', 'exercises.video_url')
                ->orderBy('phase_exercises.order_index')
                ->get();
        }

        $this->auditLogger->log($user, 'view_rehab_plan', 'rehab_plans', $planId);

        return ['plan' => $plan, 'phases' => $phases];
    }

    public function createRehabPlan(User $user, array $data): array
    {
        $physioProfile = DB::table('physiotherapist_profiles')->where('user_id', $user->id)->firstOrFail();

        $planId = DB::table('rehab_plans')->insertGetId([
            'uuid'               => (string) \Str::uuid(),
            'patient_id'         => $data['patient_id'],
            'physio_id'          => $physioProfile->id,
            'title'              => $data['title'] ?? null,
            'condition'          => $data['condition'] ?? null,
            'total_phases'       => $data['total_phases'] ?? 4,
            'current_phase'      => 1,
            'start_date'         => $data['start_date'] ?? today()->toDateString(),
            'estimated_end_date' => $data['estimated_end_date'] ?? null,
            'status'             => 'active',
            'ai_generated'       => false,
            'plan_notes'         => $data['plan_notes'] ?? null,
            'created_at'         => now(),
            'updated_at'         => now(),
        ]);

        // Create default phases
        $totalPhases = $data['total_phases'] ?? 4;
        $phaseNames  = ['Pain Relief & Protection', 'Range of Motion Restoration', 'Strengthening', 'Return to Function'];

        for ($i = 1; $i <= $totalPhases; $i++) {
            DB::table('rehab_phases')->insert([
                'plan_id'      => $planId,
                'phase_number' => $i,
                'name'         => $phaseNames[$i - 1] ?? "Phase {$i}",
                'status'       => $i === 1 ? 'active' : 'upcoming',
                'start_week'   => ($i - 1) * 2 + 1,
                'end_week'     => $i * 2,
            ]);
        }

        $this->auditLogger->log($user, 'create_rehab_plan', 'rehab_plans', $planId);

        return $this->getRehabPlan($planId, $user);
    }

    public function advancePhase(User $user, int $planId): array
    {
        $plan = DB::table('rehab_plans')->find($planId);
        abort_if(! $plan, 404, 'Plan not found.');
        abort_if($plan->current_phase >= $plan->total_phases, 422, 'Already at final phase.');

        $currentPhase = DB::table('rehab_phases')
            ->where('plan_id', $planId)
            ->where('phase_number', $plan->current_phase)
            ->first();

        $nextPhase = DB::table('rehab_phases')
            ->where('plan_id', $planId)
            ->where('phase_number', $plan->current_phase + 1)
            ->first();

        if ($currentPhase) {
            DB::table('rehab_phases')->where('id', $currentPhase->id)
                ->update(['status' => 'completed', 'completed_at' => now(), 'advancement_approved_by' => $user->id, 'advancement_approved_at' => now()]);
        }
        if ($nextPhase) {
            DB::table('rehab_phases')->where('id', $nextPhase->id)
                ->update(['status' => 'active', 'started_at' => now()]);
        }

        DB::table('rehab_plans')->where('id', $planId)
            ->update(['current_phase' => $plan->current_phase + 1, 'updated_at' => now()]);

        $this->auditLogger->log($user, 'advance_rehab_phase', 'rehab_plans', $planId);

        return $this->getRehabPlan($planId, $user);
    }

    public function addExerciseToPhase(User $user, int $planId, array $data): array
    {
        $plan  = DB::table('rehab_plans')->find($planId);
        abort_if(! $plan, 404, 'Plan not found.');

        $phase = DB::table('rehab_phases')
            ->where('plan_id', $planId)
            ->where('phase_number', $data['phase_number'] ?? $plan->current_phase)
            ->firstOrFail();

        $maxOrder = DB::table('phase_exercises')
            ->where('phase_id', $phase->id)
            ->max('order_index') ?? 0;

        $id = DB::table('phase_exercises')->insertGetId([
            'phase_id'           => $phase->id,
            'exercise_id'        => $data['exercise_id'],
            'sets'               => $data['sets'] ?? null,
            'reps'               => $data['reps'] ?? null,
            'duration_min'       => $data['duration_min'] ?? null,
            'frequency_per_week' => $data['frequency_per_week'] ?? 1,
            'order_index'        => $maxOrder + 1,
            'progression_note'   => $data['progression_note'] ?? null,
            'caution_note'       => $data['caution_note'] ?? null,
            'is_active'          => true,
        ]);

        return (array) DB::table('phase_exercises')->find($id);
    }

    public function completeExercise(User $user, int $phaseExerciseId, array $data): array
    {
        $patientProfile = DB::table('patient_profiles')->where('user_id', $user->id)->firstOrFail();

        $id = DB::table('exercise_completions')->insertGetId([
            'patient_id'        => $patientProfile->id,
            'phase_exercise_id' => $phaseExerciseId,
            'completed_date'    => $data['completed_date'] ?? today()->toDateString(),
            'sets_done'         => $data['sets_done'] ?? null,
            'reps_done'         => $data['reps_done'] ?? null,
            'pain_during'       => $data['pain_during'] ?? null,
            'pain_after'        => $data['pain_after'] ?? null,
            'patient_feedback'  => $data['patient_feedback'] ?? null,
            'completion_status' => $data['completion_status'] ?? 'done',
            'created_at'        => now(),
        ]);

        // Award XP for exercise completion
        $this->awardXP($patientProfile->id, 20, 'exercise_complete');

        $this->auditLogger->log($user, 'exercise_complete', 'exercise_completions', $id);

        return (array) DB::table('exercise_completions')->find($id);
    }

    public function aiModifyExercise(User $user, int $phaseExerciseId, array $feedbackData): array
    {
        $phaseExercise = DB::table('phase_exercises')
            ->join('exercises', 'phase_exercises.exercise_id', '=', 'exercises.id')
            ->where('phase_exercises.id', $phaseExerciseId)
            ->select('phase_exercises.*', 'exercises.name as exercise_name', 'exercises.description')
            ->firstOrFail();

        $payload = [
            'exercise_name'    => $phaseExercise->exercise_name,
            'current_sets'     => $phaseExercise->sets,
            'current_reps'     => $phaseExercise->reps,
            'patient_feedback' => $feedbackData['feedback'] ?? '',
            'pain_during'      => $feedbackData['pain_during'] ?? null,
            'pain_after'       => $feedbackData['pain_after'] ?? null,
        ];

        $modification = $this->claudeAdapter->modifyExercise($payload);

        // Persist AI modification on the latest completion
        DB::table('exercise_completions')
            ->where('phase_exercise_id', $phaseExerciseId)
            ->latest('created_at')
            ->limit(1)
            ->update(['ai_modification' => json_encode($modification)]);

        return $modification;
    }

    private function awardXP(int $patientId, int $amount, string $source): void
    {
        DB::table('xp_transactions')->insert([
            'patient_id' => $patientId,
            'xp_amount'  => $amount,
            'source'     => $source,
            'reason'     => "Earned {$amount} XP for {$source}",
            'created_at' => now(),
        ]);

        DB::table('patient_xp')
            ->where('patient_id', $patientId)
            ->increment('total_xp', $amount);
    }
}
