# NVpoSH
A battery-included Neovim distribution optimized for the **PowerShell ecosystem**.

## Why Use This Config?

**Problem:** VS Code is heavy, requires a GUI, and consumes significant memory. It is often unusable on restricted servers or slow VPN connections.

**Solution:** `psh-nvim` provides the **VS Code feature set** inside a lightweight terminal environment:

1.  **IntelliSense:** Same underlying engine as VS Code (PowerShell Editor Services).
2.  **Debugging:** Same DAP protocol.
3.  **Keybinds:** Mapped for efficiency and reduced RSI.
4.  **Portability:** Clone and run on any machine (Windows/Linux/Mac) in seconds.

## Quick Start (Automated Install)
The included setup.ps1 script backs up your existing configuration and deploys PoSH-Nvim. On Windows, it also automates dependency installation.

**Windows**

Setup.ps1 Automatically installs all prerequisites via winget (Neovim, Git, Node, LazyGit, Zig, Ripgrep, FD) and installs a patched Nerd Font. 
(see below) for manula install options.

Open PowerShell as Administrator.

Run the following:
```powershell
git clone https://github.com/stevenservo-hub/PoSH-Nvim.git
cd PoSH-Nvim
.\setup.ps1
```

**Linux**
**Note:** Ensure PowerShell (pwsh) is installed. You must install system dependencies (Neovim, Git, etc.) manually via your package manager.

```bash
git clone https://github.com/stevenservo-hub/PoSH-Nvim.git
cd PoSH-Nvim
pwsh ./setup.ps1
```

**All Platforms:** Backs up your existing configuration (e.g., ~/.config/nvim.bak.TIMESTAMP) and deploys the new init.lua and usersettings to the correct directory.

## Manual Installation
If you prefer to configure your environment manually, or if you are on Linux, ensure you have the following prerequisites installed and available in your PATH before copying the configuration files.

1. Prerequisites

| Requirement | Windows (Winget) | Linux (Ubuntu/Debian) | Linux (Fedora/RHEL) |
| :--- | :--- | :--- | :--- |
| **Neovim** (v0.9+) | `Neovim.Neovim` | `neovim` | `neovim` |
| **Git** | `Git.Git` | `git` | `git` |
| **NodeJS** (For AI) | `OpenJS.NodeJS.LTS` | `nodejs npm` | `nodejs npm` |
| **LazyGit** (Git UI) | `JesseDuffield.LazyGit` | [See LazyGit Docs](https://github.com/jesseduffield/lazygit) | `lazygit` |
| **RipGrep** (Search) | `BurntSushi.ripgrep.MSVC` | `ripgrep` | `ripgrep` |
| **FD** (Finder) | `sharkdp.fd` | `fd-find` | `fd-find` |
| **C Compiler** | `zig.zig` | `build-essential` | `gcc` |

2. Fonts
**Nerd Font:** Required for file icons and status bar glyphs to render correctly.
**Recommendation:** Download a Nerd Font here (e.g., JetBrains Mono Nerd Font) and install it on your system.

3. Deployment
Once prerequisites are met, copy the contents of this repository (excluding the .git folder) to your Neovim configuration directory:

Windows: $env:LOCALAPPDATA\nvim

Linux: ~/.config/nvim
## Post-Install Checks
1. Open Neovim.
2. Run `:checkhealth` to verify all providers (Node, Git, Python) are detected.
3. Run `:Copilot auth` to sign into GitHub.
4. Run `:Lazy` to check plugin status.

## Custom Keymap Reference
**Leader Key:** `-` (Dash)

### Intellisense (LSP & Autocomplete)
| Key | Mode | Action |
| :--- | :--- | :--- |
| `gd` | Normal | **Go to Definition** (Jumps to function/cmdlet source) |
| `K` | Normal | **Hover Doc** (Shows cmdlet syntax/help popup) |
| `Tab` | Insert | **Autocomplete Menu** (Select next list suggestion) |
| `S-Tab` | Insert | **Autocomplete Back** (Select previous list suggestion) |

### AI (GitHub Copilot)
| Key | Mode | Action |
| :--- | :--- | :--- |
| `Alt + l` | Insert | **Accept Ghost Text** (Commits the gray inline suggestion) |
| `Alt + ]` | Insert | **Next Suggestion** (Cycle forward through ghost text options) |
| `-cc` | Normal | **Toggle Chat** (Opens the floating Copilot window) |
| `-ce` | Normal | **Explain Code** (Ask Copilot to explain selection/cursor) |
| `-cf` | Normal | **Fix Code** (Ask Copilot to fix bugs/errors in selection) |
| `-cr` | Normal | **Reset Chat** (Clear conversation history) |

### Neo-Tree
| Key | Mode | Action |
| :--- | :--- | :--- |
| `-e` | Normal | **Switch between Neo Tree and the editor** |
| `Shift + H` | Normal (while focusing neo-tree) | **Show hideden files** |
| `Shift + P` | Normal (while focusing neo-tree) | **Preview files before opening** |

### Git Management (LazyGit)
| Key | Mode | Action |
| :--- | :--- | :--- |
| `-gg` | Normal | **Open LazyGit Dashboard** (Full TUI for Staging/Commits/Push) |

### Core & UI
| Key | Mode | Action |
| :--- | :--- | :--- |
| `-e` | Normal | **Switch between Neo Tree and the editor** |
| `-h` | Normal | **Clear Highlights** (Removes search highlighting) |
| `-r` | Normal | **Toggle Relative Numbers** (Switches relative/absolute) |
| `-n` | Normal | **Enable Line Numbers** (`set number`) |
| `-nn` | Normal | **Disable Line Numbers** (`set nonumber`) |
| `-m` | Normal | **Enable Mouse** (Click/scroll enabled) |
| `-mm` | Normal | **Disable Mouse** (Pure keyboard mode) |
| `jj` | Insert | **Escape** (Instant exit from Insert Mode) |

### Window Managment
| Key | Mode | Action |
| :--- | :--- | :--- |
| `-v` | Normal | Vertical Split |
| `-h` | Normal | Horizontal Split |
| `Ctrl+h`| Normal | Move to Left Window |
| `Ctrl+j` | Normal | Move to Lower Window |
| `Ctrl+k` | Normal | Move to Upper Window |
| `Ctrl+l` | Normal | Move to Right Window |
| `Alt+Up` | Normal | Increase Window Height |
| `Alt+Down` | Normal | Decrease Window Height |
| `Alt+Left` | Normal | Decrease Window Width |
| `Alt+Right` | Normal | Increase Window Width |
| `-q` | Normal | Close current split |
| `-tn` | Normal | New Tab (Workspace) |
| `-tc` | Normal | Close Tab |
| `Shift+l` | Normal | Next Tab |
| `Shift+h` | Normal | Previous Tab |

## VIsual Tour

One stop automated setup.

<img width="848" height="490" alt="image" src="https://github.com/user-attachments/assets/dcc93ee0-b131-4e3a-8223-6e8cf16df954" />

Whichkey integration.

<img width="1033" height="200" alt="image" src="https://github.com/user-attachments/assets/aec88c71-4174-4440-a6c3-0d4518829f79" />

Lazygit, a full git management system within nvim

<img width="1188" height="648" alt="image" src="https://github.com/user-attachments/assets/78c0522f-928d-4391-8393-2fdb214c84d9" />

Toggleterm to give you  PS terminal access within nvim

<img width="1871" height="964" alt="image" src="https://github.com/user-attachments/assets/3e1ca8ed-a133-4bca-9e57-7e117c9816f2" />

Full LSP and intellisense for powershell, python, GO, etc. Giving you "in terminal" access to definitions and keywords. 

<img width="487" height="74" alt="image" src="https://github.com/user-attachments/assets/690c6329-c775-4c8e-afb7-747fea70fcbb" />
<img width="540" height="498" alt="image" src="https://github.com/user-attachments/assets/f38c55cb-3cea-4a1f-970b-091ab63ba311" />

Mouse support for those who cannot live without it.

<img width="490" height="204" alt="image" src="https://github.com/user-attachments/assets/63c5a391-dd18-46d9-a080-deae043599b6" />

Co-pilot runs inline. There is also the ability to toggle session chat which works on the global buffer to make code transfer easy.

<img width="575" height="53" alt="image" src="https://github.com/user-attachments/assets/7be77e97-cd2f-4985-aee2-28f84e1b3c6a" />
<img width="1334" height="686" alt="image" src="https://github.com/user-attachments/assets/7ad649f7-4c6b-436b-9002-1c5dc89d39d7" />

Neotree gives you full access to the filesystem so you can move in and out of files without leaving.

<img width="422" height="305" alt="image" src="https://github.com/user-attachments/assets/7743f185-00c8-46c5-bc08-d9b05c60bb0a" />

Preview files before opening

<img width="1853" height="949" alt="image" src="https://github.com/user-attachments/assets/fa011789-2fc4-49e0-8619-a86452e55ddc" />

Easy Windows Management

<img width="1914" height="991" alt="image" src="https://github.com/user-attachments/assets/1e00dbd1-f93d-4215-972e-78781b0ed62f" />
