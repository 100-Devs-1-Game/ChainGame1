extends Area2D

@onready var label: RichTextLabel = %Label

@export var display_time: float = 0.3
@export var readable: bool = false

var display_size: Vector2
var display_position: Vector2

func _ready() -> void:
	display_size = label.size
	display_position = label.position
	label.size = Vector2.ZERO
	label.position = Vector2.ZERO
	label.hide()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		display()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		reset()

func display() -> void:
	label.show()
	var tween = create_tween()
	tween.parallel().tween_property(label, "size", display_size, display_time)
	tween.parallel().tween_property(label, "position", display_position, display_time)
	
func reset() -> void:
	var tween = create_tween()
	tween.parallel().tween_property(label, "size", Vector2.ZERO, display_time)
	tween.parallel().tween_property(label, "position", Vector2.ZERO, display_time)
	tween.tween_callback(label.hide)
