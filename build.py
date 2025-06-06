#!/usr/bin/env python3
import os
import zipfile
import fnmatch
import shutil
import sys
import subprocess

# Try to import Pillow for PNG→ICO conversion; it's optional.
try:
    from PIL import Image  # type: ignore
    HAVE_PIL = True
except ImportError:
    HAVE_PIL = False

GAME_NAME = "Evil Egg"

# -----------------------------------------------------------------------------
# Custom Exclusion Patterns
# Use forward slashes in patterns (like "tools/is_debug.lua").
# -----------------------------------------------------------------------------
RAW_EXCLUDED_PATTERNS = [
    '*.git*', 
	'*.pyc', 
	'__pycache__', 
	'*.zip', 
	'venv*', 
	'*.love', 
	'*.ase',
    'build', 
	'*.editorconfig', 
	'makelove-build', 
	'*.aseprite', 
	'*.gitignore',
    'node_modules*', 
	'palette_cycle_test_image.png', 
	'*.exe', 
	'tools/is_debug.lua',
    'assets/audio/music/*.wav', 
	'assets/steam/*',
]

# Convert patterns to always use forward slashes
EXCLUDED_PATTERNS = [p.replace('\\', '/') for p in RAW_EXCLUDED_PATTERNS]

LOVE_EXECUTABLE = r"C:\\Program Files\\LOVE\\love.exe"  # Modify as needed
LOVE_DLL_DIR    = r"C:\\Program Files\\LOVE"              # Modify if needed
OUTPUT_EXE_NAME = f"{GAME_NAME}.exe"                         # Final game EXE name
OUTPUT_DIR      = "build"                                   # Output folder name
ZIP_NAME        = f"{GAME_NAME}.zip"                        # Final ZIP file name

# Icon + ResourceHacker paths
ICON_SOURCE     = os.path.join('assets', 'icon.png')
RESOURCE_HACKER = os.path.join('tools', 'ResourceHacker.exe')
LICENSE_FILE    = os.path.join(LOVE_DLL_DIR, 'license.txt')

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

def should_exclude(rel_path: str) -> bool:
    """Return True if *rel_path* matches an exclusion pattern."""
    for pattern in EXCLUDED_PATTERNS:
        if fnmatch.fnmatch(rel_path, pattern):
            print(f"Excluding {rel_path} because of {pattern}")
            return True
        # Handle directory patterns like "assets/steam/*"
        parts = rel_path.split('/')
        for i in range(1, len(parts)):
            partial = '/'.join(parts[:i]) + '/*'
            if partial in EXCLUDED_PATTERNS and fnmatch.fnmatch(rel_path, partial):
                print(f"Excluding {rel_path} because of {partial}")
                return True
    return False


def clear_build_folder() -> None:
    """Blasts everything inside *build/* while keeping the folder itself."""
    if os.path.isdir(OUTPUT_DIR):
        for entry in os.listdir(OUTPUT_DIR):
            p = os.path.join(OUTPUT_DIR, entry)
            if os.path.isfile(p) or os.path.islink(p):
                os.unlink(p)
            else:
                shutil.rmtree(p)
        print(f"Cleared all contents inside '{OUTPUT_DIR}'.")
    else:
        os.makedirs(OUTPUT_DIR)


def create_love_file(project_root: str) -> str:
    """Zip the whole project (minus excludes) into project.love and return its path."""
    love_name = f"{GAME_NAME}.love"
    with zipfile.ZipFile(love_name, 'w', zipfile.ZIP_DEFLATED) as z:
        for root, dirs, files in os.walk(project_root):
            rel_root = os.path.relpath(root, project_root).replace('\\', '/')
            # Early-out if the whole dir is excluded
            if rel_root != '.' and should_exclude(rel_root):
                dirs[:] = []
                continue
            # Prune sub-dirs that are excluded so os.walk skips them
            dirs[:] = [d for d in dirs if not should_exclude(f"{rel_root}/{d}" if rel_root != '.' else d)]
            for fname in files:
                rel_path = fname if rel_root in ('.', '') else f"{rel_root}/{fname}"
                if should_exclude(rel_path):
                    continue
                z.write(os.path.join(root, fname), arcname=rel_path)
    print(f"Created .love file: {love_name}")
    return love_name


# -----------------------------------------------------------------------------
# Icon helpers
# -----------

def _png_to_ico(src: str, dst: str) -> bool:
    if not HAVE_PIL:
        print("Warning: Pillow is missing; can't convert PNG→ICO. Skipping icon embedding.")
        return False
    try:
        img = Image.open(src)
        img.save(dst, format='ICO', sizes=[(256,256),(128,128),(64,64),(48,48),(32,32),(16,16)])
        print(f"Converted {src} → {dst}")
        return True
    except Exception as e:
        print(f"Warning: ICO conversion failed: {e}")
        return False


def _reshack_embed_icon(exe: str, ico: str) -> None:
    if not os.path.isfile(RESOURCE_HACKER):
        print(f"Warning: {RESOURCE_HACKER} not found; skipping icon embedding.")
        return

    # ResHacker can't overwrite in-place; write to temp then replace.
    temp_exe = exe + '.tmp'

    def _run(mask: str) -> bool:
        cmd = [
            RESOURCE_HACKER,
            '-open', exe,
            '-save', temp_exe,
            '-action', 'addoverwrite',
            '-resource', ico,  # "-resource" works for all new versions; "-res" is legacy
            '-mask', mask,
        ]
        print('Running:', ' '.join(cmd))
        try:
            result = subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            print(result.stdout)
            return True
        except subprocess.CalledProcessError as e:
            print(f"ResHacker failed (mask={mask}):", e.stdout or e)
            return False

    # Try the two most common masks: (ICONGROUP,1,0) then (ICONGROUP,MAINICON,)
    success = _run('ICONGROUP,1,') or _run('ICONGROUP,MAINICON,')

    if success and os.path.isfile(temp_exe):
        os.replace(temp_exe, exe)
        print(f"Embedded icon successfully into {exe}")
    else:
        if os.path.exists(temp_exe):
            os.remove(temp_exe)
        print("Warning: Unable to embed icon after both attempts; continuing without icon.")

# -----------------------------------------------------------------------------
# Packaging (Windows)
# -----------------------------------------------------------------------------

def package_for_windows(love_file: str) -> None:
    if not os.path.isfile(LOVE_EXECUTABLE):
        print(f"Error: LOVE.exe not found at {LOVE_EXECUTABLE}")
        return

    clear_build_folder()

    # Copy .love file to build folder
    build_love = os.path.join(OUTPUT_DIR, os.path.basename(love_file))
    shutil.copy(love_file, build_love)
    print(f"Copied {love_file} → build/")

    out_exe = os.path.join(OUTPUT_DIR, OUTPUT_EXE_NAME)

    # Stitch LOVE.exe + game.love
    with open(out_exe, 'wb') as f_out, open(LOVE_EXECUTABLE, 'rb') as f_love, open(love_file, 'rb') as f_game:
        f_out.write(f_love.read())
        f_out.write(f_game.read())
    print(f"Created standalone game executable: {out_exe}")

    # Copy DLLs
    for dll in ('lua51.dll', 'love.dll', 'OpenAL32.dll', 'SDL3.dll'):
        src = os.path.join(LOVE_DLL_DIR, dll)
        dst = os.path.join(OUTPUT_DIR, dll)
        if os.path.isfile(src):
            shutil.copy(src, dst)
            print(f"Copied {dll} → build/")
        else:
            print(f"Warning: {dll} missing in LOVE directory")

    # Copy license (optional)
    if os.path.isfile(LICENSE_FILE):
        shutil.copy(LICENSE_FILE, os.path.join(OUTPUT_DIR, 'license.txt'))
        print("Copied license.txt → build/")

    # Handle icon embedding
    temp_ico = os.path.join(OUTPUT_DIR, '_tmp_icon.ico')
    if os.path.isfile(ICON_SOURCE) and _png_to_ico(ICON_SOURCE, temp_ico):
        _reshack_embed_icon(out_exe, temp_ico)
        try:
            os.remove(temp_ico)
        except OSError:
            pass
    else:
        print("Warning: assets/icon.png missing; EXE will keep default icon.")

    print("Packaging complete! Find your goodies in the 'build' folder.")

# -----------------------------------------------------------------------------
# ZIP helper
# -----------------------------------------------------------------------------

def create_zip() -> None:
    zip_path = os.path.join(OUTPUT_DIR, ZIP_NAME)
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as z:
        for root, _, files in os.walk(OUTPUT_DIR):
            rel_root = os.path.relpath(root, OUTPUT_DIR).replace('\\', '/')
            for fname in files:
                if fname == ZIP_NAME or fname.endswith('.love'):
                    continue  # don't zip the zip or .love files
                arcname = fname if rel_root in ('.', '') else f"{rel_root}/{fname}"
                z.write(os.path.join(root, fname), arcname=arcname)
    print(f"Created final ZIP archive: {zip_path}")

# -----------------------------------------------------------------------------
# Entry point
# -----------------------------------------------------------------------------

def main() -> None:
    project_root = os.path.dirname(os.path.realpath(__file__))
    os.chdir(project_root)

    love_file = create_love_file(project_root)

    if sys.platform.startswith('win'):
        package_for_windows(love_file)
        create_zip()
    else:
        print(f"On Linux/macOS, run with: love {love_file}")

if __name__ == '__main__':
    main()
