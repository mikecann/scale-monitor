# Agent guidance for scale-monitor

This repo contains a Windows PowerShell WinForms popup for changing one monitor's DPI scaling. Source files live at the repo root. `install.ps1` creates two silent-launch shortcuts, and `uninstall.ps1` removes only shortcuts still pointing at this clone.

## Key rules

- Never put source files in `C:\dev\tools`. Only installer-generated shortcuts or stubs belong there. All logic stays in this repo.
- Large binaries belong in `C:\dev\tools`, never in Git. Do not commit `.exe` or `.dll` files. This tool currently needs no external binaries or packages.
- Use test-first development for non-trivial changes. If there is no clean test seam, extract one first and add a test.
- When behaviour changes, update relevant expectations and rerun the tests, including changes to UI copy, layout, startup or tested contracts.
- Test before committing. Run the checks below, then smoke-test on Windows with PowerShell and `wscript.exe`. Check exit codes. A macOS parse check does not prove WinForms, registry or DPI behaviour.
- No console windows for GUI/taskbar launches. Shortcuts must launch `scale-monitor.vbs` through `wscript.exe`. The VBS wrapper uses window style 0 to hide PowerShell. Do not point taskbar shortcuts straight at PowerShell or the `.bat` wrapper.
- Keep `.bat` files ASCII. Generated batch files must use `-Encoding ASCII`.
- Editing source does not require reinstalling, because shortcuts point at the live clone. Re-run `install.ps1` when moving the clone or changing installer behaviour.
- Keep install/uninstall repeatable and preserve other tools' files. This tool has no Explorer context-menu verbs, shared submenu, generated icons, PATH changes or API keys.
- If dependencies are added, put their checks in a self-contained, idempotent root `deps.ps1` and invoke it from `install.ps1`. Check before installing, show clear output, and print instructions for large manual-download binaries.
- No em dashes or en dashes in documentation. Keep writing plain and personal. Do not add UI eyebrows or kickers.

## scale-monitor specifics

- Monitor: HG584T05, "Display 4", AMD Radeon Graphics.
- Registry key: `HKCU:\Control Panel\Desktop\PerMonitorSettings\RTK8405_0C_07E9_97^C9A428C8B2686559443005CCA2CE3E2E`.
- `DpiValue = 4` gives 200% scaling (normal use).
- `DpiValue = 7` gives 300% scaling (filming).
- The script modifies the registry, broadcasts `WM_SETTINGCHANGE`, then calls `ChangeDisplaySettingsEx("\\.\DISPLAY4", CDS_RESET)` to apply live.
- The current popup also offers `DpiValue = 8` (350%) and `DpiValue = 9` (400%). These mappings and the monitor identity are specific to Mike's setup.
- Do not change monitor settings as part of installer tests. Registry and live display checks require the user's intended monitor on Windows.

## Verification

```powershell
pwsh -NoProfile -File .\scripts\check-syntax.ps1
pwsh -NoProfile -File .\tests\install.Tests.ps1

# Windows smoke tests:
powershell -NoProfile -ExecutionPolicy Bypass -File .\scale-monitor.ps1
wscript.exe .\scale-monitor.vbs

# Refresh shortcuts after moving the clone:
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

The automated tests fake `WScript.Shell` and use temporary files. They verify shortcut targets, quoting, repeat installs/uninstalls and preservation of unrelated or repointed shortcuts. CI uses Windows PowerShell 5.1 to check compatibility with the actual launcher host.
