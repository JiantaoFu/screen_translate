import os
import shutil
import zipfile
from pathlib import Path

try:
    from optimum.onnxruntime import ORTModelForSeq2SeqLM
    from transformers import AutoTokenizer
except ImportError:
    print("Error: Missing required packages.")
    print("Please run: pip install optimum[onnxruntime] transformers")
    exit(1)

def export_and_zip(model_id, zip_name):
    print(f"\n========== Exporting {model_id} to ONNX ==========")
    zip_folder_name = zip_name.replace('.zip', '')
    out_dir = Path("temp_onnx") / zip_folder_name
    
    if out_dir.exists():
        shutil.rmtree(out_dir)
        
    print("Downloading and exporting model (this might take a few minutes)...")
    # Export model using optimum
    model = ORTModelForSeq2SeqLM.from_pretrained(model_id, export=True)
    tokenizer = AutoTokenizer.from_pretrained(model_id)
    
    model.save_pretrained(out_dir)
    tokenizer.save_pretrained(out_dir)
    
    print(f"Creating zip file {zip_name}...")
    with zipfile.ZipFile(zip_name, 'w', zipfile.ZIP_DEFLATED) as zf:
        for root, _, files in os.walk(out_dir):
            for file in files:
                file_path = Path(root) / file
                # The flutter app expects these exact files
                if file.endswith('.onnx') or file.endswith('.spm') or file == 'config.json':
                    # Put it inside a folder named like the zip file, because the Dart code expects:
                    # file.name.startsWith('$langPairKey/')
                    # So for `opus-mt-en-zh.zip`, it expects `opus-mt-en-zh/encoder_model.onnx`
                    arcname = Path(zip_folder_name) / file
                    print(f"  Adding {arcname}...")
                    zf.write(file_path, arcname)

    print(f"Done! {zip_name} is ready to be uploaded to HuggingFace.")
    
    # Cleanup
    shutil.rmtree(out_dir)

if __name__ == "__main__":
    print("Starting ONNX export script...")
    export_and_zip("Helsinki-NLP/opus-mt-en-zh", "opus-mt-en-zh.zip")
    
    print("\nEnglish to Chinese model exported successfully!")
    print("Note: A direct Japanese->Chinese OPUS-MT model is not officially available from Helsinki-NLP.")
    print("Now upload 'opus-mt-en-zh.zip' to your HuggingFace repository: fuji246/small-translation")
