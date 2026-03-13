/// DSM-5-TR Level 2 Cross-Cutting Symptom Measures — Adults Only
///
/// Sources: APA DSM-5-TR Online Assessment Measures
/// https://www.psychiatry.org/psychiatrists/practice/dsm/educational-resources/assessment-measures
///
/// Domains covered (maps directly from Level 1 flagged domains):
///   I.   Depression  → PROMIS Emotional Distress—Depression—Short Form (8 items)
///   II.  Anger       → PROMIS Emotional Distress—Anger—Short Form (5 items)
///   III. Mania       → Altman Self-Rating Mania Scale [ASRM] (5 items)
///   IV.  Anxiety     → PROMIS Emotional Distress—Anxiety—Short Form (7 items)
///   V.   Somatic     → PHQ-15 (15 items)
///   VIII.Sleep       → PROMIS Sleep Disturbance—Short Form (8 items)
///   X.   Repetitive  → FOCI Severity Scale Part B (5 items)
///   XIII.Substance   → NIDA-Modified ASSIST adapted (8 items)

class Level2Question {
  final String id;
  final String text;

  const Level2Question({required this.id, required this.text});
}

class Level2Domain {
  final String domainKey;     // matches Level 1 category prefix e.g. "I"
  final String title;         // e.g. "Depression"
  final String instrument;    // e.g. "PROMIS Emotional Distress—Depression—Short Form"
  final List<Level2Question> questions;
  final List<String> optionLabels; // text labels for the scale
  final List<int> optionValues;    // numeric values for each option (same index)
  final String scoringNote;        // clinical scoring description
  final int maxScore;
  final List<Level2Threshold> thresholds;

  const Level2Domain({
    required this.domainKey,
    required this.title,
    required this.instrument,
    required this.questions,
    required this.optionLabels,
    required this.optionValues,
    required this.scoringNote,
    required this.maxScore,
    required this.thresholds,
  });
}

class Level2Threshold {
  final int minScore;
  final int maxScore;
  final String severity;
  final String clinicalNote;
  final bool requiresAction;

  const Level2Threshold({
    required this.minScore,
    required this.maxScore,
    required this.severity,
    required this.clinicalNote,
    this.requiresAction = false,
  });
}

class Level2Result {
  final String domainKey;
  final String domainTitle;
  final String instrument;
  final int rawScore;
  final int maxScore;
  final String severity;
  final String clinicalNote;
  final bool requiresAction;
  final Map<String, int> responses;

  const Level2Result({
    required this.domainKey,
    required this.domainTitle,
    required this.instrument,
    required this.rawScore,
    required this.maxScore,
    required this.severity,
    required this.clinicalNote,
    required this.requiresAction,
    required this.responses,
  });

  Map<String, dynamic> toMap() => {
    'domainKey': domainKey,
    'domainTitle': domainTitle,
    'instrument': instrument,
    'rawScore': rawScore,
    'maxScore': maxScore,
    'severity': severity,
    'clinicalNote': clinicalNote,
    'requiresAction': requiresAction,
    'responses': responses,
  };
}

class DSM5Level2Questions {
  // ─────────────────────────────────────────────────────────────────────────
  // DOMAIN MAP: Level 1 category key prefix → Level 2 domain key
  // ─────────────────────────────────────────────────────────────────────────
  static const Map<String, String> _level1ToDomainKey = {
    'I': 'depression',
    'II': 'anger',
    'III': 'mania',
    'IV': 'anxiety',
    'V': 'somatic',
    'VIII': 'sleep',
    'X': 'repetitive',
    'XIII': 'substance',
  };

  // ─────────────────────────────────────────────────────────────────────────
  // PROMIS 5-point scale (used by Depression, Anger, Anxiety, Sleep)
  // ─────────────────────────────────────────────────────────────────────────
  static const List<String> _promisOptions = [
    'Never',
    'Rarely',
    'Sometimes',
    'Often',
    'Always',
  ];
  static const List<int> _promisValues = [1, 2, 3, 4, 5];

  // ─────────────────────────────────────────────────────────────────────────
  // ASRM / FOCI 5-point scale (0–4)
  // ─────────────────────────────────────────────────────────────────────────
  static const List<String> _asrmOptions = [
    '0 — Absent / Not at all',
    '1 — Slight / Minimal',
    '2 — Mild',
    '3 — Moderate',
    '4 — Marked / Severe',
  ];
  static const List<int> _asrmValues = [0, 1, 2, 3, 4];

  // ─────────────────────────────────────────────────────────────────────────
  // PHQ-15 3-point scale (0–2)
  // ─────────────────────────────────────────────────────────────────────────
  static const List<String> _phq15Options = [
    'Not bothered at all',
    'Bothered a little',
    'Bothered a lot',
  ];
  static const List<int> _phq15Values = [0, 1, 2];

  // ─────────────────────────────────────────────────────────────────────────
  // NIDA-ASSIST 6-point scale
  // ─────────────────────────────────────────────────────────────────────────
  static const List<String> _assistOptions = [
    'Never',
    'Once or Twice',
    'Monthly',
    'Weekly',
    'Daily or Almost Daily',
  ];
  static const List<int> _assistValues = [0, 2, 3, 4, 6];

  // =========================================================================
  // ALL DOMAINS
  // =========================================================================
  static final Map<String, Level2Domain> _domains = {

    // ── I. DEPRESSION ── PROMIS Emotional Distress—Depression—Short Form
    'depression': Level2Domain(
      domainKey: 'depression',
      title: 'Depression',
      instrument: 'PROMIS Emotional Distress—Depression—Short Form',
      questions: const [
        Level2Question(id: 'd1', text: 'I felt worthless.'),
        Level2Question(id: 'd2', text: 'I felt that I had nothing to look forward to.'),
        Level2Question(id: 'd3', text: 'I felt helpless.'),
        Level2Question(id: 'd4', text: 'I felt sad.'),
        Level2Question(id: 'd5', text: 'I felt like a failure.'),
        Level2Question(id: 'd6', text: 'I felt depressed.'),
        Level2Question(id: 'd7', text: 'I felt unhappy.'),
        Level2Question(id: 'd8', text: 'I felt hopeless.'),
      ],
      optionLabels: _promisOptions,
      optionValues: _promisValues,
      scoringNote: 'Sum all items (range 8–40). Higher scores = greater depression severity. '
          'Raw score maps to PROMIS T-score. Clinical cutoffs: Mild ≥16, Moderate ≥21, Severe ≥27.',
      maxScore: 40,
      thresholds: const [
        Level2Threshold(minScore: 8, maxScore: 15, severity: 'None to Minimal', clinicalNote: 'No clinically significant depression. Routine monitoring recommended.'),
        Level2Threshold(minScore: 16, maxScore: 20, severity: 'Mild Depression', clinicalNote: 'Mild depressive symptoms. Consider psychoeducation and watchful waiting.'),
        Level2Threshold(minScore: 21, maxScore: 26, severity: 'Moderate Depression', clinicalNote: 'Moderate depression. Consider structured psychological intervention (e.g., CBT) or pharmacotherapy evaluation.', requiresAction: true),
        Level2Threshold(minScore: 27, maxScore: 40, severity: 'Severe Depression', clinicalNote: 'Severe depression. Urgent psychiatric evaluation and treatment indicated.', requiresAction: true),
      ],
    ),

    // ── II. ANGER ── PROMIS Emotional Distress—Anger—Short Form
    'anger': Level2Domain(
      domainKey: 'anger',
      title: 'Anger',
      instrument: 'PROMIS Emotional Distress—Anger—Short Form',
      questions: const [
        Level2Question(id: 'an1', text: 'I felt angry.'),
        Level2Question(id: 'an2', text: 'I felt like I was ready to explode.'),
        Level2Question(id: 'an3', text: 'I wanted to throw something.'),
        Level2Question(id: 'an4', text: 'I was grouchy.'),
        Level2Question(id: 'an5', text: 'I felt annoyed.'),
      ],
      optionLabels: _promisOptions,
      optionValues: _promisValues,
      scoringNote: 'Sum all items (range 5–25). Higher scores = greater anger severity. '
          'Mild: 10–14; Moderate: 15–19; Severe: ≥20.',
      maxScore: 25,
      thresholds: const [
        Level2Threshold(minScore: 5, maxScore: 9, severity: 'None to Minimal', clinicalNote: 'No clinically significant anger. Routine monitoring.'),
        Level2Threshold(minScore: 10, maxScore: 14, severity: 'Mild Anger', clinicalNote: 'Mild anger symptoms. Psychoeducation on anger management may be helpful.'),
        Level2Threshold(minScore: 15, maxScore: 19, severity: 'Moderate Anger', clinicalNote: 'Moderate anger. Consider anger management therapy or psychiatric evaluation.', requiresAction: true),
        Level2Threshold(minScore: 20, maxScore: 25, severity: 'Severe Anger', clinicalNote: 'Severe anger. Psychiatric evaluation indicated. Risk of harm to self or others should be assessed.', requiresAction: true),
      ],
    ),

    // ── III. MANIA ── Altman Self-Rating Mania Scale (ASRM)
    'mania': Level2Domain(
      domainKey: 'mania',
      title: 'Mania',
      instrument: 'Altman Self-Rating Mania Scale (ASRM)',
      questions: const [
        Level2Question(id: 'm1', text: 'I feel happier or more cheerful than usual.\n\n0 = I do not feel happier or more cheerful than usual\n1 = I occasionally feel happier or more cheerful than usual\n2 = I often feel happier or more cheerful than usual\n3 = I feel happier or more cheerful than usual most of the time\n4 = I feel happier or more cheerful than usual all of the time'),
        Level2Question(id: 'm2', text: 'I feel more self-confident than usual.\n\n0 = I do not feel more self-confident than usual\n1 = I occasionally feel more self-confident than usual\n2 = I often feel more self-confident than usual\n3 = I feel more self-confident than usual most of the time\n4 = I feel extremely self-confident all of the time'),
        Level2Question(id: 'm3', text: 'I need less sleep than usual.\n\n0 = I do not need less sleep than usual\n1 = I occasionally need less sleep than usual\n2 = I often need less sleep than usual\n3 = I frequently need less sleep than usual\n4 = I can go all day and night without any sleep and still not feel tired'),
        Level2Question(id: 'm4', text: 'I talk more than usual.\n\n0 = I do not talk more than usual\n1 = I occasionally talk more than usual\n2 = I often talk more than usual\n3 = I frequently talk more than usual\n4 = I talk constantly and cannot be interrupted'),
        Level2Question(id: 'm5', text: 'I have been more active than usual (socially, sexually, at work, home, or school).\n\n0 = I am not more active than usual\n1 = I am occasionally more active than usual\n2 = I am often more active than usual\n3 = I am frequently more active than usual\n4 = I am constantly more active or on the go all of the time'),
      ],
      optionLabels: _asrmOptions,
      optionValues: _asrmValues,
      scoringNote: 'Sum all items (range 0–20). Score ≥6 indicates probable presence of a manic or hypomanic state.',
      maxScore: 20,
      thresholds: const [
        Level2Threshold(minScore: 0, maxScore: 5, severity: 'No Mania', clinicalNote: 'No significant manic symptoms. Routine monitoring.'),
        Level2Threshold(minScore: 6, maxScore: 9, severity: 'Hypomania Likely', clinicalNote: 'Score ≥6 indicates probable hypomanic episode. Psychiatric evaluation for bipolar spectrum disorder recommended.', requiresAction: true),
        Level2Threshold(minScore: 10, maxScore: 20, severity: 'Mania Likely', clinicalNote: 'Score ≥10 indicates probable manic episode. Urgent psychiatric evaluation required.', requiresAction: true),
      ],
    ),

    // ── IV. ANXIETY ── PROMIS Emotional Distress—Anxiety—Short Form
    'anxiety': Level2Domain(
      domainKey: 'anxiety',
      title: 'Anxiety',
      instrument: 'PROMIS Emotional Distress—Anxiety—Short Form',
      questions: const [
        Level2Question(id: 'ax1', text: 'I felt fearful.'),
        Level2Question(id: 'ax2', text: 'I found it hard to focus on anything other than my anxiety.'),
        Level2Question(id: 'ax3', text: 'My worries overwhelmed me.'),
        Level2Question(id: 'ax4', text: 'I felt uneasy.'),
        Level2Question(id: 'ax5', text: 'I felt nervous.'),
        Level2Question(id: 'ax6', text: 'I felt like something awful might happen.'),
        Level2Question(id: 'ax7', text: 'I felt anxious.'),
      ],
      optionLabels: _promisOptions,
      optionValues: _promisValues,
      scoringNote: 'Sum all items (range 7–35). Higher scores = greater anxiety severity. '
          'Mild ≥14; Moderate ≥19; Severe ≥24.',
      maxScore: 35,
      thresholds: const [
        Level2Threshold(minScore: 7, maxScore: 13, severity: 'None to Minimal', clinicalNote: 'No clinically significant anxiety. Routine monitoring.'),
        Level2Threshold(minScore: 14, maxScore: 18, severity: 'Mild Anxiety', clinicalNote: 'Mild anxiety symptoms. Consider psychoeducation and stress management.'),
        Level2Threshold(minScore: 19, maxScore: 23, severity: 'Moderate Anxiety', clinicalNote: 'Moderate anxiety. Consider CBT, structured psychological therapy, or pharmacotherapy evaluation.', requiresAction: true),
        Level2Threshold(minScore: 24, maxScore: 35, severity: 'Severe Anxiety', clinicalNote: 'Severe anxiety. Psychiatric evaluation and treatment urgently recommended.', requiresAction: true),
      ],
    ),

    // ── V. SOMATIC SYMPTOMS ── PHQ-15
    'somatic': Level2Domain(
      domainKey: 'somatic',
      title: 'Somatic Symptoms',
      instrument: 'Patient Health Questionnaire 15 Somatic Symptom Severity Scale (PHQ-15)',
      questions: const [
        Level2Question(id: 's1', text: 'Stomach pain'),
        Level2Question(id: 's2', text: 'Back pain'),
        Level2Question(id: 's3', text: 'Pain in your arms, legs, or joints (knees, hips, etc.)'),
        Level2Question(id: 's4', text: 'Menstrual cramps or other problems with your periods (if applicable)'),
        Level2Question(id: 's5', text: 'Headaches'),
        Level2Question(id: 's6', text: 'Chest pain'),
        Level2Question(id: 's7', text: 'Dizziness'),
        Level2Question(id: 's8', text: 'Fainting spells'),
        Level2Question(id: 's9', text: 'Feeling your heart pound or race'),
        Level2Question(id: 's10', text: 'Shortness of breath'),
        Level2Question(id: 's11', text: 'Pain or problems during sexual intercourse (if applicable)'),
        Level2Question(id: 's12', text: 'Constipation, loose bowels, or diarrhea'),
        Level2Question(id: 's13', text: 'Nausea, gas, or indigestion'),
        Level2Question(id: 's14', text: 'Feeling tired or having low energy'),
        Level2Question(id: 's15', text: 'Trouble sleeping'),
      ],
      optionLabels: _phq15Options,
      optionValues: _phq15Values,
      scoringNote: 'During the past 4 WEEKS, how much have you been bothered by each symptom? '
          'Sum all items (range 0–30). Minimal: 0–4; Low: 5–9; Medium: 10–14; High: ≥15.',
      maxScore: 30,
      thresholds: const [
        Level2Threshold(minScore: 0, maxScore: 4, severity: 'Minimal', clinicalNote: 'Minimal somatic symptom burden. Routine monitoring.'),
        Level2Threshold(minScore: 5, maxScore: 9, severity: 'Low', clinicalNote: 'Low somatic symptom burden. Consider evaluation of specific symptoms if distressing.'),
        Level2Threshold(minScore: 10, maxScore: 14, severity: 'Medium', clinicalNote: 'Medium somatic symptom burden. Further evaluation for somatic symptom disorder recommended.', requiresAction: true),
        Level2Threshold(minScore: 15, maxScore: 30, severity: 'High', clinicalNote: 'High somatic symptom burden. Comprehensive medical and psychiatric evaluation required.', requiresAction: true),
      ],
    ),

    // ── VIII. SLEEP ── PROMIS Sleep Disturbance—Short Form
    'sleep': Level2Domain(
      domainKey: 'sleep',
      title: 'Sleep Disturbance',
      instrument: 'PROMIS Sleep Disturbance—Short Form',
      questions: const [
        Level2Question(id: 'sl1', text: 'My sleep quality was... (1=Very poor, 5=Very good — please reverse your thinking for this item)'),
        Level2Question(id: 'sl2', text: 'My sleep was refreshing.'),
        Level2Question(id: 'sl3', text: 'I had difficulty falling asleep.'),
        Level2Question(id: 'sl4', text: 'I had difficulty staying asleep.'),
        Level2Question(id: 'sl5', text: 'My sleep was restless.'),
        Level2Question(id: 'sl6', text: 'I tried to sleep at the wrong times of day (early morning, during the day, early evening).'),
        Level2Question(id: 'sl7', text: 'I had trouble sleeping.'),
        Level2Question(id: 'sl8', text: 'I woke up too early and could not fall back to sleep.'),
      ],
      optionLabels: _promisOptions,
      optionValues: _promisValues,
      scoringNote: 'Over the past 7 days. Sum all items (range 8–40). '
          'Item 1 and 2 are reverse-scored (5→1, 4→2, etc.). Higher = worse sleep. '
          'Mild ≥16; Moderate ≥22; Severe ≥28.',
      maxScore: 40,
      thresholds: const [
        Level2Threshold(minScore: 8, maxScore: 15, severity: 'None to Minimal', clinicalNote: 'No clinically significant sleep disturbance. Sleep hygiene counselling if requested.'),
        Level2Threshold(minScore: 16, maxScore: 21, severity: 'Mild Sleep Disturbance', clinicalNote: 'Mild sleep disturbance. Consider sleep hygiene education and CBT-I strategies.'),
        Level2Threshold(minScore: 22, maxScore: 27, severity: 'Moderate Sleep Disturbance', clinicalNote: 'Moderate sleep disturbance. Evaluate for insomnia disorder; consider CBT-I or sleep specialist referral.', requiresAction: true),
        Level2Threshold(minScore: 28, maxScore: 40, severity: 'Severe Sleep Disturbance', clinicalNote: 'Severe sleep disturbance. Urgent evaluation required; consider polysomnography referral and pharmacological management.', requiresAction: true),
      ],
    ),

    // ── X. REPETITIVE THOUGHTS & BEHAVIORS ── FOCI Severity Scale Part B
    'repetitive': Level2Domain(
      domainKey: 'repetitive',
      title: 'Repetitive Thoughts and Behaviors',
      instrument: 'Florida Obsessive-Compulsive Inventory (FOCI) Severity Scale — Part B (Compulsions)',
      questions: const [
        Level2Question(id: 'r1', text: 'How much time do you spend performing repetitive behaviors? How much of your day is affected?\n\n0=None, 1=Mild (<1 hr/day), 2=Moderate (1–3 hrs/day), 3=Severe (3–8 hrs/day), 4=Extreme (>8 hrs/day)'),
        Level2Question(id: 'r2', text: 'How much do your repetitive behaviors interfere with your work, school, or other social/leisure activities? Is there anything you avoid because of them?\n\n0=None, 1=Mild (slight interference, overall functioning unimpaired), 2=Moderate (definite interference, manageable), 3=Severe (substantial impairment), 4=Extreme (incapacitating)'),
        Level2Question(id: 'r3', text: 'How distressed or upset do you feel when you perform the behaviors? Or if prevented from performing them?\n\n0=None, 1=Mild (slightly anxious), 2=Moderate (disturbing but manageable), 3=Severe (very disturbing), 4=Extreme (disabling distress)'),
        Level2Question(id: 'r4', text: 'How hard do you try to resist the compulsive behaviors or take your mind off them?\n\n0=Makes active effort to resist all the time, 1=Tries to resist most of the time, 2=Makes some effort to resist, 3=Yields reluctantly, 4=Completely gives in willingly'),
        Level2Question(id: 'r5', text: 'How strong is the drive to perform the compulsive behaviors? How much control do you have?\n\n0=Complete control, 1=Much control — can resist with some effort, 2=Moderate control — hard to resist, 3=Little control — strong drive, 4=No control — yielding feels automatic'),
      ],
      optionLabels: _asrmOptions,
      optionValues: _asrmValues,
      scoringNote: 'Sum all items (range 0–20). Subclinical: 0–7; Mild OCD: 8–11; Moderate OCD: 12–15; Severe OCD: 16–20.',
      maxScore: 20,
      thresholds: const [
        Level2Threshold(minScore: 0, maxScore: 7, severity: 'Subclinical', clinicalNote: 'Subclinical compulsive symptoms. Monitor; no immediate clinical intervention required.'),
        Level2Threshold(minScore: 8, maxScore: 11, severity: 'Mild OCD Symptoms', clinicalNote: 'Mild OCD symptoms. Consider psychoeducation and CBT/ERP referral for evaluation.', requiresAction: true),
        Level2Threshold(minScore: 12, maxScore: 15, severity: 'Moderate OCD Symptoms', clinicalNote: 'Moderate OCD symptoms. CBT with Exposure and Response Prevention (ERP) is first-line treatment. Consider SSRI pharmacotherapy.', requiresAction: true),
        Level2Threshold(minScore: 16, maxScore: 20, severity: 'Severe OCD Symptoms', clinicalNote: 'Severe OCD. Combination CBT/ERP + pharmacotherapy recommended. Consider urgent psychiatric evaluation.', requiresAction: true),
      ],
    ),

    // ── XIII. SUBSTANCE USE ── NIDA-Modified ASSIST (adapted)
    'substance': Level2Domain(
      domainKey: 'substance',
      title: 'Substance Use',
      instrument: 'NIDA-Modified ASSIST (Alcohol, Smoking, and Substance Involvement Screening Test)',
      questions: const [
        Level2Question(id: 'su1', text: 'In your lifetime, which of the following substances have you used (not including use solely for medical reasons)?\n[Tobacco products, Alcohol, Cannabis, Cocaine, Amphetamines, Inhalants, Sedatives, Hallucinogens, Opioids, Other drugs]\n\nRate the MOST RECENTLY used substance\'s frequency below:'),
        Level2Question(id: 'su2', text: 'In the PAST THREE MONTHS, how often have you used alcohol (beer, wine, spirits, etc.)?'),
        Level2Question(id: 'su3', text: 'In the PAST THREE MONTHS, how often have you used tobacco products (cigarettes, chewing tobacco, cigars, etc.)?'),
        Level2Question(id: 'su4', text: 'In the PAST THREE MONTHS, how often have you used cannabis (marijuana, pot, grass, hash, etc.)?'),
        Level2Question(id: 'su5', text: 'In the PAST THREE MONTHS, how often have you used cocaine, crack, or other stimulants (amphetamines, meth, ecstasy, etc.)?'),
        Level2Question(id: 'su6', text: 'In the PAST THREE MONTHS, how often have you used sedatives, sleeping pills, or anxiolytics (Valium, Xanax, Klonopin, etc.) OTHER THAN as prescribed?'),
        Level2Question(id: 'su7', text: 'In the PAST THREE MONTHS, how often have you used opioid pain medications (Vicodin, OxyContin, codeine, heroin, etc.) OTHER THAN as prescribed?'),
        Level2Question(id: 'su8', text: 'During the PAST THREE MONTHS, how often have you had a strong desire or urge to use any substance?'),
      ],
      optionLabels: _assistOptions,
      optionValues: _assistValues,
      scoringNote: 'Each item scored 0/2/3/4/6. Sum all items. '
          'Low risk: 0–3 (alcohol) or 0–3 (drugs); Moderate risk: 4–15; High risk: ≥16.',
      maxScore: 48,
      thresholds: const [
        Level2Threshold(minScore: 0, maxScore: 3, severity: 'Low Risk', clinicalNote: 'Low risk substance use or none. Provide substance use information and encourage abstinence or moderation.'),
        Level2Threshold(minScore: 4, maxScore: 15, severity: 'Moderate Risk', clinicalNote: 'Moderate risk. Brief intervention (SBIRT — Screening, Brief Intervention, and Referral to Treatment) is recommended.', requiresAction: true),
        Level2Threshold(minScore: 16, maxScore: 48, severity: 'High Risk / Likely Dependence', clinicalNote: 'High risk of substance dependence. Referral to specialist substance use treatment services required.', requiresAction: true),
      ],
    ),
  };

  // =========================================================================
  // PUBLIC API
  // =========================================================================

  /// Returns the Level2Domain for the given domain key, or null if not found.
  static Level2Domain? getDomain(String domainKey) => _domains[domainKey];

  /// Given a list of flagged Level 1 domain strings (e.g. ["I. Depression", "IV. Anxiety"]),
  /// returns the ordered list of Level2Domain objects to assess.
  static List<Level2Domain> getDomainsForFlagged(List<String> flaggedLevel1Domains) {
    final List<Level2Domain> result = [];
    final seen = <String>{};

    for (final flagged in flaggedLevel1Domains) {
      // Extract roman numeral prefix, e.g. "I. Depression" → "I"
      final parts = flagged.split('.');
      final prefix = parts.first.trim();
      final key = _level1ToDomainKey[prefix];
      if (key != null && !seen.contains(key)) {
        final domain = _domains[key];
        if (domain != null) {
          result.add(domain);
          seen.add(key);
        }
      }
    }
    return result;
  }

  /// Calculates the score and returns a Level2Result given a domain key and responses map.
  /// Responses map: questionId → selected option index (index into optionValues).
  static Level2Result calculateResult(
    String domainKey,
    Map<String, int> responses,
  ) {
    final domain = _domains[domainKey];
    if (domain == null) {
      return Level2Result(
        domainKey: domainKey,
        domainTitle: 'Unknown',
        instrument: 'Unknown',
        rawScore: 0,
        maxScore: 0,
        severity: 'Unknown',
        clinicalNote: 'Domain not found.',
        requiresAction: false,
        responses: responses,
      );
    }

    int rawScore = 0;
    for (final entry in responses.entries) {
      final optIndex = entry.value;
      if (optIndex >= 0 && optIndex < domain.optionValues.length) {
        rawScore += domain.optionValues[optIndex];
      }
    }

    // Find matching threshold
    Level2Threshold? matched;
    for (final threshold in domain.thresholds) {
      if (rawScore >= threshold.minScore && rawScore <= threshold.maxScore) {
        matched = threshold;
        break;
      }
    }
    matched ??= domain.thresholds.last;

    return Level2Result(
      domainKey: domainKey,
      domainTitle: domain.title,
      instrument: domain.instrument,
      rawScore: rawScore,
      maxScore: domain.maxScore,
      severity: matched.severity,
      clinicalNote: matched.clinicalNote,
      requiresAction: matched.requiresAction,
      responses: responses,
    );
  }

  /// Returns all available domain keys.
  static List<String> get allDomainKeys => _domains.keys.toList();

  /// Returns a human-friendly domain name for a given key.
  static String getDomainTitle(String key) => _domains[key]?.title ?? key;
}
