extends Single_Script_Finite_State_Machine

@export var ai_controller : NPC_Combat_AiC

func _ready() -> void:
	super() #Make sure original _ready() function runs. 
	state_entered.connect(_state_entered)
	state_exited.connect(_state_exited)
	

func _state_entered(compound, atomic):
	match compound:
		"HitStun":
			match atomic:
				"Stunned": ai_controller.skill_use_allowed = false
				"NotStunned": ai_controller.skill_use_allowed = true
		"Skills":
			match atomic:
				"SkillUse": ai_controller.skill_use_allowed = false
				"SkillComplete": ai_controller.skill_use_allowed = true
	
func _state_exited(_compound, _atomic):
	pass
