import zipfile

apk_path = r"C:\Users\Lenovo\.gemini\antigravity-ide\scratch\GCam-iOS\MGC_9.8.102_V0_MGC_gcamapk.io.apk"

with zipfile.ZipFile(apk_path, 'r') as z:
    libs = [n for n in z.namelist() if n.startswith("lib/") and n.endswith(".so")]
    print(f"Total .so libraries: {len(libs)}")
    for l in libs:
        print(l)
