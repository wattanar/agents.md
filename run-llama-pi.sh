#!/bin/bash

set -euo pipefail

# Tested on llama.cpp 
# Model: Qwen3.6-35B-A3B-MXFP4_MOE.gguf

llama-server \
  --models-dir ~/models \
  --no-models-autoload \
  -ngl 999 \
  -c 131072 \
  -ctk q8_0 \
  -ctv q8_0 \
  -fa on \
  --n-cpu-moe 35 \
  --load-mode mmap \
  -t 8 \
  -np 1 \
  --reasoning on \
  --reasoning-budget 4096 \
  --reasoning-budget-message "Proceed to final answer." \
  --chat-template-kwargs '{"preserve_thinking": true}' \
  -b 2048 \
  -ub 512 \
  --host 127.0.0.1 \
  --port 8081 \
  --jinja
