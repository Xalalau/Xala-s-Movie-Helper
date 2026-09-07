# Changelog

## Rev.25.6 — 2026-09-07

- Replaced blocked `showconsole` calls with translated help dialogs, while keeping the existing console output.
- Changed Matching shadows to a manual console action instead of binding a checkbox to the blocked `r_shadowrendertotexture` ConVar.
- Excluded Matching shadows from automatic Defaults resets and explained the manual enable/disable commands in English and Portuguese.
- Fixed the general FOV setting incorrectly executing its numeric value as a console command, including `178` and `100`.
- Fixed shadow resolution selection to use the option's numeric data instead of its display label.
- Preselected the current supported shadow resolution and handled missing, invalid, or closed selections without errors or debug `nil` output.
- Corrected the text editor include and distribution paths to match the shipped lowercase filename.
- Updated the Information panel to `XMH.Rev.25.6 - 07/09/2026 (dd/mm/yyyy)`.

The patch does not supply missing map/model textures, change shaders or fonts,
or modify other addons. Garry's Mod was not available for an in-game test;
see `tests/README.md` for the isolated checks and the remaining manual checklist.
