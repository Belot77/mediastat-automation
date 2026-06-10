#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
    echo "Usage: $0 <radarr|sonarr> <media-path> [profile]" >&2
    exit 2
fi

source_name="$1"
media_path="$2"
profile="${3:-}"

case "${source_name}" in
    radarr|sonarr) ;;
    *)
        echo "source must be radarr or sonarr" >&2
        exit 2
        ;;
esac

: "${MEDIASTAT_AUTOMATION_URL:?Set MEDIASTAT_AUTOMATION_URL, for example http://localhost:8080/automation/queue}"
: "${MEDIASTAT_AUTOMATION_TOKEN:?Set MEDIASTAT_AUTOMATION_TOKEN before running this test}"

automation_url="${MEDIASTAT_AUTOMATION_URL%/}"
if [[ "${automation_url}" != */automation/queue ]]; then
    automation_url="${automation_url}/automation/queue"
fi

if [[ -n "${profile}" ]]; then
    payload=$(python3 -c 'import json, sys; print(json.dumps({"source": sys.argv[1], "event": "import", "path": sys.argv[2], "profile": sys.argv[3], "post_action": "keep", "category": ""}))' "${source_name}" "${media_path}" "${profile}")
else
    payload=$(python3 -c 'import json, sys; print(json.dumps({"source": sys.argv[1], "event": "import", "path": sys.argv[2], "post_action": "keep", "category": ""}))' "${source_name}" "${media_path}")
fi

tmp_body="$(mktemp)"
trap 'rm -f "${tmp_body}"' EXIT

http_status=$(
    curl -sS \
        -o "${tmp_body}" \
        -w "%{http_code}" \
        -X POST "${automation_url}" \
        -H "Content-Type: application/json" \
        -H "X-Automation-Token: ${MEDIASTAT_AUTOMATION_TOKEN}" \
        -d "${payload}"
)

echo "HTTP status: ${http_status}"
echo "Response body:"
cat "${tmp_body}"
echo

if [[ "${http_status}" -lt 200 || "${http_status}" -ge 300 ]]; then
    exit 1
fi
