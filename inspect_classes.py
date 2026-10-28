import zipfile
import struct

apk_path = r"C:\Users\Lenovo\.gemini\antigravity-ide\scratch\GCam-iOS\MGC_9.8.102_V0_MGC_gcamapk.io.apk"

def inspect_class_data(dex_data, class_descriptor):
    # Header fields
    string_ids_size, string_ids_off = struct.unpack_from('<II', dex_data, 0x38)
    type_ids_size, type_ids_off = struct.unpack_from('<II', dex_data, 0x40)
    class_defs_size, class_defs_off = struct.unpack_from('<II', dex_data, 0x60)
    
    # Read string offsets
    string_offsets = [struct.unpack_from('<I', dex_data, string_ids_off + i * 4)[0] for i in range(string_ids_size)]
    
    def get_str(idx):
        if idx >= len(string_offsets): return ""
        off = string_offsets[idx]
        # skip uleb128 length
        while (dex_data[off] & 0x80) != 0:
            off += 1
        off += 1
        end = dex_data.find(b'\x00', off)
        return dex_data[off:end].decode('utf-8', errors='ignore')

    type_strings = []
    for i in range(type_ids_size):
        str_idx = struct.unpack_from('<I', dex_data, type_ids_off + i * 4)[0]
        type_strings.append(get_str(str_idx))

    print(f"Total class defs: {class_defs_size}")
    
    for i in range(class_defs_size):
        c_off = class_defs_off + i * 32
        class_idx, access_flags, superclass_idx, interfaces_off, source_file_idx, annotations_off, class_data_off, static_values_off = struct.unpack_from('<IIIIIIII', dex_data, c_off)
        c_name = type_strings[class_idx]
        
        if class_descriptor.lower() in c_name.lower():
            print(f"\n>>> FOUND CLASS: {c_name} (class_data_off: {class_data_off}, static_values_off: {static_values_off})")
            
            # Print nearby text / strings in dex_data
            if class_data_off > 0 and class_data_off < len(dex_data):
                chunk = dex_data[class_data_off:class_data_off + 1500]
                # print any ASCII strings in chunk
                import re
                words = re.findall(b'[a-zA-Z0-9_.$\\-+=:;]{3,}', chunk)
                print("Class data chunk words:", [w.decode('ascii', errors='ignore') for w in words])

with zipfile.ZipFile(apk_path, 'r') as z:
    for dex_name in ["classes.dex", "classes2.dex"]:
        data = z.read(dex_name)
        print(f"\n*** SEARCHING {dex_name} ***")
        inspect_class_data(data, "ColorTune")
        inspect_class_data(data, "RamPatcher")
