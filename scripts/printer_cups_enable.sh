#!/bin/bash
# Resumes the CanonTR4650 CUPS queue on the print-server Pi.
# Any jobs held while paused print automatically, in order.
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=8 \
    -i /config/.ssh/id_ed25519_printserver \
    jon@192.168.1.46 \
    "sudo -n cupsenable CanonTR4650"
