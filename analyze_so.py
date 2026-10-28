import zipfile
import re

apk_path = r"C:\Users\Lenovo\.gemini\antigravity-ide\scratch\GCam-iOS\MGC_9.8.102_V0_MGC_gcamapk.io.apk"

with zipfile.ZipFile(apk_path, 'r') as z:
    for lib_target in ["lib/arm64-v8a/liboliveoil.so", "lib/arm64-v8a/libimage.so"]:
        print(f"\n=================== ANALYZING {lib_target} ===================")
        data = z.read(lib_target)
        print(f"Size: {len(data)} bytes ({len(data)/(1024*1024):.2f} MB)")
        
        # Search for interesting strings
        keywords = ["tonemap", "hdr", "exposure", "white_balance", "matrix", "ccm", "color_transform", "sharp", "denoise", "fusion", "merge", "burst", "curve", "spline", "black_level", "contrast", "shadow"]
        
        # Extract ASCII strings of length >= 4
        strings = re.findall(b'[a-zA-Z0-9_/.-]{4,}', data)
        found = set()
        for s in strings:
            try:
                decoded = s.decode('ascii')
                if any(k in decoded.lower() for k in keywords):
                    found.add(decoded)
            except:
                pass
                
        print(f"Found {len(found)} matching symbol/parameter strings")
        for item in sorted(list(found))[:80]:
            print("  ", item)
