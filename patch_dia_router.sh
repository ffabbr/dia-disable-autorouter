#!/bin/bash

set -e

MODEL_PATH="$HOME/Library/Caches/company.thebrowser.dia/ModelFileCache/ondevicerouter/classification_head.safetensors"
VENV_PATH="$HOME/.dia-router-venv"

echo "----- Dia Router Patch -----"

# 1. Check model exists
if [ ! -f "$MODEL_PATH" ]; then
    echo "Model file not found at:"
    echo "$MODEL_PATH"
    exit 1
fi

# 2. Create venv if missing
if [ ! -d "$VENV_PATH" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "$VENV_PATH"
fi

# 3. Activate venv
source "$VENV_PATH/bin/activate"

# 4. Install dependencies if missing
if ! python -c "import torch" 2>/dev/null; then
    echo "Installing torch..."
    pip install torch
fi

if ! python -c "import safetensors" 2>/dev/null; then
    echo "Installing safetensors..."
    pip install safetensors
fi

if ! python -c "import numpy" 2>/dev/null; then
    echo "Installing numpy..."
    pip install numpy
fi

if ! python -c "import packaging" 2>/dev/null; then
    echo "Installing packaging..."
    pip install packaging
fi

# 5. Unlock file (in case it was locked)
chmod 644 "$MODEL_PATH"

# 6. Run patch
python <<EOF
from safetensors.torch import load_file, save_file
from pathlib import Path

model_path = Path("$MODEL_PATH")
tensors = load_file(str(model_path))

# Modify both classifier biases
tensors["classifier.modules_to_save.default.bias"][1] = -1000.0
tensors["classifier.original_module.bias"][1] = -1000.0

save_file(tensors, str(model_path))
print("Bias patched successfully.")
EOF

# 7. Lock file again
chmod 444 "$MODEL_PATH"

echo "Model locked."
echo "Done."
