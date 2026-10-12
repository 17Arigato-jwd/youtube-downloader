#!/usr/bin/env python3
"""
AS Youtube Downloader — based on yt-dlp — version 1.6.2
"""

import subprocess
import sys
import re
import os
import shutil
import threading
import itertools
import time
from pathlib import Path
from colorama import init, Fore, Style

init(autoreset=True)

# ─── Constants ────────────────────────────────────────────────────────────────

VERSION       = "1.6.2"
DEFAULT_DIR   = str(Path.home() / "Downloads")

AUDIO_FORMATS = ["MP3", "WAV", "FLAC", "M4A", "OPUS"]
VIDEO_FORMATS = ["MP4", "MKV", "WEBM", "AVI"]
ALL_FORMATS   = AUDIO_FORMATS + VIDEO_FORMATS

VIDEO_QUALITY = {
    "lowest":  "worstvideo+worstaudio/worst",
    "360p":    "bestvideo[height<=360]+bestaudio/best[height<=360]",
    "480p":    "bestvideo[height<=480]+bestaudio/best[height<=480]",
    "720p":    "bestvideo[height<=720]+bestaudio/best[height<=720]",
    "1080p":   "bestvideo[height<=1080]+bestaudio/best[height<=1080]",
    "1440p":   "bestvideo[height<=1440]+bestaudio/best[height<=1440]",
    "4k":      "bestvideo[height<=2160]+bestaudio/best[height<=2160]",
    "highest": "bestvideo+bestaudio/best",
}

AUDIO_QUALITY = {
    "lowest":  "9",
    "low":     "6",
    "medium":  "4",
    "high":    "2",
    "highest": "0",
}

# ─── Yes / No Library ─────────────────────────────────────────────────────────

YES_WORDS: set = {
    "yes", "yeah", "y", "yep", "yea", "ya", "yup",
    "true", "tru", "t",
    "affirmative", "sure", "certainly", "absolutely",
    "indeed", "roger", "aye", "ok", "okay", "1",
}

NO_WORDS: set = {
    "no", "nah", "n", "nope", "nay", "nada",
    "false", "f",
    "negative", "nein", "never", "0",
}


def parse_bool(s: str):
    """Return True for yes-like, False for no-like, None for unrecognised."""
    v = s.strip().lower()
    if v in YES_WORDS:
        return True
    if v in NO_WORDS:
        return False
    return None


# ─── Banner ───────────────────────────────────────────────────────────────────

def banner():
    inner_plain = f"  AS Youtube Downloader | based on yt-dlp | version {VERSION}  "
    w = len(inner_plain)
    inner_colored = (
        f"  {Fore.MAGENTA}AS{Fore.WHITE} "
        f"{Fore.RED}Youtube{Fore.WHITE} "
        f"Downloader | based on yt-dlp | version {VERSION}  "
    )
    print(f"\n{Fore.WHITE}╔{'═' * w}╗")
    print(f"{Fore.WHITE}║{inner_colored}{Fore.WHITE}║")
    print(f"{Fore.WHITE}╚{'═' * w}╝{Style.RESET_ALL}\n")


# ─── Terminal Helpers ─────────────────────────────────────────────────────────

def section(title: str):
    bar = "─" * max(2, 40 - len(title))
    print(f"\n{Fore.WHITE}┌─ {title} {bar}")


def check_deps():
    missing = [t for t in ("yt-dlp", "ffmpeg") if shutil.which(t) is None]
    if missing:
        print(f"{Fore.RED}✗  Missing dependencies: {', '.join(missing)}")
        print(f"{Fore.YELLOW}   Install: pip install 'yt-dlp[default,curl-cffi]'  |  https://ffmpeg.org/download.html")
        sys.exit(1)


def detect_js_runtime() -> str | None:
    """
    Crawl well-known filesystem locations for a JavaScript runtime (Node.js,
    Deno, PhantomJS) that may not be visible inside sandboxed / Flatpak
    environments where PATH is stripped down.

    Returns a yt-dlp ``--js-runtimes`` argument string such as
    ``"node:/usr/bin/node"`` for the first verified binary found, or
    ``None`` when no runtime is available on the host.

    Search order (first match wins):
      1. Node.js   — common distro and nvm/fnm install paths
      2. Deno      — common Deno install paths
      3. PhantomJS — legacy fallback
    """
    candidates: list[tuple[str, list[str]]] = [
        ("node", [
            "/usr/bin/node",
            "/usr/local/bin/node",
            "/usr/bin/nodejs",
            "/usr/local/bin/nodejs",
            "/opt/node/bin/node",
            "/opt/nodejs/bin/node",
            str(Path.home() / ".nvm/versions/node"),   # nvm root — walked below
            str(Path.home() / ".fnm/node-versions"),   # fnm root — walked below
        ]),
        ("deno", [
            "/usr/bin/deno",
            "/usr/local/bin/deno",
            str(Path.home() / ".deno/bin/deno"),
        ]),
        ("phantomjs", [
            "/usr/bin/phantomjs",
            "/usr/local/bin/phantomjs",
        ]),
    ]

    def _is_executable(p: str) -> bool:
        return os.path.isfile(p) and os.access(p, os.X_OK)

    for runtime_name, paths in candidates:
        for raw_path in paths:
            p = Path(raw_path)

            # For version-manager roots (nvm/fnm) walk one level deeper to find
            # the actual binary, e.g. ~/.nvm/versions/node/v22.0.0/bin/node
            if not p.exists():
                continue

            if p.is_dir():
                for child in sorted(p.iterdir(), reverse=True):  # newest version first
                    candidate = child / "bin" / runtime_name
                    if _is_executable(str(candidate)):
                        return f"{runtime_name}:{candidate}"
            else:
                if _is_executable(str(p)):
                    return f"{runtime_name}:{p}"

    return None



def ask(prompt: str, default=None, choices: list = None, question: bool = False) -> str:
    """
    Generic prompt.
      question=False  →  "Prompt [default | opt1/opt2]:"    (Source / Format / Output)
      question=True   →  "Prompt? [default | opt1/opt2]:"   (Options section only)
    """
    base   = prompt.rstrip("?:")
    suffix = "?" if question else ""
    q      = base + suffix

    if default is not None and choices:
        bracket = f" {Fore.WHITE}[{Fore.CYAN}{default}{Fore.WHITE} | {'/'.join(choices)}]"
    elif default is not None:
        bracket = f" {Fore.WHITE}[{Fore.CYAN}{default}{Fore.WHITE}]"
    elif choices:
        bracket = f" {Fore.WHITE}[{'/'.join(choices)}]"
    else:
        bracket = ""

    while True:
        raw = input(f"  {Fore.WHITE}{q}{bracket}{Fore.WHITE}: {Style.RESET_ALL}").strip()

        if not raw:
            if default is not None:
                return str(default)
            print(f"  {Fore.RED}✗  This field is required.")
            continue

        if choices:
            if raw.lower() in [c.lower() for c in choices]:
                return raw.lower()
            print(f"  {Fore.RED}✗  Choose one of: {' | '.join(choices)}")
            continue

        return raw


def ask_bool(prompt: str, default: bool = False, question: bool = True) -> bool:
    """
    Yes/no prompt that accepts the full YES_WORDS / NO_WORDS vocabulary.
      question=True  (default) — adds '?'  used in the Options section
      question=False            — no suffix, used for non-option prompts
    """
    base    = prompt.rstrip("?:")
    suffix  = "?" if question else ""
    q       = base + suffix
    def_str = "yes" if default else "no"
    bracket = f" {Fore.WHITE}[{Fore.CYAN}{def_str}{Fore.WHITE} | yes/no]"

    while True:
        raw = input(f"  {Fore.WHITE}{q}{bracket}{Fore.WHITE}: {Style.RESET_ALL}").strip()
        if not raw:
            return default
        result = parse_bool(raw)
        if result is not None:
            return result
        print(f"  {Fore.RED}✗  Please answer yes or no  (y/n, yeah/nah, true/false…)")


# ─── Spinner ──────────────────────────────────────────────────────────────────

class Spinner:
    """Animated spinner that runs in a background thread while yt-dlp starts up."""

    FRAMES = ["|", "/", "─", "\\"]

    def __init__(self, label: str = "Initialising"):
        self.label   = label
        self._stop   = threading.Event()
        self._thread = None

    def _run(self):
        for frame in itertools.cycle(self.FRAMES):
            if self._stop.is_set():
                break
            sys.stdout.write(
                f"\r  {Fore.CYAN}{frame}  {Fore.WHITE}{self.label}…{Style.RESET_ALL}   "
            )
            sys.stdout.flush()
            time.sleep(0.09)

    def start(self):
        self._stop.clear()
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()
        return self

    def stop(self):
        """Stop and erase the spinner line."""
        self._stop.set()
        if self._thread and self._thread.is_alive():
            self._thread.join(timeout=0.4)
        sys.stdout.write("\r\033[K")
        sys.stdout.flush()


# ─── Progress Display ─────────────────────────────────────────────────────────

class Progress:
    """
    3-line block that rewrites itself in place:

        Stage label…   size  speed  ETA
        ──────────────────────────────────────────────────────
        [██│████████████████│████│░░│░░░░]   42%

    Each │ divider marks a phase boundary.  Segment widths are proportional
    to the phase weights, so heavier phases get a wider slice of the bar.
    """

    BAR_WIDTH = 30

    def __init__(self, phases: list):
        """
        phases — ordered list of (key, label, weight)
          key    : identifier used in update() calls
          label  : human-readable stage name
          weight : relative time cost; controls segment width in the bar
        """
        self.phases        = phases
        self._total_weight = sum(w for _, _, w in phases)
        self._phase_map    = {key: i for i, (key, _, _) in enumerate(phases)}
        self._active       = False

        # Pre-compute character positions where │ dividers are inserted
        self._dividers: set = set()
        cumw = 0
        for key, _, w in phases[:-1]:
            cumw += w
            pos = int(self.BAR_WIDTH * cumw / self._total_weight)
            if 0 < pos < self.BAR_WIDTH:
                self._dividers.add(pos)

    # ── Internals ─────────────────────────────────────────────────────────────

    def _bar_fill(self, phase_key: str, within: float) -> float:
        """Overall 0-100 fill for being at `within`% through `phase_key`."""
        idx    = self._phase_map.get(phase_key, 0)
        before = sum(self.phases[i][2] for i in range(idx))
        pw     = self.phases[idx][2]
        return (before + pw * within / 100.0) / self._total_weight * 100.0

    def _draw(self, label: str, fill: float, extra: str = ""):
        filled  = int(self.BAR_WIDTH * max(0.0, min(fill, 100.0)) / 100)
        bar_raw = "█" * filled + "░" * (self.BAR_WIDTH - filled)

        # Build bar string with │ at phase boundaries
        seg = ""
        for i, ch in enumerate(bar_raw):
            if i in self._dividers:
                seg += f"{Fore.WHITE}│{Fore.YELLOW}"
            seg += ch

        pct        = int(fill)
        label_line = f"{Fore.WHITE}{label}"
        if extra:
            label_line += f"  {Fore.WHITE}{extra}"
        rule_line  = f"{Fore.WHITE}{'─' * 54}{Style.RESET_ALL}"
        bar_line   = f"{Fore.WHITE}[{Fore.YELLOW}{seg}{Fore.WHITE}]  {Fore.GREEN}{pct:>3}%"

        if self._active:
            sys.stdout.write("\033[3A")   # move up 3 lines to overwrite

        sys.stdout.write(f"\033[K{label_line}\n")
        sys.stdout.write(f"\033[K{rule_line}\n")
        sys.stdout.write(f"\033[K{bar_line}\n")
        sys.stdout.flush()
        self._active = True

    # ── Public API ────────────────────────────────────────────────────────────

    def update(self, phase_key: str, within: float, extra: str = ""):
        """Redraw the progress block for `phase_key` at `within`% of that phase."""
        if phase_key not in self._phase_map:
            return          # phase was not included for this download — ignore
        idx   = self._phase_map[phase_key]
        label = self.phases[idx][1]
        fill  = self._bar_fill(phase_key, within)
        self._draw(f"{label}…", fill, extra)

    def finish(self, saved_path: str = ""):
        self._draw(f"{Fore.GREEN}✓  Complete!", 100)
        if saved_path:
            print(f"\n{Fore.GREEN}✓  Saved → {Fore.WHITE}{saved_path}")
        else:
            print()


# ─── Startup Updater & Loading Bar ──────────────────────────────────────────

class UpdateBar:
    """
    Animated 3-line loading bar for startup update routine matching Progress UI.
    """
    BAR_WIDTH = 30

    def __init__(self):
        self._active = False

    def draw(self, label: str, fill: float, extra: str = ""):
        fill    = max(0.0, min(fill, 100.0))
        filled  = int(self.BAR_WIDTH * fill / 100)
        bar_raw = "█" * filled + "░" * (self.BAR_WIDTH - filled)

        pct        = int(fill)
        label_line = f"{Fore.WHITE}{label}"
        if extra:
            label_line += f"  {Fore.CYAN}{extra}"
        rule_line  = f"{Fore.WHITE}{'─' * 54}{Style.RESET_ALL}"
        bar_line   = f"{Fore.WHITE}[{Fore.YELLOW}{bar_raw}{Fore.WHITE}]  {Fore.GREEN}{pct:>3}%"

        if self._active:
            sys.stdout.write("\033[3A")   # move up 3 lines to overwrite

        sys.stdout.write(f"\033[K{label_line}\n")
        sys.stdout.write(f"\033[K{rule_line}\n")
        sys.stdout.write(f"\033[K{bar_line}\n")
        sys.stdout.flush()
        self._active = True

    def finish(self, message: str = ""):
        self.draw(f"{Fore.GREEN}✓  {message or 'Complete!'}", 100)
        print()

    def warn(self, message: str = ""):
        self.draw(f"{Fore.YELLOW}⚠  {message or 'Skipped'}", 100)
        print()


def update_ytdlp(timeout: int = 15):
    """
    Check for and apply yt-dlp updates at startup with an animated loading bar.
    Handles yt-dlp self-update (-U), pip upgrades, and offline fallbacks gracefully.
    """
    if shutil.which("yt-dlp") is None:
        return

    bar = UpdateBar()
    bar.draw("Checking for yt-dlp updates…", 5)

    result = {
        "done": False,
        "label": "Connecting to update servers…",
        "message": "",
        "warn": False,
        "fill": 5.0,
    }

    def _worker():
        curr_ver = ""
        try:
            # Step 1: Detect current yt-dlp version
            v_proc = subprocess.run(
                ["yt-dlp", "--version"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=4,
            )
            if v_proc.returncode == 0:
                curr_ver = v_proc.stdout.strip()
                result["label"] = f"Checking latest release (current: v{curr_ver})…"
            else:
                result["label"] = "Checking latest release…"
            result["fill"] = 30.0

            # Step 2: Run yt-dlp -U
            u_proc = subprocess.Popen(
                ["yt-dlp", "-U"],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
            )

            lines = []
            try:
                for line in u_proc.stdout:
                    line_s = line.strip()
                    if line_s:
                        lines.append(line_s)
                    lower = line_s.lower()
                    if "updating to version" in lower or "download" in lower:
                        result["label"] = "Downloading yt-dlp update…"
                        result["fill"] = 65.0
                    elif "installing" in lower:
                        result["label"] = "Installing updated package…"
                        result["fill"] = 85.0
                u_proc.wait(timeout=timeout)
            except subprocess.TimeoutExpired:
                u_proc.kill()
                result["warn"] = True
                result["message"] = f"Update timed out — using v{curr_ver}" if curr_ver else "Update timed out"
                result["done"] = True
                return

            output = " ".join(lines)
            rc = u_proc.returncode

            # If yt-dlp suggests pip upgrade
            if "pip install" in output.lower() and ("installed via pip" in output.lower() or "use:" in output.lower()):
                result["label"] = "Updating yt-dlp via pip…"
                result["fill"] = 75.0
                pip_cmd = [sys.executable, "-m", "pip", "install", "--upgrade", "yt-dlp[default,curl-cffi]"]
                p_proc = subprocess.run(
                    pip_cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    timeout=timeout,
                )
                if p_proc.returncode == 0:
                    v2 = subprocess.run(["yt-dlp", "--version"], stdout=subprocess.PIPE, text=True, timeout=3)
                    new_ver = v2.stdout.strip() if v2.returncode == 0 else ""
                    result["message"] = f"yt-dlp updated to v{new_ver} via pip" if new_ver else "yt-dlp updated via pip"
                else:
                    result["warn"] = True
                    result["message"] = f"yt-dlp is up to date (v{curr_ver})" if curr_ver else "Update check completed"
                result["done"] = True
                return

            if rc == 0:
                if "up to date" in output.lower():
                    result["message"] = f"yt-dlp is up to date (v{curr_ver})" if curr_ver else "yt-dlp is up to date"
                elif "updated" in output.lower() or "installed" in output.lower():
                    v2 = subprocess.run(["yt-dlp", "--version"], stdout=subprocess.PIPE, text=True, timeout=3)
                    new_ver = v2.stdout.strip() if v2.returncode == 0 else ""
                    result["message"] = f"yt-dlp updated to v{new_ver}" if new_ver else "yt-dlp updated successfully"
                else:
                    result["message"] = f"yt-dlp is up to date (v{curr_ver})" if curr_ver else "yt-dlp check complete"
            else:
                if "package manager" in output.lower():
                    result["message"] = f"yt-dlp managed by system package (v{curr_ver})" if curr_ver else "yt-dlp check complete"
                else:
                    result["warn"] = True
                    result["message"] = f"Update check skipped — using v{curr_ver}" if curr_ver else "Update check skipped (offline)"

        except Exception:
            result["warn"] = True
            result["message"] = f"Update check skipped — using v{curr_ver}" if curr_ver else "Update check skipped"
        finally:
            result["done"] = True

    worker_thread = threading.Thread(target=_worker, daemon=True)
    worker_thread.start()

    cur_fill = 5.0
    while not result["done"]:
        target_fill = max(cur_fill, result["fill"])
        if cur_fill < target_fill:
            cur_fill += min(2.5, target_fill - cur_fill)
        elif cur_fill < 88.0:
            cur_fill += 0.8
        bar.draw(result["label"], cur_fill)
        time.sleep(0.08)

    while cur_fill < 100.0:
        cur_fill += 6.0
        bar.draw(result["label"], min(100.0, cur_fill))
        time.sleep(0.02)

    if result.get("warn"):
        bar.warn(result.get("message", "Update check skipped"))
    else:
        bar.finish(result.get("message", "yt-dlp is up to date"))


# ─── Phase Builder ────────────────────────────────────────────────────────────

def build_phases(opts: dict) -> list:
    """
    Return the ordered (key, label, weight) phase list for this download.

    The set of phases — and therefore the number and sizes of bar segments —
    varies dynamically with the user's chosen options:
      • audio format   → "Converting format" instead of "Merging streams"
      • sponsorblock   → extra "Removing sponsor segments" phase
      • chapters       → extra "Splitting chapters" phase
      • metadata       → extra "Embedding metadata" phase
    Weights approximate real relative durations so segment widths feel natural.
    """
    is_audio = opts["fmt"] in AUDIO_FORMATS

    phases = [
        ("init",     "Initialising",  1),
        ("download", "Downloading",   8),
    ]
    if is_audio:
        phases.append(("convert",  "Converting format",        2))
    else:
        phases.append(("merge",    "Merging streams",          2))

    if opts.get("sponsorblock"):
        phases.append(("sponsor",  "Removing sponsor segments", 1))
    if opts.get("chapters"):
        phases.append(("chapters", "Splitting chapters",        1))
    if opts.get("metadata"):
        phases.append(("metadata", "Embedding metadata",        1))

    return phases


# ─── Command Builder ──────────────────────────────────────────────────────────

def build_cmd(url: str, opts: dict) -> list:
    is_audio = opts["fmt"] in AUDIO_FORMATS
    out_tpl  = os.path.join(opts["out_dir"], f"{opts['name']}.%(ext)s")

    cmd = ["yt-dlp", url, "-o", out_tpl, "--newline", "--continue", "--ignore-errors"]

    # Resolve JS runtime explicitly so yt-dlp can solve YouTube's n-challenge
    # even inside sandboxed environments (Flatpak, venv) where PATH is stripped.
    js_runtime = detect_js_runtime()
    if js_runtime:
        cmd += ["--js-runtimes", js_runtime]

    if is_audio:
        cmd += [
            "-f",              "bestaudio/best",
            "--extract-audio",
            "--audio-format",  opts["fmt"].lower(),
            "--audio-quality", AUDIO_QUALITY.get(opts["quality"], "0"),
        ]
    else:
        cmd += [
            "-f",                    VIDEO_QUALITY.get(opts["quality"], "bestvideo+bestaudio/best"),
            "--merge-output-format", opts["fmt"].lower(),
        ]

    if opts.get("metadata"):
        cmd += ["--add-metadata", "--embed-thumbnail", "--convert-thumbnails", "jpg"]

    if opts.get("subtitles"):
        cmd += ["--write-subs", "--write-auto-subs", "--sub-langs", opts.get("sub_lang", "en")]

    if opts.get("sponsorblock"):
        cmd += ["--sponsorblock-remove", "sponsor,intro,outro,selfpromo,interaction"]

    if opts.get("chapters"):
        cmd += ["--split-chapters"]

    if not opts.get("playlist"):
        cmd += ["--no-playlist"]
    else:
        playlist_tpl = os.path.join(opts["out_dir"], "%(playlist_index)s - %(title)s.%(ext)s")
        cmd[cmd.index("-o") + 1] = playlist_tpl

    if opts.get("rate_limit"):
        cmd += ["-r", opts["rate_limit"]]

    if opts.get("cookies_browser"):
        cmd += ["--cookies-from-browser", opts["cookies_browser"]]

    return cmd


# ─── Download Runner ──────────────────────────────────────────────────────────

def run_download(cmd: list, progress: Progress, spinner: Spinner) -> int:
    """Spawn yt-dlp; hand off from spinner to progress bar on first output."""
    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        universal_newlines=True,
    )

    spinner_live = True

    def handoff():
        nonlocal spinner_live
        if spinner_live:
            spinner.stop()
            spinner_live = False

    for line in proc.stdout:
        line = line.rstrip()

        # First recognisable yt-dlp output → kill spinner, show init phase
        if spinner_live and any(k in line for k in ("[youtube]", "[info]", "[Playlist]", "[download]")):
            handoff()
            progress.update("init", 80)

        # Download percentage
        if "[download]" in line and "%" in line:
            m = re.search(
                r"(\d+\.?\d*)%"
                r"(?:\s+of\s+([\d.]+\s*\S+))?"
                r"(?:.*?at\s+([\d.]+\s*\S+/s))?"
                r"(?:.*?ETA\s+([\d:]+))?",
                line,
            )
            if m:
                pct       = float(m.group(1))
                size_str  = m.group(2) or ""
                speed_str = m.group(3) or ""
                eta_str   = f"ETA {m.group(4)}" if m.group(4) else ""
                extra     = "  ".join(filter(None, [size_str, speed_str, eta_str]))
                progress.update("download", pct, extra)

        elif any(k in line for k in ("ExtractAudio", "[ffmpeg]", "Converting")):
            handoff()
            progress.update("convert", 50)

        elif any(k in line for k in ("Merging", "Merger")):
            handoff()
            progress.update("merge", 50)

        elif "[SponsorBlock]" in line:
            handoff()
            progress.update("sponsor", 50)

        elif "SplitChapters" in line:
            handoff()
            progress.update("chapters", 50)

        elif any(k in line for k in ("Metadata", "EmbedThumbnail", "Thumbnail")):
            handoff()
            progress.update("metadata", 50)

    handoff()   # safety: kill spinner even if yt-dlp produced no output
    proc.wait()
    return proc.returncode


# ─── Option Collector ─────────────────────────────────────────────────────────

def collect_options(urls: list) -> dict:
    opts: dict = {}

    if len(urls) == 1 and ("list=" in urls[0] or "playlist" in urls[0].lower()):
        print(f"\n  {Fore.YELLOW}⚑  Playlist URL detected.")
        opts["playlist"] = ask_bool("Download entire playlist", default=False, question=True)
    else:
        opts["playlist"] = False

    # ── Format & Quality ──────────────────────────────────────────────────────
    section("Format & Quality")
    print(f"  {Fore.WHITE}Audio: {Fore.CYAN}{' | '.join(AUDIO_FORMATS)}")
    print(f"  {Fore.WHITE}Video: {Fore.CYAN}{' | '.join(VIDEO_FORMATS)}{Style.RESET_ALL}")

    while True:
        fmt = ask("Format", default="MP3", question=False).upper()
        if fmt in ALL_FORMATS:
            opts["fmt"] = fmt
            break
        print(f"  {Fore.RED}✗  Not a recognised format — see the list above.")

    is_audio = opts["fmt"] in AUDIO_FORMATS

    if is_audio:
        opts["quality"] = ask(
            "Audio quality", default="highest",
            choices=list(AUDIO_QUALITY.keys()), question=False
        )
    else:
        opts["quality"] = ask(
            "Video quality", default="1080p",
            choices=list(VIDEO_QUALITY.keys()), question=False
        )

    # ── Output ────────────────────────────────────────────────────────────────
    section("Output")
    opts["name"]    = ask("Filename / template (no extension)", default="%(title)s", question=False)
    opts["out_dir"] = ask("Output directory", default=DEFAULT_DIR, question=False)
    os.makedirs(opts["out_dir"], exist_ok=True)

    # ── Options ───────────────────────────────────────────────────────────────
    section("Options")
    opts["metadata"]  = ask_bool("Embed metadata & thumbnail", default=True,  question=True)
    opts["subtitles"] = ask_bool("Download subtitles",         default=False, question=True)
    if opts["subtitles"]:
        opts["sub_lang"] = ask("Subtitle language code", default="en", question=False)

    # Defaults for all extra options (overwritten below if sub-menu is opened)
    opts["sponsorblock"]    = False
    opts["chapters"]        = False
    opts["cookies_browser"] = None
    opts["rate_limit"]      = None

    # ── Extra Options Sub-menu ────────────────────────────────────────────────
    if ask_bool("Configure extra options", default=False, question=True):

        if not is_audio:
            opts["sponsorblock"] = ask_bool(
                "Remove sponsor/intro/outro segments (SponsorBlock)",
                default=False, question=True
            )
            opts["chapters"] = ask_bool(
                "Split output by chapters",
                default=False, question=True
            )

        if ask_bool(
            "Use browser cookies (age-restricted / members-only)",
            default=False, question=True
        ):
            opts["cookies_browser"] = ask(
                "Browser", default="chrome",
                choices=["chrome", "firefox", "safari", "edge", "brave"],
                question=False
            )

        if ask_bool("Limit download speed", default=False, question=True):
            opts["rate_limit"] = ask("Max speed (e.g. 2M, 500K)", default="2M", question=False)

    opts["show_bg"] = ask_bool("Show raw yt-dlp output", default=False, question=True)

    return opts


# ─── Single Download ──────────────────────────────────────────────────────────

def download_one(url: str, opts: dict, label: str = ""):
    if label:
        print(f"\n{Fore.WHITE}{label}")

    cmd = build_cmd(url, opts)

    if opts.get("show_bg"):
        result = subprocess.run(cmd)
        if result.returncode != 0:
            print(f"{Fore.RED}✗  yt-dlp exited with code {result.returncode}.")
        return

    phases   = build_phases(opts)
    spinner  = Spinner("Initialising").start()
    progress = Progress(phases)

    rc = run_download(cmd, progress, spinner)

    if rc == 0:
        saved = os.path.join(opts["out_dir"], f"{opts['name']}.{opts['fmt'].lower()}")
        progress.finish(saved)
    else:
        print(f"\n\n\n{Fore.RED}✗  yt-dlp exited with code {rc}.")
        print(f"   {Fore.YELLOW}Re-run with 'Show raw yt-dlp output = yes' for details.")


# ─── Entry Point ──────────────────────────────────────────────────────────────

def main():
    banner()
    check_deps()

    try:
        if "--no-update" not in sys.argv and "--skip-update" not in sys.argv:
            section("Updates")
            update_ytdlp()

        if "--update" in sys.argv:
            sys.exit(0)

        section("Source")
        mode = ask("Mode", default="single", choices=["single", "batch"], question=False)

        if mode == "batch":
            print(f"\n  {Fore.YELLOW}Enter URLs one per line — blank line to finish.")
            urls = []
            while True:
                u = input(f"  {Fore.WHITE}URL {len(urls) + 1}: {Style.RESET_ALL}").strip()
                if not u:
                    break
                urls.append(u)
            if not urls:
                print(f"{Fore.RED}✗  No URLs entered. Exiting.")
                return
        else:
            urls = [ask("YouTube URL", question=False)]

        opts = collect_options(urls)

        print()
        for i, url in enumerate(urls, 1):
            label = f"[{i}/{len(urls)}]  {url}" if len(urls) > 1 else ""
            download_one(url, opts, label=label)

        if len(urls) > 1:
            print(f"\n{Fore.GREEN}✓  All {len(urls)} downloads finished.")

    except KeyboardInterrupt:
        print(f"\n\n\n\n{Fore.RED}✗  Interrupted.")
        sys.exit(0)


if __name__ == "__main__":
    main()
