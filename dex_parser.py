import zipfile
import struct

apk_path = r"C:\Users\Lenovo\.gemini\antigravity-ide\scratch\GCam-iOS\MGC_9.8.102_V0_MGC_gcamapk.io.apk"

def parse_dex_for_class(dex_data, class_names):
    # Search for strings in DEX
    string_ids_size, string_ids_off = struct.unpack_from('<II', dex_data, 0x38)
    print(f"string_ids_size: {string_ids_size}")
    
    # Read string offsets
    string_offsets = []
    for i in range(min(string_ids_size, 200000)):
        off = struct.unpack_from('<I', dex_data, string_ids_off + i * 4)[0]
        string_offsets.append(off)
        
    def read_uleb128(data, off):
        result = 0
        shift = 0
        while True:
            byte = data[off]
            off += 1
            result |= (byte & 0x7f) << shift
            if (byte & 0x80) == 0:
                break
            shift += 7
        return result, off

    dex_strings = []
    for off in string_offsets:
        utf16_len, str_start = read_uleb128(dex_data, off)
        # read null-terminated MUTF-8
        end = dex_data.find(b'\x00', str_start)
        if end != -1:
            try:
                dex_strings.append(dex_data[str_start:end].decode('utf-8', errors='ignore'))
            except:
                dex_strings.append("")
        else:
            dex_strings.append("")
            
    print(f"Extracted {len(dex_strings)} strings from DEX")
    
    # Filter strings related to ColorTune, RamPatcher, and CCT
    related = [s for s in dex_strings if any(k in s.lower() for k in ["colortune", "rampatcher", "cct", "sharpness", "tonemap", "saturation", "contrast", "shadow", "gain"])]
    return related

with zipfile.ZipFile(apk_path, 'r') as z:
    for dex_name in ["classes.dex", "classes2.dex"]:
        data = z.read(dex_name)
        print(f"\n=================== DEX STRINGS FOR {dex_name} ===================")
        rel = parse_dex_for_class(data, ["ColorTune", "RamPatcher"])
        print(f"Found {len(rel)} related tuning strings:")
        for r in rel[:100]:
            print("  ", r)
