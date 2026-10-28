import zipfile
import re

apk_path = r"C:\Users\Lenovo\.gemini\antigravity-ide\scratch\GCam-iOS\MGC_9.8.102_V0_MGC_gcamapk.io.apk"

with zipfile.ZipFile(apk_path, 'r') as z:
    for dex_name in ["classes.dex", "classes2.dex", "classes3.dex"]:
        data = z.read(dex_name)
        print(f"\n--- {dex_name} ({len(data)} bytes) ---")
        
        # Search for class descriptors: Lcom/...;
        classes = re.findall(b'L([a-zA-Z0-9_/]+);', data)
        bsg_classes = set()
        for c in classes:
            c_str = c.decode('ascii', errors='ignore')
            if any(k in c_str.lower() for k in ["bsg", "mgc", "patcher", "custom", "tonemap", "cct", "color_transform"]):
                bsg_classes.add(c_str)
                
        print(f"Found {len(bsg_classes)} custom/BSG classes:")
        for c in sorted(list(bsg_classes))[:30]:
            print("  ", c)
            
        # Search for method / string references to tone map, color, matrix, contrast
        strings = re.findall(b'[a-zA-Z0-9_]{5,}', data)
        target_strings = set()
        for s in strings:
            s_str = s.decode('ascii', errors='ignore')
            if any(k in s_str.lower() for k in ["tonemap", "libpatcher", "colortransform", "cct_transform", "awb_gain", "hdr_plus_burst", "night_sight"]):
                target_strings.add(s_str)
        print(f"Target strings found ({len(target_strings)}):")
        for s in sorted(list(target_strings))[:30]:
            print("  ", s)
