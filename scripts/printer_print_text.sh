#!/bin/bash
# Prints plain text to the CanonTR4650 queue on the print-server Pi.
# Content arrives base64-encoded (arg 1) specifically so arbitrary email
# body text never gets interpreted as shell syntax on either end.
CONTENT_B64="$1"

echo "$CONTENT_B64" | base64 -d | ssh -o StrictHostKeyChecking=no -o ConnectTimeout=8 \
    -i /config/.ssh/id_ed25519_printserver \
    jon@192.168.1.46 \
    "lp -d CanonTR4650 -t 'Auto Print'"
