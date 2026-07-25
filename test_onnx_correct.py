import sys
sys.stdout.reconfigure(encoding='utf-8')

from transformers import AutoTokenizer
from huggingface_hub import hf_hub_download
import onnxruntime as ort
import numpy as np
import sentencepiece as spm

model_name = "Helsinki-NLP/opus-mt-en-zh"
tokenizer = AutoTokenizer.from_pretrained(model_name)

tokenizer_tgt = hf_hub_download(repo_id="onnx-community/opus-mt-en-zh", filename="target.spm")
sp_tgt = spm.SentencePieceProcessor()
sp_tgt.load(tokenizer_tgt)

enc_path = hf_hub_download(repo_id="onnx-community/opus-mt-en-zh", filename="onnx/encoder_model_quantized.onnx")
dec_path = hf_hub_download(repo_id="onnx-community/opus-mt-en-zh", filename="onnx/decoder_model_quantized.onnx")
dec_past_path = hf_hub_download(repo_id="onnx-community/opus-mt-en-zh", filename="onnx/decoder_with_past_model_quantized.onnx")

text = "What're you currently looking for in your company, a co-founder?"
print("Input text:", text)

# Correct HF tokenization with sacremoses pre-tokenization
input_ids = tokenizer(text)["input_ids"]
print("Correct HF Input IDs:", input_ids)

enc_sess = ort.InferenceSession(enc_path)
dec_sess = ort.InferenceSession(dec_path)
dec_past_sess = ort.InferenceSession(dec_past_path)

input_ids_np = np.array([input_ids], dtype=np.int64)
attention_mask_np = np.ones_like(input_ids_np, dtype=np.int64)

# 1. Encoder
enc_out = enc_sess.run(None, {
    "input_ids": input_ids_np,
    "attention_mask": attention_mask_np
})
last_hidden_state = enc_out[0]

# 2. Decoder first step with START TOKEN = 65000
decoder_start_token_id = 65000
dec_out = dec_sess.run(None, {
    "input_ids": np.array([[decoder_start_token_id]], dtype=np.int64),
    "encoder_hidden_states": last_hidden_state,
    "encoder_attention_mask": attention_mask_np
})

logits = dec_out[0][0, -1]
next_token = int(np.argmax(logits))
generated = [next_token]

past_kv = {}
for o, val in zip(dec_sess.get_outputs(), dec_out):
    if o.name.startswith("present."):
        past_kv[o.name.replace("present.", "past_key_values.")] = val

# 3. Autoregressive loop
for step in range(1, 50):
    if generated[-1] == 0:
        break
    
    step_inputs = {
        "input_ids": np.array([[generated[-1]]], dtype=np.int64),
        "encoder_attention_mask": attention_mask_np,
        **past_kv
    }
    
    step_out = dec_past_sess.run(None, step_inputs)
    step_logits = step_out[0][0, -1]
    next_token = int(np.argmax(step_logits))
    generated.append(next_token)
    
    for o, val in zip(dec_past_sess.get_outputs(), step_out):
        if o.name.startswith("present."):
            past_kv[o.name.replace("present.", "past_key_values.")] = val

clean_ids = [i for i in generated if i != 0]
print("ONNX Result with Correct HF Pre-Tokenization:", sp_tgt.decode(clean_ids))
