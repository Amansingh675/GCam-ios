import zipfile
import re

apk_path = r"C:\Users\Lenovo\.gemini\antigravity-ide\scratch\GCam-iOS\MGC_9.8.102_V0_MGC_gcamapk.io.apk"

with zipfile.ZipFile(apk_path, 'r') as z:
    # 1. Read GLSL preview shaders
    for shader_name in ["res/raw/preview_frag.glsl", "res/raw/serengeti_preview_frag.glsl"]:
        if shader_name in z.namelist():
            print(f"=== {shader_name} ===")
            content = z.read(shader_name).decode('utf-8', errors='ignore')
            print(content[:1000])
            print("\n")

    # 2. Search for libpatcher / tuning keys in classes.dex or classes*.dex
    dex_files = [n for n in z.namelist() if n.endswith(".dex")]
    print(f"Found {len(dex_files)} DEX files: {dex_files}")
    
    # Check strings in dex files for BSG settings keys
    keys = ["tonemap", "gamma", "sharpness", "saturation", "contrast", "dehaze", "noise", "shading", "cct", "awb", "patcher", "black_level", "white_level"]
    found_keys = set()
    
    for dex in dex_files:
        data = z.read(dex)
        # Find printable ASCII strings
        # Look for strings containing 'pref_' or 'key_' or 'bsg_' or related to tuning
        matches = re.findall(b'pref_[a-zA-Z0-9_]+', data)
        for m in matches:
            s = m.decode('ascii', errors='ignore')
            if any(k in s.lower() for k in keys):
                found_keys.add(s)
                
    print(f"\n=== FOUND GCam / BSG PREFERENCE KEYS ({len(found_keys)}) ===")
    for k in sorted(list(found_keys))[:60]:
        print(k)
