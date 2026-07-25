from transformers import AutoTokenizer
import sentencepiece as spm
from huggingface_hub import hf_hub_download

model_name = "Helsinki-NLP/opus-mt-en-zh"
tokenizer = AutoTokenizer.from_pretrained(model_name)

text = "What're you currently looking for in your company, a co-founder?"
hf_ids = tokenizer(text)["input_ids"]
print("HF Tokenizer IDs:", hf_ids)

tokenizer_src = hf_hub_download(repo_id="onnx-community/opus-mt-en-zh", filename="source.spm")
sp_src = spm.SentencePieceProcessor()
sp_src.load(tokenizer_src)

sp_ids = sp_src.encode(text)
print("SentencePiece raw IDs:", sp_ids)
