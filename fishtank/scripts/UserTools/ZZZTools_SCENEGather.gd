@tool
extends EditorScript
class_name ZTOOL_GatherScenes

## Location for the consolidated output.
const OUTPUT_FILE := "res://ZTOOL_GatherScenes.txt"

## Directory names you don’t want to scan (add more as needed).
const SKIP_DIRS: PackedStringArray = [".godot", ".import", ".tmp", ".git"]  # editor cache / metadata  # import cache


func _run() -> void:
    # Gather every scene’s path + text.
    var lines: Array[String] = []
    _scan_dir("res://", lines)

    # Join the lines and write once.
    var file := FileAccess.open(OUTPUT_FILE, FileAccess.WRITE)
    if file == null:
        push_error(
            (
                "ZTOOL_GatherScenes: cannot open %s (error %d)"
                % [OUTPUT_FILE, FileAccess.get_open_error()]
            )
        )
        return

    file.store_string("\n".join(lines))
    file.close()
    print("ZTOOL_GatherScenes: wrote %d scenes to %s" % [lines.size(), OUTPUT_FILE])


## Recursively walks *dir_path*, appending results into *out_lines*.
func _scan_dir(dir_path: String, out_lines: Array[String]) -> void:
    var dir := DirAccess.open(dir_path)
    if dir == null:
        push_warning("Cannot open directory %s (error %d)" % [dir_path, DirAccess.get_open_error()])
        return

    dir.list_dir_begin()
    while true:
        var entry := dir.get_next()
        if entry == "":
            break  # done

        if entry == "." or entry == "..":
            continue

        var sub_path := dir_path.path_join(entry)
        if dir.current_is_dir():
            # Skip engine / VCS / hidden folders.
            if entry.begins_with(".") or SKIP_DIRS.has(entry):
                continue
            _scan_dir(sub_path, out_lines)  # descend
        else:
            var ext := entry.get_extension().to_lower()
            if ext == "tscn" or ext == "scn":
                out_lines.append("### SCENE: %s" % sub_path)
                if ext == "tscn":
                    var sf := FileAccess.open(sub_path, FileAccess.READ)
                    if sf:
                        out_lines.append(sf.get_as_text())
                        sf.close()
                    else:
                        out_lines.append(
                            "-- could not read (error %d)" % FileAccess.get_open_error()
                        )
                else:
                    # Binary scenes are unreadable textually.
                    out_lines.append("-- binary .scn file (content omitted)")
                out_lines.append("")  # blank separator
    dir.list_dir_end()
