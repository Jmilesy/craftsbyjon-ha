#!/bin/bash
# Pauses the CanonTR4650 CUPS queue on the print-server Pi.
# Jobs sent while paused are held by CUPS and released automatically
# when the queue is re-enabled (see printer_cups_enable.sh).
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=8 \
    -i /config/.ssh/id_ed25519_printserver \
    jon@192.168.1.46 \
    "sudo -n cupsdisable CanonTR4650"
