import base64
from io import BytesIO
from time import time
from typing import Any

import PIL
import requests
import runpod  # type: ignore
import torch
from diffusers import (
    EulerAncestralDiscreteScheduler,
    StableDiffusionInstructPix2PixPipeline,
)
from diffusers.pipelines.stable_diffusion import StableDiffusionSafetyChecker


def handler(event: Any) -> dict:
    start_time = time()

    model_id = "timbrooks/instruct-pix2pix"
    pipe = StableDiffusionInstructPix2PixPipeline.from_pretrained(
        model_id,
        torch_dtype=torch.float16,
        safety_checker=StableDiffusionSafetyChecker.from_pretrained(
            "CompVis/stable-diffusion-safety-checker"
        ),
    )
    pipe.to("cuda")
    pipe.scheduler = EulerAncestralDiscreteScheduler.from_config(pipe.scheduler.config)

    image_url = event["input"]["image_url"] if "image_url" in event["input"] else None
    prompt = event["input"]["prompt"] if "prompt" in event["input"] else None
    num_steps = event["input"]["num_steps"] if "num_steps" in event["input"] else 10

    def download_image(url):
        image = PIL.Image.open(requests.get(url, stream=True).raw)
        image = PIL.ImageOps.exif_transpose(image)
        image = image.convert("RGB")
        return image

    def image_to_base64(image: PIL.Image) -> str:
        buffered = BytesIO()
        image.save(buffered, format="JPEG")
        img_byte = buffered.getvalue()
        return base64.b64encode(img_byte).decode()

    image = download_image(image_url)

    results = pipe(
        prompt, image=image, num_inference_steps=num_steps, image_guidance_scale=1
    )

    generation_time = time() - start_time
    print(f"Generated in {generation_time} seconds")

    return {
        "image_base64": image_to_base64(results.images[0]),
        "generation_time": generation_time,
        "is_nsfw": results.nsfw_content_detected[0],
    }


runpod.serverless.start({"handler": handler})
