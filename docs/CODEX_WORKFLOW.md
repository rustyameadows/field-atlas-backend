# Codex Workflow

## Task Lists

Keep a visible task list for work that is multi-step, cross-file, risky,
ambiguous, or likely to outlive one response. Update the list as work changes.

Small direct edits can skip a formal task list when the path is obvious and the
change is easy to verify.

## Scratchpad

For bigger tasks, create or update a scratchpad note under `docs/scratchpad/`.
Use a date and short slug, such as:

```text
docs/scratchpad/2026-06-13-mapkit-associations.md
```

Keep it short. Capture current goal, findings, decisions, open questions,
commands run, verification status, and the next concrete step. The scratchpad is
for continuity when context is compacted or another agent needs to resume.

## Browser Verification

Use the Codex in-app Browser for local app verification. Review the Browser
skill/instructions before using it in a session.

Do not use an external browser for local verification unless the user explicitly
asks for that fallback.

When local UI or API behavior needs human verification, start or reuse the Rails
server and provide the exact URL. Prefer:

```text
http://127.0.0.1:3000/
```

For API work, include a sample URL or curl command that exercises the changed
endpoint.

## Status Updates

While working, keep user updates concise and concrete. Say what context was
found, what is being changed, and what verification is running.

At handoff, include what changed, what was verified, what could not be verified,
and any server URL that is still useful.
