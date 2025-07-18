import os

def count_lines(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            return len(f.readlines())
    except Exception:
        return 0

def find_lua_files_lines(root_dir):
    file_lines = []
    for subdir, dirs, files in os.walk(root_dir):
        if '.git' in dirs:
            dirs.remove('.git')  # Don't visit .git directories

        for file in files:
            if file.endswith('.lua'):
                filepath = os.path.join(subdir, file)
                lines = count_lines(filepath)
                if lines > 0:
                    file_lines.append((lines, filepath))
    
    file_lines.sort(key=lambda x: x[0], reverse=True)
    
    return file_lines

if __name__ == "__main__":
    workspace_root = '.'
    top_files = find_lua_files_lines(workspace_root)
    
    print("Top 20 .lua files by line count:")
    for i, (lines, filepath) in enumerate(top_files[:20]):
        print(f"{i+1}. {filepath}: {lines} lines") 
