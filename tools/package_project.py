#!/usr/bin/env python3
"""Make a ZIP Godot Project Manager can extract, with explicit folder records."""
from pathlib import Path
import sys
import zipfile

root = Path(__file__).resolve().parents[1]
output = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else root.parent / 'Ira-Panda-Godot.zip'
files = sorted(f for f in root.rglob('*') if f.is_file()
               and not any(p in {'.git', '.godot', '__pycache__'} for p in f.relative_to(root).parts)
               and f.suffix not in {'.import', '.zip', '.pyc'} and f != output)
folders = set()
for file in files:
    parent = file.relative_to(root).parent
    while parent != Path('.'):
        folders.add(parent.as_posix() + '/')
        parent = parent.parent

def entry(name, directory=False):
    info = zipfile.ZipInfo(name, date_time=(2026, 10, 9, 12, 0, 0))
    info.create_system = 0
    info.external_attr = 0x10 if directory else 0x20
    info.compress_type = zipfile.ZIP_STORED if directory else zipfile.ZIP_DEFLATED
    return info

with zipfile.ZipFile(output, 'w') as archive:
    for name in sorted(folders, key=lambda name: (name.count('/'), name)):
        archive.writestr(entry(name, True), b'')
    for file in files:
        archive.writestr(entry(file.relative_to(root).as_posix()), file.read_bytes())
with zipfile.ZipFile(output) as archive:
    assert archive.testzip() is None
    assert 'project.godot' in archive.namelist()
    assert all(folder in archive.namelist() for folder in folders)
print(f'Created {output.name}: {len(files)} files, {len(folders)} explicit folders')
