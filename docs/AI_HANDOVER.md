# MediaStat Project Handover

This file is for the next ChatGPT/project chat. It is human-readable project state, not strict agent policy.

## Start Here

- Repo root: `C:\Projects\mediastat`
- GitHub repo: `Belot77/mediastat-automation`
- Branch: `main`
- Latest known commit: `dc43245 Target Radarr refresh movie command`
- Dev add-on folder: `mediastat_automation_dev/`
- Current target dev version: `1.0.34-dev20`
- Do not use `C:\Projects\mediastat-ha-dev`.
- Do not treat `C:\Projects` as the repo root.

Next immediate task: install/test dev20 Radarr payload.

## Current Safety State

- `dry_run` true.
- qBit/SAB disabled.
- Live review enabled OFF unless deliberately testing.
- Radarr refresh-after-Move OFF until dev20 test passes.
- Manual review/Move only.
- Review output must stay under MediaStatReview.
- Manual Move remains manual.
- No auto-delete, auto-replace, auto-quarantine, or auto-Plex/Radarr action unless a specific OFF-by-default toggle exists and is being deliberately tested.

Current useful URLs:

- MediaStat Automation Dev: `http://192.168.1.22:8081/`
- Automation page: `http://192.168.1.22:8081/automation`
- Encode Jobs page: `http://192.168.1.22:8081/encode`

## Recent Commits

- `dc43245 Target Radarr refresh movie command`
- `65137b3 Improve Radarr refresh after move matching`
- `31f6020 Filter subtitle tracks during encode`
- `d0cf649 Align HA add-on automation default profile`
- `f403edf Add QP16 manual review and Radarr move refresh`
- `17bc771 Fix encode jobs preview button`

Mention `dc43245` as the latest known commit when orienting a new chat.

## Important Local Helper Files

`AGENTS.md` and `docs/AI_HANDOVER.md` are project docs if committed.

These local helper/test files may be untracked. Do not add or commit them unless explicitly approved:

- `automation-qbit-radarr-ignore.json`
- `automation-realfile-dryrun.json`
- `automation-test.json`
- `encode-display-check.txt`
- `qp16-manual-check.txt`
- `radarr-move-check.txt`
- `radarr-settings-check.txt`

## App Paths

- Main app file: `main.py`
- Dev add-on app file: `mediastat_automation_dev/main.py`
- Main encode template: `templates/encode.html`
- Dev encode template: `mediastat_automation_dev/templates/encode.html`
- Main automation template: `templates/automation.html`
- Dev automation template: `mediastat_automation_dev/templates/automation.html`

Keep root and Automation Dev copies in sync when touching shared behavior/UI.

## Current Radarr Context

- Radarr version checked: `6.2.1.10461`.
- Radarr system/status API worked and returned Radarr `6.2.1.10461`.
- Radarr swagger path returned login HTML in one attempt and was not used as proof.

Known needed Radarr path mappings:

- `/media/TrueNas1/TrueNas Movies` -> `/movies`
- `/media/TrueNas2SMB/TrueNas2 Movies` -> `/movies2`

Kids movies path is ignored/unmapped unless deliberately added later.

Previous successful path-mapping test:

- Tuner mapped to `/movies2/Tuner (2026)/Tuner (2026)(WEBDL-2160p).mkv`
- MediaStat resolved Radarr movie ID `5808` via `path_mapping`.

## Radarr Refresh-after-Move Issue and Fix

Previous MediaStat result looked correct:

```text
Radarr refresh after Move: accepted - movie 5808 - source path_mapping - mapped /movies2/Tuner (2026)/Tuner (2026)(WEBDL-2160p).mkv - Radarr RefreshMovie command accepted
```

But Radarr command history showed:

- `name: RefreshMovie`
- `message: Updating info for Jason Bourne`
- `body.movieIds: []`

This proved the old payload was too broad/wrong.

Old bad payload:

```json
{"name": "RefreshMovie", "movieId": 5808}
```

Fixed in `dc43245`:

```json
{"name": "RefreshMovie", "movieIds": [5808]}
```

MediaStat also added a safe display/diagnostic summary:

```python
radarr_command_payload_summary = f"RefreshMovie movieIds=[{movie_id}]"
```

Until the dev20 test proves Radarr command history has a single ID in `body.movieIds`, keep Radarr refresh-after-Move OFF.

## Next Immediate Test Plan

1. Install/update/restart MediaStat Automation Dev `1.0.34-dev20`.
2. Confirm version `1.0.34-dev20`.
3. Keep Radarr refresh-after-Move OFF by default.
4. Use one safe completed review encode.
5. Enable Radarr refresh-after-Move only for that test.
6. Move once.
7. Confirm Encode Jobs card shows `RefreshMovie movieIds=[id]`.
8. Check Radarr `/api/v3/command` and confirm `body.movieIds` contains exactly one ID and is not `[]`.
9. Restore Radarr refresh-after-Move OFF.

Useful PowerShell for Radarr command history:

```powershell
$resp = Invoke-WebRequest "$RadarrUrl/api/v3/command" -Headers @{ "X-Api-Key" = $ApiKey } -UseBasicParsing
$resp.Content
```

## Encoding Policy

MediaStat Automation is now QP16-only for active encoding.

- QP18 is parked/not active unless deliberately reintroduced later.
- QP20 and QP22 should be removed completely.
- Do not keep QP20/QP22 as hidden/legacy profiles.
- There are no known old jobs needing QP20/QP22 compatibility.
- Future ladder is not a multi-QP compression ladder.
- Future ladder means: encode at QP16, compare against original, then decide.

Decision rule:

- If QP16 is good enough, keep QP16 and replace manually.
- If QP16 is not good enough or uncertain, keep original.

VMAF:

- VMAF remains on the roadmap as a QP16-vs-original validation guardrail.
- VMAF is not a profile selector.
- VMAF should not auto-replace by itself.
- Use sample-based VMAF first, not whole-movie VMAF by default.

## Subtitle Filtering State

Subtitle filtering patch committed in `31f6020`.

Observed job-card examples:

- `2/2 kept (1 forced English, 1 English; 0 dropped)`
- `2/5 kept (1 forced English, 1 English; 3 dropped)`

Continue validating naturally on real files. Goal: keep useful English/forced English subtitles and drop unnecessary clutter.

## Review/Staging Paths

Review output must stay under MediaStatReview.

Existing review mappings:

- `/media/TrueNas1/TrueNas Movies` -> `/media/TrueNas1/MediaStatReview/Movies`
- `/media/TrueNas2SMB/TrueNas2 Movies` -> `/media/TrueNas2SMB/MediaStatReview/Movies`

## Completed Workflow Milestones

- Radarr dry-run integration passed.
- Persistent history passed.
- Readable history UI passed.
- Invalid path handling passed.
- File stability guardrail passed.
- Human-readable size UI passed.
- Review/staging output path passed.
- Job preview/would-queue visibility passed.
- GUI schedule/settings/review preflight passed.
- Per-root review mappings passed.
- GUI Mapping/Preflight Test + Readiness Checklist passed.
- Disabled live-review encode gate passed.
- Manual one-file live-review endpoint passed.
- Ingress helper bug fixed.
- Encode Jobs Preview button fixed.
- Manual Move tested and worked.
- QP16 manual dropdown/View Encode Jobs/Radarr-after-Move default-off committed.
- Subtitle filtering committed and field-tested.
- Radarr path-mapping/movie-ID matching committed.
- Radarr `RefreshMovie` payload patched to `movieIds=[id]`; test pending.

## Roadmap

1. Finish Radarr refresh-after-Move dev20 test.
2. Add Plex Analyze/Scan after Move:
   - default OFF
   - targeted only
   - no broad Plex scan unless explicitly approved
3. Continue subtitle filtering validation.
4. QP16-only cleanup:
   - remove QP18/QP20/QP22 from active config/UI/automation choices
   - set all defaults to QP16
   - add hard guard rejecting non-QP16 jobs
5. Automation page cleanup:
   - simpler settings
   - safer dangerous toggles
   - clearer readiness/status
   - do not duplicate Encode Jobs management
6. Code refactor/streamline:
   - small commits
   - no behavior changes during refactor
7. Quality validation:
   - preview comparison
   - MediaInfo/audio/subtitle checks
   - HDR/Dolby Vision warnings
   - file-size saving summary
   - sample-based VMAF where useful
8. Smarter recommendation engine:
   - decide whether a file should get a QP16 review encode
   - no lower-quality profile choices
9. Semi-automation later:
   - Radarr import dry-run recommendations
   - Radarr live review queue with strict gates
   - Sonarr later
10. Optional extras:
   - remux-only subtitle/audio cleanup
   - Plex/Radarr result history
   - better encode history/search
   - qBit/SAB only if still needed

## Validation Reminder

For app changes:

```powershell
python -m py_compile main.py mediastat_automation_dev/main.py
& "C:\Program Files\Git\bin\bash.exe" -n ha-addon/run.sh
& "C:\Program Files\Git\bin\bash.exe" -n mediastat_automation_dev/run.sh
git diff --check
```

For this helper-doc update, show:

```powershell
git diff -- AGENTS.md docs/AI_HANDOVER.md
git status --short
```
