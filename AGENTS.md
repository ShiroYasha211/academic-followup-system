\# AGENTS.md - Moeen Project Instructions



\## General behavior



You are working on the Moeen project.



Before making changes:

\- Understand the existing structure.

\- Keep changes scoped to the requested screen, component, or feature.

\- Prefer small, safe changes over large rewrites.

\- Do not refactor unrelated code.

\- Do not change behavior unless explicitly requested.



After making changes:

\- Summarize changed files.

\- Explain what was changed.

\- Mention any risks or manual checks needed.

\- Run available checks/builds when appropriate.



\---

## Default behavior



If the user says:

\- "صمم"

\- "حسن الشكل"

\- "اجعلها عصرية"

\- "واجهة"

\- "UI"

\- "UX"



Use UI Mode.



If the user says:

\- "أصلح"

\- "bug"

\- "error"

\- "لا يعمل"

\- "crash"

\- "مشكلة"

\- "build failed"



Use Bugfix Mode.



If the user says:

\- "أضف"

\- "ميزة"

\- "feature"

\- "زر جديد"

\- "شاشة جديدة"

\- "endpoint"

\- "ربط"

\- "نفذ"



Use Feature Mode.



If the user says:

\- "نظف الكود"

\- "رتب"

\- "refactor"

\- "حسن البنية"



Use Refactor Mode.



If the user says:

\- "حلل"

\- "افحص"

\- "ما السبب"

\- "بدون تعديل"



Use Investigation Mode.



When the mode is unclear, choose the safest mode and keep the scope limited.



\## Hard safety rules



Do not change:

\- business logic unless explicitly requested

\- API contracts

\- backend behavior

\- database schema

\- authentication flow

\- authorization/permissions

\- routing behavior

\- state management behavior

\- validation rules

\- existing app features

\- unrelated files



If a requested UI change seems to require logic changes, stop and explain the risk before editing.



\---



\## UI / UX redesign rules



For any frontend, UI, UX, styling, layout, screen redesign, visual polish, CSS, Tailwind, React, Flutter, or responsive design task:



Use these skills when available:

\- `.agents/skills/redesign-existing-projects/SKILL.md` for existing screens

\- `.agents/skills/gpt-taste/SKILL.md` for visual quality and anti-slop review

\- `.agents/skills/image-to-code/SKILL.md` when a reference image or screenshot is provided

\- `.agents/skills/design-taste-frontend/SKILL.md` for new frontend UI work



Allowed UI-only changes:

\- layout

\- spacing

\- alignment

\- typography

\- colors

\- contrast

\- visual hierarchy

\- icons

\- component presentation

\- borders

\- radius

\- shadows

\- animations/transitions

\- responsive behavior

\- loading/empty/error visual states

\- CSS/classes/styles

\- UI-only component structure when needed



Do not change:

\- API calls

\- data flow

\- business logic

\- event handler behavior

\- validation behavior

\- authentication behavior

\- routing behavior

\- backend files

\- database files



\---



\## UI workflow



For every UI redesign request:



1\. Inspect the target screen/interface.

2\. Identify the exact files involved.

3\. Read and apply the relevant skill files if present.

4\. Before editing, briefly state:

&#x20;  - target screen

&#x20;  - current visual problems

&#x20;  - design direction

&#x20;  - files expected to change

&#x20;  - confirmation that no logic changes are needed

5\. Implement UI-only changes.

6\. After editing:

&#x20;  - summarize changed files

&#x20;  - list visual improvements

&#x20;  - confirm whether any logic was touched

&#x20;  - if logic was touched accidentally, revert that part



\---



\## Visual quality standard



The UI must look:

\- professional

\- modern

\- polished

\- production-ready

\- consistent

\- not generic AI-generated UI



Avoid:

\- generic centered SaaS hero unless appropriate

\- random purple/blue gradients

\- three equal cards unless the content requires it

\- inconsistent border radius

\- inconsistent shadows

\- weak typography hierarchy

\- poor spacing rhythm

\- low contrast

\- cluttered layouts

\- placeholder visual decisions

\- redesigning unrelated screens



\---



\## Arabic / RTL support



If the screen contains Arabic:

\- Preserve Arabic text direction.

\- Respect RTL layout.

\- Do not break Arabic typography.

\- Do not replace Arabic content with English placeholders.

\- Keep labels, messages, and user-facing Arabic text intact unless explicitly asked to improve copy.



\---



\## Preferred response style



Be direct and practical.

Do not over-explain obvious changes.

When uncertain, make a safe professional choice and keep scope limited.

---



\## Work modes



The user may request different types of work. Choose the correct mode based on the request.



\### 1. UI Mode



Use this mode for:

\- redesign

\- visual polish

\- layout

\- styling

\- responsiveness

\- typography

\- colors

\- UX presentation



Rules:

\- UI/design changes only.

\- Do not change business logic, API calls, routing behavior, authentication, validation, or data flow.

\- Use `.agents/skills/redesign-existing-projects/SKILL.md` and `.agents/skills/gpt-taste/SKILL.md` when available.



\---



\### 2. Bugfix Mode



Use this mode for:

\- fixing errors

\- broken behavior

\- crashes

\- failed builds

\- incorrect logic

\- runtime exceptions

\- TypeScript/Flutter/backend errors



Workflow:

1\. Reproduce or inspect the bug.

2\. Identify the root cause before editing.

3\. Make the smallest safe fix.

4\. Avoid unrelated refactors.

5\. Preserve existing behavior except for the broken part.

6\. Add or update tests if the project already has a test pattern.

7\. Run the most relevant check/build/test after the fix.

8\. Summarize:

&#x20;  - root cause

&#x20;  - files changed

&#x20;  - fix made

&#x20;  - verification performed

&#x20;  - remaining risks



Rules:

\- Do not guess blindly.

\- Do not rewrite large sections unless the current structure is clearly the cause.

\- Do not change public APIs unless explicitly required.

\- Do not hide errors with broad try/catch or empty fallbacks.

\- Do not remove validation just to make the bug disappear.

\- Do not disable TypeScript, linting, tests, or warnings to pass checks.



\---



\### 3. Feature Mode



Use this mode for:

\- adding a new feature

\- adding a new screen

\- adding a new flow

\- adding backend endpoints

\- connecting frontend to backend

\- adding settings/options/actions



Workflow:

1\. Understand the existing architecture first.

2\. Identify affected layers:

&#x20;  - frontend

&#x20;  - backend

&#x20;  - database

&#x20;  - desktop

&#x20;  - shared types

3\. Propose a short implementation plan before editing if the feature touches more than one layer.

4\. Reuse existing patterns and components.

5\. Keep the feature consistent with existing naming, structure, permissions, and error handling.

6\. Implement incrementally.

7\. Add or update tests when a test pattern exists.

8\. Run relevant checks/builds.

9\. Summarize:

&#x20;  - what was added

&#x20;  - files changed

&#x20;  - how to use/test the feature

&#x20;  - risks or follow-up needed



Rules:

\- Do not invent a new architecture if the existing one works.

\- Do not duplicate logic if a reusable utility/service already exists.

\- Do not add dependencies unless clearly justified.

\- Do not change unrelated features.

\- Do not break existing API contracts.

\- Ask before making destructive database changes.



\---



\### 4. Refactor Mode



Use this mode for:

\- cleanup

\- simplifying code

\- improving maintainability

\- removing duplication

\- reorganizing components/services



Rules:

\- Behavior must remain exactly the same.

\- Do not combine refactor with feature changes unless explicitly requested.

\- Keep refactors small and reviewable.

\- Run tests/builds after changes.

\- Summarize before/after structure.



\---



\### 5. Investigation Mode



Use this mode when the user asks:

\- why is this happening?

\- inspect this

\- analyze this error

\- find the cause

\- what should we change?



Rules:

\- Do not modify files.

\- Inspect code, logs, and project structure.

\- Provide root cause hypotheses ranked by likelihood.

\- Mention exact files/functions involved.

\- Recommend the safest fix.

