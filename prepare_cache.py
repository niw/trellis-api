import os
import json
from huggingface_hub import hf_hub_download
import torch
import rembg

# Download Hugging Face hosted models to os.environ['HF_HOME']
print(os.environ['HF_HOME'])

repo_id = "JeffreyXiang/TRELLIS-image-large"

config_file = hf_hub_download(repo_id, "pipeline.json")

with open(config_file, "r") as f:
    args = json.load(f)["args"]

for _, v in args["models"].items():
    print(v)
    hf_hub_download(repo_id, f"{v}.json")
    hf_hub_download(repo_id, f"{v}.safetensors")

# Download https://github.com/facebookresearch/dinov2 models to os.environ['TORCH_HOME']
print(os.environ['TORCH_HOME'])

torch.hub.load("facebookresearch/dinov2", args["image_cond_model"], pretrained=True)

# Download https://github.com/danielgatis/rembg/releases/download/v0.0.0/u2net.onnx to os.environ['U2NET_HOME']
print(os.environ['U2NET_HOME'])

rembg.new_session('u2net')
