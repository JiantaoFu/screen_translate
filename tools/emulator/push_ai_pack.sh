#!/usr/bin/env bash
# Usage: push_ai_pack.sh <pack> [quantized|fp16]   e.g. push_ai_pack.sh opus-mt-ko-en fp16
# Installs an AI (ONNX) language pack into the debug app on the emulator.
# The in-app download is slow on the emulator's network; this fetches the
# files on the host (cached in build/ai_packs/) and copies them into the
# app's files dir, where the app looks for them. The variant must match the
# pack's entry in kSupportedOnnxPairs (useFp16).
source "$(dirname "$0")/common.sh"
PACK=$1; VARIANT=${2:-quantized}
[ -n "$PACK" ] || { echo "usage: $0 <pack> [quantized|fp16]"; exit 1; }
if $A shell run-as $PKG ls files/onnx_models/$PACK/vocab.json >/dev/null 2>&1; then
  echo "$PACK already installed"; exit 0
fi
DIR="$ROOT/build/ai_packs/$PACK"
mkdir -p "$DIR"
base=https://huggingface.co/onnx-community/$PACK/resolve/main
for pair in "onnx/encoder_model_$VARIANT.onnx encoder_model.onnx" \
            "onnx/decoder_model_$VARIANT.onnx decoder_model.onnx" \
            "onnx/decoder_with_past_model_$VARIANT.onnx decoder_with_past_model.onnx" \
            "source.spm source.spm" "vocab.json vocab.json"; do
  set -- $pair
  [ -f "$DIR/$2" ] || curl -sSLf -o "$DIR/$2" "$base/$1" || { echo "download failed: $1"; exit 1; }
done
$A shell am force-stop $PKG
$A shell run-as $PKG mkdir -p files/onnx_models/$PACK
for f in encoder_model.onnx decoder_model.onnx decoder_with_past_model.onnx source.spm vocab.json; do
  $A push "$DIR/$f" /data/local/tmp/$f >/dev/null &&
    $A shell "run-as $PKG sh -c 'cat /data/local/tmp/$f > files/onnx_models/$PACK/$f'" &&
    $A shell rm /data/local/tmp/$f || { echo "push failed: $f (emulator /data full?)"; exit 1; }
done
echo "$PACK installed"
