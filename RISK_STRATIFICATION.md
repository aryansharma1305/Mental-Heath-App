# Risk Stratification Rules

This document defines the persisted risk label used by the app for assessment triage and longitudinal review. The label is computed once when an assessment is saved and stored as `assessments.risk_level`. It should not be re-derived at display time, because scoring rules may evolve and historical records must preserve the clinical classification assigned at the time of assessment.

## Risk Levels

- `low`: no elevated DSM-5 score, no Level 2 domains triggered, and no capacity concern identified.
- `moderate`: DSM-5 total score is elevated or any DSM-5 Level 2 domain is triggered.
- `high`: capacity is not found, DSM-5 score is severe, or multiple DSM-5 Level 2 domains are triggered.
- `critical`: emergency-basis override, or capacity is not found while multiple DSM-5 Level 2 domains are triggered.

## Inputs

- DSM-5 total score, computed from raw question-level responses using stable question IDs with legacy order fallback.
- Triggered DSM-5 Level 2 domains, using the DSM-5 Level 1 domain threshold rules already implemented in `AssessmentQuestions`.
- MHCA/capacity outcome, inferred from the persisted assessment outcome text.
- Emergency basis, reserved for the consent-recording phase and currently passed as `false`.

## Thresholds

- Emergency basis: `critical`.
- Capacity not found plus two or more triggered Level 2 domains: `critical`.
- Capacity not found after an MHCA/capacity assessment: `high`.
- DSM-5 total score `>= 32`: `high`.
- Three or more triggered Level 2 domains: `high`.
- DSM-5 total score `>= 16`: `moderate`.
- One or more triggered Level 2 domains: `moderate`.
- Otherwise: `low`.

## Rationale

The rule set intentionally combines symptom severity, follow-up burden, and capacity outcome into one triage label. That makes the label cross-instrument rather than a simple DSM-5 score colour. The stored label supports patient-level longitudinal tracking, review prioritisation, richer PDF reporting, and future consent-aware safety escalation.

## Display Rules

- Patient profiles show the worst persisted risk level across that patient's assessment history.
- Patient detail assessment history shows the persisted risk level for each assessment.
- Dashboards and reports should read the stored `risk_level` value rather than recalculating from current rules.
