class_name Single_Script_Finite_State_Machine extends  Node
"""
This is designed to be a light-weight state machine contained in a single script. 
"Oops, it's all Strings."

Capable of handling multiple parallel states through the use of Dictionaries. 
It constructs the dictionaries itself at runtime from the Atomic States dictionary editable in the Inspector.
They Keys of the Dictionary become the Atomic State's name, and the Values of the Dictionary become which Compound State they belong to.
(Compound States are the categories that Atomic States belong to. eg. The 'Walking' Atomic state could belong to the 'Movement' Compound State.)

While being light-weight and versatile, it does not provide much type-safety, as all Compound and Atomic states are Strings,
and State Changes require the use of Strings as well as checking states.
To remedy this as best as possible, multiple debug messages have been included where possible to warn of incorrect strings and potentially help find typos.
"""

##The Node this State Machine contains state's for.
@export var parent : Node
##The Key of the dictionary is the Atomic State name. The Value is the Compound State it belongs to. [br]All Atomic states must have unique names.[br]
##If only one Atomic State is assigned to a Compound State, the Compound State will automaically create a second state labeled 
## "Not" + the Atomic State's name.[br](ie. singular Atomic State "Running" in Compound State "Movement" will also have "NotRunning" added to "Movement")[br]
##The inital state of the Compound State will be the first Atomic State declared, or the "Not" value in the case
##of singlular states.[br]
##Inital states are emitted from state_entered once current_state_setup() is complete.
@export var atomic_states : Dictionary[String, String] = {}
##Prefer to leave this off. When on, it emits the current Atomic state of every Compound state every physics frame. Use get_current_state() where possible instead.
@export var physics_process_signal_needed : bool
##Prefer to leave this off. When on, it emits the current Atomic state of every Compound state every frame. Use get_current_state() where possible instead.
@export var process_signal_needed: bool
##When enabled, you must provide the name of your signal buss Autoload script. [br]	Project -> Project Settings -> Globals -> Autoloads. [br]	The name should match the name in the "Name" column for your autoload. [br]
##Your global autoload must contain a signal called "state_change_request" with parameters for String, Node2D, String. [br]eg: state_change_request(Source: String, Deliver_To: Node, State: String)
@export var global_signal_buss_connection_desired : bool = false
##Project -> Project Settings -> Globals -> Autoloads. [br]The name should match the name in the "Name" column for your autoload.
@export var global_signal_connection_name : String

var compound_states : Dictionary[String,Array] = {}
var current_states : Dictionary[String, String] = {}
var previous_states: Dictionary[String, String] = {}
var signal_buss

##Emitted when a state changes, contains which Atomic State was entered and which Compound State it belongs to.
signal state_entered(Compound: String, Atomic: String)
##Emitted when a state changes, contains which Atomic state was exited and which Compound State it belongs to.
signal state_exited(Compound: String, Atomic: String)
##If enabled, emits the current Atomic State of ALL Compound States every physics frame.
signal state_physics_processing(delta:float, Compound: String, Atomic: String)
##If enabled, emits the current Atomic State of ALL Compound States every frame.
signal state_processing(delta:float, Compound: String, Atomic: String)


func _ready() -> void:
	setup()

func _process(delta: float) -> void:
	for i in current_states.size():
		state_processing.emit(delta, current_states.keys()[i], current_states[current_states.keys()[i]])
		
func _physics_process(delta: float) -> void:
	for i in current_states.size():
		state_physics_processing.emit(delta, current_states.keys()[i], current_states[current_states.keys()[i]])
	
func setup() -> void:
	global_buss_auto_connect()
	default_atomic_states()
	compound_state_setup()
	current_state_setup()
	if physics_process_signal_needed:
		set_physics_process(true)
	else:
		set_physics_process(false)
	if process_signal_needed:
		set_process(true)
	else:
		set_process(false)
	
func compound_state_setup() -> void:
	for i in atomic_states.size():
		var current_value = atomic_states.values()[i]
		var current_key = atomic_states.keys()[i]
		if !compound_states.has(current_value):
			compound_states[current_value] = [current_key] 
		elif compound_states.has(current_value):
			compound_states[current_value].push_back(current_key)
	for i in compound_states.size():
		var current_key : String = compound_states.keys()[i]
		if compound_states[current_key].size() == 1:
			compound_states[current_key].push_front(String("Not") + compound_states[current_key][0])

##After current state setup is complete Initial states are emitted from state_entered.[br]
##This call is deferred to ensure the scene tree is loaded before initial states are broadcasted.
func current_state_setup() -> void:
	for i in compound_states.size():
		var current_key = compound_states.keys()[i]
		current_states[String(current_key)] = compound_states[current_key][0]
	previous_states = current_states.duplicate()
	for i in compound_states.size():
		state_entered.emit.call_deferred(current_states.keys()[i], current_states.values()[i])

##Call this function to enter a state or exit one. Prefer to use this function directly when possible.[br]
##If you need a separate Scene to request state changes you will need to use a Global Signal from an Autoload Script.
func enter_state(compound: String, atomic: String) -> void:
	if current_states.has(compound):
		if compound_states[compound].has(atomic):
			if current_states[compound] != atomic:
				previous_states[compound] = current_states[compound]
				current_states[compound] = atomic
				state_exited.emit(compound, previous_states[compound])
				state_entered.emit(compound, current_states[compound])
			else: return #If we are already the requested state, just return. There may be multiple requests to change to the same state. 
		else: push_error("Atomic State: %s is not assigned to %s" % [atomic, parent.name])
	else: push_error("Compound State: %s is not assigned to %s" % [compound, parent.name])
	
func _state_change_request(source: String, deliver_to: Node2D, state: String) -> void:
	if deliver_to == parent:
		for i in compound_states.size():
			if compound_states[compound_states.keys()[i]].has(state):
				enter_state(compound_states.keys()[i], state)
				return
		push_error("Recieved state change request from %s, but state: %s is not assigned to %s" % [source, state, parent.name])
	else: return
	
##Returns the current value of "compound". If compound is not a valid Compound State pushes an error and returns an empty string.
func get_current_state(compound: String) -> String:
	if current_states.has(compound):
		return current_states[compound]
	else: 
		push_error("Compound State: %s is not assigned to %s" % [compound, parent.name]) 
		return ""
		
##Returns a dictionary of all the Compound States and their current Atomic State values
func get_all_current_states() -> Dictionary:
	return current_states
	
func global_buss_auto_connect() -> void:
	if global_signal_buss_connection_desired:
		if global_signal_connection_name != "":
			if get_tree().root.has_node(global_signal_connection_name):
				signal_buss = get_tree().root.get_node(global_signal_connection_name)
				if signal_buss.has_signal("state_change_request"):
					signal_buss.connect("state_change_request", _state_change_request)
				else:
					global_signal_buss_connection_desired = false
					push_error("Signal buss: %s does not contain signal: state_change_request, could not connect." % global_signal_connection_name)
			else:
				global_signal_buss_connection_desired = false
				push_error("Global Signal Buss name was not found.")
		else: 
			global_signal_buss_connection_desired = false
			push_error("Global Signal Buss enabled but Signal Buss name not provided")
			return
		
	
##Add states here you want all inheritors to have.
func default_atomic_states() -> void:
	#eg.
	#atomic_states["Idle"] = "Movement"
	pass
