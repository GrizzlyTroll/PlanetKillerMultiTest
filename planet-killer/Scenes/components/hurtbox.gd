class_name HurtBox
extends Area2D

signal recevied_damage(damage: int)

@export var health: Health

func _ready():
	connect("area_entered", _on_area_entered)

func _on_area_entered(hitbox: HitBox) -> void:
	if hitbox != null:
		health.health -= hitbox.damage
		recevied_damage.emit(hitbox.damage)
