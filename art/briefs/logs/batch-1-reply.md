Wrote these nine files in `art/source/raw/`:

`hello.png`, `thank.png`, `wave.png`, `point.png`, `laugh.png`, `cheer.png`, `_generic.png`, `_category_emotes.png`, `_category_voice.png`.

All nine are square 1254 × 1254 PNGs with transparent alpha. The tool used its native square size. The image tool was **OpenAI’s built-in `image_gen`**; it did not expose a model version.

The exact prompt for each icon consisted of the common text below, with its `Primary request:` line inserted after `Asset type:` and any listed constraint addition appended to the final `Constraints:` line.

```text
Use case: stylized-concept
Asset type: World of Warcraft addon radial emote wheel icon, one of nine original matching icons
Primary request: [icon-specific line below]
Style/medium: restrained fantasy, painterly but simple; one bold silhouette-readable symbol, clean edges, minimal texture noise, no photorealism. Warm ivory and parchment main shapes with bronze or muted-gold accents.
Composition/framing: centered within a circle covering about 80% of a square 1024 x 1024 canvas, consistent line weight and visual weight with a nine-icon family, readable at 40 pixels. Corners clear for a circular crop.
Lighting/mood: soft light from top-left, subtle warm rim light.
Background: genuinely transparent alpha.
Constraints: original artwork only; no text, letters, numbers, labels, borders, rings, frames, badges, logos, World of Warcraft icon imitation, Blizzard art imitation, faction crests, or existing icon set imitation.[icon-specific addition below]
```

| File | Exact `Primary request:` text | Exact constraint addition |
|---|---|---|
| `hello.png` | A speech bubble with a small raised open palm inside it: a spoken greeting. The speech bubble must be the defining outer shape; it must not read as a waving hand alone. Soft sky blue accent. | ` Natural hand with correct finger count, no extra fingers.` |
| `thank.png` | Two natural hands pressed palm to palm in a gesture of thanks, held low in the composition, with a small warm glowing rose heart just above the fingertips. Convey gratitude rather than prayer. | ` Natural hands with correct finger count, no extra fingers.` |
| `wave.png` | One natural open hand tilted mid-wave, with two curved motion arcs beside it. Soft sky blue accent. No speech bubble. | ` Natural hand with correct finger count, no extra fingers.` |
| `point.png` | A natural hand with the index finger extended, pointing up and to the right, with a short dashed amber arc or arrow continuing the direction. | ` Natural hand with correct finger count, no extra fingers.` |
| `laugh.png` | A round, friendly laughing face with eyes squeezed shut in crescents, a wide open smiling mouth, and two small tears of joy. Warm yellow accent. Simple and cartoon-friendly, not creepy. | None |
| `cheer.png` | Two raised fists or open arms thrown up high in celebration, with a small burst of gold and crimson sparkles or confetti above. Clearly different from hands pressed together. | ` Natural hands with correct finger count, no extra fingers.` |
| `_generic.png` | An empty ornate speech bubble with exactly three dots inside, a neutral emote symbol. Ivory and muted gold only, with no saturated accent. No hand. | None |
| `_category_emotes.png` | A small stylized full-body figure in a joyful expressive pose, arms out and one leg lifted, as a bold silhouette. Teal accent. | None |
| `_category_voice.png` | A stylized open mouth or small herald's horn emitting three curved sound waves. Violet accent. | None |