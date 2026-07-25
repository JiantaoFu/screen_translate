from huggingface_hub import hf_hub_download
import json

config_path = hf_hub_download(repo_id="onnx-community/opus-mt-en-zh", filename="config.json")
with open(config_path, "r", encoding="utf-8") as f:
    config = json.load(f)

print("Decoder start token ID:", config.get("decoder_start_token_id"))
print("EOS token ID:", config.get("eos_token_id"))
print("PAD token ID:", config.get("pad_token_id"))
print("Full config:", json.dumps(config, indent=2))
