extends Node2D

export(String) var _color;
onready var move_tween = $MoveTween;
var matched = false;

func _ready():
	pass

func move(target):
	move_tween.interpolate_property(self, "position", position, target, .3, Tween.TRANS_SINE, Tween.EASE_OUT);
	move_tween.start();
	pass

func dim():
	$Sprite.modulate = Color(1, 1, 1, .5);