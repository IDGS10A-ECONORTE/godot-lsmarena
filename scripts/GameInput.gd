extends Node

signal command_received(command: String, payload: Dictionary)

var latest_command: String = ""
var latest_payload: Dictionary = {}

func set_command(command: String, payload: Dictionary = {}) -> void:
	latest_command = command
	latest_payload = payload
	emit_signal("command_received", command, payload)

func clear() -> void:
	latest_command = ""
	latest_payload = {}

