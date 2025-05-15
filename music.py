#!/usr/bin/env python3
import os
import subprocess
import shutil
import sys

SOURCE_DIR = os.path.join("assets", "audio", "music")

def convert_wav_to_ogg(wav_path):
    ogg_path = os.path.splitext(wav_path)[0] + ".ogg"
    # if os.path.exists(ogg_path):
    #     print(f"Skipping (already exists): {ogg_path}")
    #     return

    try:
        subprocess.run(
            ["ffmpeg", "-y", "-i", wav_path, "-q:a", "0", ogg_path],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=True
        )
        print(f"Converted: {wav_path} -> {ogg_path}")
    except subprocess.CalledProcessError:
        print(f"ERROR: Failed to convert {wav_path}")

def walk_and_convert(base_dir):
    for root, _, files in os.walk(base_dir):
        for filename in files:
            if filename.lower().endswith(".wav"):
                full_path = os.path.join(root, filename)
                convert_wav_to_ogg(full_path)

if __name__ == "__main__":
    if not shutil.which("ffmpeg"):
        print("ERROR: ffmpeg not found on PATH. Please install it and try again.")
        sys.exit(1)
    walk_and_convert(SOURCE_DIR)
