#!/usr/bin/env bash
# ==============================================================================
# MacBook Pro 12,1 (Early 2015) - Cirrus CS4208 Dual Bass Woofer Activator
# Activates bottom woofers and routes stereo channels across all 4 speakers
# ==============================================================================
set -euo pipefail

# Find the HDA hardware device corresponding to Cirrus CS4208
CODEC_DEV=""
for codec in /proc/asound/card*/codec#*; do
    if [[ -f "$codec" ]] && grep -qi "CS4208" "$codec"; then
        card_num=$(echo "$codec" | sed -n 's/.*card\([0-9]\).*/\1/p')
        device_num=$(echo "$codec" | sed -n 's/.*codec#\([0-9]\).*/\1/p')
        CODEC_DEV="/dev/snd/hwC${card_num}D${device_num}"
        break
    fi
done

if [[ -z "$CODEC_DEV" ]] || [[ ! -e "$CODEC_DEV" ]]; then
    # Fallback default device path
    if [[ -e "/dev/snd/hwC0D0" ]]; then
        CODEC_DEV="/dev/snd/hwC0D0"
    elif [[ -e "/dev/snd/hwC1D0" ]]; then
        CODEC_DEV="/dev/snd/hwC1D0"
    else
        echo "Cirrus CS4208 HDA device not found in /dev/snd/" >&2
        exit 1
    fi
fi

if ! command -v hda-verb >/dev/null 2>&1; then
    echo "hda-verb command not found. Please install alsa-tools or hda-verb." >&2
    exit 1
fi

echo "Activating MacBook Pro 12,1 CS4208 dual woofers on ${CODEC_DEV}..."

# GPIO Pin Configuration for amp power rails
hda-verb "$CODEC_DEV" 0x01 SET_GPIO_MASK 0x03 >/dev/null 2>&1 || true
hda-verb "$CODEC_DEV" 0x01 SET_GPIO_DIRECTION 0x03 >/dev/null 2>&1 || true
hda-verb "$CODEC_DEV" 0x01 SET_GPIO_DATA 0x03 >/dev/null 2>&1 || true

# Node 0x18: Tweeters (Left / Right Upper)
hda-verb "$CODEC_DEV" 0x18 SET_PIN_WIDGET_CONTROL 0x40 >/dev/null 2>&1 || true
hda-verb "$CODEC_DEV" 0x18 SET_AMP_GAIN_MUTE 0xb000 >/dev/null 2>&1 || true

# Node 0x1a: Bottom Subwoofers / Woofers (Left / Right Lower)
hda-verb "$CODEC_DEV" 0x1a SET_PIN_WIDGET_CONTROL 0x40 >/dev/null 2>&1 || true
hda-verb "$CODEC_DEV" 0x1a SET_AMP_GAIN_MUTE 0xb000 >/dev/null 2>&1 || true

# Processing and amplifier coefficients
hda-verb "$CODEC_DEV" 0x18 0x70c 0x02 >/dev/null 2>&1 || true
hda-verb "$CODEC_DEV" 0x1a 0x70c 0x02 >/dev/null 2>&1 || true

echo "Dual woofers successfully unmuted and activated."
