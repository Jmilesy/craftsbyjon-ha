#!/bin/bash
# Prints a file (e.g. a PDF attachment) to the CanonTR4650 queue on the
# print-server Pi. Content arrives base64-encoded (arg 1); the extension
# (arg 2) is validated against a strict allowlist before use anywhere.
CONTENT_B64="$1"
EXT_RAW="${2:-pdf}"

# Only ever accept a short alphanumeric extension - reject anything else
if [[ "$EXT_RAW" =~ ^[a-zA-Z0-9]{1,5}$ ]]; then
    EXT="$EXT_RAW"
else
    EXT="pdf"
fi

# ext "esc": raw ESC/POS bytes for the Epson TM-T88V staff slip printer on the
# Pi (added 12 Nov 2026, see Miles_Home home-tech/hardware/plans/epson-staff-slip-plan.md).
# Goes to the raw CUPS queue EpsonSlip and never touches the Canon queue.
if [ "$EXT" = "esc" ]; then
    echo "$CONTENT_B64" | base64 -d | ssh -o StrictHostKeyChecking=no -o ConnectTimeout=8 \
        -i /config/.ssh/id_ed25519_printserver \
        jon@192.168.1.46 \
        "lp -d EpsonSlip -o raw -t 'Staff slip'"
    exit $?
fi

REMOTE_PATH="/tmp/cbj_print_job_$$.${EXT}"

echo "$CONTENT_B64" | base64 -d | ssh -o StrictHostKeyChecking=no -o ConnectTimeout=8 \
    -i /config/.ssh/id_ed25519_printserver \
    jon@192.168.1.46 \
    "cat > '${REMOTE_PATH}' && lp -d CanonTR4650 -t 'Auto Print' '${REMOTE_PATH}' && rm -f '${REMOTE_PATH}'"
