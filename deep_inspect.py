import zipfile
import re

apk_path = r"C:\Users\Lenovo\.gemini\antigravity-ide\scratch\GCam-iOS\MGC_9.8.102_V0_MGC_gcamapk.io.apk"

with zipfile.ZipFile(apk_path, 'r') as z:
    all_names = z.namelist()
    
    # 1. Native libs
    libs = [n for n in all_names if n.startswith("lib/")]
    print(f"--- NATIVE LIBRARIES ({len(libs)}) ---")
    for l in libs:
        print(l)
        
    # 2. XML resources (especially settings/preferences)
    xmls = [n for n in all_names if n.startswith("res/xml")]
    print(f"\n--- RES/XML ({len(xmls)}) ---")
    for x in xmls[:50]:
        print(x)
        
    # 3. Check for BSG / MGC custom files
    bsg_files = [n for n in all_names if any(w in n.lower() for w in ["bsg", "mgc", "patcher", "tuning", "raw", "color_transform"])]
    print(f"\n--- BSG / MGC / TUNING FILES ({len(bsg_files)}) ---")
    for b in bsg_files:
        print(b)
