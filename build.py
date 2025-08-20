#!/usr/bin/env python3
import os
import zipfile
import fnmatch
import shutil
import sys
import subprocess
import music

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
    'build',
    '*.love',
    '*.editorconfig',
    'makelove-build',
    '*.gitignore',
    '*.exe',
	'.dll',
	'*steam_appid.txt',
	'*steam_api64.dll',
	'*luasteam.dll',

    # non build stuff
    '*.ase',
    '*.aseprite',
    'assets/sprite/palette_cycle_test_image.png',
    'assets/sprite/palettized/palette_cycle_test_image.png',
    'tools/is_debug.lua',
	'tools/luasteam',
	'tools/fennel-1.5.0-x86_64',
    'assets/audio/music/*.wav',
    'assets/steam/*',
]

# Convert patterns to always use forward slashes
EXCLUDED_PATTERNS = [p.replace('\\', '/') for p in RAW_EXCLUDED_PATTERNS]

# --- Build Configuration ---
# Modify these paths if they differ on your system.
BUILD_DIR       = "build"
WIN_NODRM_BUILD_DIR = os.path.join(BUILD_DIR, "windows_nodrm")
WIN_STEAM_BUILD_DIR = os.path.join(BUILD_DIR, "windows_steam")
LINUX_BUILD_DIR = os.path.join(BUILD_DIR, "linux")

# For Windows native builds
LOVE_EXECUTABLE_WIN = r"C:\Program Files\LOVE\love.exe"
LOVE_DLL_DIR_WIN    = r"C:\Program Files\LOVE"

# For running Windows builds on Linux (requires Wine)
# You must have a Windows installation of LÖVE accessible from your Linux system.
# Point this to the directory containing love.exe and DLLs.
WIN_LOVE_DIR_ON_LINUX = os.path.expanduser("~/.wine/drive_c/Program Files/LOVE")
WINE_CMD = "wine"

# Common paths
RESOURCE_HACKER_EXE = os.path.join('tools', 'ResourceHacker.exe')
ICON_SOURCE         = os.path.join('assets', 'icon.png')


# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

def should_exclude(rel_path: str) -> bool:
    """Return True if *rel_path* matches an exclusion pattern."""
    # Normalize path separators for matching
    rel_path = rel_path.replace('\\', '/')
    for pattern in EXCLUDED_PATTERNS:
        if fnmatch.fnmatch(rel_path, pattern):
            return True
    return False

def clear_build_folder() -> None:
    """Blasts the entire build folder and recreates it."""
    if os.path.isdir(BUILD_DIR):
        print(f"Removing existing build directory: {BUILD_DIR}")
        shutil.rmtree(BUILD_DIR)
    os.makedirs(BUILD_DIR)
    print(f"Created clean build directory: {BUILD_DIR}")


def create_love_file(project_root: str) -> str:
    """Zip the whole project (minus excludes) into project.love and return its path."""
    love_name = f"{GAME_NAME}.love"
    love_path = os.path.join(project_root, love_name) # Create in root temporarily
    abs_build_dir = os.path.abspath(BUILD_DIR)
    with zipfile.ZipFile(love_path, 'w', zipfile.ZIP_DEFLATED) as z:
        for root, dirs, files in os.walk(project_root):
            # Exclude the build directory itself by checking if the current root
            # is inside the absolute build directory path.
            if root.startswith(abs_build_dir):
                continue

            rel_root = os.path.relpath(root, project_root)
            # Prune sub-dirs that are excluded so os.walk skips them
            dirs[:] = [d for d in dirs if not should_exclude(os.path.join(rel_root, d).replace('\\', '/'))]
            for fname in files:
                # Also exclude the love file itself
                if fname == love_name:
                    continue
                rel_path = os.path.join(rel_root, fname).replace('\\', '/')
                if should_exclude(rel_path):
                    continue
                full_path = os.path.join(root, fname)
                z.write(full_path, arcname=rel_path)
    print(f"Created .love file: {love_path}")
    return love_path


# -----------------------------------------------------------------------------
# Icon helpers
# -----------------------------------------------------------------------------

def _png_to_ico(src: str, dst: str) -> bool:
    """Converts a PNG to a multi-sized ICO file."""
    if not HAVE_PIL:
        print("Warning: Pillow is missing; can't convert PNG→ICO. Skipping icon embedding.")
        return False
    try:
        img = Image.open(src)
        img.save(dst, format='ICO', sizes=[(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)])
        print(f"Converted {src} → {dst}")
        return True
    except Exception as e:
        print(f"Warning: ICO conversion failed: {e}")
        return False

def _reshack_embed_icon(exe: str, ico: str, use_wine: bool = False) -> None:
    """Embeds an icon into an EXE using Resource Hacker."""
    if not os.path.isfile(RESOURCE_HACKER_EXE):
        print(f"Warning: {RESOURCE_HACKER_EXE} not found; skipping icon embedding.")
        return

    temp_exe = exe + '.tmp'

    def _run(mask: str) -> bool:
        # Using absolute paths to be safe
        rh_exe = os.path.abspath(RESOURCE_HACKER_EXE)
        abs_exe = os.path.abspath(exe)
        abs_temp_exe = os.path.abspath(temp_exe)
        abs_ico = os.path.abspath(ico)

        # Construct command as a string, quoting paths
        cmd_str = (
            f'"{rh_exe}" '
            f'-open "{abs_exe}" '
            f'-save "{abs_temp_exe}" '
            f'-action addoverwrite '
            f'-resource "{abs_ico}" '
            f'-mask {mask}'
        )

        if use_wine:
            cmd_str = f'{WINE_CMD} {cmd_str}'

        print('Running:', cmd_str)
        try:
            # When using shell=True, pass the command as a single string.
            result = subprocess.run(
                cmd_str,
                check=True,
                capture_output=True,
                text=True,
                shell=True
            )
            print(result.stdout)
            return True
        except (subprocess.CalledProcessError, FileNotFoundError) as e:
            output = e.stdout or e.stderr or ""
            print(f"ResHacker failed (mask={mask}): {e}\n--- stdout ---\n{e.stdout}\n--- stderr ---\n{e.stderr}")
            return False

    # Try common masks
    success = _run('ICONGROUP,1,') or _run('ICONGROUP,MAINICON,')

    if success and os.path.isfile(temp_exe):
        os.replace(temp_exe, exe)
        print(f"Embedded icon successfully into {exe}")
    else:
        if os.path.exists(temp_exe):
            os.remove(temp_exe)
        print("Warning: Unable to embed icon; continuing without.")


# -----------------------------------------------------------------------------
# Packaging
# -----------------------------------------------------------------------------

def package_for_windows(love_file: str, build_type: str) -> None:
    """Creates a standalone Windows build for a specific distribution type."""
    print(f"\n--- Packaging for Windows ({build_type}) ---")
    is_on_linux = sys.platform.startswith('linux')

    if build_type == 'steam':
        win_build_dir = WIN_STEAM_BUILD_DIR
    else: # nodrm
        win_build_dir = WIN_NODRM_BUILD_DIR

    if is_on_linux:
        love_exe_path = os.path.join(WIN_LOVE_DIR_ON_LINUX, 'love.exe')
        love_dll_dir = WIN_LOVE_DIR_ON_LINUX
        if not os.path.isdir(love_dll_dir):
            print(f"Error: Windows LÖVE directory for Wine not found at '{love_dll_dir}'")
            print("Please install a Windows version of LÖVE and configure WIN_LOVE_DIR_ON_LINUX.")
            return
    else:
        love_exe_path = LOVE_EXECUTABLE_WIN
        love_dll_dir = LOVE_DLL_DIR_WIN

    if not os.path.isfile(love_exe_path):
        print(f"Error: love.exe not found at '{love_exe_path}'")
        return

    os.makedirs(win_build_dir, exist_ok=True)
    out_exe = os.path.join(win_build_dir, f"{GAME_NAME}.exe")

    # Stitch LOVE.exe + game.love
    with open(out_exe, 'wb') as f_out, \
         open(love_exe_path, 'rb') as f_love, \
         open(love_file, 'rb') as f_game:
        f_out.write(f_love.read())
        f_out.write(f_game.read())
    print(f"Created standalone game executable: {out_exe}")

    # Copy DLLs
    dlls_to_copy = ['lua51.dll', 'love.dll', 'OpenAL32.dll', 'SDL3.dll']
    for dll in dlls_to_copy:
        src = os.path.join(love_dll_dir, dll)
        if os.path.isfile(src):
            shutil.copy(src, os.path.join(win_build_dir, dll))
        else:
            print(f"Warning: Missing DLL '{dll}' in '{love_dll_dir}'")

    # If steam build, copy steam files
    if build_type == 'steam':
        steam_files = ['steam_api64.dll', 'luasteam.dll', 'steam_appid.txt']
        for f in steam_files:
            src = os.path.join(os.getcwd(), f)
            if os.path.isfile(src):
                shutil.copy(src, os.path.join(win_build_dir, f))
                print(f"Copied steam file: {f}")
            else:
                print(f"Warning: Missing steam file for build: {f}")

    # Copy license
    license_src = os.path.join(love_dll_dir, 'license.txt')
    if os.path.isfile(license_src):
        shutil.copy(license_src, os.path.join(win_build_dir, 'license.txt'))

    # Handle icon embedding
    if os.path.isfile(ICON_SOURCE):
        temp_ico = os.path.join(BUILD_DIR, '_tmp_icon.ico')
        if _png_to_ico(ICON_SOURCE, temp_ico):
            _reshack_embed_icon(out_exe, temp_ico, use_wine=is_on_linux)
            try:
                os.remove(temp_ico)
            except OSError:
                pass
    else:
        print("Warning: assets/icon.png missing; EXE will keep default icon.")

    print(f"Windows package created in: {win_build_dir}")

def package_for_linux(love_file: str) -> None:
    """Creates a standalone Linux build."""
    print("\n--- Packaging for Linux ---")
    os.makedirs(LINUX_BUILD_DIR, exist_ok=True)
    shutil.copy(love_file, os.path.join(LINUX_BUILD_DIR, os.path.basename(love_file)))
    print(f"Linux package created in: {LINUX_BUILD_DIR}")


def create_final_zips() -> None:
    """Create final zip archives for distribution."""
    print("\n--- Creating Final Archives ---")
    for subdir in os.listdir(BUILD_DIR):
        dir_path = os.path.join(BUILD_DIR, subdir)
        if not os.path.isdir(dir_path):
            continue

        zip_name = f"{GAME_NAME}_{subdir}.zip"
        zip_path = os.path.join(BUILD_DIR, zip_name)

        with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as z:
            for root, _, files in os.walk(dir_path):
                for file in files:
                    full_path = os.path.join(root, file)
                    # Archive name is relative to the directory being zipped
                    arcname = os.path.relpath(full_path, dir_path)
                    if 'nodrm' in subdir:
                        arcname = os.path.join(GAME_NAME, arcname)
                    z.write(full_path, arcname)
        print(f"Created archive: {zip_path}")


# -----------------------------------------------------------------------------
# Entry point
# -----------------------------------------------------------------------------

def main() -> None:
    """Main build orchestrator."""
    args = {arg.lower() for arg in sys.argv[1:]}

    # Determine which builds to run
    build_targets = []
    if 'steam' in args:
        build_targets.append('steam')
    if 'nodrm' in args:
        build_targets.append('nodrm')
    # Default to both if no specific target is given
    if not build_targets:
        build_targets = ['steam', 'nodrm']

    music.go()
    clear_build_folder()
    love_file = create_love_file(os.getcwd())

    # Package for each platform
    if sys.platform == 'win32' or sys.platform == 'cygwin' or sys.platform.startswith('linux'):
        for target in build_targets:
            package_for_windows(love_file, target)

    if sys.platform.startswith('linux'):
        package_for_linux(love_file)

    create_final_zips()

    # Clean up the .love file from the root
    if os.path.exists(love_file):
        os.remove(love_file)
    print("\nBuild complete!")


if __name__ == '__main__':
    main()
