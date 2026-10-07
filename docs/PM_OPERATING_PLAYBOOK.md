# 🎯 Strict PM Operating Playbook — How to Vibe Code Clinic OS

> This playbook provides prompt templates and rules for you (the **Product Manager**) to command the AI while preventing scope creep, broken architecture, or context rot.

---

## 🔁 The 4-Step PM Loop

Whenever you want the AI to build or change something, never say *"can you add feature X"*. Instead, enforce this loop:

```
[ Step 1: Feature Brief ]  ──>  [ Step 2: Architecture & Schema Check ]
           │                                      │
           ▼                                      ▼
[ Step 4: Verification Gate ] <──  [ Step 3: Scoped Implementation ]
```

---

## 📝 Prompt Templates for the PM

### Template A: New Feature Request
Use this template when introducing any new screen, modal, or workflow:

```markdown
Role: You are the Senior Engineer for GuwahatiOne Clinic OS. I am the Product Manager.
Task: [Feature Name]

User Problem:
[Explain who needs this and why — e.g. "Doctor needs to mark an emergency walk-in without losing queue order"]

Acceptance Criteria:
1. [Criterion 1]
2. [Criterion 2]

Constraints:
- Adhere strictly to AGENTS.md and docs/SCHEMA_AND_MODELS.md.
- Do NOT make code changes yet. First provide:
  (a) Screen/UI flow proposal
  (b) Proposed state management in ClinicProvider
  (c) Any Firestore schema modifications
```

---

### Template B: Bug Fix / Edge Case
Use this template when an edge case or regression occurs:

```markdown
Bug Report:
- Symptom: [e.g. When printing on A5 paper, margin overlaps doctor details]
- Expected Behavior: [e.g. A5 margins scale proportionally]

Instruction:
1. Trace the root cause in the existing codebase before modifying anything.
2. Confirm if any models or Firestore streams are affected.
3. Propose a surgical fix with minimal diff.
```

---

### Template C: Code Quality & Health Audit
Use this at the end of a sprint or feature milestone:

```markdown
Perform a Strict Engineering Audit:
1. Run `flutter analyze` and report any warnings or deprecations.
2. Verify that zero appointment deletion calls exist in the codebase.
3. Check all Firestore writes against docs/SCHEMA_AND_MODELS.md.
4. Report any dead code or duplicate helper functions.
```

---

## ⚡ Useful Slash Commands in Antigravity

- **`/plan`**: Type `/plan [feature description]` when starting a multi-step task to force the agent into a deliberate step-by-step roadmap before it writes code.
- **`/grill-me`**: Type `/grill-me` to have the AI interview *you* on edge cases, business rules, and UI UX decisions before designing a feature.
- **`/learn`**: Type `/learn` whenever the agent makes a mistake you had to correct, so it remembers the rule across sessions.
- **`/goal`**: Type `/goal` when giving an end-to-end task that needs to run thoroughly to completion without stopping halfway.
