class_name PickupMagnet
extends Area2D

## Attracts nearby pickups toward the parent entity. Attach to the player bed.
## Radius is driven by GameManager.player_stats.pickup_radius.

@export var attract_speed: float = 400.0
@export var collect_distance: float = 20.0

signal pickup_collected(pickup: Node2D)

var _attracting: Array[Node2D] = []


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _physics_process(delta: float) -> void:
	var parent_pos := global_position
	for i in range(_attracting.size() - 1, -1, -1):
		var pickup := _attracting[i]
		if not is_instance_valid(pickup):
			_attracting.remove_at(i)
			continue
		var direction := (parent_pos - pickup.global_position).normalized()
		pickup.global_position += direction * attract_speed * delta
		if pickup.global_position.distance_to(parent_pos) < collect_distance:
			pickup_collected.emit(pickup)
			_attracting.remove_at(i)


func update_radius(new_radius: float) -> void:
	var shape := collision_shape
	if shape and shape.shape is CircleShape2D:
		(shape.shape as CircleShape2D).radius = new_radius


@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")


func _on_area_entered(area: Area2D) -> void:
	var parent_node := area.get_parent()
	if parent_node and parent_node.is_in_group("pickup"):
		_attracting.append(parent_node)


func _on_area_exited(area: Area2D) -> void:
	var parent_node := area.get_parent()
	if parent_node in _attracting:
		_attracting.erase(parent_node)
