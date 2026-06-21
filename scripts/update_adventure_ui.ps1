from pathlib import Path
base = Path(r"D:\\Got\\GodotSharp\\Program\\??????")
(base / "scripts" / "chapter_node_manager_new.gd").write_text("extends RefCounted\n", encoding="utf-8")
print("ok")
