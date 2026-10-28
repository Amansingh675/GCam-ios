import zipfile
import json
import os
import re

apk_path = r"C:\Users\Lenovo\.gemini\antigravity-ide\scratch\GCam-iOS\MGC_9.8.102_V0_MGC_gcamapk.io.apk"

with zipfile.ZipFile(apk_path, 'r') as z:
    all_names = z.namelist()
    print(f"Total files in APK: {len(all_names)}")
    
    keywords = ["tuning", "color", "tone", "lut", "matrix", "hdr", "awb", "patcher", "curve", "config", "camera_config", "gcam", "settings", "profile"]
    matched = [n for n in all_names if any(k in n.lower() for k in keywords)]
    print(f"Matched keyword files: {len(matched)}")
    
    print("\n--- SAMPLE ASSETS & TUNING FILES ---")
    for name in matched[:80]:
        print(name)

    # Check for specific asset directories
    assets = [n for n in all_names if n.startswith("assets/")]
    print(f"\nTotal assets/: {len(assets)}")
    for a in assets[:50]:
        print(a)
