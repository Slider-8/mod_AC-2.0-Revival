"""Cross-check every tamable companion type against vanilla EntityType + Library."""
import re
import os
import glob

REPO = r"C:\Users\igorl\Documents\05_Games_&_Entertainment\Modding\mod_AC"
LIB = os.path.join(REPO, "scripts", "companions", "companions_library.nut")
VAN = os.path.join(REPO, ".refs", "vanilla", "scripts")

src = open(LIB, encoding="utf-8").read()

# TypeList: Name = index
tl_block = src[src.index("TypeList <- {"):]
tl_block = tl_block[:tl_block.index("}")]
typelist = {m.group(1): int(m.group(2))
            for m in re.finditer(r"(\w+)\s*=\s*(\d+)", tl_block)}

# Library entries: Type = TypeList.X  ... MaxPerCompany = N ... Script = "..."
lib_entries = {}
for chunk in re.finditer(r"Type\s*=\s*this\.Const\.Companions\.TypeList\.(\w+)(.*?)(?=Type\s*=\s*this\.Const\.Companions\.TypeList\.|\Z)",
                         src, re.S):
    name = chunk.group(1)
    body = chunk.group(2)
    mx = re.search(r"MaxPerCompany\s*=\s*(\d+)", body)
    sc = re.search(r'Script\s*=\s*"([^"]+)"', body)
    lib_entries[name] = {
        "max": int(mx.group(1)) if mx else None,
        "script": sc.group(1) if sc else None,
    }

# resolveTameType mapping: EntityType -> TypeList
rt = src[src.index("resolveTameType <- function"):]
rt = rt[:rt.index("\n}")]
reachable = set(re.findall(r"return TL\.(\w+)", rt))
entity_types = set(re.findall(r"et == ETC\.(\w+)", rt))

# vanilla EntityType constants actually referenced anywhere in vanilla source
van_text = ""
for p in glob.glob(os.path.join(VAN, "**", "*.nut"), recursive=True):
    try:
        van_text += open(p, encoding="utf-8", errors="replace").read()
    except Exception:
        pass
van_types = set(re.findall(r"EntityType\.(\w+)", van_text))

print("=" * 72)
print("ENTITY TYPES USED BY resolveTameType -> do they exist in vanilla?")
print("=" * 72)
for et in sorted(entity_types):
    print(f"  {'OK  ' if et in van_types else 'MISSING'}  Const.EntityType.{et}")

print()
print("=" * 72)
print("TAMABLE TYPES (reachable from resolveTameType)")
print("=" * 72)
for name in sorted(reachable):
    idx = typelist.get(name, "?")
    e = lib_entries.get(name)
    if e is None:
        print(f"  !! {name:18} idx={idx}  NO LIBRARY ENTRY")
        continue
    ok = "OK " if e["script"] else "!! "
    print(f"  {ok} {name:18} idx={idx:>3}  max={str(e['max']):>3}  script={e['script']}")

print()
print("=" * 72)
print("LIBRARY TYPES NOT REACHABLE BY TAMING (drop/upgrade only -- expected)")
print("=" * 72)
for name in sorted(set(lib_entries) - reachable):
    print(f"     {name:22} idx={typelist.get(name,'?')}")

print()
print("=" * 72)
print("SANITY: Library entry count vs TypeList count")
print("=" * 72)
print(f"  TypeList entries : {len(typelist)}")
print(f"  Library entries  : {len(lib_entries)}")
missing = set(typelist) - set(lib_entries)
if missing:
    print(f"  !! in TypeList but no Library entry: {sorted(missing)}")
