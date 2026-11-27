# Промты для генерации картинок

Сохранено 2026-11-27 при передаче проекта. Здесь всё, что нужно, чтобы рисовать картинки для игры: куда класть файлы, как их называть и какие промты использовать.

Картинки кладутся в ветку `main`, в папку `assets/visual-kit/`. Игра нарезает их при сборке; сами файлы никто не меняет.

Два правила для любого спрайта:

- **Прозрачный фон.** Если фон непрозрачный, спрайт пропускается и рисуется кодом. Вырезать по догадке нельзя.
- **Один референс стиля.** К каждому запросу прикладывайте готовую картинку из игры: к полам и препятствиям готовый пол Косого переулка, к персонажам готовый лист персонажа.

## 1. Пол

Пол повторяется плиткой с зеркалом, поэтому на нём не должно быть ничего уникального: любая заметная деталь размножится симметричным узором.

Файл: `assets/visual-kit/floors/<карта>.png`. Имена карт перечислены в разделе 3.

```
Top-down game ground texture, straight orthographic view from directly above, portrait 9:16.
Surface: [SURFACE].
Only flat ground, nothing rising above it: no walls, no buildings, no furniture, no props, no characters.
The same material and the same density of detail from edge to edge. No single large or unique detail, no central motif, no path, no border, no frame.
Any seams or boards run straight, parallel to the image edges; no diagonal lines.
Flat even lighting: no cast shadows, no light pools, no vignette, no darker edges, no gradient.
Hand-painted dark fantasy style matching the attached reference, muted colours, slightly darker than mid-tone.
No text, no logos, no UI.
```

## 2. Препятствие

Файл: `assets/visual-kit/props/<карта>/<тип>-<размер>-<имя>.png`. Имя задаёт поведение и размер:

- **Тип:** `wall` и `low` непроходимы, `pit` рисуется плоско на полу и непроходим, `deco` проходим.
- **Размер:** `s` шириной с героя, `m` около 2,5 героя, `l` около 5, `xl` около 9.
- **Свет:** слово `lamp` в имени добавляет пятно света.
- **Столбы:** `wall-s-lamp-...` должен быть высоким и узким, тогда твёрдым будет только основание.

```
Single game sprite of [OBJECT], for a top-down fantasy action game.
View from above, tilted slightly so a thin strip of the side facing the bottom of the image is visible. The object stands upright, its base at the bottom.
One object only, centred, fully inside the frame with empty margin on all sides. Nothing cut off by the image edge.
Transparent background. No ground, no floor, no cast shadow, no glow spilling outside the object.
Light from the top-left. Hand-painted dark fantasy style matching the attached reference.
Square canvas. No text, no logos.
```

Для ям (`pit-...`) вторая строка заменяется на:

```
Seen from directly above, lying flat on the ground: a hole with a dark interior and a narrow rim of broken ground around it.
```

Если генератор не даёт прозрачный фон, запасной вариант — ровный фон цвета `#FF00FF`. Вырезание по этому цвету в игре **не сделано**: об этом нужно сказать агенту.

## 3. Что рисовать по картам

Готов только Косой переулок (`01-diagon-alley`): пол и 9 препятствий (`wall-xl-shop-row`, `wall-l-book-shop`, `wall-l-potion-shop`, `wall-m-market-stall`, `wall-s-lamp-post`, `low-s-barrels`, `low-s-crates`, `low-m-cart`, `pit-m-sinkhole`).

Ниже 14 карт без пола и препятствий. В таблицах: имя файла и текст для `[OBJECT]`. Одинаковые предметы (обломки, пень, колонну, жаровню) можно нарисовать один раз и скопировать в несколько папок.

Совет: сначала сделать две карты (`02-academy-courtyard` и `boss-01-mirror-chamber`), посмотреть на телефоне повтор пола и расстановку, и только потом остальные. После загрузки сказать агенту: новые имена нужно вписать в `Arena.KNOWN` в `scripts/game/arena.gd`.

**`02-academy-courtyard`**. Пол: `old grey castle courtyard flagstones with moss in the joints and a few small fallen leaves`

| Файл | [OBJECT] |
|---|---|
| `wall-xl-cloister-wall` | a section of a gothic stone cloister wall with three pointed arches |
| `wall-l-fountain` | a round stone fountain with a carved central spout |
| `wall-m-knight-statue` | a stone knight statue on a square plinth |
| `low-m-stone-bench` | a long weathered stone bench |
| `wall-s-lamp-torch` | a tall iron torch post with a burning flame |
| `low-s-urn` | a stone garden urn with ivy |

**`boss-01-mirror-chamber`**. Пол: `dark polished stone floor tiles with fine cracks and dust`

| Файл | [OBJECT] |
|---|---|
| `wall-l-great-mirror` | a tall ornate standing mirror in a gilded frame on clawed feet |
| `wall-l-broken-arch` | a broken stone archway |
| `wall-m-pillar` | a thick stone pillar, broken off at the top |
| `low-m-fallen-column` | a fallen stone column lying on its side, in two pieces |
| `wall-s-lamp-brazier` | a tall iron brazier with a small fire |
| `low-s-rubble` | a small heap of stone rubble |

**`03-forbidden-forest`**. Пол: `dark forest floor: damp earth, moss, dead leaves and small twigs`

| Файл | [OBJECT] |
|---|---|
| `wall-xl-ancient-tree` | the wide gnarled trunk of an ancient tree with spreading roots, broken off above, no foliage |
| `wall-l-boulders` | a cluster of large mossy boulders |
| `wall-m-dead-tree` | a dead leafless tree with a twisted trunk |
| `low-m-fallen-log` | a fallen mossy log |
| `low-s-stump` | a tree stump with mushrooms |
| `deco-s-lamp-mushrooms` | a small patch of glowing blue mushrooms |
| `pit-m-burrow` | a burrow hole in the earth among roots |

**`04-storm-pitch`**. Пол: `wet dark green sports turf, short trampled grass with small muddy patches`

| Файл | [OBJECT] |
|---|---|
| `wall-xl-spectator-stand` | a section of a wooden spectator stand draped with striped cloth |
| `wall-l-goal-hoops` | three tall golden goal hoops on poles, on a shared base |
| `wall-m-equipment-shed` | a small wooden equipment shed |
| `low-m-ball-chest` | an open leather-strapped chest of sports balls |
| `low-s-bench` | a short wooden bench |
| `wall-s-lamp-post` | a tall iron lamp post with a glowing lantern |
| `pit-m-mud-pool` | a muddy water-filled hollow |

**`boss-02-underground-dungeon`**. Пол: `wet greenish dungeon flagstones with shallow puddles and slime in the joints`

| Файл | [OBJECT] |
|---|---|
| `wall-l-serpent-statue` | a large stone statue of a coiled serpent with a raised head |
| `wall-l-collapsed-wall` | a section of collapsed dungeon wall with a rusty grate |
| `wall-m-pillar` | a thick stone pillar carved with scales |
| `low-m-bone-pile` | a heap of old bones |
| `low-s-rubble` | a small heap of stone rubble |
| `wall-s-lamp-brazier` | a tall iron brazier with a green flame |
| `pit-m-drain` | a round floor drain with a broken iron grate |

**`05-mysteries-archive`**. Пол: `black glossy stone floor tiles with faint blue reflections`

| Файл | [OBJECT] |
|---|---|
| `wall-xl-shelf-row` | a long row of tall dark shelves filled with small glowing glass orbs |
| `wall-l-orb-shelf` | a tall dark shelf filled with small glowing glass orbs |
| `wall-m-stone-arch` | an ancient freestanding stone arch with a tattered grey veil |
| `low-m-desk` | a heavy dark desk covered with scrolls |
| `low-s-orb-stand` | a glass orb on a small bronze stand |
| `wall-s-lamp-post` | a tall bronze stand with a blue flame |

**`06-frost-village`**. Пол: `trampled snow with patches of dark cobblestone showing through`

| Файл | [OBJECT] |
|---|---|
| `wall-xl-cottage-row` | a row of three snow-roofed timber cottages |
| `wall-l-cottage` | a snow-roofed timber cottage with a lit window |
| `wall-m-pine` | a snow-covered pine tree |
| `low-m-sleigh` | a wooden sleigh loaded with sacks |
| `low-s-woodpile` | a small stack of firewood under snow |
| `wall-s-lamp-post` | a tall iron street lamp with snow on top |

**`boss-03-lakeside-forest-clearing`**. Пол: `dark wet grass with pebbles and patches of frost, at night`

| Файл | [OBJECT] |
|---|---|
| `wall-l-rock-outcrop` | a large jagged rock outcrop |
| `wall-l-willow-trunk` | the thick leaning trunk of an old willow with bare hanging branches |
| `wall-m-dead-tree` | a dead leafless tree with a twisted trunk |
| `low-m-rowboat` | an old wooden rowboat pulled ashore |
| `low-s-stump` | a tree stump |
| `wall-s-lamp-lantern` | an old lantern hanging on a tall wooden post |
| `pit-m-pond` | a small dark pond with a thin rim of ice |

**`07-serpent-vault`**. Пол: `ancient green-grey stone slabs with fine cracks and specks of gold dust`

| Файл | [OBJECT] |
|---|---|
| `wall-l-serpent-statue` | a large stone statue of a coiled serpent with a raised head |
| `wall-l-treasure-heap` | a large heap of gold coins and goblets |
| `wall-m-pillar` | a thick stone pillar carved with serpents |
| `low-m-chest` | a large iron-bound treasure chest |
| `low-s-urn` | a bronze urn |
| `wall-s-lamp-brazier` | a tall iron brazier with a green flame |
| `pit-m-well` | a round stone well shaft |

**`08-midnight-crossroads`**. Пол: `dark wet cobblestones at night with small puddles`

| Файл | [OBJECT] |
|---|---|
| `wall-xl-house-row` | a row of three narrow dark town houses |
| `wall-l-toll-house` | a small stone toll house |
| `wall-m-signpost` | a crossroads signpost with four arms on a stone base |
| `low-m-carriage-wreck` | a broken black carriage with a missing wheel |
| `low-s-crates` | a small stack of wooden crates |
| `wall-s-lamp-post` | a tall iron street lamp with a violet glow |
| `pit-m-manhole` | an open round manhole |

**`boss-04-ruined-classroom`**. Пол: `worn wooden floorboards covered with dust, the boards running straight from top to bottom`

| Файл | [OBJECT] |
|---|---|
| `wall-l-collapsed-wall` | a section of collapsed classroom wall with a broken window |
| `wall-l-blackboard` | a large cracked blackboard on a wooden stand |
| `wall-m-bookcase` | a tall bookcase with spilled books |
| `low-m-desk-pile` | a pile of overturned school desks |
| `low-s-chair` | an overturned wooden chair |
| `low-s-cauldron` | a small dented cauldron |
| `wall-s-lamp-candelabra` | a tall iron candelabra with lit candles |

**`09-storm-prison`**. Пол: `rough dark wet stone slabs with rain puddles`

| Файл | [OBJECT] |
|---|---|
| `wall-xl-cell-block` | a long section of prison wall with three barred cell doors |
| `wall-l-watchtower` | the square stone base of a watchtower |
| `wall-m-iron-cage` | a rusty iron cage |
| `low-m-chains` | a heap of heavy iron chains and shackles |
| `low-s-rubble` | a small heap of stone rubble |
| `wall-s-lamp-post` | a tall iron post with a cold blue lantern |
| `pit-m-grate` | a square floor pit covered by a broken iron grate |

**`10-astronomy-tower`**. Пол: `pale stone slabs with tiny brass star inlays scattered evenly`

| Файл | [OBJECT] |
|---|---|
| `wall-l-telescope` | a large brass telescope on a heavy tripod |
| `wall-l-orrery` | a large brass orrery with rings and planets |
| `wall-m-star-globe` | a celestial globe on a wooden stand |
| `wall-m-battlement` | a short section of battlement wall |
| `low-m-chart-table` | a table covered with star charts |
| `low-s-stool` | a small wooden stool with books on it |
| `wall-s-lamp-brazier` | a tall iron brazier with a violet flame |

**`boss-05-broken-bridge`**. Пол: `weathered grey bridge paving stones with cracks and scorch marks`

| Файл | [OBJECT] |
|---|---|
| `wall-l-broken-parapet` | a long broken section of stone bridge parapet |
| `wall-l-tower-stub` | the ruined stone base of a bridge tower |
| `wall-m-broken-statue` | a broken stone statue on a plinth |
| `low-m-rubble-heap` | a large heap of fallen masonry |
| `low-s-rubble` | a small heap of stone rubble |
| `wall-s-lamp-post` | a bent iron lamp post with a green glow |
| `pit-m-hole` | a ragged hole broken through stone paving, darkness below |

## 4. Персонажи и боссы: лист из пяти направлений

**Оговорка.** Точный текст промтов для персонажей, который давался в чате, не сохранился. Ниже формат, которого ждёт игра (он точный), и шаблон, написанный заново при передаче проекта. Словесные описания Гермионы, Рона, Квиррелла и Василиска тоже не сохранились; их листы уже лежат в репозитории и работают как референсы.

Что ждёт игра:

- Один ряд из пяти фигур одного персонажа: лицом к зрителю, вполоборота вправо-вниз, вправо, вполоборота вправо-вверх (со спины), спиной. Левую сторону игра получает зеркалом.
- Ноги всех фигур на одной линии, рост одинаковый.
- **Широкие промежутки.** Фигуры не должны касаться друг друга ни палочкой, ни мантией. Если касаются, игра режет по самому пустому столбцу и может отрезать палочку.
- Прозрачный фон, холст 16:9.

Файлы, `assets/visual-kit/sprites/`:

| Кто | Файлы | Состояние |
|---|---|---|
| Гарри | `hero-wizard-8dir-idle.png`, `-walk-a`, `-walk-b` | idle и walk-a есть, walk-b нет (генератор отказал) |
| Гермиона | `hermione-8dir-idle.png`, `-walk-a`, `-walk-b` | все три есть |
| Рон | `ron-8dir-idle.png`, `-walk-a`, `-walk-b` | все три есть, в walk-листах фигуры касаются |
| Квиррелл | `boss-01-quirrell-8dir-idle.png`, `-8dir-cast.png` | есть, фигуры касаются |
| Василиск | `boss-02-cockatrice-basilisk-8dir-idle.png`, `-8dir-gaze.png` | есть |
| Дементор, Нагайна, Волан-де-Морт | листов нет | используется одна картинка; промты не написаны, в код нужно добавить имена файлов |

Шаблон (написан заново):

```
Sprite sheet for a top-down fantasy action game: the same character five times in one horizontal row, turning in 45-degree steps.
Left to right: 1) facing the viewer, 2) turned to the bottom-right, 3) facing right, side view, 4) turned to the top-right, seen from behind, 5) facing away, back view.
Character: [CHARACTER].
Pose in all five: [POSE]. The wand points where the character faces.
The same high three-quarter camera from above in all five. Full body from head to feet, the same size in all five.
All feet stand on one horizontal line. Wide empty gaps between the figures: nothing overlaps or touches, no wand, robe or hair reaches a neighbour.
Transparent background. No ground, no shadows, no frames, no labels, no numbers, no text.
Light from the top-left. Hand-painted dark fantasy style matching the attached reference.
Wide 16:9 canvas.
```

`[POSE]`:

- idle: `standing still, wand held ready`
- walk-a: `walking, mid-stride with the left leg forward, robe swinging`
- walk-b: `walking, mid-stride with the right leg forward, robe swinging`
- атака босса: поза замаха или колдовства

Про Гарри. Генератор отказался делать его walk-листы из-за сходства с чужим персонажем. Решение, принятое в проекте: не переписывать промт, чтобы обойти фильтр. Без walk-листов шаг анимируется кодом. Если нужен рисованный шаг, это менее узнаваемый дизайн героя и все три листа заново.

## 5. Одиночный враг

Файл: `assets/visual-kit/sprites/mobs/<имя>.png`. Вариант `<имя> v2.png` побеждает исходный. Игра ищет только эти 20 имён:

`cauldron`, `sprite`, `mimic`, `caster`, `armor`, `book`, `portrait`, `spider`, `wraith`, `plant` (эти десять уже лежат отдельными файлами), `centaur`, `ball`, `drowned`, `automaton`, `serpent`, `frostwitch`, `carriage`, `gargoyle`, `guard`, `owl` (эти десять берутся из общего листа `enemies-expansion-pseudo3d-atlas.png`).

Картинок нет совсем у врагов «Эхо пророчества», «Заколдованный снеговик», «Оборотень» и у боссов глав (Страж переулка, Арагог, Хекс-возмущение, Змеиный идол, Фенрир Сивый): они рисуются кодом. Чтобы дать им картинки, нужна правка кода.

Шаблон (написан заново; точное требование одно — фигура смотрит вправо-вниз, фон прозрачный):

```
Single game sprite of [CREATURE], for a top-down fantasy action game.
High three-quarter view from above. The creature faces the bottom-right.
One creature only, whole body inside the frame with empty margin on all sides.
Transparent background. No ground, no cast shadow, no text.
Light from the top-left. Hand-painted dark fantasy style matching the attached reference.
Square canvas.
```

## 6. Вид строго сверху (для змей)

Используется у Василиска, когда он ползёт и бросается: одна фигура, которую игра сама поворачивает в любую сторону. Файлы: `boss-02-cockatrice-basilisk-top-move.png`, `-top-lunge.png`. Для Нагайны такие позы понадобятся тоже; имена файлов нужно будет добавить в код.

Шаблон (написан заново; точные требования — вид строго сверху, голова у правого края, одна фигура, прозрачный фон):

```
Single game sprite of [CREATURE] seen from directly above, straight top-down, no perspective.
The body lies along the horizontal axis of the image, the head at the right end, the tail at the left end.
Pose: [POSE].
One creature only, the whole body inside the frame with empty margin.
Transparent background. No ground, no cast shadow, no text.
Hand-painted dark fantasy style matching the attached reference.
Wide 16:9 canvas.
```

`[POSE]`: для движения `slithering forward in a gentle S-curve`, для броска `stretched out straight in a lunge, jaws open`.
