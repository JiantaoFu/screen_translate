import sys
sys.stdout.reconfigure(encoding='utf-8')

from optimum.onnxruntime import ORTModelForSeq2SeqLM
from transformers import AutoTokenizer

model_id = "onnx-community/opus-mt-en-zh"
tokenizer = AutoTokenizer.from_pretrained(model_id)
model = ORTModelForSeq2SeqLM.from_pretrained(model_id)

text = "What're you currently looking for in your company, a co-founder?"
print("Input text:", text)

inputs = tokenizer(text, return_tensors="pt")
print("Tokenizer output input_ids:", inputs["input_ids"].tolist())
print("Tokenizer decoded:", tokenizer.decode(inputs["input_ids"][0]))

outputs = model.generate(**inputs, max_new_tokens=50)
result = tokenizer.decode(outputs[0], skip_special_tokens=True)
print("Optimum ONNX generation result:", result)
print("Optimum generated token IDs:", outputs[0].tolist())
