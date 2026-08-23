class_name WorkerSpriteFrames
extends RefCounted

const CELL_SIZE := Vector2(128.0, 160.0)
const DIRECTIONS := [&"s", &"e", &"n", &"w"]

const ANIMATIONS := {
	&"idle": {"first": 0, "count": 1, "fps": 1.0, "loop": false},
	&"walk": {"first": 1, "count": 4, "fps": 8.0, "loop": true},
	&"surprised": {"first": 5, "count": 4, "fps": 8.0, "loop": false},
	&"carry_cross": {"first": 9, "count": 4, "fps": 8.0, "loop": true},
}


static func create(atlas: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")

	for row in DIRECTIONS.size():
		var direction: StringName = DIRECTIONS[row]
		for state: StringName in ANIMATIONS:
			var config: Dictionary = ANIMATIONS[state]
			var animation_name := StringName("%s_%s" % [state, direction])
			frames.add_animation(animation_name)
			frames.set_animation_loop(animation_name, config["loop"])
			frames.set_animation_speed(animation_name, config["fps"])
			for frame_index in config["count"]:
				var atlas_frame := AtlasTexture.new()
				atlas_frame.atlas = atlas
				atlas_frame.region = Rect2(
					Vector2(config["first"] + frame_index, row) * CELL_SIZE,
					CELL_SIZE
				)
				frames.add_frame(animation_name, atlas_frame)

	return frames
