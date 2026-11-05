# 猫猫贴纸素材

日期：2026-11-05。内置资源 `character.png`：1254 × 1254 RGBA PNG，Alpha 范围 0–255，独立角色，无底板、文案和倒计时。通过内置 image_gen 工具生成，原稿保留在用户 `.codex/generated_images/01a1a5a1-bb27-7170-b70f-93bb20578b88/exec-fe9cc28a-0378-461b-8f99-9e6375522cc5.png`，项目直接复制，未裁切或重绘。

## 生成提示词

Use case: stylized-concept. Asset type: independent transparent PNG mascot for a desktop countdown sticky-note app named Shiyu. Create exactly one charming 2D hand drawn chibi cream and soft apricot tabby cat, full body, large round head, tiny rounded paws resting forward as if leaning on a note edge, small curved tail, warm dark cocoa pencil outlines with subtle irregular hand-drawn line quality, flat warm pastel fills, delicate peach cheek blush, peaceful eyes and tiny friendly smile. Cozy Japanese stationery sticker illustration, tasteful restrained cute, no 3D. 1024x1024 square canvas, centered full cat with all ears/tail/paws intact and generous transparent margin. Actual alpha transparent background. ONLY cat and its own thin cream sticker-cut outline. NO card, no paper, no text, no numbers, no UI, no background, no shadow ground, no extra objects. Intended to appear about 150px wide above a live countdown, crisp readable silhouette.

工具实际输出尺寸为 1254 × 1254，应用等比显示。后期可在应用外观目录以同名 PNG 替换角色；标题和倒计时始终动态呈现，不嵌入位图。

## 四个窗口姿态

新增三张图片以坐姿猫 `character.png` 为造型参考，由内置 imagegen 工具生成。项目直接复制 1254 × 1254 的 RGBA 原稿。各图独立透明，Alpha 范围为 0–255，完整保留角色轮廓。原稿位于 `.codex/generated_images/01a1a5a1-bb27-7170-b70f-93bb20578b88/`。

| 窗口 | 姿态 | 内置资源 | 原稿 |
| --- | --- | --- | --- |
| 1 | 坐姿 | `character.png` | `exec-fe9cc28a-0378-461b-8f99-9e6375522cc5.png` |
| 2 | 伸懒腰 | `character-stretch.png` | `exec-a8f41247-f4d2-4fea-9fdf-3d5593988bfc.png` |
| 3 | 挥爪 | `character-wave.png` | `exec-461749ee-feb6-4cbe-a664-b820bbbe976f.png` |
| 4 | 蜷睡 | `character-sleep.png` | `exec-e6ae63fd-5e26-46c0-8c71-337f2614b150.png` |

替换某个窗口时，在应用素材目录使用对应的 `character-1.png` 至 `character-4.png`。旧的 `character.png` 仍可替换主窗。配色、倒计时和设置图标由应用实时绘制。

### 新姿态生成提示词

- 伸懒腰 · Use case: illustration-story. Isolated PNG mascot sprite for a desktop countdown floating window. Use the local reference as a character and rendering reference for the SAME chibi orange tabby: oversized round cream face, orange forehead and cheek stripes, warm chocolate textured linework, soft peach watercolor/pastel coloring, rosy cheeks, thin pale cream die-cut sticker rim, tiny body. New pose: playfully stretching forward in a clear play-bow, both front paws extended along an invisible baseline toward the viewer’s left, shoulders lowered, rump raised on the right, tail lifted in a gentle curve. Three-quarter side view and a distinctly diagonal silhouette. Exactly one full kitten. Bold clean shapes recognizable at 70 pixels, centered in a square canvas, large subject with even transparent margins, preserve ears, paws, whiskers and full tail. True transparent background. No text, sparkles, props, ground, shadow, scene, card or extra figures.
- 挥爪 · Use case: illustration-story. Isolated PNG mascot sprite for a desktop countdown floating window. Use the local reference as a character and rendering reference for the SAME chibi orange tabby: oversized round cream face, orange forehead and cheek stripes, warm chocolate textured linework, soft peach watercolor/pastel coloring, rosy cheeks, thin pale cream die-cut sticker rim, tiny body. New pose: sitting upright and waving with one clearly lifted front paw beside the face, little pink paw pads visible, one eye winking, head slightly tilted, other front paw stays on the floor and a little curved striped tail. A visibly asymmetric upright silhouette. Exactly one full kitten. Bold clean shapes recognizable at 70 pixels, centered in a square canvas, large subject with even transparent margins, preserve ears, paws, whiskers and full tail. True transparent background. No text, sparkles, props, ground, shadow, scene, card or extra figures.
- 蜷睡 · Use case: illustration-story. Isolated PNG mascot sprite for a desktop countdown floating window. Use the local reference as a character and rendering reference for the SAME chibi orange tabby: oversized round cream face, orange forehead and cheek stripes, warm chocolate textured linework, soft peach watercolor/pastel coloring, rosy cheeks, thin pale cream die-cut sticker rim, tiny body. New pose: curled up asleep in a compact round ball, chin nestled on its front paws, both closed eyelids with downward relaxed arcs, striped tail wrapping around the body. Side/three-quarter view. A low and unmistakably horizontal silhouette. Exactly one full kitten. Bold clean shapes recognizable at 70 pixels, centered in a square canvas, large subject with even transparent margins, preserve ears, paws, whiskers and full tail. True transparent background. No text, sparkles, props, ground, shadow, scene, card or extra figures.
