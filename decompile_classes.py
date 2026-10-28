import zipfile
import struct

apk_path = r"C:\Users\Lenovo\.gemini\antigravity-ide\scratch\GCam-iOS\MGC_9.8.102_V0_MGC_gcamapk.io.apk"

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

with zipfile.ZipFile(apk_path, 'r') as z:
    dex_data = z.read("classes.dex")
    
    string_ids_size, string_ids_off = struct.unpack_from('<II', dex_data, 0x38)
    string_offsets = [struct.unpack_from('<I', dex_data, string_ids_off + i * 4)[0] for i in range(string_ids_size)]
    
    def get_str(idx):
        if idx >= len(string_offsets): return ""
        off = string_offsets[idx]
        while (dex_data[off] & 0x80) != 0:
            off += 1
        off += 1
        end = dex_data.find(b'\x00', off)
        return dex_data[off:end].decode('utf-8', errors='ignore')

    type_ids_size, type_ids_off = struct.unpack_from('<II', dex_data, 0x40)
    type_strings = [get_str(struct.unpack_from('<I', dex_data, type_ids_off + i * 4)[0]) for i in range(type_ids_size)]
    
    field_ids_size, field_ids_off = struct.unpack_from('<II', dex_data, 0x50)
    # field: class_idx (ushort), type_idx (ushort), name_idx (uint)
    
    method_ids_size, method_ids_off = struct.unpack_from('<II', dex_data, 0x58)
    # method: class_idx (ushort), proto_idx (ushort), name_idx (uint)
    def get_method_name(idx):
        if idx >= method_ids_size: return ""
        m_off = method_ids_off + idx * 8
        c_idx, p_idx, n_idx = struct.unpack_from('<HHI', dex_data, m_off)
        return f"{type_strings[c_idx]}->{get_str(n_idx)}"

    class_defs_size, class_defs_off = struct.unpack_from('<II', dex_data, 0x60)
    for i in range(class_defs_size):
        c_off = class_defs_off + i * 32
        class_idx, access_flags, superclass_idx, interfaces_off, source_file_idx, annotations_off, class_data_off, static_values_off = struct.unpack_from('<IIIIIIII', dex_data, c_off)
        c_name = type_strings[class_idx]
        
        if c_name in ["Lcom/ColorTune;", "Lcom/RamPatcher;"]:
            print(f"\n=================== DECOMPILING STRINGS IN {c_name} ===================")
            off = class_data_off
            static_fields_size, off = read_uleb128(dex_data, off)
            instance_fields_size, off = read_uleb128(dex_data, off)
            direct_methods_size, off = read_uleb128(dex_data, off)
            virtual_methods_size, off = read_uleb128(dex_data, off)
            
            print(f"Counts: static_fields={static_fields_size}, instance_fields={instance_fields_size}, direct_methods={direct_methods_size}, virtual_methods={virtual_methods_size}")
            
            # Skip fields
            for _ in range(static_fields_size + instance_fields_size):
                f_idx_diff, off = read_uleb128(dex_data, off)
                f_flags, off = read_uleb128(dex_data, off)
                
            # Read direct and virtual methods
            for m_idx in range(direct_methods_size + virtual_methods_size):
                m_diff, off = read_uleb128(dex_data, off)
                m_flags, off = read_uleb128(dex_data, off)
                code_off, off = read_uleb128(dex_data, off)
                
                if code_off > 0:
                    registers_size, ins_size, outs_size, tries_size, debug_info_off, insns_size = struct.unpack_from('<HHHHII', dex_data, code_off)
                    insns_bytes = dex_data[code_off + 16 : code_off + 16 + insns_size * 2]
                    
                    # Parse bytecode for const-string (0x1a string_id) and const-string/jumbo (0x1b string_id)
                    b_idx = 0
                    while b_idx < len(insns_bytes) - 1:
                        op = insns_bytes[b_idx]
                        if op == 0x1a: # const-string
                            str_idx = struct.unpack_from('<H', insns_bytes, b_idx + 2)[0]
                            val = get_str(str_idx)
                            if len(val) > 0:
                                print(f"    String: '{val}'")
                            b_idx += 4
                        elif op == 0x1b: # const-string/jumbo
                            str_idx = struct.unpack_from('<I', insns_bytes, b_idx + 2)[0]
                            val = get_str(str_idx)
                            if len(val) > 0:
                                print(f"    String (jumbo): '{val}'")
                            b_idx += 6
                        else:
                            b_idx += 2
