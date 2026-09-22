extends Node
## Sonda de bugs: exercita caminhos do jogo e relata o que está errado.
## Roda com: godot4 --headless tests/BugProbe.tscn

var _game_over_count: int = 0
var _failures: Array[String] = []
var _passes: Array[String] = []

func _ready() -> void:
	await get_tree().process_frame
	_test_game_over_spam()
	_test_new_record_logic()
	_test_save_api()
	await _test_touch_joystick_release()
	await _test_arrow_lifetime()
	_test_world_bounds()
	_report()

func _check(ok: bool, name: String, detail: String = "") -> void:
	if ok:
		_passes.append(name)
	else:
		_failures.append("%s%s" % [name, (" — " + detail) if detail else ""])

# 1. game_over deve ser emitido UMA vez só, não a cada ataque depois de morto
func _test_game_over_spam() -> void:
	GameState.reset_run()
	GameState.game_over.connect(func(): _game_over_count += 1)
	for i in range(20):
		GameState.take_damage(10)
	_check(_game_over_count == 1, "game_over emitido 1x",
		"foi emitido %d vezes (spam depois da morte)" % _game_over_count)

# 2. Cenário real: recorde anterior 500, jogador faz 100 nesta run.
#    Não pode dizer "Novo Recorde".
func _test_new_record_logic() -> void:
	GameState.high_score = 500
	GameState.best_wave = 3
	GameState.reset_run()
	var previous_high: int = 500
	for i in range(5):
		GameState.register_hit(20)
	var run_score: int = GameState.score
	# a lógica que o HUD usa hoje:
	var hud_says_record: bool = run_score >= GameState.high_score and run_score > 0
	var really_is_record: bool = run_score > previous_high
	_check(hud_says_record == really_is_record, "detecção de recorde correta",
		"placar da run=%d, recorde anterior=%d, mas o HUD diria recorde=%s" % [run_score, previous_high, hud_says_record])

# 3. salvar precisa ser controlado, não a cada acerto
func _test_save_api() -> void:
	_check(GameState.has_method("flush_save"), "salvamento controlado (flush_save)",
		"GameState grava em disco a cada acerto que bate recorde (trava no navegador)")

# 4. soltar o analógico no celular deve parar o personagem
func _test_touch_joystick_release() -> void:
	var tc = load("res://scenes/ui/TouchControls.tscn").instantiate()
	add_child(tc)
	await get_tree().process_frame
	tc._touch_start(0, Vector2(100, 400))
	tc._touch_drag(0, Vector2(100, 300), Vector2(0, -100))
	tc._process(0.016)
	var pressed_while_held: bool = Input.is_action_pressed("move_forward")
	tc._touch_end(0)
	tc._process(0.016)
	var still_pressed: bool = Input.is_action_pressed("move_forward")
	_check(pressed_while_held, "analógico move enquanto segurado")
	_check(not still_pressed, "analógico PARA ao soltar o dedo",
		"move_forward continua pressionado — no celular o personagem anda sozinho pra sempre")
	Input.action_release("move_forward")
	tc.queue_free()

# 5. flecha que erra tudo precisa sumir sozinha
func _test_arrow_lifetime() -> void:
	var arrow = load("res://scenes/entities/Arrow.tscn").instantiate()
	add_child(arrow)
	await get_tree().process_frame
	var has_lifetime := false
	for prop in arrow.get_property_list():
		if prop.name == "max_lifetime":
			has_lifetime = true
	_check(has_lifetime, "flecha tem tempo de vida máximo",
		"flecha que erra tudo e cai do mapa nunca é liberada (vazamento de corpos físicos)")
	arrow.queue_free()

# 6. as arenas precisam de barreira em volta (senão o jogador cai no vazio)
func _test_world_bounds() -> void:
	for scene_path in ["res://scenes/TrainingRange.tscn", "res://scenes/WaveArena.tscn"]:
		var packed: PackedScene = load(scene_path)
		var state := packed.get_state()
		var wall_count := 0
		for i in range(state.get_node_count()):
			var n: String = str(state.get_node_name(i))
			if n.begins_with("Wall") or n.begins_with("Bound"):
				wall_count += 1
		_check(wall_count >= 4, "%s tem barreira completa" % scene_path.get_file(),
			"só %d parede(s) — dá pra andar pra fora do mapa e cair pra sempre" % wall_count)

func _report() -> void:
	print("\n================ SONDA DE BUGS ================")
	for p in _passes:
		print("  OK    ", p)
	for f in _failures:
		print("  FALHA ", f)
	print("Total: %d ok, %d falhas" % [_passes.size(), _failures.size()])
	print("==============================================\n")
	get_tree().quit()
