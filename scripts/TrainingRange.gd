extends Node3D
## Zera o placar/onda ao entrar no campo de treino, pra não herdar estado
## de uma sessão anterior do Modo Ondas (GameState é global/autoload).

func _ready() -> void:
	GameState.reset_run()
