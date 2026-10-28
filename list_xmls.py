import zipfile

apk_path = r"C:\Users\Lenovo\.gemini\antigravity-ide\scratch\GCam-iOS\MGC_9.8.102_V0_MGC_gcamapk.io.apk"

with zipfile.ZipFile(apk_path, 'r') as z:
    xmls = [n for n in z.namelist() if n.startswith("res/xml/") and n.endswith(".xml")]
    print(f"Total res/xml files: {len(xmls)}")
    
    # Filter for settings or preferences
    pref_xmls = [x for x in xmls if any(k in x.lower() for k in ["pref", "setting", "patcher", "camera", "developer", "advanced"])]
    print(f"Preference XMLs: {len(pref_xmls)}")
    for p in pref_xmls:
        print(p)
