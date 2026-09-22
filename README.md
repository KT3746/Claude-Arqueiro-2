# Arqueiro

Um jogo de arqueiro em **primeira pessoa**, feito em Godot 4.3. Puxe a corda, sinta o peso do arco, mire compensando a gravidade e acerte o alvo — ou sobreviva às ondas de espectros nas ruínas da floresta.

Inspirado em: **Zelda (mira/tensão do arco)**, **In Death: Unchained / Elven Assassin** (loop arcade de ondas) e **Skyrim** (feel físico do disparo).

## Como jogar

- **Mouse**: olhar em volta
- **WASD**: mover / **Shift**: correr / **Espaço**: pular
- **Botão esquerdo (segurar)**: puxa a corda — quanto mais tempo segurar (até ~0,9s), mais forte sai a flecha
- **Botão esquerdo (soltar)**: dispara
- **Botão direito (segurar)**: mira (zoom e passo mais lento, pra precisão)
- **Esc**: solta/prende o cursor do mouse

A flecha é um projétil físico de verdade — sofre efeito de gravidade e forma um arco de trajetória. Mire mais alto para alvos distantes.

## Modos

- **Campo de Treino**: alvos parados, um pendular (balançando) e um giratório (que vira de perfil), pra treinar mira e timing.
- **Modo Ondas**: espectros surgem das ruínas em ondas crescentes e avançam até você. Acerte a cabeça para dano/pontuação extra. Sobreviva o quanto puder.

## Feedback e qualidade de vida

- Marcador de acerto na mira e texto flutuante com a zona atingida (`+100 Ouro`, `+50 Cabeça!`)
- Espectros acendem e levam um "soco" de escala ao serem atingidos — dá pra saber que a flechada pegou
- Vinheta vermelha ao tomar dano, pulsando quando a vida fica baixa
- Tremor de câmera e câmera lenta breve (hit-stop) nos acertos de destaque
- Menu de pausa (Esc) que pausa o jogo de verdade
- Recorde de pontos e de onda salvos entre sessões

## Testes

`tests/BugProbe.tscn` é uma sonda de regressão que exercita os caminhos que já
deram problema (game over repetido, analógico grudado no celular, flecha que
vaza, barreira do cenário). Rode com:

```
godot4 --headless tests/BugProbe.tscn
```

Ela imprime um relatório `OK` / `FALHA` por item.

## Estrutura do projeto

```
scenes/
  ui/            MainMenu.tscn, HUD.tscn
  entities/      Player, Arrow, Target, Enemy, BowView, HitEffect
  environment/   ForestScatter (árvores/pedras via MultiMesh), RuinPillar, RuinArch
  TrainingRange.tscn   cena do Campo de Treino
  WaveArena.tscn       cena do Modo Ondas
scripts/
  autoload/GameState.gd   placar, vida, combo, onda (estado global)
  Player.gd               movimento em 1ª pessoa + mecânica do arco
  Arrow.gd                física da flecha e detecção de acerto
  Target.gd               pontuação por zona concêntrica (estilo alvo olímpico)
  Enemy.gd / WaveManager.gd   inimigos e progressão de ondas
  BowView.gd               modelo do arco em 1ª pessoa (limbo + corda animada)
  SceneAtmosphere.gd        céu, névoa e luz douradas via código
  ForestScatter.gd          espalha árvores/pedras estilizadas (MultiMesh)
```

Todo o visual (arco, flechas, alvos, ruínas, árvores, inimigos) é feito com primitivas geométricas e materiais/partículas configurados via código — sem depender de pacotes de assets externos.

## Rodando

Abra a pasta no Godot 4.3+ e rode o projeto (F5). A cena principal é `scenes/ui/MainMenu.tscn`.
