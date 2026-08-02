# CLAUDE.md

Operating manual for AI coding agents in this repository. Claude Code
loads this file directly; Codex reads the same content through the
`AGENTS.md` symlink. The rules here are binding and mechanical: where
this file states a rule, apply it as written instead of relying on
judgment or model defaults.

## Project Overview

This repo is the community-maintained developer documentation for
FlexRadio Systems' **FlexLib** C# API. It is the companion reference to
[SmartStreamer4](https://github.com/cdub89/SmartStreamer4), which is
built against the same library.

It contains **hand-written prose only**. There is no source code, no
build, no test suite, and no release pipeline. The deliverable is
accuracy: an operator copies a signature out of these pages and it
either compiles against the real library or it wastes their evening.
Nearly every commit in this repo's history is a correction of a
signature that was wrong, which is why the Ground Truth rule below is
the load-bearing rule of the project.

This documentation is **unofficial and not affiliated with FlexRadio
Systems**. FlexLib itself is FlexRadio's proprietary property and is
licensed separately; it is not distributed here. See Licensing and
Redistribution Policy.

## Scope and Versioning

**This repo documents FlexLib 4.2.x.** Decided 2026-08-02. There is no
separate 4.1.5 section and no parallel 4.1.5 edition. Where 4.1.5
appears it is historical context only: the Migration Guide's
4.1.5-to-4.2.x record, and the "Corrections from the 4.1.5 edition"
table in the API Reference, which documents places the old edition
disagreed with the library rather than real version changes.

**Per-document verification status.** The pages were not all verified
against the same build, and claiming otherwise would be a lie the
reader cannot check. Every page under `docs/` carries a status line
directly under its title, in this form:

```markdown
> **Verified against FlexLib 4.2.20.41343** (2026-08-02). Signatures on
> this page were read from the 4.2.20 source.
```

or, where that is not yet true:

```markdown
> **Partially verified.** Written against 4.1.5 and corrected in
> targeted passes; not yet re-read end to end against a 4.2.x source
> tree. Verify any signature you depend on.
```

Never upgrade a page's status line without actually re-reading that
page against the source. Relabeling is not verification. When a page
is fully re-verified, update its status line and say so in the report.

## Ground Truth

**No API claim goes into these docs unless it was read out of the
FlexLib source.** This is the rule the whole repo exists to serve, and
it is blocking.

This covers: type names, member names, method signatures, parameter
order and types, return types, event delegate shapes, enum members and
their spellings, property mutability, collection types, string
constants the library matches on (meter names, mode names, status
keys), and default values.

- **Read the source, do not infer.** Not from another page in this
  repo, not from the generated YAML, not from SmartStreamer4's usage,
  not from memory, not from what the naming convention suggests. Those
  are leads for where to look, never evidence.
- **State the version.** Any correction or addition names the FlexLib
  build it was verified against (e.g. `4.2.20.41343`), because "the
  current source" ages out of the report immediately.
- **Cite the file.** Record `FlexLib/Slice.cs:86` style references in
  the report and the commit body. The next session re-verifies from
  the citation instead of re-deriving from scratch.
- **The source is Windows-only.** The vendor tree is not in this repo
  and is not on the Linux seat. See Dev Environment. On Linux, an API
  claim cannot be verified, only flagged for the Windows seat.
- **Unverifiable claims do not ship.** If the source cannot be reached
  this session, either leave the existing text alone or mark the new
  text explicitly as unverified and name it in the report. Do not
  quietly write a plausible signature.

Precedent for why this is mechanical rather than advisory: commit
`15ccde1` corrected ten classes of error at once (`Slice.Mode` for
`DemodMode`, a `Radio.MeterList` and `Radio.MeterAdded` that do not
exist, `Meter.Value` that does not exist, `Tuner` confused with the
radio's built-in ATU). Each was individually plausible. None survived
contact with the source.

## Task Lifecycle

Follow this sequence for every change. Do not skip or reorder steps.

1. **Propose.** No file gets written or edited until the proposed
   change has been explained and the user has given input on it. A
   proposal covers what will change and why, which pages are touched,
   and the alternatives considered including the do-nothing and
   subtraction options. Exempt: fixes the blocking gates demand on a
   change the user already approved, and edits the user has already
   fully specified.
2. **Locate.** Use the Quick Start table at the bottom of this file.
   Never guess a path or a heading anchor; confirm with Grep.
3. **Read first.** Read the passage being changed and the pages that
   cross-link to it. Anchors break silently.
4. **Verify against source.** For anything covered by Ground Truth,
   read the FlexLib source before writing the claim. On the Linux seat,
   defer and flag.
5. **Edit** following Design Philosophy, Doc Quality, and Conventions
   below.
6. **Gate.** Immediately after each edit, run the markdown gate (see
   Doc Quality). A failing gate blocks all further work until it
   passes. DocFX build gates are Windows-only and must be named as
   deferred when they cannot run.
7. **Verify.** Demonstrate the change is right: quote the source line
   that backs a corrected signature, or state which cross-links were
   re-checked. Never claim a correction is right without evidence.
8. **Report.** State what changed, which FlexLib build and file backs
   each API claim, which gates ran and their results, which gates were
   deferred to Windows, and anything skipped with the reason.

### Definition of Done

A change is complete only when every applicable item holds. Check the
list before reporting completion.

- [ ] Every API claim added or changed is backed by a named FlexLib
  build and a source file reference, or is explicitly marked
  unverified and named as such in the report.
- [ ] The markdown gate passes with zero errors.
- [ ] Cross-document links and heading anchors touched by the change
  still resolve.
- [ ] Code samples follow the sample conventions and use only members
  confirmed to exist.
- [ ] The page's verification status line is accurate for what was
  actually re-read this session.
- [ ] Superseded or duplicated prose left by the change is deleted,
  not left alongside the replacement.
- [ ] A correction to a previously wrong claim carries a provenance
  note (see Correction Provenance).
- [ ] Nothing derived from FlexRadio's source tree was committed (see
  Licensing and Redistribution Policy).
- [ ] No em dashes introduced in `docs/` prose (see Conventions).
- [ ] No git commits were created (see Git).
- [ ] The final report names the gates run and their actual results.
  "Done" without gate evidence is not done.

## Repository Layout

```text
CLAUDE.md, AGENTS.md   Operating manual (AGENTS.md is a symlink)
LICENSE                CC BY 4.0, covers this repo's prose only
README.md              Repo landing page, scope and disclaimer
docs/
  index.md             DocFX home page
  README.md            Documentation index
  Getting-Started.md   Tutorial
  API-Reference.md     Hand-written quick reference (the core page)
  Examples.md          Worked examples
  Architecture.md      Design, threading model, protocol
  Migration-Guide.md   4.1.5 to 4.2.x upgrade record
  Generating-API-Docs.md  How a reader builds the full reference
  docfx.json, toc.yml  DocFX config
```

**Untracked build products.** `docs/api/` (DocFX-extracted YAML) and
`docs/_site/` (rendered HTML) are generated, are listed in
`docs/.gitignore`, and must stay untracked. They may exist on the
Windows seat. Never hand-edit them, never `git add -f` them, and never
cite them as a source (see Ground Truth and the licensing policy).

## Dev Environment

Two clones, one per machine. VS Code and Claude Code run identically on
both.

- **Windows 11 (primary)**: has the FlexLib vendor source tree and the
  `docfx` toolchain. Source verification, DocFX builds, and link
  checks against a rendered site all happen here. Confirm the vendor
  tree path at session start rather than assuming it; the SmartStreamer4
  checkout carries one under `FlexLib_API_v<version>/`, and the build
  being documented may live elsewhere.
- **Linux (secondary)**: prose, structure, linting, planning, and
  audit work. No FlexLib source and no DocFX. API claims cannot be
  verified here, only drafted and flagged. Any page edited on Linux
  that touches a signature is not done until the Windows seat confirms
  it.
- **Git is the only channel the two seats share.** Claude Code
  auto-memory is machine-local and never syncs. Durable cross-seat
  knowledge belongs in this file, not in memory. Start every session
  with `git pull` and check `git status` for "behind"; a stale clone
  invalidates file:line references. Push at session end.

## Licensing and Redistribution Policy

Decided 2026-08-02. This section records a decision; do not relitigate
it or silently reverse it.

FlexLib is distributed by FlexRadio Systems under a proprietary license
that forbids reproduction and dissemination without prior written
permission. FlexLib is **not** published as open source; there is no
public `flexradio/flexlib` repository.

**Therefore:**

- **This repo publishes original prose only.** Descriptions of the API
  written in our own words, our own examples, our own architecture
  notes. That is the community value and it is ours to license.
- **Nothing extracted from FlexRadio's source is committed.** The
  DocFX-generated `docs/api/**.yml` reproduced 544 of FlexRadio's own
  XML doc-comment summaries verbatim, and `docs/_site/**` rendered the
  same content. Both were untracked on 2026-08-02. Do not restore
  them, and do not add any new file that carries FlexRadio's comment
  text, source excerpts, or headers.
- **Readers generate the full reference themselves**, from their own
  licensed copy of FlexLib. See `docs/Generating-API-Docs.md`.
- **`LICENSE` is CC BY 4.0 and covers this repo's prose only.** It
  makes no claim over FlexLib. FlexRadio's license file is not vendored
  here; carrying it would imply this repo redistributes their material.
- **The disclaimer stays.** `README.md` and `docs/index.md` state that
  this is unofficial and unaffiliated. Do not remove or soften it.

If FlexRadio grants written permission to publish generated reference
material, that changes the policy: record the permission in `README.md`
and update this section before adding anything back.

## Design Philosophy

### Simplicity through Subtraction (load-bearing)

> "Perfection is achieved, not when there is nothing more to add, but
> when there is nothing more to take away." (Antoine de Saint-Exupery)

The default answer to "should we add this?" is **no, until proven
otherwise**. A page, section, table, example, or callout earns its
place only when its value clearly exceeds the permanent cost it
imposes: more surface to keep accurate across every FlexLib release,
more places for a stale signature to hide, more for a reader to sift.
Documentation rots in proportion to its size.

1. **Lead with the subtraction alternative.** Before adding a section,
   check whether an existing page already covers it. If it does, say so
   and recommend against the addition.
2. **Prefer correcting to appending.** A wrong passage gets rewritten
   in place, not left standing with a correction note beneath it. Two
   accounts of the same API is the failure mode this repo already has.
3. **Watch the known duplication.** `docs/README.md` and
   `docs/index.md` still overlap heavily. Do not deepen it; prefer
   consolidating when touching either.
4. **Guard against accretion.** Each addition makes the next look
   small. Name that pressure when you see it.

This does not override an explicit, justified user request.

## Doc Quality

**Markdown gate**: **After every `.md` change, run markdownlint and fix
every error before proceeding.** Blocking. Zero errors allowed.

```bash
npx markdownlint-cli2 "**/*.md" "!.claude/**" "!docs/_site/**" "!docs/api/**" "!node_modules/**"
```

Use `--fix` first for the mechanical rules (blank lines around fences
and lists, trailing spaces, final newline), then hand-fix the rest.
Never suppress a rule inline to make the gate pass; if a rule is
genuinely wrong for this repo, raise it and change
`.markdownlint.json` deliberately.

**DocFX build gate** (Windows seat only): after structural changes
(`toc.yml`, `docfx.json`, new or renamed pages, changed anchors),
build the site and confirm no warnings about unresolved links or
missing TOC targets. On Linux this gate is deferred and must be named
as such.

**Sample code conventions.** Samples are the most-copied part of these
docs and the most expensive place to be wrong.

- Every member used in a sample must be confirmed to exist (Ground
  Truth applies in full).
- Samples must be **runnable as shown**, not fragments that assume
  unstated setup. Include the `API.Init()` / event subscription
  scaffolding a reader needs, or state explicitly what the snippet
  assumes.
- Follow the library's real async shape: FlexLib creates streams and
  slices through `Request*` calls plus an event, not a synchronous
  factory return. Do not write a synchronous convenience that does not
  exist.
- **Target the reader's floor, not ours.** Readers may be on .NET
  Framework 4.6.2 as well as .NET 8. Do not use C# 12 features
  (collection expressions, primary constructors, `required` members) in
  samples unless the page is explicitly scoped to .NET 8. This repo
  deliberately does not inherit SmartStreamer4's modernization rule.
- Tag every fenced block with a language (`csharp`, `bash`, `text`).
- Prefer a short complete example over a long partial one.

**Prose style.**

- ATX headings, sentence case, no trailing punctuation in headings.
- Tables for structured comparisons, especially old-name to real-name
  corrections.
- Relative links between pages. Verify anchors; heading edits silently
  break inbound links.
- Do not add decorative emoji to new sections. The existing pages use
  them; do not propagate the pattern.
- **No em dashes** in `docs/` prose. Use periods, commas, or
  parentheses. This file and internal planning notes are exempt; the
  rule targets text that ships to readers.

## Correction Provenance

When correcting a claim that was previously wrong in these docs (as
opposed to documenting a new API), record: (1) what the old text said,
(2) what the library actually does, (3) the FlexLib build and source
file that proves it, and (4) the impact on a reader who copied the old
text (does not compile / compiles but misbehaves / silently returns
null).

For a systematic sweep, the corrections table in `API-Reference.md`
("Corrections from the 4.1.5 edition") is the right home. For a
one-off, the commit body carries it. The goal is that a future session
does not "helpfully" restore a name that was deliberately removed
because it does not exist, and that a reader who copied the old text
can tell whether they are affected.

## Codex collaboration

Codex is a second LLM (different model family, different training, its
own file-reading tools) running in this same repo; it reads this file
through the `AGENTS.md` symlink. Pass **absolute file paths**, never
pasted blobs.

The highest-value use here is narrow and specific: **independent
verification of API claims against the FlexLib source on the Windows
seat.** Two model families reading the same source and agreeing on a
signature is worth far more in this repo than a prose review, because
wrong signatures are the failure mode that actually ships.

Use it for:

1. **Verification sweeps.** Hand Codex a page and the absolute path to
   the FlexLib source tree; ask it to check every signature on the page
   against the source and report each mismatch with `file:line`. Do
   this before promoting a page's verification status line.
2. **Adversarial review of a corrections table.** Ask it to find claims
   in our correction that are themselves wrong.
3. **Spec and protocol questions**: FlexLib semantics, SmartSDR command
   framing, VITA-49 details.

### Channels

Prefer the **CLI via Bash** (inherits `~/.codex/config.toml`, sandboxes
properly). Run from the repo root.

- **Always redirect stdin**: end every `codex exec` invocation with
  `< /dev/null`. When stdin is a non-TTY pipe held open (as under the
  Bash tool), `codex exec` prints "Reading additional input from
  stdin..." and blocks forever before doing any work (diagnosed
  2026-07-17 in TheMill: a two-hour hang with zero CPU). Health check
  when a run seems stalled:
  `timeout 60 codex exec --sandbox read-only "Reply with exactly: HEALTHCHECK OK" < /dev/null`
- Read-only review: `codex exec --sandbox read-only "<prompt>" < /dev/null`
- Follow-up in the same session (cheaper than re-priming):
  `codex exec resume --last "<prompt>" < /dev/null`
- Verification sweeps over a large page can run for minutes; use a
  generous Bash timeout or `run_in_background`.

The `mcp__codex__codex` MCP tool is a **fallback** only (some sandbox
modes cannot spawn processes and silently degrade Codex to text-only).

**No degraded reviews**: if Codex reports it could not read the FlexLib
source, the verification is void. It has not verified anything; it has
guessed from the same priors we have. Switch channels and rerun.

### When NOT to call Codex

- Prose, structure, formatting, and link fixes.
- Anything answerable by reading the FlexLib source directly, when the
  source is at hand and the question is small.
- On the Linux seat for any API question: Codex has no more access to
  the source than Claude does here, so its answer is unverified by
  construction.
- As a stall when the user is waiting on a decision Claude should make.

### After Codex responds

- Read the full response. Never paste Codex's text into a page blind;
  re-derive the edit through Edit/Write.
- Run the markdown gate on anything applied.
- If Codex disagrees with Claude's read of the source: state the
  disagreement to the user explicitly, give both arguments, and resolve
  it by **quoting the source line**. This is a question with a fact at
  the bottom of it; do not settle it by deference in either direction.

## Token Efficiency

- **Mechanical edits use local tools, never model-generated Edit
  calls**: `npx markdownlint-cli2 --fix` for markdown autofix;
  `git grep -l <pat> | xargs sed -i 's/old/new/g'` for bulk renames and
  repo-wide find-and-replace (version strings, a member renamed across
  every page). A member-name correction almost always appears on more
  than one page; find them all with `git grep` before editing one.
- **Delegate simple edits to project subagents** (`.claude/agents/`):
  `editor-trivial` (Haiku) for typo fixes, wording tweaks, single-file
  edits with zero judgment, and applying an already-specified diff;
  `editor-routine` (Sonnet) for well-specified multi-page edits that
  follow an existing pattern. Reserve the primary model for source
  verification, structural decisions, and reviewing subagent output.
  **Neither subagent may make an API claim**; they apply text that has
  already been verified.
- **Context hygiene**: the pages are large (`Examples.md` ~1,300 lines,
  `Getting-Started.md` ~1,400, `API-Reference.md` ~1,000). Read only
  the relevant line ranges. Use Explore/search subagents for broad
  questions. Never re-read a file just edited. Never read
  `docs/api/**.yml` or `docs/_site/**` into context; they are large,
  generated, and not a permitted source.

## Git

Never create commits or write commit messages. The user maintains full
control over all git write operations: staging, commits, pushes, tags,
PR creation, and merges. Leave changes in the working tree and report
them. Read-only git commands (`status`, `log`, `diff`, `show`,
`grep`) are fine without asking; ask before any other mutating
operation (`pull`, `checkout`, `stash`, `rm --cached`).

## Quick Start After /clear

Where to look first for common tasks:

- **A signature is wrong**: [docs/API-Reference.md](docs/API-Reference.md)
  first, then `git grep` the member name across `docs/*.md`; the same
  wrong name is usually on two or three pages.
- **Corrections table** (old name to real name, with reader impact):
  [docs/API-Reference.md](docs/API-Reference.md), "Corrections from the
  4.1.5 edition".
- **Tutorial flow, setup, project references**:
  [docs/Getting-Started.md](docs/Getting-Started.md).
- **Worked examples, multi-radio, digital modes**:
  [docs/Examples.md](docs/Examples.md).
- **Threading model, protocol, VITA-49**:
  [docs/Architecture.md](docs/Architecture.md).
- **4.1.5 to 4.2.x breaking changes, DAX rewrite**:
  [docs/Migration-Guide.md](docs/Migration-Guide.md). Cross-check
  against SmartStreamer4's `Flexlib4-2-Migration-Guide.md`; see
  Conventions for which is canonical.
- **Site structure, nav, DocFX config**: [docs/toc.yml](docs/toc.yml),
  [docs/docfx.json](docs/docfx.json).
- **How a reader builds the full reference**:
  [docs/Generating-API-Docs.md](docs/Generating-API-Docs.md).

## Conventions

- **This repo is documentation, not software.** There is no version to
  bump, no release to cut, no changelog to maintain. Do not propose
  release machinery.
- **Migration Guide canonicality**: this repo's
  `docs/Migration-Guide.md` is canonical for the FlexLib 4.1.5 to 4.2.x
  migration as a general developer record. SmartStreamer4's
  `Flexlib4-2-Migration-Guide.md` is canonical for how that specific
  app migrated. A correction to a shared API fact must land in both;
  say so in the report when it does not.
- Spell out **ViewModel**, not VM. "VM" gets misread as Virtual
  Machine.
- Changelogs and summaries: always analyze actual diffs, never
  summarize from commit messages alone.
- Ask questions and present decisions in prose dialog, not
  multiple-choice prompts (AskUserQuestion). The operator prefers
  discussing options conversationally.
- Do not add "Last updated" dates to pages. They go stale silently and
  the verification status line already carries the meaningful date.

## References

- [README.md](README.md) - repo scope, disclaimer, how to use.
- [docs/Generating-API-Docs.md](docs/Generating-API-Docs.md) - reader
  instructions for building the full DocFX reference locally.
- [SmartStreamer4](https://github.com/cdub89/SmartStreamer4) - the
  companion application built against FlexLib 4.2.x.
