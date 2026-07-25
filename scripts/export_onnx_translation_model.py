"""
Export Helsinki-NLP OPUS-MT models to INT8-quantized ONNX format.

Usage:
    pip install transformers optimum[onnxruntime] onnx onnxruntime
    python scripts/export_onnx_translation_model.py

This script exports the following language pairs:
  - Helsinki-NLP/opus-mt-en-zh  (English -> Chinese)
  - Helsinki-NLP/opus-mt-jap-zh (Japanese -> Chinese)

Each exported model is ~35-50 MB after INT8 quantization.
Upload the resulting ZIP files to your HuggingFace repo for on-demand download.
"""

import subprocess
import sys
import os
import zipfile
import shutil
from pathlib import Path

# ─── Configuration ────────────────────────────────────────────────────────────

LANGUAGE_PAIRS = [
    {
        "model_id": "Helsinki-NLP/opus-mt-en-zh",
        "lang_pair": "opus-mt-en-zh",
        "description": "English -> Chinese (Simplified)",
    },
    {
        "model_id": "Helsinki-NLP/opus-mt-jap-zh",
        "lang_pair": "opus-mt-jap-zh",
        "description": "Japanese -> Chinese (Simplified)",
    },
]

OUTPUT_DIR = Path(__file__).parent.parent / "onnx_models"
ZIP_OUTPUT_DIR = Path(__file__).parent.parent / "onnx_models_zip"

# ─── Helper functions ─────────────────────────────────────────────────────────

def check_dependencies():
    """Ensure required Python packages are installed."""
    required = ["transformers", "optimum", "onnx", "onnxruntime"]
    missing = []
    for pkg in required:
        try:
            __import__(pkg.replace("-", "_"))
        except ImportError:
            missing.append(pkg)
    if missing:
        print(f"Missing dependencies: {', '.join(missing)}")
        print(f"Install with: pip install {' '.join(missing)} optimum[onnxruntime]")
        sys.exit(1)
    print("✓ All dependencies found.")


def export_model(model_id: str, lang_pair: str, output_path: Path):
    """Export a MarianMT model to ONNX with INT8 quantization."""
    print(f"\n{'='*60}")
    print(f"Exporting: {model_id}")
    print(f"Output:    {output_path}")
    print(f"{'='*60}")

    output_path.mkdir(parents=True, exist_ok=True)

    # Use optimum-cli to export with KV-cache support and O2 optimization
    cmd = [
        sys.executable, "-m", "optimum.commands.optimum_cli",
        "export", "onnx",
        "--model", model_id,
        "--task", "text2text-generation-with-past",
        "--optimize", "O2",
        str(output_path),
    ]

    print(f"Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=False)

    if result.returncode != 0:
        print(f"✗ Export failed for {model_id}")
        sys.exit(1)

    print(f"✓ Export complete for {lang_pair}")


def quantize_model(model_path: Path):
    """Apply INT8 static quantization to reduce model size by ~70%."""
    from optimum.onnxruntime import ORTQuantizer
    from optimum.onnxruntime.configuration import AutoQuantizationConfig

    print(f"\nQuantizing models in: {model_path}")

    # Files to quantize
    onnx_files = [
        "encoder_model.onnx",
        "decoder_model.onnx",
        "decoder_with_past_model.onnx",
    ]

    qconfig = AutoQuantizationConfig.arm64(is_static=False, per_channel=False)

    for filename in onnx_files:
        filepath = model_path / filename
        if not filepath.exists():
            print(f"  Skipping {filename} (not found)")
            continue

        quantizer = ORTQuantizer.from_pretrained(model_path, file_name=filename)
        quantizer.quantize(
            save_dir=model_path,
            quantization_config=qconfig,
        )
        # Replace original with quantized version
        quantized_path = model_path / filename.replace(".onnx", "_quantized.onnx")
        if quantized_path.exists():
            os.replace(quantized_path, filepath)
            print(f"  ✓ Quantized: {filename}")
        else:
            print(f"  ⚠ Quantized file not found, keeping original: {filename}")


def create_zip(model_path: Path, lang_pair: str, zip_output_dir: Path) -> Path:
    """Package model files into a ZIP for HuggingFace hosting."""
    zip_output_dir.mkdir(parents=True, exist_ok=True)
    zip_path = zip_output_dir / f"{lang_pair}.zip"

    # Files required by the Flutter app (onnx_translation package)
    required_files = [
        "encoder_model.onnx",
        "decoder_model.onnx",
        "decoder_with_past_model.onnx",
        "vocab.json",
        "tokenizer_config.json",
        "generation_config.json",
        "source.spm",
        "target.spm",
        "special_tokens_map.json",
        "config.json",
    ]

    print(f"\nCreating ZIP: {zip_path}")
    total_size = 0
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as zf:
        for filename in required_files:
            filepath = model_path / filename
            if filepath.exists():
                zf.write(filepath, arcname=f"{lang_pair}/{filename}")
                size_mb = filepath.stat().st_size / (1024 * 1024)
                total_size += filepath.stat().st_size
                print(f"  + {filename:<40} ({size_mb:.1f} MB)")
            else:
                print(f"  - {filename:<40} (not found, skipping)")

    total_mb = total_size / (1024 * 1024)
    zip_mb = zip_path.stat().st_size / (1024 * 1024)
    print(f"\n✓ ZIP created: {zip_path}")
    print(f"  Raw size:  {total_mb:.1f} MB")
    print(f"  ZIP size:  {zip_mb:.1f} MB")
    return zip_path


def print_upload_instructions(zip_paths: list):
    """Print HuggingFace upload instructions."""
    print("\n" + "="*60)
    print("NEXT STEPS: Upload to HuggingFace")
    print("="*60)
    print("\n1. Install huggingface-hub:")
    print("   pip install huggingface-hub")
    print("\n2. Login to HuggingFace:")
    print("   huggingface-cli login")
    print("\n3. Upload ZIP files to your repo:")
    for zip_path in zip_paths:
        filename = zip_path.name
        print(f"\n   huggingface-cli upload fuji246/small-translation {zip_path} {filename}")
    print("\n4. After upload, the app will be able to download models from:")
    print("   https://huggingface.co/fuji246/small-translation/resolve/main/<lang_pair>.zip")
    print()


# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    check_dependencies()

    zip_paths = []
    for pair in LANGUAGE_PAIRS:
        model_id = pair["model_id"]
        lang_pair = pair["lang_pair"]
        description = pair["description"]

        print(f"\n{'#'*60}")
        print(f"# {description}")
        print(f"# Model: {model_id}")
        print(f"# Lang pair key: {lang_pair}")
        print(f"{'#'*60}")

        model_output_path = OUTPUT_DIR / lang_pair

        # Step 1: Export to ONNX
        export_model(model_id, lang_pair, model_output_path)

        # Step 2: Quantize to INT8
        try:
            quantize_model(model_output_path)
        except Exception as e:
            print(f"⚠ Quantization failed ({e}), continuing with FP32 model")

        # Step 3: Package into ZIP
        zip_path = create_zip(model_output_path, lang_pair, ZIP_OUTPUT_DIR)
        zip_paths.append(zip_path)

    # Final instructions
    print_upload_instructions(zip_paths)

    print("\n✓ All models exported successfully!")
    print(f"  ZIP files are in: {ZIP_OUTPUT_DIR}")


if __name__ == "__main__":
    main()
