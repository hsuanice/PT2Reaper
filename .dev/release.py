#!/usr/bin/env python3
# @noindex  (local maintenance tool for this repository, not a ReaPack package)
"""PT2Reaper: (re)write the ReaPack headers of the published files (local dev tool).

Adapted from hsuanice/ReaScripts .dev/migrate.py (same header rules, same integrity checks).

usage (from the repository root):
  python3 .dev/release.py publish.json "bullet" ["bullet" ...]          # dry run: report only
  python3 .dev/release.py publish.json "bullet" ["bullet" ...] --write  # rewrite in place
  add --all to rewrite every published file (default: only files changed since the last commit)
  add --pre for a pre-release (version ...pre1; use it until hsuanice has tested in REAPER)

The bullets are the package changelog. A changed file whose header is already in release
format (--[[ ... @noindex ... ]]) keeps its own @changelog bullets; other files get the
package bullets. .gitignore is regenerated from publish.json (whitelist).

publish.json: {"scripts": ["file.lua", ...],   # PRO TOOLS/ files shown in the Action List ([main])
               "libs":    ["file.lua", ...],   # PRO TOOLS/ files loaded by the scripts ([nomain])
               "shortcuts": {"file.lua": "Cmd+S", ...}}   # suggested keys for the About text

What it does:
  - every published file gets a --[[ ]] header: @version = Taipei YY.MMDD.HHMM, @noindex,
    @changelog = the bullets given (this release only); the old header changelog is appended
    to Changelogs/<file>.md (full history stays in the repository)
  - PRO TOOLS/hsuanice_PT2Reaper.lua = the one ReaPack package (@metapackage, @provides all files)
  - the code below the header is verified byte-identical; no header line may get lost
"""
import json, os, re, subprocess, sys, textwrap

CAT = "PRO TOOLS"
META = "hsuanice_PT2Reaper.lua"
CL_URL = "https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs"
FULL = f"Full history: Changelogs/ in the repository ({CL_URL})"
KEYS_NOTE = ("Shortcuts are suggestions only (the Pro Tools keys) - nothing is assigned automatically. "
             "macOS names; on Windows Cmd = Ctrl, Option = Alt, Control = Win.")

TAG_RE = re.compile(r"^@(\w+)[ \t]*(.*)$")
BLOCK_END_RE = re.compile(r"^\s*(--)?\]\](--)?\s*$")
HANDLED = ("description", "version", "author", "link", "links", "provides", "changelog",
           "noindex", "metapackage")

ABOUT = """# PT2Reaper

Pro Tools style editing for REAPER: one REAPER action per Pro Tools command, named after the
Pro Tools command (Action List: search "Pro Tools").

Highlights
- Nudge: clip / clip start / end / contents / selection / play, by the Nudge value of the
  Grid Nudge Panel (Pro Tools Nudge presets: Measure, Min:Secs, Timecode, Feet+Frames, Samples).
- Edit selection: Tab to Transient, Move / Extend / Shrink Edit Selection, Double / Halve,
  Separate Clip (at selection, on grid, at transients), Trim, Clear / Delete with partial fades.
- Fades: Create Fades, Delete Fades, fade shapes, crossfades.
- Transport: Play/Stop, Play Half Speed, Insertion Follows Playback, QuickPunch and Record Punch
  (punch in / out while playing; the pass records in the background on hidden "QP buffer" tracks).

How to use
- Nothing is bound automatically. A good way: put the Pro Tools keys in an alternate keymap
  section (Action List > Section: "Main (alt-1)") and switch with
  "Main action section: Toggle override to alt-1", so your own REAPER keys stay untouched.
- The Grid Nudge Panel shows and sets the Grid and Nudge values.

Requirements
- REAPER 7.
- js_ReaScriptAPI (optional): the Grid Nudge Panel gives the keyboard focus back to the
  arrange view after a click.

Credits
- Transport (Play/Stop, Play Half Speed, Insertion Follows Playback): behaviour modelled on
  TJF Scripts by Tim Farrell (github.com/sonictim/TJF-Scripts).
- Pro Tools is a trademark of Avid Technology; this project is not affiliated with Avid.
- Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice."""


def split_header(lines):
    first = lines[0].rstrip("\n")
    if first.startswith("--[["):
        content = [first[4:].strip()] if first[4:].strip() else []
        for i in range(1, len(lines)):
            if BLOCK_END_RE.match(lines[i]):
                return content, i + 1
            content.append(lines[i].rstrip("\n"))
        sys.exit("unterminated header block")
    content = []
    for i, ln in enumerate(lines):
        if not ln.startswith("--"):
            return content, i
        body = ln.rstrip("\n")[2:]
        content.append(body[1:] if body.startswith(" ") else body)
    sys.exit("header never ends")


def parse_tags(content):
    tags, order, cur = {}, [], None
    for ln in content:
        m = TAG_RE.match(ln)
        if m:
            cur = m.group(1).lower()
            cur = "notes" if cur == "note" else cur
            if cur not in tags:
                tags[cur] = []
                order.append(cur)
            if m.group(2).strip():
                tags[cur].append(m.group(2).rstrip())
        elif cur:
            tags[cur].append(ln.rstrip())
        elif ln.strip():
            tags.setdefault("_pre", []).append(ln.rstrip())
    for v in tags.values():
        while v and not v[0].strip():
            v.pop(0)
        while v and not v[-1].strip():
            v.pop()
    return tags, order


def block(tag, values):
    if not values:
        return [f"@{tag}"]
    vals = textwrap.dedent("\n".join(values)).split("\n")
    if len(vals) == 1 and tag in ("description", "version", "author"):
        return [f"@{tag} {vals[0]}"]
    return [f"@{tag}"] + [("  " + v) if v.strip() else "" for v in vals]


def changelog_md(name, desc, version, bullets, old_v, old_cl, existing):
    head = f"# {name} — Changelog\n\n{desc}\n\n"
    entry = f"## {version}\n\n" + "".join(f"- {b}\n" for b in bullets) + "\n"
    if old_cl:
        entry += (f"History before {version} (moved out of the script header; last header version: "
                  f"`{old_v}`).\n\n```text\n" + textwrap.dedent("\n".join(old_cl)).strip("\n") + "\n```\n\n")
    if existing:  # newest first, below the title block
        rest = existing.split("\n## ", 1)
        return head + entry + ("## " + rest[1] if len(rest) > 1 else "")
    return head + entry


def convert(root, rel, version, bullets, write):
    path = os.path.join(root, rel)
    lines = open(path, encoding="utf-8").readlines()
    content, n = split_header(lines)
    tags, order = parse_tags(content)
    own = [l.strip()[2:] for l in tags.get("changelog", []) if l.strip().startswith("- ")
           and not l.strip().startswith("- Full history")]
    if lines[0].startswith("--[[") and "noindex" in tags and own:
        bullets = own        # already in release format: its own changelog is this release
        tags["changelog"] = []  # (nothing older to move to Changelogs/)
    name = os.path.basename(rel)
    pre = tags.pop("_pre", [])
    if pre and "description" not in tags:
        tags["description"], pre = [pre[0]], pre[1:]
    if pre:
        tags["about"] = pre + ([""] if tags.get("about") else []) + tags.get("about", [])
        if "about" not in order:
            order.insert(0, "about")
    desc = list(tags.get("description", [name[:-4]]))
    # file names have no brackets (Name [X] -> Name - X, Clip[s] -> Clips): same in the description
    d0 = re.sub(r"\s*\[([^\]]*)\]", r" - \1", desc[0].replace("[s]", "s").replace("(s)", "s"))
    desc[0] = re.sub(r"\s+", " ", d0).strip()
    hdr = ["--[["] + block("description", desc) + [f"@version {version}", "@author hsuanice", "@noindex"]
    hdr += block("changelog", [f"- {b}" for b in bullets] + [f"- {FULL}"])
    for t in order:
        if t not in HANDLED:
            hdr += block(t, tags[t])
    links = tags.get("link", []) + tags.get("links", [])
    if links:
        hdr += block("links", links)
    hdr.append("--]]")
    body = "".join(lines[n:])
    body = body if body.startswith("\n") or not body else "\n" + body
    new = "\n".join(hdr) + "\n" + body
    kept = "\n".join(hdr) + "\n" + "\n".join(tags.get("changelog", []))
    lost = [l for l in content if l.strip() and l.strip() not in kept and not TAG_RE.match(l.strip())
            and l.rstrip() not in tags.get("provides", []) + tags.get("version", [])]
    if lost:
        sys.exit(f"LOST header lines in {name}: {lost[:5]}")
    if not new.endswith("".join(lines[n:])):
        sys.exit(f"BODY CHANGED in {name}")
    old_v = " ".join(tags.get("version", ["?"]))
    if write:
        open(path, "w", encoding="utf-8", newline="\n").write(new)
        cl = os.path.join(root, "Changelogs", name[:-4] + ".md")
        os.makedirs(os.path.dirname(cl), exist_ok=True)
        existing = open(cl, encoding="utf-8").read() if os.path.exists(cl) else ""
        open(cl, "w", encoding="utf-8", newline="\n").write(
            changelog_md(name, " ".join(desc), version, bullets, old_v, tags.get("changelog", []), existing))
    return f"{name:70} {old_v[:24]:24} hdr {n:4} -> {len(hdr):3}"


def main():
    args = [a for a in sys.argv[1:] if a not in ("--write", "--all", "--pre")]
    write = "--write" in sys.argv
    if len(args) < 2:
        sys.exit(__doc__)
    cfg = json.load(open(args[0], encoding="utf-8"))
    bullets = args[1:]
    root = os.getcwd()
    version = subprocess.run(["date", "+%y.%m%d.%H%M"], env={**os.environ, "TZ": "Asia/Taipei"},
                             capture_output=True, text=True, check=True).stdout.strip()
    if "--pre" in sys.argv:
        version += "pre1"
    files = ["hsuanice_PT2Reaper.lua"] + cfg["scripts"] + cfg["libs"]
    gi = ["# Whitelist: only the published PT2Reaper files are tracked (generated by .dev/release.py).",
          "# Everything else in PRO TOOLS/ (unfinished stubs, local tools, SelectionSync) stays local.",
          "/*", "!/.gitignore", "!/.github/", "!/.reapack-index.conf", "!/README.md", "!/index.xml",
          "!/Changelogs/", "!/.dev/", "", "!/PRO TOOLS/", "/PRO TOOLS/*"] \
         + [f"!/PRO TOOLS/{f}" for f in sorted(files)] + ["", ".DS_Store", "__pycache__/", ""]
    if write:
        open(os.path.join(root, ".gitignore"), "w", encoding="utf-8", newline="\n").write("\n".join(gi))
    todo = cfg["scripts"] + cfg["libs"]
    if "--all" not in sys.argv:
        st = subprocess.run(["git", "status", "--porcelain", "--untracked-files=all", "--ignored=no", "--", CAT],
                            capture_output=True, text=True, cwd=root).stdout
        changed = {l[3:].strip().strip('"').split("/", 1)[-1] for l in st.splitlines()}
        new_files = [f for f in todo if subprocess.run(["git", "ls-files", "--error-unmatch", f"{CAT}/{f}"],
                     capture_output=True, cwd=root).returncode != 0]
        todo = [f for f in todo if f in changed or f in new_files]
    report = []
    for f in todo:
        report.append(convert(root, f"{CAT}/{f}", version, bullets, write))
    keys = cfg.get("shortcuts", {})
    rows = [f"- {f[len('hsuanice_Pro Tools '):-4] if f.startswith('hsuanice_Pro Tools ') else f[:-4]}: {keys[f]}"
            for f in sorted(cfg["scripts"]) if keys.get(f)]
    about = ABOUT.split("\n") + (["", "## Suggested shortcuts (Pro Tools keys)", *rows, "", KEYS_NOTE] if rows else [])
    meta = (["--[[", "@description PT2Reaper - Pro Tools style editing, nudge, fades and QuickPunch for REAPER",
             f"@version {version}", "@author hsuanice", "@metapackage", "@provides"]
            + [f"  [main] {f}" for f in sorted(cfg["scripts"])]
            + [f"  [nomain] {f}" for f in sorted(cfg["libs"])]
            + block("changelog", [f"- {b}" for b in bullets] + [f"- {FULL}"])
            + block("about", about)
            + ["@links", "  GitHub https://github.com/hsuanice/PT2Reaper",
               "  Forum thread https://forum.cockos.com/showthread.php?p=2910884#post2910884",
               "--]]", "-- This file only describes the package for ReaPack; it is not installed.", ""])
    if write:
        open(os.path.join(root, CAT, META), "w", encoding="utf-8", newline="\n").write("\n".join(meta))
        cl = os.path.join(root, "Changelogs", META[:-4] + ".md")
        existing = open(cl, encoding="utf-8").read() if os.path.exists(cl) else ""
        open(cl, "w", encoding="utf-8", newline="\n").write(
            changelog_md(META, "PT2Reaper package", version, bullets, "-", [], existing))
    print(f"version {version}  ({'WRITTEN' if write else 'dry run'})")
    print(f"package {META}: {len(cfg['scripts'])} [main] + {len(cfg['libs'])} [nomain], {len(rows)} suggested keys")
    print("\n".join(report))


if __name__ == "__main__":
    main()
