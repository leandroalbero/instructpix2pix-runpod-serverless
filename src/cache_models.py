"""
Fetches and caches the models
"""

import torch
from diffusers import StableDiffusionInstructPix2PixPipeline


def get_models() -> None:
    model_id = "timbrooks/instruct-pix2pix"
    StableDiffusionInstructPix2PixPipeline.from_pretrained(
        model_id, torch_dtype=torch.float16, safety_checker=None
    )


if __name__ == "__main__":
    get_models()
