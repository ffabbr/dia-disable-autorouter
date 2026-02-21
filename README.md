# dia-disable-autorouter
Patch for Dia’s cmd-T router that disables AI auto-routing by modifying the on-device classification head (safetensors) bias to always select web search. One script to auto-patch, manage dependencies in a venv, and lock/unlock the model file to prevent overwrite on startup. Another script to undo the changes (unlock the file)
