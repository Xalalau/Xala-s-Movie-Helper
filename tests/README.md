# XMH client regression checks

## Run

From the addon root:

```sh
python3 tests/run.py
```

Requirements: Python 3.9+ and one of `lua5.4`, `lua5.3`, `lua`, `luajit`, or
`texlua` on PATH. No third-party Python packages are needed.

To compare against a separately extracted original addon:

```sh
python3 tests/run.py --source /path/to/original/xalas-movie-helper
```

The runner creates a temporary copy and normalizes GLua operator aliases outside
strings and comments. It never rewrites the installed addon. The Lua harness
loads the actual client files into isolated environments, records console
commands, simulates the two reported blocked commands, captures dialogs, and
exercises menu builders, the synchronization callback, Defaults, and CalcView.

## Results for this patch

47 checks passed: 5 syntax checks and 42 regression checks. The unchanged
original commit `7bfcb276762a8dd4c083fba3494fc858ae8e0dfc` passed 8 and failed 39
of the same checks. Some failures assert new behavior or the new version;
this is not a claim that the original addon had 39 independent bugs.

Coverage includes both supported languages, the four former `showconsole`
call sites, blocked shadow checkbox binding, Defaults with cheats on/off,
manual shadow instructions with the current value, FOV changes to 178/100,
FOV opt-in and camera separation, the existing flashlight command proxy,
all four shadow resolutions, absent/removed panels, invalid selections,
case-sensitive loader paths, and the Information panel revision.

## Limits

These are simulated API tests, not a Garry's Mod or LuaJIT-in-engine session.
The standalone Lua runtime does not reproduce renderer behavior, VGUI layout,
network traffic, mounted Workshop content, server policies, or real multiplayer.
The unchanged server file contains GLua `continue` and is deliberately excluded
from stock-Lua parsing and execution. Five client/shared/loader files are parsed.
The Lua 5.3/5.4 distinction between integers and floats is tolerated where a
command argument represents a number; the shipped GLua source is preserved.

## In-game checklist (not executed here)

- Restart with only one XMH copy loaded; confirm Information shows Rev.25.6 and the text editor opens.
- In English and Portuguese, open the pedestrian, lip-sync, crosshair, and shadow-resolution help. Confirm readable dialogs and no `showconsole` error.
- Open Shadows, click Matching shadows, and manually run either displayed command. Reopen the instructions to check the current value. Use Defaults with `sv_cheats` set manually to 0 and 1; confirm no blocked-command error.
- Enable the existing general FOV option, change the slider to 178, and reset to 100. Confirm the view changes without numeric unknown commands. Check a GMod camera separately.
- Check current shadow-resolution preselection, change to a different supported value, and apply twice. Run `xmh_shadowres` before opening its panel in a fresh session. Avoid unnecessarily large textures when checking this manually.
- Check a multiplayer session and a case-sensitive server installation; validate module distribution and client menus.

## API references

The implementation follows the Facepunch documentation for Blocked ConCommands,
Derma_Message, DComboBox:GetSelected (text first, stored data second), and
DComboBox:AddChoice (third argument selects the option). The documentation was
checked on 2026-09-07. No workaround attempts to bypass the engine command block.
