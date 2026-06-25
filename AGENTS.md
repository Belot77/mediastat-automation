# MediaStat Agent Instructions

These instructions apply to work in `C:\Projects\mediastat`.

## Repository

- Local repo: `C:\Projects\mediastat`
- GitHub repo: `Belot77/mediastat-automation`
- Current branch: `main`
- Latest known commit: `dc43245 Target Radarr refresh movie command`
- Do not use old paths such as `C:\Projects\mediastat-ha-dev`.
- Do not use `C:\Projects` as the repo root.

## Required Reading

Before changing files, read:

1. `C:\Projects\AGENTS.md`
2. `AGENTS.md`
3. `docs/AI_HANDOVER.md`

## Working Rules

- Do not commit unless explicitly told.
- Do not stage untracked helper files unless explicitly approved.
- Keep changes small and reviewable.
- Inspect relevant code before changing it.
- Do not scan the whole repo blindly.
- Do not mass-reformat files.
- Inspect diffs before any commit.
- Work only in this repo unless explicitly instructed otherwise.
- Treat runtime config, API keys, logs, Home Assistant storage, tokens, and local test artifacts as private.

## Local Helper/Test Files Not to Commit

These are local helper/test files. Do not add or commit them unless explicitly approved:

- `automation-qbit-radarr-ignore.json`
- `automation-realfile-dryrun.json`
- `automation-test.json`
- `encode-display-check.txt`
- `qp16-manual-check.txt`
- `radarr-move-check.txt`
- `radarr-settings-check.txt`

## Important Paths

- Dev add-on folder: `mediastat_automation_dev/`
- Main app file: `main.py`
- Dev add-on app file: `mediastat_automation_dev/main.py`
- Main encode template: `templates/encode.html`
- Dev encode template: `mediastat_automation_dev/templates/encode.html`
- Main automation template: `templates/automation.html`
- Dev automation template: `mediastat_automation_dev/templates/automation.html`

Keep root app and Automation Dev copies in sync when a change affects both.

## Safety Rules

- Do not change encoder, ffmpeg, ffprobe, GPU, QSV, VAAPI, NVENC, or queue behavior unless explicitly requested.
- Do not duplicate existing MediaStat features without checking for existing routes, helpers, templates, and UI first.
- Do not replace, delete, quarantine, rename, or overwrite originals automatically.
- Manual Move remains manual.
- Review/staging output must remain separate from originals until manual Move.
- No broad Radarr refreshes.
- No broad Plex scans.
- No Radarr `MovieSearch`, `DownloadedMoviesScan`, rename, delete, or destructive/broad command unless explicitly approved.
- The only currently allowed Radarr post-Move command is targeted `RefreshMovie`.
- Automatic Radarr/Plex actions must require a specific tested toggle and must be OFF by default.
- Keep job progress and job management on the Encode Jobs page, not duplicated on the Automation page.

## Current Safe Runtime State

- `dry_run` true.
- qBit/SAB disabled.
- Live review enabled OFF unless deliberately testing.
- Radarr refresh-after-Move OFF until `1.0.34-dev20` is tested.
- Manual review/Move only.

## Encoding Policy

- Active encoding policy is QP16-only.
- QP18 is parked unless deliberately reintroduced.
- QP20 and QP22 should be removed completely, not kept as hidden/legacy profiles.
- Future quality validation is: encode at QP16, compare against original, then decide.
- If QP16 is good enough, keep QP16 and replace manually.
- If QP16 is not good enough or uncertain, keep original.
- VMAF is a QP16-vs-original guardrail, not a profile selector.
- VMAF should not auto-replace by itself.
- Use sample-based VMAF first, not whole-movie VMAF by default.

## Radarr Rules

- Radarr refresh-after-Move is default OFF.
- Radarr version last checked: `6.2.1.10461`.
- Known needed Radarr path mappings:
  - `/media/TrueNas1/TrueNas Movies` -> `/movies`
  - `/media/TrueNas2SMB/TrueNas2 Movies` -> `/movies2`
- Kids movies path is ignored/unmapped unless deliberately added later.
- Previous mapped test resolved Tuner to Radarr movie ID `5808` through `path_mapping`.
- `dc43245` fixed the command payload to `{"name": "RefreshMovie", "movieIds": [movie_id]}`.
- The next test must prove Radarr command history contains one ID in `body.movieIds`, not `[]`.

## Validation Commands

Run the relevant validation for app changes:

```powershell
python -m py_compile main.py mediastat_automation_dev/main.py
& "C:\Program Files\Git\bin\bash.exe" -n ha-addon/run.sh
& "C:\Program Files\Git\bin\bash.exe" -n mediastat_automation_dev/run.sh
git diff --check
```

For documentation-only helper file changes, at minimum show:

```powershell
git diff -- AGENTS.md docs/AI_HANDOVER.md
git status --short
```

## Before Commit

Only commit when explicitly told. Before committing, run:

```powershell
git status --short
git diff --stat
git diff -- <relevant-files>
```

Confirm no helper/runtime/private files are staged by accident.

## Response Requirements

After changes, report:

- Changed files
- Summary
- Validation results
- Whether committed or not
- Next manual test plan
