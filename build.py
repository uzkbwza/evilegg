#!/usr/bin/env python3
import os
import zipfile
import fnmatch
import shutil
import sys

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
EXCLUDED_PATTERNS = [
    '*.git*',        # Exclude .git and related files
    '*.pyc',         # Exclude Python bytecode
    '__pycache__',   # Exclude Python cache directories
    '*.zip',         # Exclude existing zip files
    'venv*',         # Exclude virtual environments
	# '*.love',
	'*.ase',
    'node_modules*', # Exclude node_modules folder
    '*.exe'          # Exclude .exe files (so we don’t bundle existing ones)
]

LOVE_EXECUTABLE = r"C:\Program Files\LOVE\love.exe"  # Modify this path as needed
LOVE_DLL_DIR = r"C:\Program Files\LOVE"  # Modify if needed
OUTPUT_EXE_NAME = "game.exe"  # Change this to whatever your game is named


def should_exclude(name, excluded_patterns):
    """Check if 'name' matches any exclusion patterns."""
    return any(fnmatch.fnmatch(name, pattern) for pattern in excluded_patterns)


def create_love_file(script_dir):
    """Creates a .love file by zipping the game directory."""
    love_filename = os.path.basename(script_dir) + ".love"
    
    with zipfile.ZipFile(love_filename, 'w', zipfile.ZIP_DEFLATED) as myzip:
        for root, dirs, files in os.walk(script_dir):
            dirs[:] = [d for d in dirs if not should_exclude(d, EXCLUDED_PATTERNS)]
            for file in files:
                if should_exclude(file, EXCLUDED_PATTERNS):
                    continue
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, script_dir)
                myzip.write(full_path, arcname=rel_path)

    print(f"Created .love file: {love_filename}")
    return love_filename


def package_for_windows(love_file):
    """Combines love.exe with the .love file to create a standalone Windows executable."""
    if not os.path.exists(LOVE_EXECUTABLE):
        print(f"Error: LÖVE executable not found at {LOVE_EXECUTABLE}")
        return

    output_dir = os.path.join(os.getcwd(), "game_release")
    os.makedirs(output_dir, exist_ok=True)

    # Create the final game executable
    output_exe = os.path.join(output_dir, OUTPUT_EXE_NAME)
    with open(output_exe, "wb") as out_file:
        with open(LOVE_EXECUTABLE, "rb") as love_exe_file:
            out_file.write(love_exe_file.read())  # Copy love.exe binary
        with open(love_file, "rb") as love_data_file:
            out_file.write(love_data_file.read())  # Append .love data

    print(f"Created standalone game executable: {output_exe}")

    # Copy necessary DLLs
    dll_files = ["lua51.dll", "love.dll", "OpenAL32.dll", "SDL2.dll"]
    for dll in dll_files:
        src_path = os.path.join(LOVE_DLL_DIR, dll)
        dest_path = os.path.join(output_dir, dll)
        if os.path.exists(src_path):
            shutil.copy(src_path, dest_path)
            print(f"Copied {dll} to {output_dir}")
        else:
            print(f"Warning: {dll} not found in {LOVE_DLL_DIR}")

    print("Packaging complete. The 'game_release' folder contains your final game!")


def main():
    """Main function to create a .love file and package the game for Windows."""
    script_path = os.path.realpath(__file__)
    script_dir = os.path.dirname(script_path)
    os.chdir(script_dir)

    love_file = create_love_file(script_dir)

    if sys.platform.startswith("win"):
        package_for_windows(love_file)
    else:
        print(f"On Linux/macOS, you can run the game with: love {love_file}")


if __name__ == "__main__":
    main()
