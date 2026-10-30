# VEIL CIRCUIT — Visual Asset Sources

## Current pass

The current night-city pass uses original GDScript-generated MultiMesh geometry and four project-authored Godot spatial shaders:

- `shaders/city_asphalt.gdshader` — fine asphalt grain and restrained surface variation.
- `shaders/city_concrete.gdshader` — concrete panel joints and subtle surface noise.
- `shaders/city_facade.gdshader` — facade panel seams and per-building colour variation.
- `shaders/city_metal.gdshader` — brushed painted-metal detail.

No external image or model is downloaded at runtime. This keeps the current build self-contained and avoids blindly importing large texture archives.

## CC0 libraries reviewed for future use

These are resource libraries, not assets already bundled in this pass. Each individual item should be checked again before it is added to the repository.

- **Poly Haven** — textures, HDRIs and models. Its published asset licence is CC0; attribution is not required, though appreciated. Licence: https://polyhaven.com/license
- **ambientCG** — PBR materials and surface scans. The site publishes its asset library under CC0 1.0. Source: https://ambientcg.com/

## Mobile import rules

For the 4 GB Android target:

1. Prefer 512 px or 1K maps for visible hero surfaces; do not bundle 4K/8K maps by default.
2. Import only the maps actually used (usually base colour, normal and roughness; add AO only when it produces a visible benefit).
3. Keep normal maps in OpenGL convention for Godot unless an importer conversion is explicitly configured.
4. Use mipmaps and platform texture compression; check APK size and runtime memory after every texture batch.
5. Keep the game playable offline; no runtime asset downloads, paid APIs, subscriptions, or paid asset packs.

## Attribution

The shaders and visual-pass code in this repository are original project code. No Poly Haven or ambientCG image files are claimed as integrated by the current visual pass.
