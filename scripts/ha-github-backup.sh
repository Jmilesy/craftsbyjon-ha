#!/usr/bin/env bash
set -euo pipefail

STAMP="$(date '+%Y-%m-%d %H:%M:%S %z')"
export HA_GIT_SAVE_AUTOMATION=1
exec /usr/local/bin/ha-git-save "HA safety backup ${STAMP}"
