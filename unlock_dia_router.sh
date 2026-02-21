#!/bin/bash

MODEL_PATH="$HOME/Library/Caches/company.thebrowser.dia/ModelFileCache/ondevicerouter/classification_head.safetensors"

if [ ! -f "$MODEL_PATH" ]; then
    echo "Model file not found."
    exit 1
fi

chmod 644 "$MODEL_PATH"
echo "Model unlocked (writable)."
