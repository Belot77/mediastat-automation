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
output path, reason/error, warnings, and HTTP-style outcome.

Tokens, request headers, secrets, and full raw request bodies are not stored. The
Automation page reads a bounded recent view, currently the last 100 readable
entries, and skips missing or partially unreadable history safely.

Keep `dry_run: true`, `allow_arr_sidecar_output: false`, and `post_action: keep`
for current Radarr/Sonarr testing. In dry-run mode the history shows the
decisions MediaStat would make without queueing encode jobs.

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
