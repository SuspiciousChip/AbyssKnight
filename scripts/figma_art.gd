extends RefCounted

const ROOT := "res://assets/"

static func manifest() -> Dictionary:
	var path := ROOT + "manifest.json"
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func texture(relative_path: String) -> Texture2D:
	var path := ROOT + relative_path
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func named_texture(key: String) -> Texture2D:
	var data := manifest()
	var textures: Dictionary = data.get("textures", {})
	if not textures.has(key):
		return null
	return texture(str(textures[key]))


static func character_frames(character: String) -> SpriteFrames:
	var data := manifest()
	var characters: Dictionary = data.get("characters", {})
	if not characters.has(character):
		return null
	var entry: Dictionary = characters[character]
	var size: Array = entry.get("cell", [])
	if size.size() != 2:
		return null
	var width: int = int(size[0])
	var height: int = int(size[1])
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var animations: Dictionary = entry.get("animations", {})
	for name in animations:
		var definition: Dictionary = animations[name]
		var strip_texture := texture(str(definition.get("file", "")))
		if strip_texture == null:
			continue
		frames.add_animation(str(name))
		frames.set_animation_speed(str(name), float(definition.get("fps", 6)))
		frames.set_animation_loop(str(name), name == "idle" or name == "run")
		for index in range(int(definition.get("frames", 0))):
			var frame := AtlasTexture.new()
			frame.atlas = strip_texture
			frame.region = Rect2(index * width, 0, width, height)
			frames.add_frame(str(name), frame)
	return frames if frames.has_animation("idle") else null
