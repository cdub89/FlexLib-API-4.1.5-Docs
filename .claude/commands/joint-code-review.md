---
description: Joint Claude+Codex documentation review - API accuracy against the FlexLib source, plus structure/duplication/staleness. Whole-repo via subagent fan-out, or targeted to a page or the current diff. Output severity-prioritized triage; auto-apply only non-negotiable fixes.
argument-hint: "[page or directory; --all for the whole repo; defaults to current diff]"
---

# joint-code-review

A two-axis review at high effort, adapted for a documentation repo where
the product is accuracy.

- **Accuracy axis (primary)**: every API claim checked against the
  FlexLib source. Type and member names, signatures, parameter order and
  types, return types, event delegate shapes, enum spellings, collection
  types, string constants the library matches on (meter names, mode
  names, status keys), default values. Samples that will not compile.
  Samples that compile but misbehave. Claims that were true in 4.1.5 and
  are not in 4.2.x. Adherence to `CLAUDE.md`, git history, and prior
  corrections.
- **Structure axis**: duplication across pages (`docs/README.md` and
  `docs/index.md` are known overlappers); stale cross-links and broken
  heading anchors; pages disagreeing with each other about the same API;
  verification status lines that overclaim; orphaned sections; TOC
  entries pointing at content that moved; dead external links.

**Seat check, run this first.** The accuracy axis requires the FlexLib
source tree, which exists only on the Windows seat. Confirm it is
present and note the exact build (e.g. `4.2.20.41343`). If it is absent,
say so plainly at the top of the output, run the structure axis only,
and mark every accuracy finding as unverified rather than producing
plausible guesses. A review that cannot read the source has not checked
accuracy.

**Codex**: prefer `codex exec --sandbox read-only "<prompt>" < /dev/null`
from the repo root. Pass absolute paths, never pasted blobs. Give it the
absolute path to the FlexLib source tree alongside the page under review.
`mcp__codex__codex` is a fallback only. If Codex reports it could not
read the source, its accuracy findings are void.

**Target**: $ARGUMENTS

- Empty -> review current uncommitted/unpushed changes
  (`git diff` + `git diff --cached` + `git log origin/main..HEAD`).
- `--all` -> whole-repo mode (subagent fan-out below).
- A page or directory -> review just that target.

## Whole-repo mode (`--all`): parallelize via subagents

Fan out by spawning `general-purpose` subagents in a **single message**
(multiple Agent tool calls in one response so they run concurrently).
The natural split for this repo is one page per subagent:

- `docs/API-Reference.md` (largest accuracy surface; includes the
  corrections table, which must itself be checked for wrong corrections)
- `docs/Getting-Started.md`
- `docs/Examples.md`
- `docs/Architecture.md`
- `docs/Migration-Guide.md` (cross-check against SmartStreamer4's
  `Flexlib4-2-Migration-Guide.md`)
- `docs/index.md` + `docs/README.md` + `docs/toc.yml` + `docs/docfx.json`
  (structure, duplication, nav, links)

Brief each subagent fully - they start with no memory of this
conversation:

- **Scope** - the exact page they own; tell them not to edit outside it.
- **Both axes** - apply accuracy AND structure to every section in scope.
  Within accuracy, every subagent runs all four lenses:
  1. `CLAUDE.md` adherence, especially Ground Truth and the sample
     conventions.
  2. Source verification: read the FlexLib source for every claim. Report
     the source `file:line` that backs each verdict.
  3. Git history (`git log -p`, `git blame`) - a claim that looks wrong
     may have been deliberately corrected already, and a claim that looks
     right may be a reverted correction creeping back.
  4. Cross-page consistency - the same member documented differently on
     another page.
- **Sample compilation** - flag any sample using a member that does not
  exist, and any sample requiring C# 12 features (the reader floor is
  .NET Framework 4.6.2).
- **Confidence rating** - every finding rated 0-100: 0 = false positive;
  25 = unverified (no source access); 50 = real but low-impact;
  75 = real, a reader will hit it OR directly named in `CLAUDE.md`;
  100 = verified against the source with a citation. Findings below 80
  are dropped at merge. **An accuracy finding without a source citation
  caps at 25.**
- **False-positive list (do NOT flag)** - style nitpicks not named in
  `CLAUDE.md`; the existing decorative emoji on legacy pages; prose
  voice; anything markdownlint already catches; the deliberate 4.1.5
  historical content in the Migration Guide and the corrections table.
- **Return format** - H/M/L findings with `file:line`, the FlexLib source
  citation, a one-paragraph fix sketch, confidence score, and which
  lens/axis caught it. No preamble, no fluff.

## Merge

Collect findings into one list. Drop confidence below 80. Dedupe across
scopes - the same wrong member found on two pages is one correction
applied in two places, and it raises the priority, not lowers it.
Adjudicate Codex-vs-Claude disagreements by **quoting the source line**;
these are questions with a fact at the bottom of them, so do not settle
them by deference in either direction. Escalate to the user only when the
source itself is ambiguous.

## Rules

- Do **not** undo previous corrections. If a member was deliberately
  removed because it does not exist (check the corrections table and
  recent commit bodies), leave it removed.
- Never cite `docs/api/**.yml` or `docs/_site/**` as a source. They are
  generated, untracked, and derived from a stale 4.1.5 extraction.
- Never restore anything derived from FlexRadio's source tree into the
  repo (see Licensing and Redistribution Policy in `CLAUDE.md`).
- Read-only inspection of git; never run state-mutating git commands.

## Output and apply

Output one prioritized list (H / M / L) with `file:line` refs, source
citations, and concrete fix sketches. Apply without asking only the
non-negotiable fixes: a signature verified wrong against the source, a
sample that cannot compile, a broken link. Surface everything else as
proposals. Run the blocking gate on anything you touch:

```bash
npx markdownlint-cli2 "**/*.md" "!.claude/**" "!docs/_site/**" "!docs/api/**" "!node_modules/**"
```

On the Windows seat, also rebuild the DocFX site after structural changes
and confirm no unresolved-link or missing-TOC-target warnings. On Linux,
name that gate as deferred.
