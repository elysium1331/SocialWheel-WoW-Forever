# Icon request: SocialWheel batch 1

Generate 9 original icons using your image generation tool and save each one as a
PNG at `art/source/raw/<key>.png`, relative to the current working directory.
Create the folder if it doesn't exist. Change no other files.

## Where the icons are used

A World of Warcraft addon shows emotes on a radial wheel. Each icon sits inside a
dark circular slot (near-black, #17140f) with a thin muted-gold ring, and is
displayed at **40–64 pixels**. The circle mask crops the corners, so keep the
subject centered inside a circle covering about 80% of the canvas.

## Style (identical for all 9)

- Restrained fantasy, painterly but simple. One bold symbol per icon, readable as a silhouette at 40 px.
- Palette: warm ivory and parchment for the main shapes, bronze or muted-gold accents, plus one small saturated accent color per icon (listed below).
- Soft light from the top-left with a subtle warm rim light. Clean edges, minimal texture noise, no photorealism.
- Same line weight, framing, scale and visual weight across the whole set, so they look like one family.
- **Transparent background.** If transparency isn't possible, use a flat pure-black background with nothing else.
- Square, 1024 × 1024 (or the tool's native square size).

## Hard rules

- No text, letters, numbers, labels, borders, rings, frames, badges or logos.
- Original artwork only: don't imitate or reference World of Warcraft icons, Blizzard art, faction crests or any existing icon set.
- Hands must look natural: correct finger count, no extra fingers.

## The icons

| key | subject | accent color |
|---|---|---|
| hello | A speech bubble with a small raised open palm inside it: a spoken greeting. It must not look like a waving hand alone. | soft sky blue |
| thank | Two hands pressed palm to palm in a gesture of thanks, with a small warm glowing heart just above the fingertips. Gratitude, not prayer. | rose |
| wave | One open hand tilted mid-wave with two curved motion arcs beside it. No speech bubble. | soft sky blue |
| point | A hand with the index finger extended, pointing up and to the right, with a short dashed arc or arrow continuing the direction. | amber |
| laugh | A round, friendly laughing face: eyes squeezed shut in crescents, wide open smiling mouth, two small tears of joy. Simple and cartoon-friendly, not creepy. | warm yellow |
| cheer | Two raised fists or open arms thrown up in celebration, with a small burst of sparkles or confetti above. | gold and crimson confetti |
| _generic | An empty ornate speech bubble with three dots inside (a neutral "emote" symbol). | none (ivory and gold only) |
| _category_emotes | A small stylized figure in a joyful expressive pose (arms out, one leg lifted), as a full-body silhouette. | teal |
| _category_voice | A stylized open mouth or small herald's horn emitting three curved sound waves. | violet |

## Must stay distinct at 40 px

- **hello vs wave:** a speech bubble is the defining shape of hello; motion arcs and no bubble define wave.
- **thank vs cheer:** hands together and low versus arms raised high.
- **_generic vs hello:** the generic bubble has dots and no hand.

## When finished

Reply with:
- the list of files written
- the image model or tool name and version you used
- the exact prompt you used for each icon
