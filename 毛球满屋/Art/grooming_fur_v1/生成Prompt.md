# 灰白长毛猫分层候选资产生成Prompt

使用内置imagegen；参考为用户提供灰白长毛猫与近景效果图，所有生成PNG保留原图及Alpha，没有用脚本修色或改像素。

## 顺毛底图初稿

```text
Use case: precise-object-edit / game sprite production.
Create a TRANSPARENT-BACKGROUND 2D clean BASE CAT sprite for the supplied reference cat. Image 1 specifies close-up gameplay camera, pose and identity; image 2 specifies its brushed/tidy coat. Output the CAT ONLY, remove room, table, shadows and all background.
Match the same very chunky gray/taupe and cream-white long-haired cat: simple dark oval eyes, dark brown tiny nose/whiskers, pink inner ears, head at left, torso broad at center, four short paws standing, big fluffy tail raised on the right with cream tip. Keep the reference's paper-sprite cartoon rendering and thick dark brown outer contour.
The whole cat is clean and neatly brushed, the perfect underlying surface revealed when messy fur modules are removed. Back locks and gray bands should flow smoothly from head toward tail; cream cheek/chest/belly remain softly fluffy but orderly. Do NOT add dirt, dark mud, knots, fleas, loose fur or stray flyaway spikes. Avoid noisy individual realistic hairs.
Palette locked to reference: warm taupe grays around RGB(168,152,137) and deeper gray-brown shading; cream around RGB(253,247,235) with soft beige shading; outer line deep brown around RGB(33,8,3). Keep neutral reference colors, no green, orange, bluish gray, white glow or ambient room tint.
A complete clean cat, generous torso area for overlay sprites, all ears/paws/tail tips within canvas. Wide 16:9 sheet, visible cat fills approximately 85% width and 82% height, identical left-facing standing pose. True transparent alpha outside silhouette, no ground shadow or checkerboard baked in. No UI, text, labels, border, watermark, scenery or tools. This is one standalone base sprite, not a sprite sheet.
```

## 顺毛底图修整（实际采用）

```text
Edit ONLY the cat's fur grooming state in image 1, using image 2 as the TIDY reference. This output is the CLEAN UNDERLYING CAT used beneath removable messy fur layers.
Image 1 must become clearly TIDIER than it currently is: REMOVE the ragged upward-pointing spikes across the top of the back and along the rear flank. Make the back outline one smooth softly curved line from shoulder to rump. Replace disordered jagged back locks with broad orderly gray fur stripes/locks all swept smoothly to the right toward the tail. Remove stray projecting spikes from cheeks and tail. Use modest smooth fluffy scallops on cheeks/belly rather than chaotic star-shaped tufts. The raised curled tail has an orderly continuous rounded fluffy outline, not a jagged burst. It is still a chubby long-haired cat, not hairless, but unmistakably BRUSHED.
Preserve the same gray/taupe and cream palette exactly, same eyes/nose/ear colors, pose, paws, cat placement, scale and transparent canvas. Keep dark brown outer line, soft simple shading and illustrated paper-sprite style. Entire cat only, true transparent background, no room, floor, table, shadow, UI, text or tools.
VERY IMPORTANT: body back and rump silhouette should be clean and smooth enough that additional separate jagged edge sprites can later create the untidy state. No spiky rough dorsal fringe is allowed in this clean base.
```

## 身躯模块

```text
Game production PNG atlas, TRUE transparent background. Match the supplied gray-and-cream cat EXACTLY in palette and 2D painted paper-sprite shading: warm taupe RGB around (168,152,137), darker warm gray-brown shades and ivory RGB around (253,247,235), warm beige shadow. No bluish gray, orange, green, mud, grime, brown dirt blobs, glossy realistic hairs or text. Transparent margins between all sprites. Use a precise equal-cell grid, no drawn grid lines, no captions/numbers/borders, centered sprites within cells with at least 15% padding.
One atlas of TWELVE modular untidy BODY FUR PATCH sprites, FOUR COLUMNS x THREE ROWS. These are small overlapping interactive fur tiles arranged on a clean cat body like fish-scale modules, each tile disappears as one whole object after a correct comb stroke. They must read as CAT HAIR, not debris or mud.
Row 1, cells left to right: taupe-gray short ruffled tuft; taupe-gray wide tousled tuft; taupe-gray upward folded tuft; taupe-gray sideways crossed tuft.
Row 2: four matching variants in cream-white for belly and chest.
Row 3: four gray-and-cream transition tufts with different gentle mixes for stripe boundaries.
Each patch is a small flat overlapping cluster of 3–6 pointed wisps/locks, with a soft blending upper attachment edge and a clearly ragged lower/right tuft edge. Flat broad reference-color fills with restrained soft shading. Thin darker taupe interior crease accents ONLY; DO NOT put a thick dark brown sticker outline around every body tile. No round fluffy balls, no knots (knots are separate), no detached random dots. Same drawing scale across variants. All 12 isolated on transparency, no cat body under them. Wide 4:3-ish sheet composition aligned to the 4x3 grid.
```

## 轮廓毛条

```text
Game production PNG atlas, TRUE transparent background. Match the supplied gray-and-cream cat EXACTLY in palette and 2D painted paper-sprite shading: warm taupe RGB around (168,152,137), darker warm gray-brown shades and ivory RGB around (253,247,235), warm beige shadow. No bluish gray, orange, green, mud, grime, brown dirt blobs, glossy realistic hairs or text. Transparent margins between all sprites. Use a precise equal-cell grid, no drawn grid lines, no captions/numbers/borders, centered sprites within cells with at least 15% padding.
One atlas of EIGHT modular ROUGH SILHOUETTE EDGE strips, FOUR COLUMNS x TWO ROWS. Used to assemble an upper ragged fur contour layer over the clean cat; comb erases only touched parts of these strips to reveal the tidy silhouette below.
Top row: four taupe-gray ragged contour strips for shoulder, dorsal back, side flank and gray tail. Bottom row: four cream ragged contour strips for cheek/chest, cream belly, leg fringe and cream tail tip.
Each asset is an elongated jagged strip with multiple outward unruly hair spikes on ONE long side. The other long side is a quiet soft feathered attachment area that lies over matching clean fur. Outer exposed hair tips have the cat's dark brown outline; the inward attachment edge must NOT have a black/dark sticker border. Attach edge lower, ragged tips above, so users can rotate the strips to align around silhouette. Isolated strips, not oval full body shapes or complete cats. No locks floating disconnected around strips. Consistent width and shading. All 8 assets true alpha transparency, generous cell gutters.
```

## 特殊对象

```text
Game asset atlas on TRUE transparent background, SIX isolated sprites in THREE COLUMNS x TWO ROWS. Match the supplied cat's warm taupe gray / cream and dark brown contour 2D paper-sprite style. No labels, grid lines, UI, border, shadows, background scene or whole cats. Generous transparent gutters.
TOP ROW left to right:
1. A small taupe-gray TANGLED FUR KNOT, a compact flat cluster of crossed/interwoven pointed locks, recognizable as the same cat hair. Not a rope, mud splat or fluffy ball.
2. A matching cream-white tangled fur knot, same shape family and reference shading.
3. A tiny cartoon SPACE FLEA: dark warm brown oval insect, simple little legs, oversized mischievous eyes, clean readable silhouette. Visually an insect rather than a fur knot; funny, not photorealistic or grotesque. No glow or colorful aura.
BOTTOM ROW left to right:
4. A small LIGHT GRAY-BEIGE DUST PATCH: a few thin powder smudges and soft dots, with plenty of transparent holes. Must look like a minor localized special object, not thick dark mud covering the cat.
5. A small CREAM-BEIGE DUST PATCH, similarly sparse, for cream fur.
6. The same flea in a compact poised-to-hop pose, matching top-right identity and scale, no motion streak painted into background.
Palette: cat-related fur gray RGB about (168,152,137), cream (253,247,235), darker warm taupe and beige shadows. Knots use ONLY these fur tones; do not make them orange, blue or green. Fleas use restrained reference outline browns. All sprites complete, separate, centered inside cells with approximately 20% margins. Flat smooth illustrated fills and a few internal lock accents. No black boxes, white matte, checkerboard or stray pixels in gutters; outside sprite shape fully transparent.
```

## 脱落表现

```text
Create one TRUE transparent-background game VFX sprite atlas with EIGHT isolated falling/peeling FUR sprites, FOUR COLUMNS x TWO ROWS. Match the reference cat's same 2D paper-sprite style and exact warm taupe-gray and cream palette. No background, floor, glow, shadow, labels, text, numbers, drawn grid lines or motion trails.
Purpose: when a correct comb stroke removes a body fur tile, the WHOLE small tile pops off and falls briefly. These sprites should look like detached folds of that same cat's coat, not mud, coins, hairballs or cotton balls.
Top row:
1 taupe-gray small folded tufty patch, bent slightly;
2 taupe-gray elongated patch curled upward;
3 mixed gray/cream detached tuft, slight rotation;
4 a small group of 2–3 taupe-gray hair wisps.
Bottom row:
1 cream-white counterpart to top-left;
2 cream-white elongated curled patch;
3 mixed cream/gray detached tuft, another mild angle;
4 small group of 2–3 cream-white hair wisps.
Use broad simple pointed hair-lock shapes with soft reference shading and a few thin warm darker crease accents. Avoid thick dark sticker borders around internal detached patches; do not add any saturated colors. Gray roughly RGB(168,152,137), cream roughly RGB(253,247,235), only their existing lighter/darker shading. Uniform sprite scale, each inside an equal grid cell with at least 20% transparent margins, separated.
Only these eight sprites with clean alpha edges and fully transparent outside. No whole cats, no insects or dirt.
```
