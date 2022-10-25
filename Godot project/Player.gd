extends KinematicBody

var speed = 7
var slide_speed = 50
const ACCEL_DEFAULT = 7
const DECCEL_DEFAULT = 1
const ACCEL_AIR = 1
const ACCEL_SLIDE = 1
onready var accel = ACCEL_DEFAULT
var gravity = 9.8
var jump = 5
var sliding = false

var cam_accel = 40
var mouse_sense = 0.1
var snap

var direction = Vector3()
var velocity = Vector3()
var gravity_vec = Vector3()
var movement = Vector3()

onready var head = $Head
onready var camera = $Head/Camera

func _ready():
	#hides the cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	#get mouse input for camera rotation
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sense))
		head.rotate_x(deg2rad(-event.relative.y * mouse_sense))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad(89))

func _process(delta):
	#camera physics interpolation to reduce physics jitter on high refresh-rate monitors
	if Engine.get_frames_per_second() > Engine.iterations_per_second:
		camera.set_as_toplevel(true)
		camera.global_transform.origin = camera.global_transform.origin.linear_interpolate(head.global_transform.origin, cam_accel * delta)
		camera.rotation.y = rotation.y
		camera.rotation.x = head.rotation.x
	else:
		camera.set_as_toplevel(false)
		camera.global_transform = head.global_transform
		
func _physics_process(delta):
	#get keyboard input
	var h_rot = global_transform.basis.get_euler().y
	var f_input = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	var h_input = 0
	if not sliding:
		h_input = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	
	#jumping and gravity
	if is_on_floor():
		snap = -get_floor_normal()
		accel = ACCEL_DEFAULT
		gravity_vec = Vector3.ZERO
	else:
		snap = Vector3.DOWN
		accel = ACCEL_AIR
		gravity_vec += Vector3.DOWN * gravity * delta
		
	if Input.is_action_just_pressed("jump") and is_on_floor():
		snap = Vector3.ZERO
		gravity_vec = Vector3.UP * jump
	if Input.is_action_just_released("slide"):
		sliding = false
	if Input.is_action_pressed("slide") and is_on_floor(): 
		snap = Vector3.ZERO
		if sliding == false:
			slide_speed = 50
		sliding = true
		if slide_speed > 0:
			slide_speed -= ACCEL_SLIDE
		
		
	
	#make it move
	direction = Vector3.ZERO
	direction = Vector3(h_input, 0, f_input).rotated(Vector3.UP, h_rot).normalized()
	if sliding:
		direction = Vector3(h_input, 0, -1).rotated(Vector3.UP, h_rot).normalized()
	velocity = velocity.linear_interpolate(direction * speed, accel * delta)
	if sliding:
		velocity = velocity.linear_interpolate(direction * slide_speed, accel * delta)
	movement = velocity + gravity_vec
	print(slide_speed)
	print(speed)
	move_and_slide_with_snap(movement, snap, Vector3.UP)
