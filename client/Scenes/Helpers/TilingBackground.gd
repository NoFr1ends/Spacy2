extends ParallaxLayer

export(Texture) var texture: Texture = null

func _ready():
	get_tree().root.connect("size_changed", self, "_on_size_changed")
	
	_fill_background()

func _on_size_changed():
	print("size changed ", get_viewport().size)
	
	for child in get_children():
		child.queue_free()
	
	_fill_background()

func _fill_background():
	var size = get_viewport().size * 2
	for x in ceil(size.x / texture.get_width()):
		for y in ceil(size.y / texture.get_height()):
			var sprite = Sprite.new()
			sprite.texture = texture
			sprite.position = Vector2(x, y) * Vector2(texture.get_width(), texture.get_height())
			add_child(sprite)
			
	motion_mirroring = Vector2(ceil(size.x / texture.get_width()) * texture.get_width(), ceil(size.y / texture.get_height()) * texture.get_height())
