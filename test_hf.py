import sys
sys.stdout.reconfigure(encoding='utf-8')

from transformers import AutoTokenizer, AutoModelForSeq2SeqLM

model_name = "Helsinki-NLP/opus-mt-en-zh"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForSeq2SeqLM.from_pretrained(model_name)

text = "What're you currently looking for in your company, a co-founder?"
inputs = tokenizer(text, return_tensors="pt")
outputs = model.generate(**inputs)
translation = tokenizer.decode(outputs[0], skip_special_tokens=True)

print("Transformers GOLD STANDARD result:", translation)
print("Generated token IDs:", outputs[0].tolist())
