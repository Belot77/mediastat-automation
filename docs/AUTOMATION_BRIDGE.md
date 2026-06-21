# MediaStat Automation Bridge V1

V1 exposes a backend-only automation endpoint that validates requests from Radarr,
Sonarr, SABnzbd, or qBittorrent and queues normal MediaStat encode jobs.

V1 is dry-run first and keep-only. It does not delete, replace, rename, overwrite,
move, stage, backup, quarantine, or refresh media/library records.

## Example config.yaml

```yaml
automation:
  enabled: true
  token: "YOUR_AUTOMATION_TOKEN"
  dry_run: true
  allow_arr_sidecar_output: false
  file_stability_check_enabled: true
  file_stability_wait_seconds: 30
  review_output_enabled: true
  review_output_root: "/media/mediastat-review"
  review_preflight_enabled: true
  default_profile: high_quality_hevc_qp18
  default_post_action: keep

  schedule:
    enabled: true
    start: "02:00"
    end: "06:00"
    mode: finish_current
    do_not_start_if_less_than_minutes_left: 90

  profiles:
    high_quality_hevc_qp18:
      label: "High Quality HEVC QP18"
      codec: hevc
      gpu: auto
      format: mkv
      qp: 18
      preset: quality
      lang: eng
    balanced_hevc_qp20:
      label: "Balanced HEVC QP20"
      codec: hevc
      gpu: auto
      format: mkv
      qp: 20
      preset: balanced
      lang: eng
    space_saver_hevc_qp23:
      label: "Space Saver HEVC QP23"
      codec: hevc
      gpu: auto
      format: mkv
      qp: 23
      preset: balanced
      lang: eng

  sources:
    radarr:
      enabled: true
      allowed_events:
        - import
      default_profile: high_quality_hevc_qp18
      default_post_action: keep
      allow_replace: false
    sonarr:
      enabled: true
      allowed_events:
        - import
      default_profile: balanced_hevc_qp20
      default_post_action: keep
      allow_replace: false
    sab:
      enabled: false
      allowed_events:
        - download_complete
      managed_categories:
        - radarr
        - sonarr
      manual_categories:
        - manual
        - mediastat
        - encode
      default_profile: balanced_hevc_qp20
      default_post_action: keep
      allow_replace: false
    qbit:
      enabled: false
      allowed_events:
        - download_complete
      managed_categories:
        - radarr
        - sonarr
      manual_categories:
        - manual
        - mediastat
        - encode
      default_profile: space_saver_hevc_qp23
      default_post_action: keep
      allow_replace: false
```

## Queue request

### Local development

When running MediaStat directly or with a locally exposed port, test against the
local service URL:

```bash
curl -X POST "http://localhost:8080/automation/queue" \
  -H "Content-Type: application/json" \
  -H "X-Automation-Token: YOUR_AUTOMATION_TOKEN" \
  -d '{
    "source": "radarr",
    "event": "import",
    "path": "/media/library/Example.mkv",
    "profile": "high_quality_hevc_qp18",
    "post_action": "keep",
    "category": ""
  }'
```

### Home Assistant add-on

When running as a Home Assistant add-on, configure automation in the add-on
Configuration tab. The add-on writes those options to `/data/config.yaml` at
startup, and MediaStat reads that file through `CONFIG_PATH`.

Ingress is intended for browser UI access through Home Assistant. External
automation clients should use the add-on's exposed port when available, for
example:

```bash
curl -X POST "http://HOME_ASSISTANT_HOST:8080/automation/queue" \
  -H "Content-Type: application/json" \
  -H "X-Automation-Token: YOUR_AUTOMATION_TOKEN" \
  -d '{
    "source": "radarr",
    "event": "import",
    "path": "/media/library/Example.mkv",
    "profile": "high_quality_hevc_qp18",
    "post_action": "keep",
    "category": ""
  }'
```

Keep `dry_run: true` for first tests. MediaStat validates the request and returns
the output path that would be queued, but it does not create an encode job.

With `dry_run: false`, Radarr and Sonarr requests are blocked by default when the
candidate output would be a live sidecar file in the same library folder as the
input. Leave `allow_arr_sidecar_output: false` for V1 unless you are deliberately
testing in a safe non-library location.

## Automation status page

Open `Automation` from the MediaStat header to view the current safe automation
configuration, the most recent automation decision, and recent decision history.
The page shows whether automation is enabled, whether dry-run is active, whether
a token is configured, source policy, and the last request/result summary.

The page also has schedule and review-output controls for automation testing.
Enter the existing automation token in the password field, set the schedule and
review output values, and save. Only these whitelisted settings are persisted:
`schedule.enabled`, `schedule.start`, `schedule.end`, `review_output_enabled`,
`review_output_root`, and `review_preflight_enabled`.

```text
/data/automation_settings.json
```

The token is sent as the `X-Automation-Token` header for the save request. It is
not displayed, stored in the settings file, or written to automation history.
The review root must be a non-empty absolute `/media/...` path, must not be `/`
or `/media`, and should point to deliberately mounted storage with enough space.

The page never renders the token value. It only shows `token_configured` as
`true` or `false`.

## Automation history

Every automation decision is appended to:

```text
/data/automation_history.jsonl
```

The file is JSON Lines format: one sanitized JSON object per line. Records include
available fields such as timestamp, source, event, category, decision/result,
dry-run state, queued/ignored state, job id, profile, post action, input path,
output path, raw file sizes, human-readable file sizes, reason/error, warnings,
and HTTP-style outcome.

Tokens, request headers, secrets, and full raw request bodies are not stored. The
Automation page reads a bounded recent view, currently the last 100 readable
entries, and skips missing or partially unreadable history safely.

Keep `dry_run: true`, `allow_arr_sidecar_output: false`, and `post_action: keep`
for current Radarr/Sonarr testing. In dry-run mode the history shows the
decisions MediaStat would make without queueing encode jobs.

## File stability guardrail

Automation checks file stability before accepting a media file as processable.
When `file_stability_check_enabled: true`, MediaStat records the input file size
and modified time, waits `file_stability_wait_seconds`, then records size and
modified time again. The file is stable only when both values are unchanged.

The safety-first default wait is 30 seconds:

```yaml
automation:
  file_stability_check_enabled: true
  file_stability_wait_seconds: 30
```

For faster dry-run testing, temporarily lower `file_stability_wait_seconds` in a
safe test environment. Keep `dry_run: true`; the stability check proves whether a
future live queue would be safe without creating an encode job.

Dry-run responses, Last Decision, and automation history include stability
fields such as `file_stable`, `stability_check_enabled`,
`stability_wait_seconds`, `size_before`, `size_after`, `mtime_before`,
`mtime_after`, and `stability_reason`. If the file changes during the wait,
MediaStat returns a file-unstable decision and does not queue anything.

## Review output path

Automation plans output into a review/staging area instead of beside the imported
movie or episode file. With the default automation settings:

```yaml
automation:
  review_output_enabled: true
  review_output_root: "/media/mediastat-review"
```

MediaStat keeps the normal encoded filename, preserves useful relative library
folders when possible, and places the planned output under the review root. Set
`review_output_root` from the Automation page to a known mounted storage path,
preferably Synology-backed, such as `/media/MediaStatReview`.

The original media file remains untouched. The review output path is intended to
stay outside Radarr, Sonarr, Plex, or other live library folders while automation
is being tested.

Raw byte values such as `size_before` and `size_after` remain in the JSON
response and history. The Automation page prefers `size_before_human` and
`size_after_human` for readability.

## Review output preflight

Accepted, stable dry-run requests run a review/staging output preflight before
they are shown as queueable. The preflight confirms that the planned output is
under `review_output_root`, confirms it is not beside the original media file,
confirms the review root already exists and is a directory, creates the planned
parent folder under the review root if needed, writes a tiny probe file there,
then deletes the probe file.

If preflight passes, the dry-run preview can show `would_queue: true` while
still keeping `queued: false` and `job_id: null`. If preflight fails, the request
still does not queue anything and the response/history show
`review_preflight_ok: false`, `queue_blocked_by: "review_preflight_failed"`, and
a clear `review_preflight_reason`.

Preflight may create folders only under the configured review output root. It
must not create a live sidecar output beside Radarr/Sonarr media, write into the
movie or episode library folder, encode media, or change original files.
MediaStat does not create `review_output_root` automatically; create or mount it
deliberately before testing. If the root is missing, preflight returns
`review_preflight_ok: false` with `review_preflight_reason:
"review output root does not exist"`.

Responses, Last Decision, and history may include fields such as
`review_preflight_enabled`, `review_output_enabled`, `review_preflight_ok`,
`review_root`, `planned_parent_path`, `planned_parent_writable`,
`output_under_review_root`, `output_beside_original`,
`movie_library_sidecar_needed`, and `write_probe_ok`.

## Job preview

Accepted dry-run automation requests include a job preview so the response,
Last Decision, and Recent Automation History show what would happen later if live
automation queueing were enabled.

Preview fields include `would_queue`, `queue_blocked_by`, `preview_status`,
planned source/event/profile/post action, planned input/output paths, and the
automation schedule window/status. In dry-run mode, a stable accepted request
uses `would_queue: true`, keeps `queued: false`, keeps `job_id: null`, and sets
`queue_blocked_by: "dry_run"`.

Unstable files use `would_queue: false` and `queue_blocked_by: "file_unstable"`.
Ignored or rejected requests remain non-queueing decisions. The preview does not
start jobs, encode files, change original media, or change scheduler behaviour.

For direct HTTP checks, request:

```bash
curl "http://localhost:8080/automation/status"
```

When running through the Home Assistant add-on, use the ingress UI link or the
add-on's exposed host port if direct HTTP access is enabled.

## Radarr/Sonarr dry-run integration

Keep automation in dry-run mode while wiring Radarr or Sonarr:

```yaml
automation:
  dry_run: true
  allow_arr_sidecar_output: false
  default_post_action: keep
```

Requests should send `post_action: "keep"` or omit `post_action` so the source
default resolves to `keep`. V1 does not replace, delete, move, stage, back up, or
refresh library entries.

Use Radarr/Sonarr import events for managed media. Keep qBit/SAB automation
disabled for now so download-complete events do not race the library manager or
create confusing duplicate decisions before import has completed.

### Radarr import payload

Use this shape from a Radarr custom script or webhook after an import event. The
exact media path should be the final imported movie file path that MediaStat can
read under its allowed roots.

```json
{
  "source": "radarr",
  "event": "import",
  "path": "/media/library/Movie Example (2026)/Movie Example (2026).mkv",
  "profile": "high_quality_hevc_qp18",
  "post_action": "keep",
  "category": ""
}
```

### Sonarr import payload

Use this shape from a Sonarr custom script or webhook after an episode import
event. The path should be the final imported episode file path.

```json
{
  "source": "sonarr",
  "event": "import",
  "path": "/media/library/Series Example/Season 01/Series Example - S01E01.mkv",
  "profile": "balanced_hevc_qp20",
  "post_action": "keep",
  "category": ""
}
```

### Dry-run helper scripts

Windows PowerShell:

```powershell
$env:MEDIASTAT_AUTOMATION_URL = "http://localhost:8080/automation/queue"
$env:MEDIASTAT_AUTOMATION_TOKEN = "YOUR_AUTOMATION_TOKEN"
.\docs\examples\automation-dryrun-test.ps1 radarr "C:\Path\To\Imported\File.mkv"
.\docs\examples\automation-dryrun-test.ps1 sonarr "C:\Path\To\Imported\Episode.mkv" balanced_hevc_qp20
```

Linux/container shell:

```bash
export MEDIASTAT_AUTOMATION_URL="http://localhost:8080/automation/queue"
export MEDIASTAT_AUTOMATION_TOKEN="YOUR_AUTOMATION_TOKEN"
./docs/examples/automation-dryrun-test.sh radarr "/media/library/Movie Example (2026)/Movie Example (2026).mkv"
./docs/examples/automation-dryrun-test.sh sonarr "/media/library/Series Example/Season 01/Series Example - S01E01.mkv" balanced_hevc_qp20
```

Both scripts print the HTTP status and response body. They do not contain a real
token; set `MEDIASTAT_AUTOMATION_TOKEN` in your shell before running them.

Radarr and Sonarr import events are preferred for managed media. SABnzbd and
qBittorrent completed-download events for managed categories are ignored so the
library manager can handle final imports.

## V1 limits

V1 only supports `post_action: keep`. Destructive replace/delete workflows,
staging output, backup/quarantine, Radarr/Sonarr refresh, dashboard UI, profile
editor UI, token generator UI, and path mapping UI are reserved for later work.
