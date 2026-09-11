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

REMOTE_PATH="/tmp/cbj_print_job_$$.${EXT}"

echo "$CONTENT_B64" | base64 -d | ssh -o StrictHostKeyChecking=no -o ConnectTimeout=8 \
    -i /config/.ssh/id_ed25519_printserver \
    jon@192.168.1.46 \
    "cat > '${REMOTE_PATH}' && lp -d CanonTR4650 -t 'Auto Print' '${REMOTE_PATH}' && rm -f '${REMOTE_PATH}'"
