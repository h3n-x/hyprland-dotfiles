# Dotfiles -- Hyprland

A complete Hyprland 0.56+ setup (Lua API `hl.*`) plus a desktop stack,
managed with [GNU Stow](https://www.gnu.org/software/stow/).
Built for: AMD Ryzen 5 8645HS (Radeon 760M iGPU) + NVIDIA RTX 3050 6GB
(the iGPU always on, the NVIDIA only on demand).

**Languages:** the whole interface (bar, panels, dashboard, settings, lock and login screens, boot menu, notifications and script
messages) is available in English, Spanish and Japanese, switched live in Settings -> Appearance -> Language. See
[Translating](#translating) to add another language. *[Leer en español](README.es.md).*

## Quick install

```bash
git clone <this-repo> ~/Dotfiles && cd ~/Dotfiles
./install.sh
```

Works on Arch Linux and the distributions based on it (EndeavourOS, CachyOS, Manjaro, Garuda; Artix on a best-effort basis):
each one is tested in a container. Run it as your user; it asks for sudo once. It updates the system, installs the packages
of the profile (from the repositories, and the few AUR ones with yay or paru, offering to install yay if you have neither),
enables NetworkManager, bluetooth and power-profiles-daemon, links the configuration with stow (any file of yours in the way is
moved to `~/.local/state/dotfiles/backup-<date>/` first, never overwritten), generates the first palette and makes zsh your shell.
Running it again only does what is missing.

```bash
./install.sh --help                 # commands and options
./install.sh --dry-run              # show every command without running it
./install.sh --profile minimal      # the desktop only (full adds dev tools and personal apps: Spotify, NetBeans, JDKs...)
./install.sh --yes --no-aur         # no questions; repository alternatives instead of the AUR
./install.sh files                  # one step alone: deps, services, files, first-run, apps
./install.sh doctor                 # check an installation (changes nothing)
./install.sh uninstall              # remove the links, restore your backed-up files, optionally the packages it added
./install.sh system                 # optional system steps (below); or one: system sddm|plymouth|grub|gpu
```

Manjaro: if its Hyprland/Quickshell/matugen are older than the configuration needs, the installer stops before linking anything
and says so. Artix: it offers to enable Arch's repositories (some packages are only there) and skips `uwsm` (it needs systemd).

**System steps** (optional, they touch root-owned files): `./install.sh system` (or `install --with-system`) offers each one
after detecting what this machine has, and never runs with `--yes` alone. The login screen (SDDM with the `dotfiles-login`
theme), the boot splash (Plymouth: its initramfs hook for mkinitcpio or dracut, and `quiet splash` on the kernel command line
for a UKI, systemd-boot, GRUB, Limine or rEFInd), the GRUB theme (only if you boot with GRUB) and the GPU (udev aliases on a
hybrid laptop, NVIDIA modesetting). Each one installs a root-owned copy of its `sync-*-theme` script and a sudoers rule limited
to it (checked with `visudo`), so a wallpaper change can update it without a password. A boot file it edits is copied to
`<file>.dotfiles-orig` the first time. `./install.sh doctor` says when a root copy is out of date.

Not automated: your git identity (`git/.gitconfig` has the author's: edit it, then `stow git`).

## Stack

| Category | Tool |
|---|---|
| Compositor | Hyprland (modular Lua config) |
| Bar | Quickshell (QML, see the Quickshell section below) |
| Launcher | Quickshell (`SUPER+D`, see the Quickshell section below) |
| Window switcher | Quickshell (`SUPER+TAB`) |
| Notifications + control center | Quickshell (see the Quickshell section below) |
| Lockscreen | Quickshell (`dotshell/lock.qml`, watched by `scripts/lock`); hyprlock only as an emergency fallback |
| Login manager | SDDM (own theme, see `sddm/`) |
| Boot splash | Plymouth (dynamic colors, see the Plymouth section below) |
| Boot menu | GRUB (own matugen theme, see the GRUB section below) |
| Idle | Hypridle |
| Wallpaper | hyprpaper |
| Blue light filter | hyprsunset (a schedule or sunset to sunrise, from Settings -> Displays) |
| Polkit | hyprpolkitagent |
| Screenshots | grim + slurp (frozen screen with hyprpicker, optional) + satty, Quickshell preview |
| Recording | wf-recorder with VA-API (Radeon), Quickshell pill |
| Viewer / player | Loupe / mpv (default apps for images and video) |
| Clipboard | Quickshell panel (`SUPER + SHIFT + V`) on cliphist + wl-clip-persist |
| Color picker | hyprpicker |
| Emoji picker | Quickshell panel (`SUPER + .`), Unicode/CLDR data in every language of the shell |
| Dashboard | Quickshell (`SUPER + A`): home, today (calendar and weather), system and workspaces |
| Media | Quickshell player (bar pill, dashboard and media keys) |
| Calendar and weather | the dashboard's Today view (Open-Meteo weather, location chosen by hand) |
| Spotify | spicetify + spicetify-marketplace (see `spicetify/`) |
| Audio visualizer | cava (dynamic colors, see the cava section below) |
| System info / fetch | fastfetch (see `fastfetch/`) |
| Terminal multiplexer | zellij (dynamic colors, see the zellij section below) |
| Markdown in the terminal | glow (dynamic colors, see the glow section below) |
| Modern `du`/`df`/`ps` | dust / duf / procs (they inherit kitty's ANSI colors, no own theming) |
| HTTP client | xh (alias `http`) |
| Quick usage examples | tealdeer (`tldr`) |
| Dynamic color palette | matugen (Material You from the wallpaper) |

| Terminal | kitty |
| File manager | Thunar |

## 1. Packages

`./install.sh deps` installs them (the profile's groups, then the version check). The lists are data, one package per line with
a comment saying who uses it, in `install/packages/`: `core.txt` (the desktop), `shell-tools.txt`, `fonts-themes.txt`, and for
the `full` profile `dev.txt` and `apps.txt` (Spotify, NetBeans, the JDKs); `aur.txt` holds the AUR ones with the
repository alternative `--no-aur` uses. By hand:

```bash
sudo pacman -S --needed $(grep -hvE '^\s*(#|$)' install/packages/{core,shell-tools,fonts-themes}.txt | awk '{print $1}')
yay -S --needed $(grep -vE '^\s*(#|$)' install/packages/aur.txt | awk '{print $1}')
```

papirus-folders recolors the folder icons on every wallpaper change without sudo, so it needs a local copy of Papirus,
Papirus-Dark and Papirus-Light in `~/.local/share/icons` (`./install.sh files` makes it).

`pipewire`/`wireplumber` are critical: without them neither audio (`wpctl`)
nor screen sharing work. If you had `pipewire-media-session`, uninstall it (it conflicts).

For the Japanese interface, install a CJK font system-wide (`noto-fonts-cjk`): the login screen runs as another user and only
sees the fonts in `/usr/share/fonts`.

## 2. Hybrid GPU (AMD iGPU + NVIDIA)

The GPU variables aren't tracked: `~/.config/hypr/scripts/gpu-setup --write` (the installer runs it)
detects your GPUs and writes them to `~/.local/state/dotfiles/hypr-gpu.lua`, which `modules/env.lua` loads first.
On a hybrid laptop it sets `AQ_DRM_DEVICES` to `/dev/dri/gpu-amd:/dev/dri/gpu-nvidia` (iGPU first,
so Hyprland always starts on it) only if those aliases exist; NVIDIA alone gets the NVIDIA variables, AMD or Intel
alone none. The aliases have no `:` in the name and come from the udev rule
`/etc/udev/rules.d/71-gpu-drm-aliases.rules` (`gpu-setup --udev-rule` prints it for your machine)
(needed because `AQ_DRM_DEVICES` separates the list with `:`, and the paths
`/dev/dri/by-path/pci-0000:XX:00.0-card` already have `:` in their own name,
which breaks Aquamarine's parsing and makes Hyprland crash with
`CBackend::create() failed!`). On a hybrid laptop `./install.sh system gpu` does the whole setup:

- writes that rule from your machine's real PCI addresses, reloads udev and rewrites `hypr-gpu.lua` (now with `AQ_DRM_DEVICES`);
- turns on NVIDIA modesetting (`options nvidia_drm modeset=1`) if the driver doesn't already;
- enables `nvidia-suspend`/`-hibernate`/`-resume` (systemd).

It takes effect at the next boot. Optional and not automated: loading the iGPU driver before NVIDIA's in the initramfs
(`MODULES=(amdgpu nvidia nvidia_modeset nvidia_uvm nvidia_drm)` in `/etc/mkinitcpio.conf`, then `sudo mkinitcpio -P`) avoids
~1 min hangs in Electron apps at boot on some laptops.

To run something on the NVIDIA (games, Blender, etc.):

```bash
~/.config/hypr/scripts/nvidia-offload steam
# or in Steam: launch options -> ~/.config/hypr/scripts/nvidia-offload %command%
```

To see whether anything runs on the NVIDIA right now: `nvidia-smi --query-compute-apps=pid,process_name --format=csv,noheader`
(or the dashboard's System view, `SUPER + A` and `S`, which shows its state without waking it).

**Recurring gotcha after a kernel/driver update**: `nvidia-open-dkms` builds the
module for the kernel installed at that moment, but the one still *loaded in
memory* belongs to the kernel you booted with. If `pacman -Syu` brings a new kernel AND
a new NVIDIA version in the same run, they stay out of sync until the next
reboot -- symptom: `nvidia-smi` throws `Failed to initialize NVML: Driver/library version
mismatch`, and any offload to the dGPU (`nvidia-offload`, Steam, games) fails or
silently uses the iGPU. A normal reboot fixes it, nothing to
reinstall; to confirm before rebooting: `uname -r` (running kernel) vs
`pacman -Q linux-zen` (installed kernel) -- if they differ, reboot.

## 3. Apply the config with Stow

`./install.sh files` links every package folder of the repo with stow (except `git`, `sddm`, `grub`, `plymouth` and
`install`). Any file of yours in the way, like the `hyprland.lua` Hyprland autogenerates, is moved first to
`~/.local/state/dotfiles/backup-<date>/`. By hand:

```bash
cd ~/Dotfiles
stow -n -v hypr quickshell kitty gtk-3.0 gtk-4.0 zsh bat yazi nvim btop thunar matugen spicetify fastfetch   # see what clashes first
stow hypr quickshell kitty gtk-3.0 gtk-4.0 zsh bat yazi nvim btop thunar matugen spicetify fastfetch
```

Quickshell (see the Quickshell section below -- bar, notifications AND
control center, and the lock screen), kitty (tab bar included), GTK, Qt
(qt5ct/qt6ct), starship, yazi (flavor
`matugen`, see `yazi/.config/yazi/theme.toml`), Neovim (own base16
colorscheme, see `nvim/.config/nvim/lua/plugins/colorscheme.lua`), btop
(theme `matugen`), satty (100% generated, `~/.config/satty/config.toml`,
not tracked in the repo -- same as starship), cava (100% generated,
`~/.config/cava/config`, not tracked either -- see the `### cava` section
below), fastfetch (via kitty's ANSI colors + a generated alias, see `### fastfetch`
below), zellij (100% generated, see `### zellij` below), glow (via
`GLOW_STYLE`, see `### glow` below), NetBeans (editor profile and window, see
`### NetBeans` below), SDDM, the Papirus-Dark folder icons
and Hyprland's borders take their palette from a
wallpaper via matugen (`matugen/.config/matugen/`) instead of having
hardcoded colors. `bat` needs no template of its own: it uses the `ansi`
theme, which delegates color to the 16 ANSI colors kitty already defines.
`~/.config/starship.toml` is 100% generated by matugen (it isn't
tracked in the repo, only the template in
`matugen/.config/matugen/templates/starship.toml`). After `stow` it has to
be generated once, otherwise those apps' `@import`/`include`/`source`/`require`/
`color_scheme_path` point to files that don't exist yet. `./install.sh first-run` does it (from the first image in
`~/Pictures/Wallpapers`, or a gradient if there's none), and the installer runs it.

To change the wallpaper (and recolor everything together) use `SUPER+SHIFT+W`: the
Quickshell gallery (search, tags, favorites, recent, preview with `Space`,
and color options per wallpaper or for all of them).
`SUPER+SHIFT+Z` goes back to the previous theme. Everything goes through
`hypr/.config/hypr/scripts/theme-apply.sh`, which also works from a
terminal (for example if Quickshell isn't running):

```bash
~/.config/hypr/scripts/theme-apply.sh ~/Pictures/Wallpapers/imagen_161.png
```

It also regenerates `~/.face` -- the "user" image drawn by the
lock screen (above the password field), the login screen and
Plymouth -- as a centered square crop (512x512, via
`magick`) of the same wallpaper: the avatar changes together with the rest of the
theming. To use a photo of yours: settings center (`SUPER+I`),
Appearance, Avatar, "Own image" and "Choose…". It's cropped the same way, applied
right away on the lock screen (and on login and boot with the system
pass, a minute later), and wallpaper changes no longer overwrite it
(`theme-apply.sh --face` remakes it by hand).

Shell: zsh (with [zinit](https://github.com/zdharma-continuum/zinit) for
plugins -- it clones itself the first time you open a terminal, no need
to install it by hand). The installer offers to make it your login shell (`chsh -s /usr/bin/zsh`).

Neovim: a modular config in `nvim/.config/nvim/lua/` (lazy.nvim + mason/LSP +
treesitter + telescope + blink.cmp + gitsigns + lualine/which-key +
flash.nvim (navigation, see `keys` in `lua/plugins/flash.lua` -- it overrides
`s`/`S`/`r`/`R` on purpose) + render-markdown.nvim + yazi.nvim as the
file explorer + snacks.nvim (dashboard, notifications, indent guides, zen
mode with `<leader>z`)).
`lazy.nvim` clones and installs everything by itself the first time you open `nvim`
(it takes a while). LSP servers (`lua_ls`, `bashls`, `pyright`, `jsonls`,
`yamlls`, `marksman`, `taplo`) and formatters (`stylua`, `shfmt`) install
themselves via mason -- `bashls`/`pyright`/`jsonls`/`yamlls` need
`nodejs`/`npm`, already in the list above. `nvim-treesitter` is
pinned to the `main` branch (`master` is frozen and doesn't support Neovim
0.12+) and needs `tree-sitter-cli` to build parsers -- also already
in the list.

### cava

`~/.config/cava/config` is 100% generated by matugen (not tracked in
the repo, only the template in `matugen/.config/matugen/templates/cava.conf`)
-- cava doesn't support `include`/import to split the colors from the rest of the
config. `background`/`foreground` stay at `'default'` so the terminal's blurred
background shows behind it (the same mechanism as
`background_opacity` in `kitty.conf`) instead of a solid background, and the
low -> high gradient uses only the wallpaper's identity colors
(tertiary -> secondary -> primary): it's decorative, so it carries no status
colors (see "Status colors" further down). If
cava is already running, the template's `post_hook` sends it `SIGUSR2` to
reload only the colors (without restarting the audio analysis) on every
wallpaper change.

### fastfetch

Unlike cava, `~/.config/fastfetch/config.jsonc` (its own stow
package, `fastfetch/`) is a real, static file -- edit it by hand without
touching matugen. The current design ("Catnap" style, a hand-drawn box with a
custom `key` per module) colors each line with raw ANSI codes
(`{#31}`, `{#34}`, `{#35}`...) that resolve against the `color0-15` palette
matugen generates for kitty (`kitty/colors.conf`) -- the same delegation
mechanism `bat` already uses with its `ansi` theme: change the wallpaper and
the colors change without regenerating anything. There's also an
`alias fastfetch=...` generated by matugen in
`~/.cache/matugen/fastfetch-opts.sh` (sourced from `.zshrc`, the same pattern
as `fzf.sh`) with `--logo-color-N`/`--color-*` flags; with the logo
disabled (`"type": "none"`) it only colors the value text
(right column) via `--color-output`. It opens by itself when you open a new
terminal (last line of `.zshrc`).

### zellij

`~/.config/zellij/config.kdl` is 100% generated by matugen (not
tracked in the repo, there's no `zellij/` stow package -- only the template in
`matugen/.config/matugen/templates/zellij-config.kdl`). zellij supports
`theme_dir` to load themes from separate files (like yazi's flavor.toml),
but that directive doesn't expand `~`/`$HOME` (tested: it throws `IoError` if
it isn't a literal absolute path) -- since this repo has to work for
any `$HOME`, the theme is embedded directly in the full config instead
of a separate file. The colors are decimal RGB (`fg 227 225 233`),
not hex -- zellij 0.45's real format, verified with
`zellij setup --dump-config`. zellij runs one server per session: an
already open session doesn't pick up a wallpaper change until restarted
(`zellij kill-all-sessions -y`); new sessions do take the
updated colors.

### glow

glow's style (`glow-style.json`, the
[glamour](https://github.com/charmbracelet/glamour) format) is also 100%
generated by matugen, based on glamour's official `dark.json` with the
color fields replaced. The `style` key of `~/.config/glow/glow.yml`
turns out not to work (tested, glow silently ignores it) -- the
`GLOW_STYLE` environment variable does, so `.zshrc` exports it, always pointing to
`~/.cache/matugen/glow-style.json`. A non-obvious detail of the template itself:
glamour uses `{{.text}}` as an internal placeholder in the `format` field of
`image_text`, which clashes with matugen's `{{ }}` syntax (it breaks the parsing
of the WHOLE file, not just that line) -- it's escaped in the template as
`{{.text}}` (a JSON unicode escape -- with no literal
braces in the template matugen doesn't even notice -- which decodes
back to real braces when glow parses the generated JSON) so that
matugen doesn't try to interpret it as one of its own variables.

### NetBeans

The editor and the window follow the wallpaper too. One template
(`matugen/.config/matugen/templates/netbeans-theme.bundle`) holds an editor color profile
called `Matugen` (every language NetBeans 30 has colors for, with the same syntax colors as
Neovim; errors, warnings and diffs in the fixed status colors) and the FlatLaf window colors.
After each theme change `hypr/.config/hypr/scripts/netbeans-theme` copies it into every
NetBeans user folder (`~/.netbeans/<version>`), selects the profile and switches FlatLaf
between dark and light with the mode. The editor font is the monospace font from the settings
(`appearance.font.mono`, the same as kitty); the size you pick in NetBeans is kept. Text smoothing is turned on in
`~/.netbeans/<version>/etc/netbeans.conf` (a `matugen` block at the end: under XWayland there's no desktop settings
service and Java draws text unsmoothed). Your own lines in `config/LookAndFeel/FlatLaf.properties`
(below the `matugen` block), a color profile you installed yourself and a non-FlatLaf look and
feel are kept. NetBeans doesn't reload any of this while it's open: a notification asks you to
restart it. Without NetBeans the script does nothing; `netbeans-theme --check` says whether
every folder is up to date.

### Quickshell

The bar (`quickshell/.config/quickshell/dotshell/`) is written in QML
on [Quickshell](https://quickshell.org) instead of Waybar -- it's launched
with `qs -c dotshell` (autostart in `autostart.lua`). It fully replaces Waybar.

- **Colors**: matugen writes `~/.cache/matugen/quickshell-colors.json`
  (template `templates/quickshell-colors.json`) and `Colors.qml` reads it and
  follows it by itself, with a transition. `Colors.qml` is a `SemanticPalette`
  (`SemanticPalette.qml`, the only semantic layer): modules use aliases
  with meaning (`Colors.accent`, `Colors.warning`, `Colors.textMuted`...)
  and never the raw Material You roles.
- **Status colors** (Phase 8, P8.7): `danger`, `warning` and `success` are
  fixed -- they don't change with the wallpaper, the scheme or the contrast, only
  with light/dark mode. `hypr/.config/hypr/scripts/palette
  status` generates them (seeds in `dotshell/data/palette.rules.json`) and `theme-apply.sh`
  leaves them in `~/.cache/matugen/status.json` before each matugen run, which
  imports them for every template (kitty, btop, nvim, zellij...: the terminal's green,
  yellow and red are always the same). `palette check`
  validates the color system (contrasts, fixed colors, literal colors in
  the QML, the templates' semantic table).
- **Code colors** (Phase 18): syntax in NetBeans, Neovim and glow (and, as an option, the terminal's blue, magenta and
  cyan) comes from a third palette, separate from the wallpaper roles and the status colors. `palette code` takes 8 hues
  from a classic base palette (Catppuccin, Gruvbox, Tokyo Night, Dracula, Nord, One Dark, Rosé Pine:
  `dotshell/data/code-palettes.json`), turns them toward the wallpaper (harmony and maximum shift), solves their
  brightness for contrast against the editor background in each mode, keeps them away from the status colors and
  apart from each other, and writes `~/.cache/matugen/code.json` together with `status.json` before each matugen run.
  Settings → Appearance → Code colors / Code roles: palette, base, harmony, vibrance, the color of each syntax role,
  bold/italic for comments, keywords and types. Errors, warnings and diffs keep the fixed status colors.
- **Languages** (Phase 15): every visible text goes through `I18n` (`I18nCore.qml` + `I18n.qml`); the English text is the
  source and the key, and each language is a catalog in `dotshell/data/i18n/<language>.json`. Dates, numbers, durations and
  plurals follow the language. Scripts translate with `hypr/.config/hypr/scripts/i18n`; `i18n check` must stay at 0 (missing
  or old keys, placeholders, plurals, and any visible text outside `I18n`).
- **Structure**: `shell.qml` (entry point + the `IpcHandler`s below),
  `modules/Bar.qml` (`PanelWindow`, one instance per screen via
  `Variants` over `Quickshell.screens`; it builds the layout stored in
  `bar.layout`: left, center -- truly centered on the screen -- and
  right), `modules/BarEntry.qml` (the module of each id),
  `modules/Pill.qml` (a reusable rounded container) and one file per
  module (`Workspaces`, `Mpris`,
  `Clock`, `Update`, `Network`, `Bluetooth`, `Tray`, `Microphone`,
  `Battery`, `IdleToggle`, `Power`). `Volume`/`Backlight` have no icon
  in the bar (at the user's request, see OSD below) -- they're still instantiated,
  without a screen, directly in `shell.qml`, because they're still the
  ones watching Pipewire/sysfs and triggering the OSD.
- **Network/bluetooth dropdowns** (`modules/NetworkDropdown.qml` +
  `BluetoothDropdown.qml`): own QML panels instead of sending you to an
  fzf menu in a terminal -- a list of real networks/devices, click
  to connect (a network with an inline password field when needed via
  `WifiNetwork.connectWithPsk()`), wifi/bluetooth toggle. `Tray.qml`
  filters the `"nm-applet"`/`"blueman"` ids so the icon isn't duplicated.
- **Control center + notifications** (`modules/ControlCenter.qml` +
  `NotificationToast.qml` + `NotificationState.qml`): fully replaces swaync.
  `NotificationState.qml` wraps a `NotificationServer`
  (the DBus service `org.freedesktop.Notifications` -- that's why it replaces
  swaync instead of living alongside it, only one process can own it
  at a time) and exposes the history + a toast queue + "do not disturb"
  (with DND on, the notification stays in the history but doesn't
  show up as a toast). `ControlCenter.qml` reproduces what
  `swaync/config.json` gave: history with "clear all" and the **quick
  settings** -- the only place for quick settings (Phase 11 B6). It opens
  with the bar's bell or `SUPER+N`, in the same place as the notices
  (Settings -> Notifications -> Where they appear; Phase 14 B1), attached to the
  frame with the Frame style; while it's open no notices pop up: the
  new ones go straight into its list. The battery pill opens its own menu
  (level, time left, power draw and health if UPower reports them, power
  profile; the middle click switches the profile). By
  default: wifi, bluetooth, night light (the same option as
  Settings -> Displays), game mode, lock, power profile and "Do not
  disturb". They're data (`controlCenter.tiles`): with the pencil (when hovering
  over the settings) or `qs -c dotshell ipc call controlcenter edit` they're
  reordered by dragging, resized (square, wide with name and
  state, row) and removed or added; there's also "keep awake"
  (the same state as the bar module, for every screen),
  microphone, capture, record, keyboard layout (with 2 or more),
  screen color (if `hyprpicker` is there) and Settings. What the
  machine doesn't have doesn't appear. Each action has a single owner
  (`QuickTiles.qml`); the network and bluetooth dropdowns' switches
  use the same one. The player and the machine's state (the
  NVIDIA included) are in the dashboard. `SUPER+N`/`SUPER+SHIFT+N` (see
  `binds.lua`) replace `swaync-client -t -sw`/`-C`.
- **OSD** (`modules/Osd.qml` + `OsdState.qml`): a temporary popup
  (icon + level bar) for volume/mic/brightness, replacing the
  `notify-send` calls used before for this. It reacts to any
  source of the change (scroll, the keyboard's volume/brightness keys,
  pavucontrol, etc.), not only a click on the bar -- precisely
  why `Volume`/`Backlight` need to keep running even without an
  icon. The battery still uses a real `notify-send` for its
  warning/critical/full thresholds (those DO have to persist, not hide themselves).
- **Real reactivity** (no polling) via Quickshell's native
  services: `Quickshell.Hyprland` (workspaces/events over Hyprland's
  socket), `Quickshell.Services.Pipewire` (audio),
  `Quickshell.Services.UPower` (battery), `Quickshell.Services.SystemTray`
  (tray -- StatusNotifierItem, shows nm-applet/blueman-applet),
  `Quickshell.Services.Mpris` and `Quickshell.Wayland.IdleInhibitor`. CPU,
  memory and temperature have no native service (they're read from `/proc` and
  `sysfs` with `FileView`) so they were taken out of the bar by choice,
  not because of a technical limitation of Quickshell.
- **Updates and maintenance** (`MaintenanceState.qml`,
  `hypr/.config/hypr/scripts/maintenance`): the bar pill only informs
  (updates, up to date, error or pending reboot; click = update in
  a terminal, right click = check now). The explanation is in the dashboard's
  Maintenance view. It checks at startup, every hour and after every
  pacman operation; closed, it does nothing else.
- **Power and session menu** (`modules/PowerMenu.qml`, `SUPER+M` and the
  bar button): lock, suspend, log out, restart and power off;
  the last three ask for confirmation and close the applications first (via
  `hyprshutdown`).
- **Clipboard history** (`modules/Clipboard.qml`, `SUPER+SHIFT+V`):
  a list with search, filters (All / Text / Images / Links, `Tab`) and
  a text and image preview on the right. `Enter` copies, `Delete`
  deletes, `Ctrl+P` pauses the history (what you copy isn't saved until
  resumed; a restart resumes it), `Ctrl+Delete` empties it (with confirmation).
  `hypr/.config/hypr/scripts/clipboard-store` saves it; it runs in front
  of `cliphist` in `autostart.lua`'s `wl-paste --watch` and **doesn't save**
  what looks sensitive: private keys, tokens (GitHub, APIs, JWT),
  `PASSWORD=`/`SECRET=`/`TOKEN=` and password-shaped strings, what
  an app marks as a password, the apps listed in
  `hypr/.config/hypr/clipboard-exclude.conf` (empty by default) and images
  over 10 MB. What you copy still pastes; it just doesn't go into the history.
  Image previews are decoded in `$XDG_RUNTIME_DIR` (RAM) and
  deleted when the panel closes. `clipboard-store --scan` counts old sensitive
  entries and `--purge-sensitive` deletes them (it only prints how many).
  It's the only interface to the history.
- **Emoji picker** (`modules/Emoji.qml` + `EmojiState.qml`,
  `SUPER+.`): a grid with category tabs (Recent, Smileys, People,
  ...), search by word start in the shell's language and in English, without accents
  (`cat`, `gato`, `heart`; in Japanese, inside the word: `笑う`), a strip with the large emoji and the skin tone.
  `Enter` types the emoji into the active window (`wtype`, without copying it),
  `Ctrl+Enter` only copies it, `Tab` changes category, `Ctrl+T` or a click
  on the dots change the tone (global, remembered). It keeps the last 30
  in `~/.local/state/dotfiles/emoji.json`. The data
  (`dotshell/data/emoji/<language>.json`, 1914 emojis with names and keywords in that language and in English) is generated by
  hand by `hypr/.config/hypr/scripts/emoji-data` from the official Unicode 17.0 list and
  CLDR 48 (pinned by sha256; license in `data/LICENSE-unicode`). To
  draw fast it uses one PNG per emoji in `~/.cache/dotfiles/emoji/72`, which
  `emoji-data --ensure-images` creates at shell startup if they're missing (≈ 20 s,
  needs `python-pillow`); meanwhile it draws text with Noto Color Emoji.
- **Launcher** (`modules/Launcher.qml` + `LauncherState.qml`, `SUPER+D`):
  a search field with its own fuzzy match
  (subsequence, no external library) over the name/`genericName`/
  `keywords` of `Quickshell.DesktopEntries`, alphabetical order without
  a search, highlighting of what matches, a dynamic window size depending on the
  number of results.
- **Window switcher** (`modules/Switcher.qml` + `SwitcherState.qml`,
  `SUPER+Tab`): cards with a preview of each window (captured once
  on opening, other workspaces too), workspace (S = special), icon and
  title, by recent use. With Super held, `Tab` / `Shift+Tab` move and
  releasing Super switches (a quick `SUPER+Tab` goes back to the previous window);
  if Super was already released, arrows, `Enter` or a click, and typing filters. `Esc`
  cancels, `Delete` closes the chosen window. Only windows of at
  least 24x24 are captured (with many windows on a workspace some end up with a
  negative size and capturing them crashed the shell); the others show the icon.
- **Clock** (`modules/Clock.qml`): the time (24 h) and, with a chosen
  location, the weather (icon and temperature; dimmed if the data is old or
  couldn't be updated). It only informs: no click action.
- **Player** (`MediaState.qml`, `modules/Mpris.qml`): the pill shows the
  title and the state (an equalizer while playing, pause when paused); a middle click
  pauses. The media keys (`binds.lua`) use the same player via
  `qs -c dotshell ipc call media next|previous|playPause`, also with the
  screen locked. "Proxy" players (playerctld) are ignored.
  **Lyrics** (Phase 12 B1): in the dashboard's Music tab, in their own
  column (`L` or "Lyrics" show or hide them; from Home, `L` opens Music
  with the lyrics), the current line in the middle; clicking a line jumps there; "Other lyrics" picks among
  other versions and `-`/`+` (or `[`/`]`) corrects the offset, which is remembered
  per song (`~/.local/state/dotfiles/lyrics.json`). It looks first for an
  `.lrc` next to the song's file, then in `~/Music/Lyrics`
  ("Artist - Title.lrc", also in subfolders) and, only if enabled in
  Settings -> Media -> Lyrics, on [LRCLIB](https://lrclib.net)
  (open, no account; title, artist and length are sent) via
  `hypr/.config/hypr/scripts/lyrics-fetch` (cache in `~/.cache/dotfiles/lyrics`;
  a song without lyrics isn't asked about again for 7 days).
- **Dashboard** (`modules/Dashboard.qml` and its views, `DashboardState.qml`):
  the center of the shell. **It opens only with `SUPER+A`** (no bar
  module opens it), centered under the bar of the focused monitor; `Esc` or
  `SUPER+A` close it. A single surface with **tabs** at the top (Phase 12
  B2): by default **Home · Music · System · Workspaces**; Today and
  Maintenance are added in Settings -> Dashboard -> Tabs (otherwise
  they still open from their zone or their letter and show up while viewed). It
  opens on Home (or on the last one, if chosen):
  - **Home**: time, date, notices (updates and maintenance, which
    open that view; notifications, do not disturb; only if there are any) and weather;
    below, the **zones**, which you choose
    (Phase 11 B4): by default the machine's overall state ("All good" and
    four gauges) and the workspaces in miniature; also the month's
    calendar and the next hours of weather (with a city). Each one compact or
    wide, in the order you want, or none. The **music card**
    (small cover, title, artist, progress, previous / play /
    next; a click or `Enter` open the Music tab) goes last by default,
    while there's a player: the zones don't shift when the music starts or
    stops. The time/date/notices/weather line and the
    player are zones too: they're removed, moved and added back
    like the others. Without music (or without the Music zone), the clock grows and the
    panel gets shorter.
    **Edit Home**: the pencil (when hovering over the zones), `Ctrl+E` or
    Settings -> Dashboard -> "Edit Home". The zones show a dotted
    outline: dragging reorders them, the size button and the cross;
    below, "Add". With the keyboard: `Tab` picks, arrows move, `T`
    size, `Delete` removes, `A` add (arrows + `Enter`), `Esc` / `Enter`
    finish. A zone that isn't there queries nothing.
    Phase 11 B5a widgets: **Profile** (avatar, greeting and uptime;
    click -> the avatar in Settings), **Quick access** (the apps
    and folders you pin in Settings -> Dashboard; without chosen folders,
    the personal ones), **Notes** (a note that saves itself) and **Tasks**
    (`Enter` adds, a click marks it done, "Clear" deletes the done ones). Notes and
    tasks are saved only on this machine (`~/.local/state/dotfiles/notes.json`
    and `todo.json`, outside the repo). `Tab` + `Enter` start typing; `Esc`
    leaves the field.
    Phase 11 B5b: **Timer** (pomodoro, stopwatch and countdown; each
    phase change notifies, with a sound if asked; durations in Settings ->
    Dashboard; the state in `~/.local/state/dotfiles/timer.json`, so a
    reload doesn't lose it; `qs -c dotshell ipc call timer toggle|reset|status`)
    and **Now** (one line with what matters most: a running timer,
    rain in the next 3 h, pending tasks, heat or frost, the
    sunset; it appears only when there's something). The bar can carry the
    **Timer** module (what's left, per minute; a click pauses).
  - **Music**: the cover cut in the shape you choose (square,
    circle, 4-, 7- or 9-lobe cookies, soft burst; Settings ->
    Media -> Cover; the wavy ones turn a little with each song), the
    player (title, artist, album, seekable progress, five
    controls, chips with more than one player) and the lyrics beside it (below if
    they don't fit), on the panel's color (no blurred background). **Cover
    colors** (Phase 12 B4, on by default): the progress bar, the
    play button and the bars take the cover's color harmonized
    with the wallpaper (`hypr/.config/hypr/scripts/local-palette`, cache in
    `~/.cache/dotfiles/local-palette`); a grey cover or a color that could be
    mistaken for a notice uses the usual one. With nothing playing, it says so; nothing
    runs. **Audio bars**
    around the cover (Phase 12 B3; Settings -> Media ->
    Visualizer, off by default): they follow the cover's shape; they come from
    [cava](https://github.com/karlstav/cava), which runs only while the
    tab is visible and something plays (never with "reduce motion").
  - **Today**: the month's calendar and the weather in a sentence ("Feels like 30°. Today
    between 18° and 33°, no rain in sight."), the next 12 h and 5 days. The
    weather comes from [Open-Meteo](https://open-meteo.com) (no key; data
    CC BY 4.0) via `hypr/.config/hypr/scripts/weather-fetch` (cache in
    `~/.cache/dotfiles/weather.json`). **Without a location nothing is queried**;
    the city is chosen here (`C`) or in Settings -> Dashboard, saved
    only on this machine (`dashboard.weather.location` in
    `~/.config/dotfiles/settings.json`, outside the repo) rounded to ~10 km, and
    queried every 30 min. Degrees in °C or °F (Settings).
  - **System**: the state in words, processor, memory, storage and
    power (with the profile), the apps that use the most (grouped by
    app, not by process), the network and the graphics (the NVIDIA without
    waking it). With **short history** (Phase 11 B5c, on by default):
    processor, memory and battery show the last minutes instead of the
    level bar, and the network and graphics their chart (the NVIDIA, bands
    where it was active). Nothing is measured separately: it keeps what's already read
    while you look at the dashboard (hence the gaps), only in memory. How many
    minutes and which charts, in Settings -> Dashboard -> System. The
    **Rings** style (Phase 12 B3): the top four as rings with the figure
    inside and the temperature as a thin arc outside.
  - **Workspaces**: each workspace like the real screen at scale (wallpaper,
    bar, gaps, borders and each window's capture, taken once when opening
    the view); a click on a window goes to that window, on the background to the
    workspace.
  - **Maintenance**: first whether the system is fine and what's worth doing
    ("The system works correctly, but 2 items need
    attention."), then what needs attention and what's recommended, with four
    severities (information, recommendation, warning, important action);
    what's fine, in a single line. Updates, pending reboot
    (kernel or NVIDIA driver), failed services (they can be hidden), orphan
    packages, caches, trash, journal and crash dumps. The detail
    (packages, services, exact commands) only when expanded. **The actions
    open a visible terminal** that shows the commands and asks for
    confirmation; `sudo` asks for the password there, never from the shell.
  Keyboard: `Ctrl+Tab` / `Ctrl+Shift+Tab` (or `Ctrl+PgDown` / `Ctrl+PgUp`)
  switch tabs, `Alt+1`..`Alt+6` go to the n-th; also the wheel over
  the tab bar or a two-finger sideways swipe. `Tab` walks through the
  Home zones, `Enter` opens the zone's tab (the zone grows to
  fill the panel), `H`/`S`/`E`/`M` open Today/System/Workspaces/Maintenance
  from anywhere, `L` opens Music with the lyrics; `Esc`/`Backspace`
  go back to Home; `1`-`9` go to that workspace; in Music (or with the focus on
  the card), `Space`, arrows (-/+10 s), `N`/`P`.
  `qs -c dotshell ipc call dashboard tab music` opens (or switches to) a tab,
  for your own shortcuts. Closed, nothing runs
  (no machine sampling nor window tracking); everything respects "reduce
  motion".
- **Screenshots and recording** (`CaptureState.qml`, `modules/CapturePreview.qml`,
  `modules/RecordingPill.qml`; scripts `screenshot`, `record`,
  `capture-select`): after each capture the area flashes, the image flies to
  a card at the bottom right (6 s, paused with the pointer over it) with
  Annotate (satty on the same file), copy, copy the path, open,
  folder (Yazi with the file selected) and trash with Undo; a double click on
  the thumbnail = Annotate / Play. The region is chosen with the screen
  frozen (it can be turned off) and windows as targets. While recording, a pill in the
  bar (time, click to stop) and marks on the area's corners. It records
  with VA-API on the Radeon (`LIBVA_DRIVER_NAME=radeonsi` only for
  wf-recorder).
- **Binds** (`binds.lua`): `SUPER+SHIFT+B` shows/hides the bar
  (`qs -c dotshell ipc call bar toggle`, affects every screen at
  once via the `BarVisibility.qml` singleton) and
  `SUPER+SHIFT+CTRL+B` forces a hard reload
  (`qs -c dotshell ipc call shell reload`, recreates the windows) --
  equivalent to the `SIGUSR1`/`SIGUSR2` signals Waybar accepted.
- To debug live: `qs -c dotshell log -f` (logs) and
  `qs -c dotshell ipc show` (lists the available `IpcHandler`s).

### Settings center

A window, "Settings", with every option of the ecosystem. It opens
with `SUPER+I`, with the control center's gear (`SUPER+N`) or with a
direct link:

```sh
~/.config/hypr/scripts/settings-ui                        # open (or bring up the open one)
~/.config/hypr/scripts/settings-ui open system            # a page
~/.config/hypr/scripts/settings-ui open capture.cardSeconds   # an option: its page, highlighted
```

It's a Quickshell instance separate from the shell
(`dotshell/settings.qml`, like the lock screen): closed, there's no process at all, and
restarting the shell doesn't close it. A single window at a time (a second
`SUPER+I` brings it to the front). It floats centered at 1100 x 720 (the
`settings-center` rule in `rules.lua`).

- **Home**: the current theme ("Change wallpaper" opens the gallery, "Theme
  options" goes to Appearance), three quick options (reduce motion,
  transparency, high contrast) and **Your changes**: each changed option,
  with its value, the default and a way back; a click on one goes to its row.
- **One page per category** (Appearance, Accessibility, Bar, Dashboard,
  Capture, Media, Notifications, Control center, System, Displays, Power, Keyboard and
  mouse, Lock and login, Shortcuts). The pages
  build themselves from `dotshell/data/settings.schema.json`: a new key
  appears on its page, with its type's control, and is found by search.
  A category without options doesn't appear. Each row says whether it's "Changed" and
  when it applies ("Next time", "Restarts the shell"); advanced ones
  stay folded at the end of the page. "Reset the page" sets everything back
  to default (it asks first).
- **Appearance** (Phase 10 B2): the **language** (Phase 15: Automatic, English, Español, 日本語; live, including the lock and
  login screens and the boot menu); the current theme -- which scheme and
  contrast it was applied with; if the ones "for every wallpaper" differ,
  "Apply to the current theme" reapplies it with them (the gallery's "Global
  theme" button brings you here) --, the interface font and the code font (the
  installed ones that cover the language, each written in itself; the
  shell, the lock and login screens use them; if one is uninstalled, the
  default comes back and Diagnostics says so), the **avatar**: from the wallpaper or an own
  image (the portal's file picker, GTK), and the **app colors**
  (P5.6, on by default): each app brings a color taken from its icon
  (the one of the icon theme in use) and harmonized with the wallpaper, only in details:
  the ring of the chosen window when switching windows, a dot under the active
  app in the bar (with window icons), the backdrop of its icon in
  notices, the launcher and Workspaces, and the player when the cover gives no
  color. A grey icon uses the usual color.
- **Accessibility**: reduce motion (the shell and also the windows'
  animations), high contrast, **interface scale** (from 85 % to
  150 % in 5 % steps: everything grows together, text, icons, the bar, rows,
  spacing and panels; if the bar doesn't fit, long titles give way before
  covering the clock), **text size** (from 85 % to 150 %, an extra just for
  the text on top of the scale), both on the lock and login screens too, and
  **always-visible focus** (a ring around whatever has the keyboard
  focus).
- **Windows** (in Appearance, Phase 10 B3): Hyprland's gaps, corners, border,
  opacity, blur and shadows.
- **Keyboard and mouse**: keyboard layouts (the first is the main one;
  with more than one, a combination switches them), key repeat, Num
  Lock, focus following the mouse, pointer speed and acceleration, and the
  touchpad (natural scrolling, tap to click, disable
  while typing, two-finger right click, speed).
- **Power**: dim, lock, turn the screen off and suspend
  after some idle time (each can be "Never"), suspend also when
  plugged in or only on battery, and stay awake while something plays.
- **Displays** (Phase 10 B5): one card per display with resolution,
  refresh rate, scale (only the ones that leave a whole space, with the space
  left), rotation, flipped, VRR, mirror and, folded, advanced color (8/10
  bits, sRGB / DCI-P3 / Display P3 / Adobe RGB / wide / EDID / HDR profiles,
  SDR brightness and saturation in HDR). With two or more, the **layout** is
  dragged (it snaps to the edges; two overlapping ones can't be applied) and
  one can be turned off (never the last). What the display doesn't report supporting
  (according to its EDID, `scripts/display-caps`) shows with a note. **Every
  change is tried**: on applying, "Keep this configuration?" appears at the top
  with 15 s; without "Keep" the previous one comes back (a separate process
  counts it: it comes back even if the screen stays black or the window
  closes). VRR applies by reloading Hyprland (a flicker). "High refresh rate
  only when plugged in" drops the built-in one to 60 Hz on battery (with a notice).
  **Night light**: on or off (also from the control center),
  a schedule or sunset to sunrise (with the weather city), temperature and
  a warmer step late at night. The versioned monitor config
  (`modules/monitors.lua`) is generic: your machine's values live in your store.
- **Bar**: the **layout** (Phase 11 B1) in three columns (left,
  center, right): each module is dragged elsewhere, in or out of
  a pill, spacers are added, and whatever is dropped in Available is
  removed; pointing at a module highlights it in the bar (with the keyboard: arrows to
  move it, Delete to remove it). Modules to add from Available (Phase
  11 B2; none come placed): keyboard layout (with two or more; a click
  goes to the next), Caps Lock / Num Lock (only while
  on), active window, notices (a bell with a dot or a number; a click opens the
  control center), privacy (shared screen, microphone or camera in
  use, in yellow), the launcher, resources (processor, memory, temperature;
  yellow above a threshold) and network speed -- these two only
  read the system while they're in the bar, every `system.sampleSeconds`.
  Workspaces: only each screen's, without the empty ones, or with each
  window's icon. Info on hover (the full date, the battery,
  the whole title...) and the wheel over the bar for volume or brightness,
  off by default. **Position** (Phase 11 B3): the bar on any
  edge (top, bottom, left, right) and its thickness (32-48 px); on a
  side the modules stack (the clock on two lines, icons only), and the
  control center, the OSD, the notices and the menus are placed from that
  edge. Floating style (separate pills), solid (attached to the edge, a
  single background), transparent or **frame** (Phase 13: the bar is the thick side
  of a frame around the screen, with rounded inner corners;
  thickness from 2 to 16 px and corner radius to choose; windows stay
  inside, with their usual gaps; the bar's menus, the dashboard, the
  control center, the OSD and the notices slide out of the frame and stay
  attached to it, with rounded joints), and "show only while holding Super"
  (it appears while holding the key, after a short delay: over the
  windows, with a background, or pushing them while visible; Phase 11 B3b).
  Which screens the bar goes on. A 24 or
  12 h clock and the date beside it, switching workspaces with the wheel, and the music
  pill with the title or only the icon (Phase 10 B4).
- **Dashboard**: the tabs and which one it opens on, the System style (gauges or rings), Home's System and Workspaces zones, the
  weather city (the same search as in the Today view; "Remove" stops querying)
  and °C / °F.
- **Capture**: copy to the clipboard, freeze the screen while choosing, PNG or
  JPEG; when recording, audio (no audio, the system sound, the microphone or
  both: a temporary PipeWire mix removed at the end) and 30 or
  60 frames.
- **Media**: the preferred player (the one the bar and the dashboard
  show if it's open), ignore browsers, the cover's shape and colors,
  the audio bars (and how many) and the maximum volume with the keys (100, 125 or 150 %).
- **Notifications**: where they appear (top right, top center,
  bottom right; the control center opens in the same place), how many at once (the others wait), a sound on
  arrival and system notices in the OSD: Caps Lock, layout change
  and charger plugged in or out (off by default).
- **Shortcuts**: the same list as the guide (`SUPER+/`), with search; it's reread
  from Hyprland every time the page opens.

What goes to Hyprland or hypridle applies at once (without reloading
Hyprland): `scripts/settings-apply` generates
`~/.local/state/dotfiles/hypr-overrides.lua` (only what you changed;
`hyprland.lua` loads it last, the repo's config is the default) and
`~/.local/state/dotfiles/hypridle.conf` (hypridle starts with that one), and the
display rules (in the same overrides) and
`~/.local/state/dotfiles/hyprsunset/hypr/hyprsunset.conf` (night light; hyprsunset starts with `XDG_CONFIG_HOME` pointing there: it doesn't accept a path). If
Hyprland uses another value (for example in game mode), the row says so. Game
mode (`SUPER+ALT+G`) turns off blur, shadows and animations, and on leaving
your values come back.
- **About**: versions, Diagnostics (values the engine didn't apply and
  why, fonts that are no longer there), your changes as a file, and the README.
- **Search** (`Ctrl+F`): label, description, keywords, without accents, in the current language and in English;
  Enter goes to the option and highlights it. `Ctrl+Tab` / `Ctrl+PgDown` switch
  pages, Tab walks through the controls (the page scrolls to the one
  with the focus), the arrows, `PgUp` / `PgDown` and `Home` / `End` scroll
  the page, the bar on the right can be dragged or clicked, and Esc clears the
  search and then closes. If the window is short, the page list on the
  left scrolls too (wheel or its bar) and the chosen page stays in
  view.

Values are saved only through `~/.config/hypr/scripts/settings`
(the only one that writes `~/.config/dotfiles/settings.json`, and only what
you changed); an invalid value isn't saved and the row says why. If a
change needs a shell restart, a notice with the button appears at the top.

To debug: `qs ipc -p ~/.config/quickshell/dotshell/settings.qml call
settingsui status` (page and highlighted option); the logs, with
`qs log -p ~/.config/quickshell/dotshell/settings.qml`.

### Spotify (spicetify + Marketplace)

`user.css` starts from [catppuccin/spicetify](https://github.com/catppuccin/spicetify)
(MIT, see `spicetify/.config/spicetify/Themes/matugen/LICENSE-catppuccin`) --
the catppuccin base is left unchanged, it only consumes the `--spice-*`
variables spicetify generates from `color.ini`. That `color.ini`
is 100% generated by matugen (a single `[matugen]` scheme, not catppuccin's 4
fixed flavors). `theme.js` (a manual accent color picker) wasn't ported:
it depended on 14 pre-generated equalizer GIFs per fixed
accent, which doesn't fit a dynamic single-accent scheme -- the
only effect is that the animated "now playing" icon doesn't animate; the
rest of the theme isn't affected.

On top of that base, own customization (the last section of `user.css`,
separate from what's inherited from catppuccin):
- Plus Jakarta Sans across the UI and Maple Mono NF for monospaced text
  (`--encore-*-font-stack`, the same fonts as the rest of the rice,
  real variables confirmed by grepping Spotify's already patched CSS --
  spicetify doesn't document them).
- A playback bar with `backdrop-filter: blur()` (this is normal CSS
  that Chromium/Electron can do over its own content -- it has
  nothing to do with Hyprland not being able to blur behind the
  Spotify window, they're two different things).
- Album covers with the same `border-radius` as Hyprland's windows
  (`decoration.rounding`, `lookandfeel.lua`).
- The progress bar and play button in the accent color instead of the default
  grey.

Unlike the rest, spicetify doesn't read `color.ini` live: it "bakes" it
into Spotify's already patched files only when running
`spicetify apply` (the template's `post_hook` does that on every wallpaper
change). If Spotify was already open, close it and open it
again to see the new colors.

Initial setup (only once, after the first `matugen image`):

```bash
spicetify config current_theme matugen color_scheme matugen
spicetify apply
```

Marketplace (to install community themes/extensions from Spotify's own UI)
via the official installer -- it only touches `~/.config/spicetify/`,
no sudo:

```bash
curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-marketplace/main/resources/install.sh | sh
```

(the installer respects the `current_theme` you already configured above --
it only overrides the theme if none is set).

### SDDM (login screen)

The greeter (`dotfiles-login`) is the same entry screen as the lock
(see "Lock screen"): stacked time, a date chip and the password
card, with the `~/.face` avatar. The cards are actions: Power off,
Restart, Suspend (if the machine can) and Session (a click goes to the
next one, for example Hyprland / Hyprland (uwsm)). It comes in over the blurred
background Plymouth leaves and, on logging in, goes out to the sharp
wallpaper the desktop starts with.

It shares the code with the lock: `dotshell/login/` (pure QtQuick),
`Tokens.qml`, `SemanticPalette.qml`, `I18nCore.qml` and `modules/Icon.qml`; the greeter's own
part is in `sddm/theme/` (`Main.qml`, `SddmAuth.qml`). matugen generates the palette
(`templates/sddm/Colors.qml`) in the system pass, 60 s
after the last wallpaper change. `scripts/sddm-theme-stage` builds the
whole theme as you in `~/.cache/matugen/sddm-login/` (with the wallpaper,
the avatar and `I18n.qml`: your language with only the greeter's texts) and the root copy of `sync-sddm-theme` only installs it in
`/usr/share/sddm/themes/dotfiles-login` (no arguments, it rejects symbolic
links): SDDM runs as the `sddm` user and can't read your home. Changing the language schedules the system pass, so the
greeter follows it a minute later.

Setup: `./install.sh system sddm`. It installs SDDM, the root-owned copy `/usr/local/bin/sync-sddm-theme` (the sudoers rule
points to that copy, never to the repo's script, which you can edit: otherwise NOPASSWD would amount to unrestricted sudo) and
its sudoers rule, builds and installs the theme, writes `/etc/sddm.conf.d/theme.conf` (`Current=dotfiles-login`) and makes SDDM
the login manager from the next boot (asking before replacing another one; it is never started in your open session).

If you edit `sync-sddm-theme.sh`, run it again: the copy in `/usr/local/bin` is the one that actually runs (`doctor` tells you
when it differs). To try the theme without logging out:
`sddm-greeter-qt6 --test-mode --theme ~/.cache/matugen/sddm-login` (QML
errors go to the journal: `journalctl --user -e`).

If the greeter didn't load: `Ctrl+Alt+F3`, log in, and
`sudo sed -i 's/^Current=.*/Current=maldives/' /etc/sddm.conf.d/theme.conf`
and `sudo systemctl restart sddm` (maldives ships with SDDM).

### Lock screen

The lock is a Quickshell instance separate from the shell
(`dotshell/lock.qml`), with the "Material You" composition: on the left the
stacked time (hours in the accent color, minutes in the text color) and the
date chip; on the right the "at a glance" cards and the password
card (`~/.face` avatar, user, field and the Caps Lock or
error line), over the blurred wallpaper. The field is on every
screen (a single shared text) and has a fixed place: the cards
grow upwards. It's the same screen as the greeter (code
shared in `dotshell/login/`): it comes in from the desktop (the background
blurs; clock, cards and password card, in that order) and on
unlocking the padlock opens and everything goes out to the sharp wallpaper. Nothing
moves if nothing changes; with "Reduce motion", everything is immediate. It's always launched by `~/.config/hypr/scripts/lock`, which
watches it:

- `SUPER+L`, the power menu and the control center call `lock --user`;
  hypridle (idle and before suspending) calls `lock`.
- If the lock crashes with the session locked, it relaunches by itself; on the
  third crash, or if it doesn't manage to lock within 3 s, it opens the **emergency
  hyprlock** (`hyprlock-emergency.conf`: no theme or generated files).
- When coming back from suspend, hypridle calls `lock --resume`: the lock
  is recreated (Hyprland doesn't give the keyboard back to the previous surface).
- `SUPER+CTRL+ALT+L` (works with the session locked): if the lock doesn't
  accept the password, it swaps it for the emergency hyprlock. It never
  unlocks.
- PAM checks the password with `dotshell/lock/pam/dotfiles-lock`
  (`pam_unix` + `pam_faillock`: 3 failed attempts, a 10 min wait).
- Log: `journalctl -t dotfiles-lock`.

#### At a glance

Each card appears only if it has something to say, and none does anything (the
cursor is hidden; the volume, brightness and media keys keep
working). They're turned off one by one in the settings center
(`SUPER+I`), "Lock and login" page (`lock.glance.*`):

- **Weather**: temperature and sky, without the location; if the data
  is more than 2 hours old, it doesn't appear. The lock never queries the network.
- **Music**: while something plays, the title and below it the artist (or the
  player); never the cover. It's visible with the session locked: if you don't
  want it to show, turn it off in "Lock and login".
- **Battery**: only on battery, with the warning color at the
  low and critical thresholds.
- **Notices**: how many arrived while locked, never the
  content; with Do not disturb on, it doesn't appear.

"Caps Lock is on" appears under the field while it's on (always:
it avoids failed attempts, which also count for `sudo`).

#### Manual recovery (from a TTY)

If `SUPER+CTRL+ALT+L` isn't enough or the screen says "lockscreen died":

1. `Ctrl+Alt+F3` and log in with your user (it asks for the password).
2. **Only if the lock is still alive** (frozen, not "lockscreen died"):
   `pkill -f "qs -p .*lock.qml"`. With "lockscreen died" it no longer exists: it
   prints nothing and can be skipped.
3. `hyprctl --instance 0 eval 'hl.clear_crashed_lockscreen()'`
   - `ok`: the session is unlocked.
   - `error: ... session is not locked`: it was already unlocked (for
     example, step 3 had already been done).
   - Anything else: steps 6 and 7.
4. `Ctrl+Alt+F1`: the session, unlocked.
5. Close the TTY: `Ctrl+Alt+F3`, `exit`, `Ctrl+Alt+F1` (otherwise a
   session stays open on tty3).

Only if step 3 doesn't work:

6. `hyprctl --instance 0 eval 'hl.config({ misc = { allow_session_lock_restore = true } })'`
7. `hyprctl --instance 0 dispatch 'hl.dsp.exec_cmd("hyprlock --config ~/.config/hypr/hyprlock-emergency.conf")'`,
   `Ctrl+Alt+F1` and the password; then step 5.
8. Last resort (it ends the session): `loginctl terminate-session <n>`
   (`loginctl list-sessions` gives the number).

The same works over SSH (without the TTY switches; `exit` closes the
SSH session).

### Plymouth (boot splash)

An own "Script" theme (`plymouth/theme/dotfiles-matugen.plymouth`, the
only static part -- it carries no colors). Everything visual is generated by
`matugen/.config/matugen/templates/plymouth.script` +
`hypr/.config/hypr/scripts/generate-plymouth-assets.sh` (ImageMagick, no
sudo, runs as a `post_hook` on every wallpaper change):

- **Background**: the active wallpaper with a strong blur + darkening + a radial
  vignette (the same criterion as the lock screen's background, but baked into
  the image because Plymouth Script has no blur filter of its own).
- **Avatar**: `~/.face` (the same square crop the lock screen uses, see
  `theme-apply.sh`) cut into a circle, centered in the transparent
  hole the spinner's ring leaves.
- **Spinner**: a 270-degree ring (24 rotating frames) tinted with
  `primary`, around the avatar.
- **Label + progress**: "Arch Linux" fixed at the bottom center and the boot
  percentage in the bottom left corner, both with `on_surface`/`primary`.
- A fade-in of the whole set in the first frames (no symmetric fade-out
  on exit -- the "script" plugin doesn't give a reliable way to
  delay the quit to animate it, and this machine's boot is already
  too fast for it to be worth the risk).

Same reason and pattern as SDDM: Plymouth runs inside the **initramfs** (before the real disk is mounted) and can't read
`~/.config` live, so every wallpaper change rebuilds the initramfs through the root-owned copy `sync-plymouth-theme` (run with
`sudo -n` from the system pass, never unrestricted sudo). It rebuilds with whatever the system uses (mkinitcpio, dracut), and
if the firmware boots `EFI/BOOT/BOOTX64.EFI` as a copy of a UKI, it copies the new UKI there too (atomically: a failed copy, for
example on a full ESP, leaves the old one intact).

Setup: `./install.sh system plymouth`. It detects the initramfs generator and the boot loader, then:

- installs Plymouth, the root copy and its sudoers rule;
- adds the `plymouth` hook: after `systemd` or `udev` in `HOOKS` (mkinitcpio; in the file that defines it last, so a
  `mkinitcpio.conf.d/` drop-in wins), or `/etc/dracut.conf.d/dotfiles-plymouth.conf` (dracut). booster has no Plymouth support;
- adds `quiet splash` where the kernel command line really comes from: `/etc/kernel/cmdline` with a UKI or systemd-boot
  (mkinitcpio and kernel-install read it), otherwise the systemd-boot entries, `GRUB_CMDLINE_LINUX_DEFAULT` (then
  `grub-mkconfig`), `/etc/default/limine` (CachyOS) or `limine.conf`, or `refind_linux.conf`;
- installs the theme and rebuilds the initramfs.

Each boot file it edits is copied to `<file>.dotfiles-orig` the first time. Safety net if the next boot misbehaves: in GRUB or
systemd-boot, `e` on the entry edits the command line for that boot only; from a live USB, put the `.dotfiles-orig` copy back.
If you edit `sync-plymouth-theme.sh`, run it again (`doctor` tells you when the copy differs).

**Mind the ESP size** with UKIs: each one weighs a few hundred MB, and a `BOOTX64.EFI` copy doubles that; avoid keeping manual
backups of a full UKI on a small ESP. Most firmwares can also boot a specific `.efi` from their own boot menu (F9/F11/Esc at
power-on, "Boot from file"), without a live USB.

### GRUB (boot menu)

An own theme (a blurred+vignetted wallpaper background, the `~/.face` avatar in a
circle, a progress ring tied to `GRUB_TIMEOUT`'s real countdown,
a rounded "pill" selection highlight, Plus Jakarta
Sans type -- the rice's interface font) generated by matugen, same
pattern as SDDM/Plymouth: `matugen/.config/matugen/templates/grub-theme.txt`
(template) + `hypr/.config/hypr/scripts/generate-grub-assets.sh`
(ImageMagick, no sudo; it also fills in the hostname and the footer text in your language, and copies the fonts next to the
images) + `hypr/.config/hypr/scripts/sync-grub-theme.sh` (root, copies that folder to `/boot/grub/themes/` and runs
`grub-mkconfig`; it never reads the repo). The fonts
(`grub/theme/font.pf2` and `font-bold.pf2`) are static -- generated ONCE
with `grub-mkfont` from Plus Jakarta Sans, with their own
name (`--name`) so as not to depend on which font GRUB ships with by
default. They only have Latin letters: with a language in another script (Japanese), the footer stays in English instead of
showing boxes.

```bash
grub-mkfont -o grub/theme/font.pf2 -s 16 --name "DotfilesSans" \
  /usr/share/fonts/TTF/PlusJakartaSans-Regular.ttf
grub-mkfont -o grub/theme/font-bold.pf2 -s 28 --name "DotfilesSansSemiBold" \
  /usr/share/fonts/TTF/PlusJakartaSans-SemiBold.ttf
```

(`grub-mkconfig` detects and loads by itself the `.pf2` files it finds in the
theme folder -- no manual `loadfont` needed.)

Setup: `./install.sh system grub` (only offered when the system boots with GRUB). It installs the root copy
`sync-grub-theme` and its sudoers rule, then the theme: it copies it to `/boot/grub/themes/`, sets `GRUB_THEME` in
`/etc/default/grub` and runs `grub-mkconfig`. Installing GRUB itself (`grub-install`) is left to you: it depends on your ESP and
firmware.

**Booting a UKI from GRUB** (optional): a `chainloader` entry boots the UKI with the command line embedded in it (the
`linux`/`initrd` commands would rebuild it from `GRUB_CMDLINE_LINUX_DEFAULT`). In `/etc/grub.d/40_custom`:

```
menuentry "Arch Linux" --class arch --class gnu-linux --class gnu --class os {
    insmod part_gpt
    insmod fat
    insmod chain
    search --no-floppy --fs-uuid --set=root <UUID-of-your-ESP-in-fstab>
    chainloader /EFI/Linux/<your-uki>.efi
}
```

With `GRUB_DEFAULT="Arch Linux"` in `/etc/default/grub` (by name: the "UEFI Firmware Settings" entry can come first).

**Try it without risking the normal boot**: `efibootmgr --bootnext <entry-number>`
boots through that entry ONCE only (it doesn't touch `BootOrder`), ideal to
try a new `grub-install`/theme before making it permanent:

```bash
efibootmgr -v                       # note your GRUB entry's number
sudo efibootmgr --bootnext <number>
# reboot, confirm it works, ONLY THEN:
sudo efibootmgr --bootorder <number>,<rest-of-the-order-you-already-had>
```

If you edit `sync-grub-theme.sh`, run `./install.sh system grub` again (same reason as SDDM/Plymouth).

## 4. Log in again

Log out and back in (SDDM) so the environment variables
(cursor, Qt, GPU) apply from scratch. `hyprctl reload` is enough for
bind/rule/appearance changes, but not for `hl.env(...)`.

`qt5ct.conf`/`qt6ct.conf` aren't stowed: `install.sh` creates them from `install/templates/` (a custom palette
pointing to the matugen scheme with your home's absolute path, which qt*ct needs, Papirus-Dark icons, Fusion style).
From then on they are your own files: the qt*ct GUI saves into them, and the installer only fixes the palette path.

## Translating

The source text is English and it's also the key: every catalog in `quickshell/.config/quickshell/dotshell/data/i18n/`
(`es.json`, `ja.json`) maps it to its language (`"ctx\u0004text"` when the same English means two things; plurals as
`{"one", "few", "many", "other"}`; `"@meta"` with the language's name, plural family and locale). To add a language:

1. Copy `es.json` to `<code>.json` (for example `fr.json`), set its `@meta`, and translate the values (keep `%1`, `%n`).
2. Add the code to `appearance.language`'s values in `dotshell/data/settings.schema.json`.
3. `~/.config/hypr/scripts/i18n check` must say 0 failures (missing keys, placeholders, plurals); `i18n extract` lists
   every key the code uses and `i18n stats` the coverage.
4. Optional: the emoji names (`emoji-data` with that language's two CLDR files) and the README.

The Japanese translation was written for this project and would gain from a native speaker's review: corrections are welcome.

## Shortcuts

On the system: **`SUPER + /`** opens the shortcut guide (searchable, always up
to date). The table below is generated from the same source -- each
shortcut's description in `hypr/.config/hypr/modules/binds.lua`, read from Hyprland -- with
`hypr/.config/hypr/scripts/keybinds readme`, which rewrites only the table
between the markers (this README in English, `README.es.md` in Spanish); it isn't edited by hand. `keybinds readme --check`
warns if it got out of date and `keybinds check` fails if a shortcut has no
description.

<!-- keybinds:start (generated: hypr/.config/hypr/scripts/keybinds readme) -->
**Shell**

| Shortcut | Action |
|---|---|
| `Super` + `D` | App launcher |
| `Super` + `Tab` or `Super` + `Shift` + `Tab` | Switch window |
| `Super` + `A` | Dashboard |
| `Super` + `N` | Control center |
| `Super` + `Shift` + `N` | Clear notifications |
| `Super` + `Shift` + `B` | Show or hide the bar |
| `Super` + `Ctrl` + `Shift` + `B` | Reload the shell |
| `Super` + `Shift` + `V` | Clipboard |
| `Super` + `.` | Emoji |
| `Super` + `/` | Shortcut guide |
| `Super` | Show the bar (hold) |

**Apps**

| Shortcut | Action |
|---|---|
| `Super` + `Enter` | Terminal |
| `Super` + `E` | Files |
| `Super` + `B` | Browser |
| `Super` + `Shift` + `C` | Color picker |

**System**

| Shortcut | Action |
|---|---|
| `Super` + `I` | Settings |
| `Super` + `L` | Lock the screen |
| `Super` + `Ctrl` + `Alt` + `L` | Emergency lock |
| `Super` + `M` | Power and session |
| `Super` + `Shift` + `M` | Log out |
| `Super` + `Ctrl` + `Shift` + `M` | Emergency exit |
| `Super` + `Alt` + `G` | Game mode |
| `Caps Lock` | Caps Lock state |
| `Num Lock` | Num Lock state |

**Windows**

| Shortcut | Action |
|---|---|
| `Super` + `Q` | Close the window |
| `Super` + `Shift` + `Q` | Force close |
| `Super` + `V` | Floating |
| `Super` + `F` | Fullscreen |
| `Super` + `Shift` + `P` | Pin on every workspace |
| `Super` + `C` | Center |
| `Super` + `P` | Pseudotile |
| `Super` + `J` | Toggle the split |
| `Super` + `G` | Group |
| `Super` + `Shift` + `G` | Lock the group |
| `Super` + `Arrows` | Move focus |
| `Super` + `Shift` + `Arrows` | Move the window |
| `Super` + `Ctrl` + `Arrows` | Resize |
| `Super` + `Left click` / `Left Ctrl` | Move with the mouse |
| `Super` + `Right click` / `Left Alt` | Resize with the mouse |
| `Super` + `R` | Resize mode |

**Workspaces**

| Shortcut | Action |
|---|---|
| `Super` + `1 … 0` | Go to workspace |
| `Super` + `Shift` + `1 … 0` | Move to workspace |
| `Super` + `Wheel` | Cycle workspaces |
| `Super` + `S` | Special workspace |
| `Super` + `Shift` + `S` | Move to special |
| `Super` + `Alt` + `L` | Switch the layout |

**Capture**

| Shortcut | Action |
|---|---|
| `Print` | Capture the monitor |
| `Super` + `Print` | Capture a region |
| `Super` + `Shift` + `Print` | Capture the window |
| `Super` + `Alt` + `R` | Record an area |
| `Super` + `Alt` + `Shift` + `R` | Record the monitor |

**Theme**

| Shortcut | Action |
|---|---|
| `Super` + `Shift` + `W` | Wallpaper gallery |
| `Super` + `Shift` + `Z` | Undo the last theme |

**Media**

| Shortcut | Action |
|---|---|
| `Volume up` / `Volume down` | Volume |
| `Mute` | Mute |
| `Microphone` | Mute the microphone |
| `Brightness up` / `Brightness down` | Brightness |
| `Previous` / `Next` | Next or previous track |
| `Play/Pause` | Play or pause |

**Resize mode** (mode: `Super` + `R`, leave with `Esc`/`Enter`)

| Shortcut | Action |
|---|---|
| `Arrows` | Resize |
| `Esc` / `Enter` | Leave the mode |
<!-- keybinds:end -->
