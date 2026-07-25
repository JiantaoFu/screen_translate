import os
from huggingface_hub import hf_hub_download
import onnxruntime as ort

model_path = hf_hub_download(repo_id="onnx-community/opus-mt-en-zh", filename="onnx/decoder_with_past_model_quantized.onnx")

session = ort.InferenceSession(model_path)
print("Inputs:")
for i in session.get_inputs():
    print(i.name, i.shape)
print("Outputs:")
for o in session.get_outputs():
    print(o.name, o.shape)
