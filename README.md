<p align="center">
  <img src="youtube-downloader.svg" alt="AS YouTube Downloader Logo" width="160" />
</p>

<h1 align="center">AS YouTube Downloader</h1>

<p align="center">
  <strong>An elegant, interactive, and robust terminal interface for downloading YouTube media via yt-dlp.</strong>
</p>

<p align="center">
  <a href="https://github.com/17Arigato-jwd/youtube-downloader/releases"><img src="https://img.shields.io/badge/release-v1.6.4-blue.svg?style=flat-square" alt="Release v1.6.4" /></a>
  <a href="https://www.python.org/downloads/"><img src="https://img.shields.io/badge/python-3.10+-3776AB.svg?style=flat-square&logo=python&logoColor=white" alt="Python 3.10+" /></a>
  <a href="https://github.com/yt-dlp/yt-dlp"><img src="https://img.shields.io/badge/powered%20by-yt--dlp-red.svg?style=flat-square" alt="Powered by yt-dlp" /></a>
  <a href="https://ffmpeg.org/"><img src="https://img.shields.io/badge/media%20engine-FFmpeg-007808.svg?style=flat-square&logo=ffmpeg&logoColor=white" alt="FFmpeg" /></a>
  <img src="https://img.shields.io/badge/command-yt--dnld-orange.svg?style=flat-square" alt="Command: yt-dnld" />
  <img src="https://img.shields.io/badge/platform-Linux%20%7C%20Windows%20%7C%20macOS%20%7C%20Android%20%7C%20iOS-lightgrey.svg?style=flat-square" alt="Platform: Linux | Windows | macOS | Android | iOS" />
</p>

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Supported Platforms & Devices](#-supported-platforms--devices)
- [Key Features](#-key-features)
- [Terminal Preview](#-terminal-preview)
- [Releases & Automated Installers (Windows, Linux, macOS)](#-releases--automated-installers)
  - [🪟 Windows Setup (Release)](#-windows-setup-release)
  - [🐧 Linux Setup (Release)](#-linux-setup-release)
  - [🍎 macOS Setup (Release)](#-macos-setup-release)
- [Manual Setup for Other Devices & Operating Systems](#-manual-setup-for-other-devices--operating-systems)
  - [😈 BSD Systems (FreeBSD, OpenBSD, NetBSD, GhostBSD)](#-bsd-systems-freebsd-openbsd-netbsd-ghostbsd)
  - [📱 Android (Termux)](#-android-termux)
  - [🍏 iOS / iPadOS (iSH / a-Shell)](#-ios--ipados-ish--a-shell)
  - [🍓 Raspberry Pi & Other SBCs](#-raspberry-pi--other-sbcs)
  - [🎮 Steam Deck & Handheld Gaming PCs (SteamOS / Bazzite)](#-steam-deck--handheld-gaming-pcs-steamos--bazzite)
  - [💻 ChromeOS (Linux Container / Crostini)](#-chromeos-linux-container--crostini)
  - [🪟 Windows Subsystem for Linux (WSL / WSL2)](#-windows-subsystem-for-linux-wsl--wsl2)
- [Quick Start (`yt-dnld`)](#-quick-start-yt-dnld)
- [Interactive Guide & Options](#-interactive-guide--options)
  - [Format & Quality Presets](#format--quality-presets)
  - [Batch & Playlist Support](#batch--playlist-support)
  - [SponsorBlock & Chapters](#sponsorblock--chapters)
  - [Browser Cookies & Authentication](#browser-cookies--authentication)
- [Command-Line Flags](#-command-line-flags)
- [How It Works](#-how-it-works)
- [Troubleshooting](#-troubleshooting)
- [Uninstallation](#-uninstallation)

---

## 🌟 Overview

**AS YouTube Downloader** combines the raw speed and power of [yt-dlp](https://github.com/yt-dlp/yt-dlp) with an intuitive, guided terminal experience. It eliminates the need to remember long, cryptic CLI flags while offering features that bare downloaders leave out:

- **Automated Dependency Health & Self-Updates**: Automatically checks for and updates `yt-dlp` upon launch with a smooth animated loading bar.
- **Automated JavaScript Runtime Discovery**: Solves YouTube's throttling `n-challenge` signature deciphering by auto-detecting Node.js or Deno across common paths, version managers (`nvm`, `fnm`), and sandboxed environments.
- **Dynamic Monotonic Progress Tracking**: An in-place 3-line terminal progress bar that tracks video download, audio download, and FFmpeg post-processing stages without ever resetting backwards.
- **Pre-Download Media Inspection**: Queries and displays complete video and stream metadata (resolution, frame rate, audio bitrates, estimated file size) before initiating the download.
- **Global `yt-dnld` Command**: Once installed, call `yt-dnld` from any terminal session, or launch the app from your Desktop or system application menu.

---

## 📱 Supported Platforms & Environments

AS YouTube Downloader is pure Python and relies only on standard ANSI escape sequences and `ffmpeg`. It runs across virtually any POSIX or Windows environment:

| Platform / Operating System | Target Environments & Distros | Setup Method | Command & Integration |
| :--- | :--- | :--- | :--- |
| **🪟 Windows** | Windows 10 & 11 (x86_64, ARM64), Windows Server, WSL 1/2 | Pre-built Release / Installer | `yt-dnld` + Start Menu & Desktop Shortcuts |
| **🐧 Linux** | Ubuntu, Debian, Arch Linux, Fedora, openSUSE, Alpine, Void, NixOS, Pop!_OS, Mint | Pre-built Release / Installer | `yt-dnld` + `.desktop` & App Menu Launcher |
| **🍎 macOS** | Apple Silicon (M1–M4) & Intel x86_64 (macOS 10.15 Catalina through macOS 15 Sequoia) | Pre-built Release / Installer | `yt-dnld` + Native `.app` & Desktop Launcher |
| **😈 BSD Family** | **FreeBSD**, **OpenBSD**, **NetBSD**, **DragonFly BSD**, **GhostBSD**, **NomadBSD** | Manual Setup (Package Manager) | `yt-dnld` in terminal shell |
| **📱 Android** | [Termux](https://termux.dev/) (arm64, arm, x86_64), UserLAnd, AndroNix | Manual Setup | `yt-dnld` via symlink in `$PREFIX/bin` |
| **🍏 iOS / iPadOS** | [iSH Shell](https://ish.app/) (Alpine Linux emulation) or [a-Shell](https://github.com/holzschu/a-shell) | Manual Setup | `yt-dnld` in local iOS terminal |
| **🎮 Gaming Handhelds** | Steam Deck (**SteamOS** Desktop Mode), ASUS ROG Ally, Legion Go, **Bazzite** | Release / Manual Setup | `yt-dnld` |
| **💻 ChromeOS** | Chromebooks via **Crostini Linux Container** | Manual Setup | `yt-dnld` + Application Menu Icon |
| **🍓 SBCs & ARM / RISC-V** | **Raspberry Pi** (Pi 1–5, Zero / Zero 2 W), Orange Pi, Pine64, RISC-V (VisionFive, Milk-V) | Linux Installer / Manual Setup | `yt-dnld` |
| **☀️ illumos / Solaris** | OpenIndiana, OmniOS, SmartOS | Manual Setup (`pkgsrc`) | `yt-dnld` |
| **🌿 Haiku OS** | Haiku x86_64 via HaikuDepot Python 3 + FFmpeg | Manual Setup | `yt-dnld` |

---

## ✨ Key Features

| Feature | Description |
| :--- | :--- |
| **🎨 Polished Terminal UI** | Clean sections, rich ANSI colors, responsive spinners, and flexible input validation accepting any yes/no variant (`y`, `yes`, `sure`, `affirmative`, `n`, `nope`, etc.). |
| **📊 Real-time Progress Bar** | Multi-stream awareness separates video and audio downloads smoothly; live ticker continues smoothly through post-processing stages. |
| **🔍 Media Inspector** | Previews title, channel, duration, requested video resolution & codec, audio bitrate & sample rate, and estimated file size. |
| **🚀 JS Runtime Auto-Detection** | Proactively searches for Node.js, Deno, and PhantomJS across host binaries and NVM/FNM directories to prevent YouTube speed throttling. |
| **🎵 Video & Audio Extraction** | Supports video containers (**MP4**, **MKV**, **WEBM**, **AVI**) and lossless/high-fidelity audio (**MP3**, **WAV**, **FLAC**, **M4A**, **OPUS**). |
| **🛡️ SponsorBlock Integration** | Automatically cuts out intros, outros, sponsor segments, self-promotions, and interaction reminders directly in the downloaded file. |
| **📑 Chapter Splitting** | Splits multi-topic videos into individual timestamped video/audio tracks based on YouTube chapters. |
| **🖼️ Rich Metadata & Artwork** | Embeds ID3/MP4 metadata tags and thumbnail cover art (converted to clean JPEG for broad media-player compatibility). |
| **💬 Subtitle Extraction** | Fetches manual and auto-generated closed captions in your preferred language code (e.g. `en`, `es`, `ja`). |
| **🍪 Authenticated Downloads** | Extracts session cookies from major web browsers (**Chrome**, **Firefox**, **Safari**, **Edge**, **Brave**) to access age-restricted or members-only videos. |
| **⚡ Bandwidth Throttling** | Optional download rate limiting (e.g. `2M`, `500K`) to prevent saturating shared connections. |
| **📦 Batch & Playlist Modes** | Supports single links, entire YouTube playlists with auto-numbering, or interactive multi-URL batch queues. |

---

## 🖥️ Terminal Preview

```text
╔═══════════════════════════════════════════════════════════════════╗
║  AS Youtube Downloader | based on yt-dlp | version 1.6.4          ║
╚═══════════════════════════════════════════════════════════════════╝

┌─ Updates ──────────────────────────────────────
Checking for yt-dlp updates…
──────────────────────────────────────────────────────
[██████████████████████████████]  100%
✓  yt-dlp is up to date (v2025.02.19)

┌─ Source ───────────────────────────────────────
  Mode [single | single/batch]: single
  YouTube URL: https://www.youtube.com/watch?v=dQw4w9WgXcQ

┌─ Format & Quality ─────────────────────────────
  Audio: MP3 | WAV | FLAC | M4A | OPUS
  Video: MP4 | MKV | WEBM | AVI
  Format [MP3]: MP4
  Video quality [1080p | lowest/360p/480p/720p/1080p/1440p/4k/highest]: 1080p

┌─ Output ───────────────────────────────────────
  Filename / template (no extension) [%(title)s]: %(title)s
  Output directory [/home/user/Downloads]: /home/user/Downloads

┌─ Options ──────────────────────────────────────
  Embed metadata & thumbnail? [yes | yes/no]: yes
  Download subtitles? [no | yes/no]: no
  Configure extra options? [no | yes/no]: no
  Show raw yt-dlp output? [no | yes/no]: no

┌─ Video Details ────────────────────────────────
  Title:       Rick Astley - Never Gonna Give You Up (Official Music Video)
  Channel:     Rick Astley
  Duration:    03:33
  Quality:     1080p (1920x1080 @60fps avc1)
  Audio:       mp4a @ ~128 kbps (44 kHz)
  Format:      MP4
  Est. Size:   ~68.4 MB

Downloading video…   48.2MiB  15.1MiB/s  ETA 00:01
──────────────────────────────────────────────────────
[████████████████████░░░░░░░░░░]   68%

✓  Complete!
──────────────────────────────────────────────────────
[██████████████████████████████]  100%

✓  Saved → /home/user/Downloads/Rick Astley - Never Gonna Give You Up (Official Music Video).mp4
```

---

## ⚡ Releases & Automated Installers

Pre-built standalone releases and installer packages for **Windows**, **Linux**, and **macOS** are automatically built and published via GitHub Actions. These packages bundle standalone binaries so you don't even need Python or build tools pre-installed on your system.

👉 **[Download the latest release for your OS from GitHub Releases](https://github.com/17Arigato-jwd/youtube-downloader/releases)**

---

### 🪟 Windows Setup (Release)

1. Download **`yt-dnld-windows-x64.zip`** from [Releases](https://github.com/17Arigato-jwd/youtube-downloader/releases).
2. Extract the ZIP archive.
3. Right-click **`install.ps1`** and choose **"Run with PowerShell"** (or run `.\install.ps1` in PowerShell).

**What the installer does on Windows:**
- Installs `yt-dnld.exe` into `%LOCALAPPDATA%\Programs\youtube-downloader`.
- Adds the folder to your **User PATH** in the Windows Registry so you can type `yt-dnld` from any Command Prompt or PowerShell window.
- Creates **Start Menu** and **Desktop** shortcuts titled **"AS YouTube Downloader"**.

*(Alternatively, you can run `yt-dnld.exe` directly as a standalone portable executable).*

---

### 🐧 Linux Setup (Release)

1. Download **`yt-dnld-linux-x86_64.tar.gz`** from [Releases](https://github.com/17Arigato-jwd/youtube-downloader/releases).
2. Extract and run the installer:
   ```bash
   tar -xzf yt-dnld-linux-x86_64.tar.gz
   ./install.sh
   ```

**What the installer does on Linux:**
- Installs the standalone executable to `~/.local/bin/yt-dnld` (available in any terminal).
- Installs the SVG icon and `.desktop` launcher to `~/.local/share/applications` so it appears in your system application menu.

---

### 🍎 macOS Setup (Release)

1. Download **`yt-dnld-macos-universal.zip`** from [Releases](https://github.com/17Arigato-jwd/youtube-downloader/releases).
2. Extract the archive and double-click **`install.command`** (or execute `./install.command` in Terminal).

**What the installer does on macOS:**
- Installs `yt-dnld` to `~/.local/bin/yt-dnld` (and `/usr/local/bin`).
- Compiles a native macOS application bundle in **`~/Applications/AS YouTube Downloader.app`** launchable via Spotlight, Launchpad, or Finder.

---

## 📱 Manual Setup for Other Devices & Operating Systems

For BSD, Android, iOS, handhelds, or environments without pre-packaged releases, setup requires only Python 3.10+, FFmpeg, and a quick clone:

---

### 😈 BSD Systems (FreeBSD, OpenBSD, NetBSD, GhostBSD)

#### FreeBSD / GhostBSD:
```bash
# 1. Install prerequisites
sudo pkg install python3 ffmpeg py311-pip git

# 2. Clone and install dependencies
git clone https://github.com/17Arigato-jwd/youtube-downloader.git
cd youtube-downloader
pip install -r requirements.txt

# 3. Create global command
mkdir -p ~/.local/bin
ln -sf "$PWD/youtube-downloader.py" ~/.local/bin/yt-dnld
chmod +x ~/.local/bin/yt-dnld
```

#### OpenBSD:
```bash
# 1. Install prerequisites
doas pkg_add python3 ffmpeg py3-pip git

# 2. Clone and setup
git clone https://github.com/17Arigato-jwd/youtube-downloader.git
cd youtube-downloader
pip install --user -r requirements.txt
mkdir -p ~/.local/bin
ln -sf "$PWD/youtube-downloader.py" ~/.local/bin/yt-dnld
chmod +x ~/.local/bin/yt-dnld
```

#### NetBSD:
```bash
sudo pkgin install python311 ffmpeg git
# Follow standard pip install and symlink above
```

---

### 📱 Android (Termux)

1. Install **Termux** (recommended from [F-Droid](https://f-droid.org/en/packages/com.termux/)).
2. Open Termux and install the dependencies:
   ```bash
   pkg update && pkg install -y python ffmpeg git
   ```
3. Clone the repo and install dependencies:
   ```bash
   git clone https://github.com/17Arigato-jwd/youtube-downloader.git
   cd youtube-downloader
   pip install -r requirements.txt
   ```
4. Create the global `yt-dnld` command in Termux:
   ```bash
   ln -sf "$PWD/youtube-downloader.py" "$PREFIX/bin/yt-dnld"
   chmod +x "$PREFIX/bin/yt-dnld"
   ```
5. Run it anytime by typing:
   ```bash
   yt-dnld
   ```

> [!TIP]
> Run `termux-setup-storage` if you wish to set your output directory to your device's shared internal storage (e.g. `/sdcard/Download`).

---

### 🍏 iOS / iPadOS (iSH / a-Shell)

#### Using iSH (Alpine Linux shell on iOS):
1. Install [iSH Shell](https://apps.apple.com/app/ish-shell/id1436902243) from the App Store.
2. Install dependencies:
   ```bash
   apk update && apk add python3 py3-pip ffmpeg git bash
   ```
3. Clone and install:
   ```bash
   git clone https://github.com/17Arigato-jwd/youtube-downloader.git
   cd youtube-downloader
   pip install -r requirements.txt
   ln -sf "$PWD/youtube-downloader.py" /usr/local/bin/yt-dnld
   chmod +x /usr/local/bin/yt-dnld
   ```
4. Run `yt-dnld`.

#### Using a-Shell:
1. Install [a-Shell](https://apps.apple.com/app/a-shell/id1473805438) from the App Store.
2. Run:
   ```bash
   git clone https://github.com/17Arigato-jwd/youtube-downloader.git
   cd youtube-downloader
   pip install -r requirements.txt
   python3 youtube-downloader.py
   ```

---

### 🍓 Raspberry Pi & Other SBCs

Any Raspberry Pi (running Raspberry Pi OS, DietPi, Ubuntu, or Armbian) or ARM/RISC-V single-board computer can run:
```bash
sudo apt update && sudo apt install -y python3 python3-pip ffmpeg git
git clone https://github.com/17Arigato-jwd/youtube-downloader.git
cd youtube-downloader
pip install -r requirements.txt
mkdir -p ~/.local/bin && ln -sf "$PWD/youtube-downloader.py" ~/.local/bin/yt-dnld
chmod +x ~/.local/bin/yt-dnld
```

---

### 🎮 Steam Deck & Handheld Gaming PCs (SteamOS / Bazzite)

1. Switch to **Desktop Mode** on your Steam Deck (or boot into your desktop session).
2. Open **Konsole** (Terminal) and run:
   ```bash
   git clone https://github.com/17Arigato-jwd/youtube-downloader.git
   cd youtube-downloader
   python3 -m pip install --user -r requirements.txt
   mkdir -p ~/.local/bin && ln -sf "$PWD/youtube-downloader.py" ~/.local/bin/yt-dnld
   chmod +x ~/.local/bin/yt-dnld
   ```
3. Type `yt-dnld` in Konsole or add it as a Non-Steam Game to launch in Gaming Mode!

---

### 💻 ChromeOS (Linux Container / Crostini)

1. Enable **Linux (Beta / Crostini)** in your Chromebook's Settings.
2. Open the **Terminal** app and run:
   ```bash
   sudo apt update && sudo apt install -y python3 python3-pip ffmpeg git
   git clone https://github.com/17Arigato-jwd/youtube-downloader.git
   cd youtube-downloader
   pip install -r requirements.txt
   mkdir -p ~/.local/bin && ln -sf "$PWD/youtube-downloader.py" ~/.local/bin/yt-dnld
   chmod +x ~/.local/bin/yt-dnld
   ```

---

### 🪟 Windows Subsystem for Linux (WSL / WSL2)

Open your WSL terminal (Ubuntu, Debian, Arch, or Fedora on WSL) and run:
```bash
sudo apt update && sudo apt install -y python3 python3-pip ffmpeg git
git clone https://github.com/17Arigato-jwd/youtube-downloader.git
cd youtube-downloader
pip install -r requirements.txt
mkdir -p ~/.local/bin && ln -sf "$PWD/youtube-downloader.py" ~/.local/bin/yt-dnld
chmod +x ~/.local/bin/yt-dnld
```
Downloads can save directly into your Windows user directory via `/mnt/c/Users/<YourUser>/Downloads`.

---

## 🚀 Quick Start (`yt-dnld`)

After running the installer for your platform, simply open any terminal and type:

```bash
yt-dnld
```

Alternatively, you can run the script directly:
```bash
python3 youtube-downloader.py
```

Follow the on-screen interactive prompts to choose your format, quality, and output preferences.

---

## 🛠️ Interactive Guide & Options

### Format & Quality Presets

#### Audio Presets
When selecting an audio format (`MP3`, `WAV`, `FLAC`, `M4A`, `OPUS`), choose from:
- `highest`: VBR 0 (highest quality VBR / 320 kbps equivalent)
- `high`: VBR 2 (~190–250 kbps)
- `medium`: VBR 4 (~160 kbps)
- `low`: VBR 6 (~115–130 kbps)
- `lowest`: VBR 9 (~65–85 kbps)

#### Video Presets
When selecting a video format (`MP4`, `MKV`, `WEBM`, `AVI`), choose from:
- `highest`: Best available video + audio streams without resolution cap
- `4k`: Best video up to 2160p + best audio
- `1440p`: Best video up to 1440p + best audio
- `1080p`: Best video up to 1080p + best audio (Default)
- `720p`: Best video up to 720p + best audio
- `480p`: Best video up to 480p + best audio
- `360p`: Best video up to 360p + best audio
- `lowest`: Smallest file size / lowest available resolution

### Batch & Playlist Support

- **Single Mode**: Prompts for a single video or audio URL.
- **Batch Mode**: Enter multiple URLs, one per line. Submit a blank line when finished to start downloading the entire queue.
- **Playlist Detection**: If a link containing `list=` is provided, the downloader asks whether you want to fetch the entire playlist. Playlists are automatically named with leading index numbers: `%(playlist_index)s - %(title)s.%(ext)s`.

### SponsorBlock & Chapters

When opening the **Extra Options** sub-menu:
- **SponsorBlock**: Automatically clips and discards `sponsor`, `intro`, `outro`, `selfpromo`, and `interaction` segments without re-encoding unaffected parts.
- **Chapter Splitting**: Splits a single long video (such as podcasts, albums, or conferences) into distinct video/audio files corresponding to the author's defined chapters.

### Browser Cookies & Authentication

For age-restricted content, unlisted videos, or YouTube Premium / Member-only streams, activate browser cookie extraction in Extra Options. Supported browsers:
- `chrome`
- `firefox`
- `safari`
- `edge`
- `brave`

> [!NOTE]
> Make sure your chosen browser is closed or not actively writing to its cookie database when the download starts so yt-dlp can read the SQLite file.

---

## ⚙️ Command-Line Flags

| Flag | Purpose |
| :--- | :--- |
| *(no flags)* | Runs standard startup check and opens interactive downloader interface. |
| `--no-update` / `--skip-update` | Skips the startup yt-dlp update check (useful for offline use or slow connections). |
| `--update` | Runs the animated yt-dlp update check and immediately exits when finished. |

### Examples

```bash
# Launch without checking for yt-dlp updates
yt-dnld --no-update

# Run only the yt-dlp updater and exit
yt-dnld --update
```

---

## 🔬 How It Works

```mermaid
flowchart TD
    Start(["Launch yt-dnld"]) --> Deps["Check Dependencies (yt-dlp, FFmpeg)"]
    Deps --> UpdateCheck{"--skip-update flag?"}
    UpdateCheck -- No --> DoUpdate["UpdateBar: yt-dlp -U / pip upgrade"]
    UpdateCheck -- Yes --> UserInput
    DoUpdate --> UserInput["Prompt: Source, Format, Quality, Output & Options"]
    UserInput --> FetchInfo["fetch_media_info() + detect_js_runtime()"]
    FetchInfo --> DisplayMeta["display_media_info(): Video/Audio Details & Est. Size"]
    DisplayMeta --> BuildCommand["build_cmd(): Assemble yt-dlp Arguments"]
    BuildCommand --> RunDownload["run_download(): Subprocess Popen with Handoff"]
    RunDownload --> ParseStreams["Parse Output: Multi-Stream Video/Audio Progress"]
    ParseStreams --> PostProc["Post-Processing: Merging / SponsorBlock / Chapters / Tags"]
    PostProc --> Complete(["Finished: Output Saved"])
```

1. **Dependency Verification**: Confirms that both `yt-dlp` and `ffmpeg` are installed and reachable.
2. **Runtime Discovery**: Inspects system directories and version manager trees (`~/.nvm`, `~/.fnm`, `~/.deno`) for an executable JavaScript binary. If found, passes `--js-runtimes` directly to yt-dlp to solve anti-scraping challenges.
3. **Metadata Inspection**: Queries YouTube's API using the Python library binding or `--dump-json` to extract precise stream specs and approximate file sizes prior to downloading.
4. **Stream Handoff & Progress Computation**: Starts an animated CLI spinner while yt-dlp initializes, then hands off cleanly to a non-flickering, three-line progress display. Tracks separate audio and video payload downloads to guarantee a smooth, monotonic 0%–100% bar.

---

## ❓ Troubleshooting

### 1. YouTube downloads are extremely slow or fail with `n-challenge`
YouTube frequently updates its JavaScript challenge algorithm to throttle download speeds.
- Ensure you have **Node.js** or **Deno** installed on your system.
- Run `yt-dnld --update` to fetch the latest `yt-dlp` release.
- Ensure `curl-cffi` is installed: `pip install --upgrade "yt-dlp[default,curl-cffi]"`.

### 2. "Sign in to confirm you're not a bot" or Age Restrictions
Use the built-in browser cookie integration:
1. Log in to YouTube in your browser (e.g. Chrome, Firefox, or Brave).
2. Run `yt-dnld` and answer `yes` to **Configure extra options?**.
3. Answer `yes` to **Use browser cookies** and pick your browser.

### 3. Missing Dependencies Error
If the script exits with:
```text
✗  Missing dependencies: ffmpeg
```
Follow the installation section for your operating system or install via your package manager.

---

## 🗑️ Uninstallation

If you ever wish to remove AS YouTube Downloader and its shortcuts completely:

- **Windows**:
  ```powershell
  .\uninstall.ps1
  # Or run installers\uninstall-windows.ps1
  ```
- **Linux**:
  ```bash
  ./uninstall.sh
  # Or run installers/uninstall-linux.sh
  ```
- **macOS**:
  ```bash
  ./uninstall.sh
  # Or run installers/uninstall-macos.sh
  ```

---

<p align="center">
  Crafted with care by <a href="https://github.com/17Arigato-jwd">17Arigato-jwd</a>.
</p>
