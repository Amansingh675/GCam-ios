import zipfile
import re

apk_path = r"C:\Users\Lenovo\.gemini\antigravity-ide\scratch\GCam-iOS\MGC_9.8.102_V0_MGC_gcamapk.io.apk"

with zipfile.ZipFile(apk_path, 'r') as z:
    for dex_name in ["classes.dex", "classes2.dex"]:
        data = z.read(dex_name)
        
        # Look for strings associated with com/RamPatcher and bsg
        # Find all strings around "SECTION_TONEMAP" or "RamPatcher"
        print(f"\n==================== INSPECTING {dex_name} ====================")
        
        for keyword in [b'SECTION_TONEMAP', b'com/RamPatcher', b'pref_satCCT', b'TONEMAP_GAMMA', b'TONEMAP_CURVE']:
            idx = 0
            while True:
                pos = data.find(keyword, idx)
                if pos == -1:
                    break
                start = max(0, pos - 200)
                end = min(len(data), pos + 400)
                snippet = data[start:end]
                # extract printable strings in this snippet
                printable = re.findall(b'[a-zA-Z0-9_./\\-+=:;]{3,}', snippet)
                print(f"\n[Match for {keyword.decode()} at offset {pos}]:")
                print("  " + " | ".join([p.decode('ascii', errors='ignore') for p in printable]))
                idx = pos + len(keyword) + 10
                if idx - pos > 10000: # limit to first 3 matches
                    break
