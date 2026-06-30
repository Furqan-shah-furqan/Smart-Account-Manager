#!/usr/bin/env bash
set -euo pipefail

FLUTTER_DIR="/tmp/flutter"

git clone https://github.com/flutter/flutter.git \
  --depth 1 \
  --branch stable \
  "$FLUTTER_DIR"

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter config --enable-web
flutter pub get

flutter build web --release --no-wasm-dry-run \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
