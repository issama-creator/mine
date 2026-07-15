
Например, разрезал одним свайпом три объекта:



COMBO ×3

+50



Это мотивирует делать длинные и точные движения.



Критический удар.



Если разрез прошёл точно через центр объекта:



PERFECT

+2x



Серия без ошибок.



10 объектов подряд

↓



FRENZY



На несколько секунд очки удваиваются.

Как разнообразить игру



Например:



0–300 м



Камни.



300–600 м



Камни + пауки.



600–900 м



Камни + летучие мыши + кристаллы.



900–1200 м



Камни + динамит + скорпионы.



1200+ м



Всё вместе.



Игроку будет казаться, что игра постоянно открывает что-то новое.







Мне нравится это направление. Но я бы сделал не копию Fruit Ninja, а игру с собственным стилем — Fruit Ninja в шахте.



Игровой цикл

Шахтер бежит

↓



Сверху летят объекты под разными углами



↓



Игрок режет свайпами



↓



Получает очки и комбо



↓



Сложность растет



↓



Через каждые 200–300 м меняется локация



↓



Через каждые 1000–1500 м — босс

Что может лететь



Обычные



🪨 Камень.

🪵 Балка.

🪙 Кусок руды.



Живые



🕷 Паук.

🦇 Летучая мышь.

🦂 Скорпион.

🐍 Змея.



Опасные



💣 Динамит.

🔥 Горящий камень.



Редкие



💎 Кристалл.

👑 Золотой самородок.

Полет объектов



Не только сверху.



Например:



↘

 ↓

↙



↗



Иногда быстро, иногда медленно.



Игрок не сможет просто водить пальцем по одной линии.



Комбо

3 объекта



COMBO x3



+50

5 объектов



COMBO x5



+150

10 объектов



FRENZY



На несколько секунд очки ×2.



Босс



Идея с двумя ударами хорошая.



Например, большой паук.



Первый свайп



↓



панцирь треснул



↓



босс продолжает лететь



↓



Второй свайп



↓



победа



Или огромный валун:



1 удар



↓



трещина



↓



2 удар



↓



разлетелся



Позже можно добавить и более сильных боссов:



3 HP



или



5 HP



После каждого удара внешний вид меняется, чтобы игрок сразу видел прогресс.



Что сделает игру интереснее



Я бы добавил случайные события.



Например:



Обвал!



10 секунд



камней становится в 3 раза больше



или



Стая летучих мышей!



или



Динамитная шахта!



Осторожно!



Это добавит разнообразия без изменения основной механики.



Самое важное



У тебя уже складывается понятная игровая петля:



автоматический бег;

свайпы;

комбо;

смена окружения;

новые типы объектов;

боссы с несколькими очками прочности.



Это достаточно насыщенный геймплей для аркадной мобильной игры. Я бы сначала довёл именно этот цикл до хорошего состояния, а уже потом добавлял магазин, улучшения, новые скины и другие долгосрочные системы.





Я бы разбил задачу на 3 больших промпта. Не один. Cursor и Claude гораздо лучше справляются, когда проект собирается этапами.

PROMPT 1 — СОБРАТЬ ВСЮ ИГРУ
You are a senior Flutter + Flame game developer.

Create a complete production-quality mobile game.

Game genre:

2D endless runner + Fruit Ninja slicing.

The player controls only swipe gestures.

A miner automatically runs forever.

The world scrolls continuously.

All assets are already located inside the assets folder.

Automatically inspect the assets directory and use every asset appropriately.

If sprite sizes differ,
background sizes differ,
pivot points are incorrect,
transparent padding is inconsistent,
or image resolutions do not match,

automatically normalize everything in code without modifying the original assets.

Never require me to manually fix assets.

Create clean architecture.

Separate:

Game

Player

World

Spawner

Effects

Camera

HUD

Score

Audio

Particles

Bosses

Animations

Input

Collision

Managers

The game must run smoothly at 60 FPS.

Everything must be modular and production ready.

The miner continuously runs.

Background loops infinitely.

Every 300 meters change biome.

Biome transition should smoothly fade.

Difficulty continuously increases.

Increase:

spawn rate

fall speed

random angles

rotation speed

without sudden jumps.

Everything should feel polished.
PROMPT 2 — GAME FEEL (самый важный)
Now polish the entire gameplay.

The game must feel as satisfying as Fruit Ninja.

Do NOT rewrite existing systems.

Improve only game feel.

Implement:

Swipe trail

Smooth glowing trail.

Rounded edges.

Fade in 0.25 sec.

Rock slicing:

Impact flash

Dust

Debris

Rock halves

Random physics

Rotation

Fade

Camera shake

Small shake for rocks

Bigger shake for bosses

Pause hit

Freeze game for 0.04 sec after every successful slice.

Floating score

+10

+25

+100

Combo

COMBO x3

COMBO x5

FRENZY

Animated text.

Scaling.

Glow.

Particles

Dust

Rock fragments

Smoke

Sparkles

Spider blood particles (stylized)

Diamond sparkle

Diamond emits light particles.

Explosion

Dynamite explosion.

Screen shake.

Smoke.

Fire.

Audio hooks

Create placeholders for:

slice

rock

diamond

explosion

combo

boss

game over

Camera

Smooth.

Never excessive.

Use squash & stretch where appropriate.

Use small anticipation before impacts.

Make every successful slice satisfying.
PROMPT 3 — ФИНАЛЬНАЯ ПОЛИРОВКА
Now finish the game like a professional mobile release.

Inspect every existing asset automatically.

If any PNG has:

wrong pivot

wrong padding

wrong transparent borders

wrong scaling

different size

wrong anchor

incorrect animation timing

automatically compensate inside code.

Never require manual asset editing.

Gameplay progression:

0-300m

Classic Mine

300-600m

Crystal Cave

600-900m

Golden Mine

900-1200m

Abandoned Mine

1200-1500m

Lava Cave

1500+

Random biome rotation.

Spawn:

Small rocks

Medium rocks

Large rocks

Diamonds

Spider

Boss Spider

Dynamite

Random cave debris

Wood beams

Create additional cave obstacles if needed while matching the game's art style.

Random Events:

Rockfall

Crystal Rain

Spider Nest

Treasure Rush

Dynamite Zone

Large animated title appears.

Bosses

Large spider

Red glowing eyes

Needs 2 successful slices.

First hit:

visible damage

Second hit:

death animation

Game Over

If dangerous object hits miner head:

short freeze

camera shake

GAME OVER

Distance

Score

Best Combo

Restart

Optimize everything.

Use Flame particles.

Avoid garbage allocations.

Maintain stable 60 FPS.

Review the entire project.

Fix inconsistencies.

Remove duplicated code.

Refactor where necessary.

The final result should feel like a polished mobile arcade game inspired by Fruit Ninja and Subway Surfers but with its own unique mining identity.
🔥 И ещё один, четвёртый промпт — самый полезный

После того как Cursor закончит, отправь ему этот запрос. Именно он часто поднимает качество с "рабочего" до "приятного":

Play the role of a senior game director.

Review the entire project critically.

Find everything that feels cheap, repetitive, awkward or unpolished.

Improve gameplay pacing.

Improve juice.

Improve player feedback.

Improve animations.

Improve timing.

Improve particles.

Improve transitions.

Improve object spawning.

Improve difficulty curve.

Improve visual hierarchy.

Improve readability.

Improve performance.

Improve code quality.

If something feels wrong, fix it automatically.

If any mechanic reduces fun, redesign it while keeping the original gameplay.

Keep the game simple.

Prioritize player emotions over technical perfection.

The first 30 seconds must immediately hook the player.

The last seconds before Game Over must be the most intense.

Every 15–20 seconds the player should experience something new:
new biome,
event,
reward,
combo,
or tension spike.

The goal is to make players think:
'Just one more run.'

Do not ask questions.
Make improvements autonomously.
Это я бы уже считал финальным ТЗ

Если у тебя действительно:

есть ассеты персонажа;
есть анимация бега;
есть фоны;
есть камни;
есть паук;
будут алмазы, динамит и остальные препятствия,

то этих промптов достаточно, чтобы Cursor собрал полноценный MVP игры.

После этого уже стоит играть самому и на основе ощущений менять баланс и темп. Ни один промпт не заменит реальные игровые тесты, но он может сильно ускорить получение первой качественной версии.





а. Я бы вообще дал Cursor одно большое техническое задание, чтобы он понял не только код, а какие эмоции должна вызывать игра.

You are a senior Game Director, Senior Mobile Game Designer and Senior Flutter + Flame developer.

You are building a complete mobile game.

This is not just coding.

Your goal is to create a highly polished, addictive arcade game with satisfying gameplay.

The game must feel like a premium mobile title.

==========================================================
GAME CONCEPT
==========================================================

The game is inspired by:

Fruit Ninja
Subway Surfers

But it must NOT copy them.

The game has its own mining theme.

The player protects a running miner by slicing everything dangerous that falls from above.

The game must immediately feel fun within the first 10 seconds.

The player should always think:

"One more run."

==========================================================
CORE GAMEPLAY
==========================================================

The miner automatically runs forever.

The player never controls movement.

The only control is swipe.

The player slices falling objects.

The swipe mechanic must feel extremely satisfying.

The entire game is built around satisfying slicing.

==========================================================
WORLD
==========================================================

The background scrolls infinitely.

Every 300 meters the biome changes.

Biome order:

Mine

Crystal Cave

Golden Mine

Abandoned Mine

Lava Cave

Ancient Ruins

After that continue random biome rotation.

Every biome changes:

background

lighting

colors

spawn objects

particles

atmosphere

music placeholder

Transition must fade smoothly.

==========================================================
PLAYER
==========================================================

The miner constantly runs.

Running animation loops.

The miner never stops until Game Over.

The player never jumps.

The player never attacks manually.

Only swipe.

==========================================================
OBJECTS
==========================================================

Spawn randomly.

Small Rock

Medium Rock

Large Rock

Diamond

Spider

Boss Spider

Dynamite

Wood Beam

Random Cave Debris

If additional obstacles improve gameplay,
create them automatically.

Everything must match the mining theme.

==========================================================
SPAWNING
==========================================================

Objects fall

from above

from random angles

with random rotation

with slightly different speeds

Never make patterns repetitive.

Spawn rate increases over time.

==========================================================
SLICING
==========================================================

This is the most important mechanic.

Every slice must feel amazing.

Implement:

Glowing swipe trail

Impact flash

Dust

Rock fragments

Particles

Physics

Object halves

Random rotation

Camera shake

Micro freeze (0.04 sec)

Floating score

Combo popup

Sound placeholders

Everything must feel juicy.

==========================================================
DIAMONDS
==========================================================

Diamonds are bonuses.

Player slices diamonds to collect them.

Diamonds sparkle.

Emit particles.

Give bonus score.

Play satisfying collect animation.

==========================================================
SPIDERS
==========================================================

Spider dies in one slice.

Boss Spider has glowing red eyes.

Boss Spider needs two slices.

First slice:

visible damage

Second slice:

death animation

==========================================================
DYNAMITE
==========================================================

If sliced:

Explosion

Smoke

Fire particles

Score

If hits miner:

Game Over

==========================================================
COMBOS
==========================================================

Multiple objects sliced in one swipe:

3

COMBO x3

5

COMBO x5

10

FRENZY

Increase multiplier.

Larger visual effects.

==========================================================
GAME RHYTHM
==========================================================

Gameplay should constantly alternate between:

calm

action

reward

tension

reward

chaos

Do not keep constant intensity.

Create emotional waves.

==========================================================
RANDOM EVENTS
==========================================================

Occasionally trigger:

Rockfall

Crystal Rain

Spider Nest

Treasure Rush

Dynamite Zone

Display large animated title.

Events last several seconds.

==========================================================
DIFFICULTY
==========================================================

Difficulty increases gradually.

Increase:

fall speed

spawn rate

angle randomness

reaction difficulty

Never create unfair situations.

==========================================================
GAME OVER
==========================================================

Dangerous object hits miner head.

Freeze.

Small camera shake.

Show:

GAME OVER

Distance

Score

Best Combo

Restart

One tap restart.

==========================================================
HUD
==========================================================

Display:

Distance

Score

Combo

High Score

Pause Button

==========================================================
VISUAL FEEL
==========================================================

Everything should feel polished.

Small animations everywhere.

Smooth transitions.

Particles.

Glow.

Scale effects.

Squash and Stretch.

No static UI.

==========================================================
PERFORMANCE
==========================================================

Target:

60 FPS

Optimize particles.

Optimize spawning.

Avoid allocations inside update().

Use Flame best practices.

==========================================================
ASSETS
==========================================================

All assets are already inside assets/.

Automatically inspect every asset.

If images have:

different sizes

wrong pivots

wrong transparent padding

wrong scaling

different resolutions

incorrect animation frame sizes

automatically compensate inside code.

Never require manual editing.

==========================================================
GAME DESIGN
==========================================================

Always prioritize:

Player satisfaction

Game feel

Responsiveness

Visual feedback

Not complexity.

Simple mechanics.

Excellent execution.

==========================================================
FINAL GOAL
==========================================================

The player should feel:

"I'll play just one more run."

Review the entire project continuously.

If anything feels repetitive,
boring,
cheap,
slow,
or awkward,

improve it automatically while keeping the original gameplay.

Create production-quality code.

Create a game that feels complete, polished and fun.
Я бы ещё добавил один абзац в самый конец

Он, как ни странно, очень помогает ИИ принимать правильные решения:

If there is a choice between adding more mechanics or making existing mechanics feel better,

always choose better game feel.

A simple game with excellent feedback is better than a complex game with weak feedback.

Every swipe must be satisfying.

Every successful slice should make the player smile.

The entire experience should encourage "one more run."