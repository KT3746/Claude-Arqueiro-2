# Arqueiro — contexto para novas sessões

Jogo de arco em 1ª pessoa, Godot 4.3 (GDScript), PT-BR. Usuário é leigo: respostas simples, em português.
Branch de trabalho: `claude/first-person-archer-game-3r1tl0`.

## Estado atual (pronto e testado)
- Campo de Treino (`scenes/TrainingRange.tscn`) e Modo Ondas (`scenes/WaveArena.tscn`), menu, HUD, pausa (Esc), recorde salvo.
- Autoloads: `GameState` (placar/vida/onda/recorde, `is_game_over`, `flush_save`), `Audio` (SFX sintetizados em código).
- Controles de toque (`TouchControls`) só aparecem em tela de toque.
- Visual 100% procedural (primitivas + materiais em código), sem assets externos.
- Builds: preset "Windows Desktop" e "Web" em `export_presets.cfg` (tests/ excluído). Web publicado pelo usuário via itch.io (upload do zip).

## Validar mudanças (obrigatório antes de commit)
Container novo não tem Godot. Instalar:
```
curl -sSL -o /tmp/g.zip https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip && unzip -o -q /tmp/g.zip -d /tmp && mv /tmp/Godot_v4.3-stable_linux.x86_64 /usr/local/bin/godot4
```
- Regressão: `godot4 --headless tests/BugProbe.tscn` (deve dar 8 ok, 0 falhas).
- Render real (pega erros que o headless não pega): `xvfb-run -a godot4 --rendering-driver opengl3 --quit-after 90 scenes/WaveArena.tscn`.
- Erro "Parameter m is null" em `--headless` puro é artefato do driver dummy — ignorar se some com opengl3.
- Exportar exige templates (~1GB): `Godot_v4.3-stable_export_templates.tpz` → `~/.local/share/godot/export_templates/4.3.stable/`.

## Armadilhas já conhecidas
- `.tscn` escrito à mão: conferir IDs/`load_steps`; mudar nó exige mudar `parent=` dos filhos.
- `create_timer()` ignora pausa por padrão — passar `false` no 2º arg em lógica de jogo.
- Não mexer em árvore/monitoring dentro de callback de física: usar `call_deferred`/`set_deferred`.
- Não sobrescrever `position` de Control ancorado sem guardar a base.

## Ideias pendentes (não pedidas ainda)
Mais tipos de inimigo, 2º cenário, dificuldade ajustável, .apk Android.
