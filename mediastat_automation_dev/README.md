# MediaStat Automation Dev

This is a development/test Home Assistant add-on for the MediaStat automation
branch. It is intended to install beside the normal MediaStat add-on without
sharing its slug, title, or exposed host port.

Configure automation from this add-on's Configuration tab. Start with
`dry_run: true` and confirm requests validate correctly before enabling live
queueing.

Automation V1 is keep-only. It does not delete, replace, move, stage, back up,
quarantine, or refresh Radarr/Sonarr. Live Radarr/Sonarr sidecar output is
blocked by default with `allow_arr_sidecar_output: false`.
