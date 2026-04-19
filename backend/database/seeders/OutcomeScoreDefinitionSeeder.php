<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class OutcomeScoreDefinitionSeeder extends Seeder
{
    public function run(): void
    {
        $scores = [
            // SPINE
            ['code' => 'ODI', 'name' => 'Oswestry Disability Index', 'abbreviation' => 'ODI', 'pathology' => 'spine', 'score_min' => 0, 'score_max' => 100, 'unit' => '%', 'lower_better' => true,
                'bands' => json_encode([['label' => 'Minimal', 'min' => 0, 'max' => 20], ['label' => 'Moderate', 'min' => 20, 'max' => 40], ['label' => 'Severe', 'min' => 40, 'max' => 60], ['label' => 'Crippling', 'min' => 60, 'max' => 100]])],
            ['code' => 'NDI', 'name' => 'Neck Disability Index', 'abbreviation' => 'NDI', 'pathology' => 'spine', 'score_min' => 0, 'score_max' => 100, 'unit' => '%', 'lower_better' => true,
                'bands' => json_encode([['label' => 'No Disability', 'min' => 0, 'max' => 8], ['label' => 'Mild', 'min' => 8, 'max' => 28], ['label' => 'Moderate', 'min' => 28, 'max' => 48], ['label' => 'Severe', 'min' => 48, 'max' => 100]])],
            ['code' => 'VAS', 'name' => 'Visual Analogue Scale', 'abbreviation' => 'VAS', 'pathology' => 'all', 'score_min' => 0, 'score_max' => 10, 'unit' => '/10', 'lower_better' => true,
                'bands' => json_encode([['label' => 'No Pain', 'min' => 0, 'max' => 1], ['label' => 'Mild', 'min' => 1, 'max' => 4], ['label' => 'Moderate', 'min' => 4, 'max' => 7], ['label' => 'Severe', 'min' => 7, 'max' => 10]])],
            ['code' => 'RMQ', 'name' => 'Roland-Morris Questionnaire', 'abbreviation' => 'RMQ', 'pathology' => 'spine', 'score_min' => 0, 'score_max' => 24, 'unit' => 'pts', 'lower_better' => true, 'bands' => null],
            ['code' => 'FABQ_W', 'name' => 'Fear-Avoidance Beliefs Questionnaire — Work', 'abbreviation' => 'FABQ-W', 'pathology' => 'spine', 'score_min' => 0, 'score_max' => 42, 'unit' => 'pts', 'lower_better' => true, 'bands' => null],
            ['code' => 'FABQ_PA', 'name' => 'Fear-Avoidance Beliefs Questionnaire — Physical Activity', 'abbreviation' => 'FABQ-PA', 'pathology' => 'spine', 'score_min' => 0, 'score_max' => 24, 'unit' => 'pts', 'lower_better' => true, 'bands' => null],
            ['code' => 'STARTT', 'name' => 'STarT Back Screening Tool', 'abbreviation' => 'STarT Back', 'pathology' => 'spine', 'score_min' => 0, 'score_max' => 9, 'unit' => 'pts', 'lower_better' => true, 'bands' => null],

            // KNEE
            ['code' => 'KOOS_PAIN', 'name' => 'KOOS — Pain', 'abbreviation' => 'KOOS Pain', 'pathology' => 'knee', 'score_min' => 0, 'score_max' => 100, 'unit' => 'pts', 'lower_better' => false, 'bands' => null],
            ['code' => 'KOOS_SX', 'name' => 'KOOS — Symptoms', 'abbreviation' => 'KOOS Sx', 'pathology' => 'knee', 'score_min' => 0, 'score_max' => 100, 'unit' => 'pts', 'lower_better' => false, 'bands' => null],
            ['code' => 'KOOS_ADL', 'name' => 'KOOS — ADL', 'abbreviation' => 'KOOS ADL', 'pathology' => 'knee', 'score_min' => 0, 'score_max' => 100, 'unit' => 'pts', 'lower_better' => false, 'bands' => null],
            ['code' => 'KOOS_SPORT', 'name' => 'KOOS — Sport/Recreation', 'abbreviation' => 'KOOS Sport', 'pathology' => 'knee', 'score_min' => 0, 'score_max' => 100, 'unit' => 'pts', 'lower_better' => false, 'bands' => null],
            ['code' => 'KOOS_QOL', 'name' => 'KOOS — Quality of Life', 'abbreviation' => 'KOOS QOL', 'pathology' => 'knee', 'score_min' => 0, 'score_max' => 100, 'unit' => 'pts', 'lower_better' => false, 'bands' => null],
            ['code' => 'IKDC', 'name' => 'International Knee Documentation Committee', 'abbreviation' => 'IKDC', 'pathology' => 'knee', 'score_min' => 0, 'score_max' => 100, 'unit' => 'pts', 'lower_better' => false, 'bands' => null],
            ['code' => 'LYSHOLM', 'name' => 'Lysholm Knee Score', 'abbreviation' => 'Lysholm', 'pathology' => 'knee', 'score_min' => 0, 'score_max' => 100, 'unit' => 'pts', 'lower_better' => false,
                'bands' => json_encode([['label' => 'Poor', 'min' => 0, 'max' => 64], ['label' => 'Fair', 'min' => 64, 'max' => 83], ['label' => 'Good', 'min' => 83, 'max' => 90], ['label' => 'Excellent', 'min' => 90, 'max' => 100]])],
            ['code' => 'TEGNER', 'name' => 'Tegner Activity Scale', 'abbreviation' => 'Tegner', 'pathology' => 'knee', 'score_min' => 0, 'score_max' => 10, 'unit' => '/10', 'lower_better' => false, 'bands' => null],
            ['code' => 'ACL_RSI', 'name' => 'ACL-Return to Sport after Injury Scale', 'abbreviation' => 'ACL-RSI', 'pathology' => 'knee', 'score_min' => 0, 'score_max' => 100, 'unit' => 'pts', 'lower_better' => false,
                'bands' => json_encode([['label' => 'Not Ready', 'min' => 0, 'max' => 56], ['label' => 'Borderline', 'min' => 56, 'max' => 72], ['label' => 'Ready', 'min' => 72, 'max' => 100]])],

            // SHOULDER
            ['code' => 'DASH', 'name' => 'Disabilities of Arm, Shoulder and Hand', 'abbreviation' => 'DASH', 'pathology' => 'shoulder', 'score_min' => 0, 'score_max' => 100, 'unit' => 'pts', 'lower_better' => true, 'bands' => null],
            ['code' => 'QDASH', 'name' => 'QuickDASH', 'abbreviation' => 'QuickDASH', 'pathology' => 'shoulder', 'score_min' => 0, 'score_max' => 100, 'unit' => 'pts', 'lower_better' => true, 'bands' => null],
            ['code' => 'ASES', 'name' => 'American Shoulder and Elbow Surgeons Score', 'abbreviation' => 'ASES', 'pathology' => 'shoulder', 'score_min' => 0, 'score_max' => 100, 'unit' => 'pts', 'lower_better' => false, 'bands' => null],
            ['code' => 'CONSTANT', 'name' => 'Constant-Murley Score', 'abbreviation' => 'Constant', 'pathology' => 'shoulder', 'score_min' => 0, 'score_max' => 100, 'unit' => 'pts', 'lower_better' => false, 'bands' => null],

            // HIP
            ['code' => 'OXFORD_HIP', 'name' => 'Oxford Hip Score', 'abbreviation' => 'OHS', 'pathology' => 'hip', 'score_min' => 0, 'score_max' => 48, 'unit' => 'pts', 'lower_better' => false,
                'bands' => json_encode([['label' => 'Poor', 'min' => 0, 'max' => 19], ['label' => 'Fair', 'min' => 19, 'max' => 27], ['label' => 'Good', 'min' => 27, 'max' => 36], ['label' => 'Excellent', 'min' => 36, 'max' => 48]])],
            ['code' => 'HARRIS_HIP', 'name' => 'Harris Hip Score', 'abbreviation' => 'HHS', 'pathology' => 'hip', 'score_min' => 0, 'score_max' => 100, 'unit' => 'pts', 'lower_better' => false,
                'bands' => json_encode([['label' => 'Poor', 'min' => 0, 'max' => 70], ['label' => 'Fair', 'min' => 70, 'max' => 80], ['label' => 'Good', 'min' => 80, 'max' => 90], ['label' => 'Excellent', 'min' => 90, 'max' => 100]])],

            // ANKLE
            ['code' => 'AOFAS', 'name' => 'AOFAS Ankle-Hindfoot Scale', 'abbreviation' => 'AOFAS', 'pathology' => 'ankle', 'score_min' => 0, 'score_max' => 100, 'unit' => 'pts', 'lower_better' => false,
                'bands' => json_encode([['label' => 'Poor', 'min' => 0, 'max' => 60], ['label' => 'Fair', 'min' => 60, 'max' => 75], ['label' => 'Good', 'min' => 75, 'max' => 90], ['label' => 'Excellent', 'min' => 90, 'max' => 100]])],

            // PSYCHOLOGICAL
            ['code' => 'PHQ9', 'name' => 'Patient Health Questionnaire-9', 'abbreviation' => 'PHQ-9', 'pathology' => 'general', 'score_min' => 0, 'score_max' => 27, 'unit' => 'pts', 'lower_better' => true,
                'bands' => json_encode([['label' => 'Minimal', 'min' => 0, 'max' => 5], ['label' => 'Mild', 'min' => 5, 'max' => 10], ['label' => 'Moderate', 'min' => 10, 'max' => 15], ['label' => 'Severe', 'min' => 20, 'max' => 27]])],
            ['code' => 'GAD7', 'name' => 'Generalized Anxiety Disorder-7', 'abbreviation' => 'GAD-7', 'pathology' => 'general', 'score_min' => 0, 'score_max' => 21, 'unit' => 'pts', 'lower_better' => true,
                'bands' => json_encode([['label' => 'Minimal', 'min' => 0, 'max' => 5], ['label' => 'Mild', 'min' => 5, 'max' => 10], ['label' => 'Moderate', 'min' => 10, 'max' => 15], ['label' => 'Severe', 'min' => 15, 'max' => 21]])],
            ['code' => 'PSEQ', 'name' => 'Pain Self-Efficacy Questionnaire', 'abbreviation' => 'PSEQ', 'pathology' => 'general', 'score_min' => 0, 'score_max' => 60, 'unit' => 'pts', 'lower_better' => false, 'bands' => null],
            ['code' => 'PSFS', 'name' => 'Patient-Specific Functional Scale', 'abbreviation' => 'PSFS', 'pathology' => 'general', 'score_min' => 0, 'score_max' => 10, 'unit' => '/10', 'lower_better' => false, 'bands' => null],
        ];

        foreach ($scores as &$score) {
            $score['reference'] = null;
            $score['description'] = null;
            $score['is_active'] = true;
            $score['created_at'] = now();
        }

        DB::table('outcome_score_definitions')->insertOrIgnore($scores);
    }
}
