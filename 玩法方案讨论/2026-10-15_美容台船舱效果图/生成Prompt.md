# 船舱美容台效果图生成Prompt

生成方式：内置 imagegen。第一张以用户房间和猫咪参考合成，第二张以第一张作为编辑对象、整洁猫作为形象参考，只修改毛发状态。

## 杂乱待梳理

```text
Use case: compositing / game scene concept mockup.
Create ONE widescreen 16:9 in-game scene mockup for Purr Orbit, based on the three supplied images.
Input roles: image 1 is the room/background composition and visual-style reference, but REMOVE its original orange calico cat entirely. Image 2 is the SAME new gray-and-cream long-haired cat in its tidy state. Image 3 is the new cat's untidy coat reference; use this UNTIDY state for this output.
Primary requirement: a real ROOM with visible depth surrounding a freestanding veterinary-style grooming table at its center. Do not replace the whole background with a leather surface. Retain the ship interior from reference 1: bronze/taupe metal back wall, large framed space window with planet and stars, angled sidewalls, metal floor receding into the distance, small warm amber wall and floor lights, dark brown illustrated outlines. Room geometry and floor perspective must be legible around and beneath the table.
Table: a broad rectangular grooming examination table, veterinary inspection-table construction. Thick padded brown leather TOP with subtle leather grain, stitched edge and rounded corners. Beneath it a visible silver-gray metal apron, sturdy height-adjustable metal pedestal/support and wide low metal base standing on the ship floor. Both top surface and support/base must be visible. Three-quarter frontal, gently elevated fixed game camera; top is a perspective trapezoid. Keep natural shadows under the base and at all four cat paws.
Character: EXACTLY ONE cat, matching image 3's design very closely: squat chunky gray/taupe and cream-white long-haired cat, dark brown thick outline, simple vertical dark eyes, small dark nose and whiskers, pink inner ears, gray striped back, fluffy raised curled tail with white tip. Four paws stand ON TOP of the leather surface. Head at left, tail at right. Untidy fur is irregular tufts and tousled clumps, especially back, cheeks, belly and tail, NOT dark mud pasted onto its body. Preserve gray and cream color identity; no orange patches. Cat should look like the provided hand-drawn 2D paper sprite, not a realistic or volumetric 3D cat.
Composition: table spans roughly 70% of frame width; cat roughly 43-48% frame width, visually dominant and large enough to groom. Cat centered over table, all paws visibly supported; table legs/base fully within lower frame. Leave enough floor foreground and sidewalls to read depth. Space window/back wall behind the cat; no extra cats, no people.
Style: unified warm-shaded cartoon pseudo-3D room and table, with a flat illustrated paper-sprite cat. Match the references' restrained metal palette and brown contour lines. Fixed game-camera image, not a cinematic poster. Crisp readable contours, softly shaded surfaces, no dramatic blur.
Output: one complete untreated/untidy reference frame. NO text, NO labels, NO HUD, NO split screen, NO comb, NO hand, NO cursor, NO watermark, NO veterinary restraint arm, NO medical procedure. These are scene-and-character appearance references; show the whole table and room.
```

## 整洁完成

```text
Use case: precise-object-edit, matched game reference frame pair.
Image 1 is the EXACT scene to edit. Image 2 is the exact tidy gray long-haired cat design to match.
Edit ONLY the cat in image 1 from UNTIDY to TIDY, following image 2. Keep the whole ship room, planet window, perspective, amber lights, leather grooming table top, seams, metal pedestal/base, all geometry, colors, shadows, lighting, camera, crop and resolution unchanged.
The same cat remains standing with four paws on exactly the same place on the leather table, same head-left/tail-right pose, same overall scale, same face, same identity and gray/cream markings. Replace the messy spiky tufts and disordered fur clumps with the orderly brushed fluffy locks of image 2: soft continuous flowing cheek fur, neatly arranged gray back stripes/locks, tidy cream belly and a well-brushed raised curled tail with cream tip. Still a long-haired fluffy cat, never turn it into a smooth short-haired cat. Same simple cartoon facial features and thick dark brown outlines; no shiny realistic hair.
Preserve exact tabletop and floor contact. No cat duplication, no humans, no tools, no cursor, no UI, no text, no watermark. One whole 16:9 in-game room frame matching image 1. This is the tidy AFTER-service counterpart to the first image, not a new composition.
```
