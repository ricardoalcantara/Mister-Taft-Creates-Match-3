extends Node2D

export (int) var _width;
export (int) var _height;
export (int) var _x_start;
export (int) var _y_start;
export (int) var _offset;
export (int) var _y_offset;

var possible_pieces = [
preload("res://scenes/YellowPiece.tscn"),
preload("res://scenes/BluePiece.tscn"),
preload("res://scenes/PinkPiece.tscn"),
preload("res://scenes/OrangePiece.tscn"),
preload("res://scenes/GreenPiece.tscn"),
preload("res://scenes/LightGreenPiece.tscn"),
];

onready var destroy_timer = get_parent().get_node("DestroyTimer");
onready var collapse_timer = get_parent().get_node("CollapseTimer");
onready var refill_timer = get_parent().get_node("RefillTimer");

var all_pieces = [];

var first_touch = Vector2();
var final_touch = Vector2();
var controlling = false;

func _ready():
	randomize();
	all_pieces = make_2d_array();
	spawn_pieces();

func make_2d_array():
	var array = [];
	for i in _width:
		array.append([]);
		for j in _height:
			array[i].append(null);
    
	return array;

func spawn_pieces():
	for i in _width:
		for j in _height:
			#var rand = floor(rand_range(0, possible_pieces.size()));
			var rand = randi()%possible_pieces.size();
			var piece = possible_pieces[rand].instance();
			var loop = 0;
			while match_at(i, j, piece._color) and loop < 100:
				# rand = floor(rand_range(0, possible_pieces.size()));
				rand = randi()%possible_pieces.size();
				piece = possible_pieces[rand].instance();
				loop += 1;
				
			add_child(piece);
			piece.position = grid_to_pixel(Vector2(i, j));
			all_pieces[i][j] = piece;

func match_at(column, row, color):
	if column > 1:
		if all_pieces[column - 1][row] != null and all_pieces[column - 2][row] != null:
			if all_pieces[column - 1][row]._color == color and all_pieces[column - 2][row]._color == color:
				return true;
				
	if row > 1:
		if all_pieces[column][row - 1] != null and all_pieces[column][row - 2] != null:
			if all_pieces[column][row - 1]._color == color and all_pieces[column][row - 2]._color == color:
				return true;
				
	return false;

func grid_to_pixel(grid_pos):
	var new_x = _x_start + _offset * grid_pos.x;
	var new_y = _y_start + -_offset * grid_pos.y;
	return Vector2(new_x, new_y);
	
func pixel_to_grid(pixel_pos):
	var new_x = round((pixel_pos.x - _x_start) / _offset);
	var new_y = round((pixel_pos.y - _y_start) / -_offset);
	return Vector2(new_x, new_y);

func is_in_grid(grid_position):
	if grid_position.x >= 0 and grid_position.x < _width:
		if grid_position.y >= 0 and grid_position.y < _height:
			return true;
	return false;

func touch_input():
	if Input.is_action_just_pressed("ui_touch"):
		var mouse_pos = pixel_to_grid(get_global_mouse_position());
		if is_in_grid(mouse_pos):
			first_touch = mouse_pos;
			controlling = true;
			
	if Input.is_action_just_released("ui_touch"):
		var mouse_pos = pixel_to_grid(get_global_mouse_position());
		if is_in_grid(mouse_pos):
			final_touch = mouse_pos;
			touch_difference(first_touch, final_touch);
			controlling = false;

func swap_pieces(column, row, direction):
	var first_piece = all_pieces[column][row];
	var other_piece = all_pieces[column + direction.x][row + direction.y];
	
	if first_piece == null or other_piece == null:
		return;
	
	all_pieces[column][row] = other_piece;
	all_pieces[column + direction.x][row + direction.y] = first_piece;
	first_piece.move(grid_to_pixel(Vector2(column + direction.x, row + direction.y)));
	other_piece.move(grid_to_pixel(Vector2(column, row)));
	find_matches();

func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1;
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1, 0));
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1, 0));
	elif abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, 1));
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, -1));

func find_matches():
	for i in _width:
		for j in _height:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j]._color;
				
				if i > 0 and i < _width - 1:
					if all_pieces[i - 1][j] != null and all_pieces[i + 1][j] != null:
						if all_pieces[i - 1][j]._color == current_color and all_pieces[i + 1][j]._color == current_color:
							all_pieces[i - 1][j].matched = true;
							all_pieces[i][j].matched = true;
							all_pieces[i + 1][j].matched = true;
							
							all_pieces[i - 1][j].dim();
							all_pieces[i][j].dim();
							all_pieces[i + 1][j].dim();
							
				if j > 0 and j < _height - 1:
					if all_pieces[i][j - 1] != null and all_pieces[i][j + 1] != null:
						if all_pieces[i][j - 1]._color == current_color and all_pieces[i][j + 1]._color == current_color:
							all_pieces[i][j - 1].matched = true;
							all_pieces[i][j].matched = true;
							all_pieces[i][j + 1].matched = true;
							
							all_pieces[i][j - 1].dim();
							all_pieces[i][j].dim();
							all_pieces[i][j + 1].dim();
	destroy_timer.start();

func _process(delta):
	touch_input();

func destroy_matched():
	for i in _width:
		for j in _height:
			if all_pieces[i][j] != null and all_pieces[i][j].matched:
				all_pieces[i][j].queue_free();
				all_pieces[i][j] = null;
				pass;
	collapse_timer.start();

func _on_DestroyTimer_timeout():
	destroy_matched();

func collapse_columns():
	for i in _width:
		for j in _height:
			if all_pieces[i][j] == null:
				for k in range(j + 1, _height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(Vector2(i, j)));
						all_pieces[i][j] = all_pieces[i][k];
						all_pieces[i][k] = null;
						break;
#						all_pieces[i][j] = all_pieces[i][k];
#						all_pieces[i][k] = null;
#						all_pieces[i][j].move(grid_to_pixel(Vector2(i, j)));
	refill_timer.start();

func _on_CollapseTimer_timeout():
	collapse_columns();

func refill_columns():
	for i in _width:
		for j in _height:
			if all_pieces[i][j] == null:
				#var rand = floor(rand_range(0, possible_pieces.size()));
				var rand = randi()%possible_pieces.size();
				var piece = possible_pieces[rand].instance();
				var loop = 0;
				while match_at(i, j, piece._color) and loop < 100:
					# rand = floor(rand_range(0, possible_pieces.size()));
					rand = randi()%possible_pieces.size();
					piece = possible_pieces[rand].instance();
					loop += 1;
					
				add_child(piece);
				piece.position = grid_to_pixel(Vector2(i, j - _y_offset));
				piece.move(grid_to_pixel(Vector2(i, j)));
				all_pieces[i][j] = piece;
	find_matches();

func _on_RefillTimer_timeout():
	refill_columns();
