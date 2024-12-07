import runpod
from runpod.serverless.utils.rp_cleanup import clean

import os
os.environ['SPCONV_ALGO'] = 'native'

from typing import *
import numpy as np
import imageio
import uuid
from PIL import Image
from trellis.pipelines import TrellisImageTo3DPipeline
from trellis.utils import render_utils, postprocessing_utils

import base64
from io import BytesIO

MAX_SEED = np.iinfo(np.int32).max

def handler(event):
    try:
        input = event["input"]

        image_bytes = base64.b64decode(input["image"])
        image = Image.open(BytesIO(image_bytes))

        seed = input.get("seed", np.random.randint(0, MAX_SEED))
        ss_sampling_steps = input.get("ss_sampling_steps", 12)
        ss_guidance_strength = input.get("ss_guidance_strength", 7.5)
        slat_sampling_steps = input.get("slat_sampling_steps", 12)
        slat_guidance_strength = input.get("slat_guidance_strength", 3)
        mesh_simplify = input.get("mesh_simplify", 0.95)
        texture_size = input.get("texture_size", 1024)

        outputs = pipeline.run(
            image,
            seed=seed,
            formats=["gaussian", "mesh"],
            preprocess_image=True,
            sparse_structure_sampler_params={
                "steps": ss_sampling_steps,
                "cfg_strength": ss_guidance_strength,
            },
            slat_sampler_params={
                "steps": slat_sampling_steps,
                "cfg_strength": slat_guidance_strength,
            }
        )

        gs = outputs["gaussian"][0]
        mesh = outputs["mesh"][0]

        glb = postprocessing_utils.to_glb(gs, mesh, simplify=mesh_simplify, texture_size=texture_size, verbose=False)

        glb_bytes = BytesIO()
        glb.export(glb_bytes, file_type="glb")

        glb_base64 = base64.b64encode(glb_bytes.getvalue()).decode("utf-8")

        return {"glb": glb_base64}

    finally:
        clean()

if __name__ == '__main__':
    pipeline = TrellisImageTo3DPipeline.from_pretrained("JeffreyXiang/TRELLIS-image-large")
    pipeline.cuda()
    try:
        # Preload rembg
        pipeline.preprocess_image(Image.fromarray(np.zeros((512, 512, 3), dtype=np.uint8)))
    except:
        pass

    runpod.serverless.start({"handler": handler})
