import zipfile
import os

apk_path = r"C:\Users\Lenovo\.gemini\antigravity-ide\scratch\GCam-iOS\MGC_9.8.102_V0_MGC_gcamapk.io.apk"
out_dir = r"C:\Users\Lenovo\.gemini\antigravity-ide\scratch\GCam-iOS\Sources\Assets"
os.makedirs(out_dir, exist_ok=True)

with zipfile.ZipFile(apk_path, 'r') as z:
    all_names = z.namelist()
    
    # Extract key icons from res/drawable-xxxhdpi or res/drawable-xxhdpi
    target_icons = [
        "ram_patcher.png",
        "tonemap.png",
        "shading.png",
        "while_level.png",
        "quantum_gm_ic_settings_white_24.png",
        "quantum_gm_ic_flash_off_white_24.png",
        "quantum_gm_ic_flash_auto_white_24.png",
        "quantum_gm_ic_flash_on_white_24.png",
        "quantum_gm_ic_timer_off_white_24.png",
        "quantum_gm_ic_timer_3_alt_1_white_24.png",
        "quantum_gm_ic_timer_10_alt_1_white_24.png",
        "quantum_ic_aspect_ratio_white_24.png",
        "quantum_ic_DNG_grey_24.png",
        "quantum_ic_camera_switch_white_24.png"
    ]
    
    extracted = 0
    for name in all_names:
        for t in target_icons:
            if name.endswith("/" + t) and "xxxhdpi" in name:
                dest = os.path.join(out_dir, t)
                with open(dest, "wb") as f:
                    f.write(z.read(name))
                print(f"Extracted: {t}")
                extracted += 1
                break
                
    print(f"Total extracted assets: {extracted}")
