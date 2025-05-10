#!/usr/bin/env python3
import os
import zipfile
import fnmatch
import shutil
import sys

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
    'tools/is_debug.lua'
]

# Convert patterns to always use forward slashes
EXCLUDED_PATTERNS = [p.replace('\\', '/') for p in RAW_EXCLUDED_PATTERNS]

LOVE_EXECUTABLE = r"C:\Program Files\LOVE\love.exe"  # Modify as needed
LOVE_DLL_DIR = r"C:\Program Files\LOVE"              # Modify if needed
OUTPUT_EXE_NAME = f"{GAME_NAME}.exe"                         # Final game EXE name
OUTPUT_DIR = "build"                                 # Output folder name
ZIP_NAME = f"{GAME_NAME}.zip"                        # Final ZIP file name

# If you want to copy the license from LOVE's DLL folder:
LICENSE_FILE = os.path.join(LOVE_DLL_DIR, "license.txt")


def should_exclude(rel_path: str) -> bool:
    """
    Checks if the given relative path (always using forward slashes)
    matches any exclusion pattern.
    """
    # For each pattern in EXCLUDED_PATTERNS, check if there's a match.
    for pattern in EXCLUDED_PATTERNS:
        if fnmatch.fnmatch(rel_path, pattern):
            print(f"excluding {rel_path} because of {pattern}")
            return True
    return False


def clear_build_folder():
    """Deletes all contents of the build folder but keeps the folder itself."""
    if os.path.exists(OUTPUT_DIR):
        for item in os.listdir(OUTPUT_DIR):
            item_path = os.path.join(OUTPUT_DIR, item)
            if os.path.isfile(item_path) or os.path.islink(item_path):
                os.unlink(item_path)
            elif os.path.isdir(item_path):
                shutil.rmtree(item_path)
        print(f"Cleared all contents inside '{OUTPUT_DIR}'.")
    else:
        os.makedirs(OUTPUT_DIR)


def create_love_file(script_dir: str) -> str:
    love_filename = os.path.basename(script_dir) + ".love"

    with zipfile.ZipFile(love_filename, 'w', zipfile.ZIP_DEFLATED) as myzip:
        for root, dirs, files in os.walk(script_dir):
            # Compute the relative path and normalize to forward slashes
            root_rel = os.path.relpath(root, script_dir).replace('\\', '/')

            # Absolute skip: if this directory itself is excluded, skip its children
            if should_exclude(root_rel) and root_rel != ".":
                dirs[:] = []
                continue

            # Filter subdirectories so os.walk won't descend into excluded ones
            dirs[:] = [
                d for d in dirs
                if not should_exclude(f"{root_rel}/{d}" if root_rel != "." else d)
            ]

            for f in files:
                rel_path = f if root_rel in ('.', '') else f"{root_rel}/{f}"
                if should_exclude(rel_path):
                    continue
                full_path = os.path.join(root, f)
                myzip.write(full_path, arcname=rel_path)

    print(f"Created .love file: {love_filename}")
    return love_filename


def package_for_windows(love_file: str):
    """Combines love.exe with the .love file and copies necessary DLLs."""
    if not os.path.exists(LOVE_EXECUTABLE):
        print(f"Error: LÖVE executable not found at {LOVE_EXECUTABLE}")
        return

    clear_build_folder()

    output_exe = os.path.join(OUTPUT_DIR, OUTPUT_EXE_NAME)

    # Merge love.exe + .love into one executable
    with open(output_exe, "wb") as out_file:
        with open(LOVE_EXECUTABLE, "rb") as love_exe_file:
            out_file.write(love_exe_file.read())
        with open(love_file, "rb") as love_data_file:
            out_file.write(love_data_file.read())

    print(f"Created standalone game executable: {output_exe}")

    # Copy necessary LÖVE DLLs (using SDL3, not SDL2)
    dll_files = ["lua51.dll", "love.dll", "OpenAL32.dll", "SDL3.dll"]
    for dll in dll_files:
        src_path = os.path.join(LOVE_DLL_DIR, dll)
        dest_path = os.path.join(OUTPUT_DIR, dll)
        if os.path.exists(src_path):
            shutil.copy(src_path, dest_path)
            print(f"Copied {dll} to {OUTPUT_DIR}")
        else:
            print(f"Warning: {dll} not found in {LOVE_DLL_DIR}")

    # Optional: copy license.txt from the DLL folder
    if os.path.exists(LICENSE_FILE):
        shutil.copy(LICENSE_FILE, os.path.join(OUTPUT_DIR, "license.txt"))
        print(f"Copied license.txt from {LOVE_DLL_DIR} to {OUTPUT_DIR}")
    else:
        print(f"Warning: license.txt not found in {LOVE_DLL_DIR}!")

    print(f"Packaging complete! The final game is in the '{OUTPUT_DIR}' folder.")


# def create_zip():
#     """
#     Creates a ZIP archive of the build folder, placing it in build/,
#     and renaming the internal folder to GAME_NAME.
#     """
#     zip_path = os.path.join(OUTPUT_DIR, ZIP_NAME)

#     with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
#         for root, _, files in os.walk(OUTPUT_DIR):
#             root_rel = os.path.relpath(root, OUTPUT_DIR).replace('\\', '/')
#             for file in files:
#                 # Don't include the ZIP itself in the ZIP
#                 if file == ZIP_NAME:
#                     continue

#                 if root_rel in ('.', ''):
#                     archive_path = f"{GAME_NAME}/{file}"
#                 else:
#                     archive_path = f"{GAME_NAME}/{root_rel}/{file}"

#                 full_path = os.path.join(root, file)
#                 zipf.write(full_path, arcname=archive_path)

#     print(f"Created final ZIP archive: {zip_path}")

def create_zip():
    """
    Creates build/Evil Egg.zip with no extra top-level folder.
    Whatever sits in build/ ends up at the root of the archive,
    while any sub-directories inside build/ are preserved.
    """
    zip_path = os.path.join(OUTPUT_DIR, ZIP_NAME)

    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, _, files in os.walk(OUTPUT_DIR):
            root_rel = os.path.relpath(root, OUTPUT_DIR).replace('\\', '/')

            for file in files:
                # Skip the ZIP we’re currently writing
                if file == ZIP_NAME:
                    continue

                full_path = os.path.join(root, file)

                # Put everything at the archive’s root, preserving any sub-dirs
                archive_path = (
                    file if root_rel in ('.', '')
                    else f"{root_rel}/{file}"
                )

                zipf.write(full_path, arcname=archive_path)

    print(f"Created final ZIP archive: {zip_path}")

def main():
    script_path = os.path.realpath(__file__)
    script_dir = os.path.dirname(script_path)
    os.chdir(script_dir)

    # 1. Create the .love file from the project folder
    love_file = create_love_file(script_dir)

    # 2. On Windows, merge the .love with love.exe & gather DLLs
    if sys.platform.startswith("win"):
        package_for_windows(love_file)
        create_zip()
    else:
        print(f"On Linux/macOS, you can run the game with: love {love_file}")


if __name__ == "__main__":
    main()
