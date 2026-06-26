#!/usr/bin/env python3
"""Generate lightweight offline image assets from the URLs already in Dart.

Usage:
  python tools/download_offline_images.py
  python tools/download_offline_images.py --only games
  python tools/download_offline_images.py --force

Requires Pillow:
  python -m pip install pillow
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from dataclasses import dataclass
from io import BytesIO
from pathlib import Path
from typing import Iterable
from urllib.parse import quote, unquote, urlencode, urlparse
from urllib.request import Request, urlopen

try:
    from PIL import Image
except Exception as exc:  # pragma: no cover - user environment guard
    print("Pillow is required: python -m pip install pillow", file=sys.stderr)
    print(f"Import error: {exc}", file=sys.stderr)
    sys.exit(2)


ROOT = Path(__file__).resolve().parents[1]
DATA_FILE = ROOT / "lib" / "src" / "data" / "game_data.dart"
MODELS_FILE = ROOT / "lib" / "src" / "models" / "models.dart"

USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/120.0 Safari/537.36 LabTrackerOfflineImageBuilder/1.0"
)
DEFAULT_QUALITY = 72
MAX_WIDTH_BY_KIND = {
    "games": 512,
    "characters": 384,
    "smash-covers": 384,
}


@dataclass(frozen=True)
class ImageTask:
    kind: str
    label: str
    url: str
    output: Path


CHARACTER_CONFIGS = [
    {
        "game": "Super Smash Bros. Ultimate",
        "folder": "smash",
        "maps": ["imagensSmash"],
    },
    {
        "game": "Street Fighter 6",
        "folder": "street_fighter_6",
        "maps": ["imagensStreetFighter6"],
        "wiki": "streetfighter.fandom.com",
    },
    {
        "game": "Mortal Kombat 1",
        "folder": "mortal_kombat_1",
        "maps": ["imagensMortalKombat1"],
        "wiki": "mortalkombat.fandom.com",
    },
    {
        "game": "Dragon Ball FighterZ",
        "folder": "dragon_ball_fighterz",
        "maps": ["imagensDBFZ"],
    },
    {
        "game": "Fatal Fury",
        "folder": "fatal_fury",
        "maps": ["imagensFatalFury"],
    },
    {
        "game": "Invincible VS",
        "folder": "invincible_vs",
        "maps": ["imagensInvincible"],
    },
    {
        "game": "2XKO",
        "folder": "2xko",
        "maps": ["imagens2XKO"],
    },
    {
        "game": "Avatar Legends: The Fighting Game",
        "folder": "avatar_legends",
        "maps": ["imagensAvatarLegends"],
        "wiki": "avatar.fandom.com",
    },
    {
        "game": "Guilty Gear -Strive-",
        "folder": "guilty_gear_strive",
        "maps": ["imagensOficiaisGuiltyGearStrive", "imagensGuiltyGearStrive"],
        "wiki": "guiltygear.fandom.com",
    },
    {
        "game": "The King of Fighters XV",
        "folder": "kof_xv",
        "maps": ["imagensKofXV"],
        "wiki": "snk.fandom.com",
    },
    {
        "game": "Tekken 8",
        "folder": "tekken_8",
        "maps": ["imagensTekken8"],
        "wiki": "tekken.fandom.com",
    },
    {
        "game": "Rivals of Aether II",
        "folder": "rivals_of_aether_ii",
        "maps": ["imagensRivalsOfAether2"],
        "wiki": "rivals-of-aether.fandom.com",
    },
]

SMASH_COVERS = [
    (
        "Villager male",
        "https://ssb.wiki.gallery/images/a/ac/Villager_SSBU.png",
        "assets/offline_images/smash_covers/villager_male.webp",
    ),
    (
        "Villager female",
        "https://ssb.wiki.gallery/images/c/c7/VillagerAltTrophyWiiU.png",
        "assets/offline_images/smash_covers/villager_female.webp",
    ),
    (
        "Wii Fit Trainer female",
        "https://ssb.wiki.gallery/images/f/ff/Wii_Fit_Trainer_SSBU.png",
        "assets/offline_images/smash_covers/wii_fit_trainer_female.webp",
    ),
    (
        "Wii Fit Trainer male",
        "https://ssb.wiki.gallery/images/9/9c/Wii_Fit_Trainer-Alt1_SSBU.png",
        "assets/offline_images/smash_covers/wii_fit_trainer_male.webp",
    ),
    (
        "Robin male",
        "https://ssb.wiki.gallery/images/8/82/Robin_SSBU.png",
        "assets/offline_images/smash_covers/robin_male.webp",
    ),
    (
        "Robin female",
        "https://ssb.wiki.gallery/images/0/03/Robin-Alt1_SSBU.png",
        "assets/offline_images/smash_covers/robin_female.webp",
    ),
    (
        "Corrin male",
        "https://ssb.wiki.gallery/images/c/c4/Corrin_SSBU.png",
        "assets/offline_images/smash_covers/corrin_male.webp",
    ),
    (
        "Corrin female",
        "https://ssb.wiki.gallery/images/b/b5/Corrin-Alt1_SSBU.png",
        "assets/offline_images/smash_covers/corrin_female.webp",
    ),
    (
        "Inkling female",
        "https://ssb.wiki.gallery/images/2/2e/Inkling_SSBU.png",
        "assets/offline_images/smash_covers/inkling_female.webp",
    ),
    (
        "Inkling male",
        "https://ssb.wiki.gallery/images/5/56/Inkling-Alt1_SSBU.png",
        "assets/offline_images/smash_covers/inkling_male.webp",
    ),
    (
        "Pokemon Trainer male",
        "https://ssb.wiki.gallery/images/2/28/Pok%C3%A9mon_Trainer_%28solo%29_SSBU.png",
        "assets/offline_images/smash_covers/pokemon_trainer_male.webp",
    ),
    (
        "Pokemon Trainer female",
        "https://ssb.wiki.gallery/images/6/6c/Pok%C3%A9mon_Trainer_%28solo%29-Alt1_SSBU.png",
        "assets/offline_images/smash_covers/pokemon_trainer_female.webp",
    ),
    (
        "Byleth male",
        "https://ssb.wiki.gallery/images/3/3d/Byleth_SSBU.png",
        "assets/offline_images/smash_covers/byleth_male.webp",
    ),
    (
        "Byleth female",
        "https://ssb.wiki.gallery/images/c/cc/Byleth-Alt1_SSBU.png",
        "assets/offline_images/smash_covers/byleth_female.webp",
    ),
    (
        "Mii Brawler male",
        "https://static.wikia.nocookie.net/ssb/images/e/e8/Mii_Brawler_-_Super_Smash_Bros._for_Nintendo_3DS_and_Wii_U.png/revision/latest?cb=20150902080957",
        "assets/offline_images/smash_covers/mii_brawler_male.webp",
    ),
    (
        "Mii Brawler female",
        "https://static.wikia.nocookie.net/ssb/images/b/b4/Mii_Brawler_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180705150043",
        "assets/offline_images/smash_covers/mii_brawler_female.webp",
    ),
    (
        "Mii Swordfighter male",
        "https://static.wikia.nocookie.net/ssb/images/2/25/Mii_Swordfighter_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20180705145938",
        "assets/offline_images/smash_covers/mii_swordfighter_male.webp",
    ),
    (
        "Mii Swordfighter female",
        "https://static.wikia.nocookie.net/ssb/images/9/90/Mii_Swordfighter.png/revision/latest?cb=20140908212918",
        "assets/offline_images/smash_covers/mii_swordfighter_female.webp",
    ),
    (
        "Mii Gunner male",
        "https://static.wikia.nocookie.net/ssb/images/6/6f/Mii_Gunner_-_Super_Smash_Bros._for_Nintendo_3DS_and_Wii_U.png/revision/latest?cb=20150902081004",
        "assets/offline_images/smash_covers/mii_gunner_male.webp",
    ),
    (
        "Mii Gunner female",
        "https://static.wikia.nocookie.net/ssb/images/e/ea/Mii_Gunner_-_Super_Smash_Bros._Ultimate.png/revision/latest?cb=20240401031836",
        "assets/offline_images/smash_covers/mii_gunner_female.webp",
    ),
]


def fix_legacy_text(text: str) -> str:
    fixed = text
    for _ in range(2):
        try:
            next_value = fixed.encode("latin1").decode("utf-8")
        except UnicodeError:
            break
        if next_value == fixed:
            break
        fixed = next_value
    return fixed


def safe_name(value: str) -> str:
    fixed = fix_legacy_text(value).lower().replace("&", " and ")
    normalized = unicodedata.normalize("NFKD", fixed)
    ascii_text = normalized.encode("ascii", "ignore").decode("ascii")
    slug = re.sub(r"[^a-z0-9]+", "_", ascii_text)
    slug = re.sub(r"_+", "_", slug).strip("_")
    return slug or "image"


def read_sources() -> tuple[str, str, dict[str, str]]:
    data = DATA_FILE.read_text(encoding="utf-8")
    models = MODELS_FILE.read_text(encoding="utf-8")
    constants = dict(re.findall(r"const\s+String\s+(\w+)\s*=\s*'([^']*)';", models))
    return data, models, constants


def find_map_block(source: str, map_name: str) -> str:
    match = re.search(rf"const\s+Map<[^=]+>\s+{re.escape(map_name)}\s*=\s*{{", source)
    if not match:
        return ""

    start = source.find("{", match.start())
    depth = 0
    in_string: str | None = None
    escaped = False

    for index in range(start, len(source)):
        char = source[index]
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == in_string:
                in_string = None
            continue

        if char in ("'", '"'):
            in_string = char
            continue
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return source[start + 1 : index]

    return ""


def dart_string_literals(raw: str) -> list[str]:
    literals: list[str] = []
    for match in re.finditer(r"'([^'\\]*(?:\\.[^'\\]*)*)'|\"([^\"\\]*(?:\\.[^\"\\]*)*)\"", raw):
        value = match.group(1) if match.group(1) is not None else match.group(2)
        literals.append(value.replace("\\'", "'").replace('\\"', '"'))
    return literals


def parse_string_map(source: str, map_name: str, constants: dict[str, str]) -> dict[str, str]:
    block = find_map_block(source, map_name)
    if not block:
        return {}

    result: dict[str, str] = {}
    entry_pattern = re.compile(
        r"(?P<key>\w+|'[^']*'|\"[^\"]*\")\s*:\s*"
        r"(?P<value>(?:'[^'\\]*(?:\\.[^'\\]*)*'|\"[^\"\\]*(?:\\.[^\"\\]*)*\"\s*)+)",
        re.S,
    )

    for match in entry_pattern.finditer(block):
        key_raw = match.group("key").strip()
        if key_raw.startswith(("'", '"')):
            key = dart_string_literals(key_raw)[0]
        else:
            key = constants.get(key_raw, key_raw)

        value = "".join(dart_string_literals(match.group("value"))).strip()
        if key and value:
            result[fix_legacy_text(key)] = value

    return result


def fandom_file_url(wiki: str | None, value: str) -> str:
    value = value.strip()
    if not value:
        return ""
    if value.startswith(("http://", "https://")):
        return value
    if not wiki:
        return value
    return f"https://{wiki}/wiki/Special:Redirect/file/{quote(value)}"


def resolve_fandom_redirect_url(url: str, timeout: int) -> str:
    parsed = urlparse(url)
    marker = "/wiki/Special:Redirect/file/"
    if marker not in parsed.path:
        return url

    file_name = unquote(parsed.path.split(marker, 1)[1])
    if not file_name:
        return url

    query = urlencode(
        {
            "action": "query",
            "titles": f"File:{file_name}",
            "prop": "imageinfo",
            "iiprop": "url",
            "format": "json",
        }
    )
    api_url = f"{parsed.scheme}://{parsed.netloc}/api.php?{query}"
    request = Request(api_url, headers={"User-Agent": USER_AGENT})

    with urlopen(request, timeout=timeout) as response:
        payload = json.loads(response.read().decode("utf-8"))

    pages = payload.get("query", {}).get("pages", {})
    for page in pages.values():
        image_info = page.get("imageinfo") or []
        if image_info and image_info[0].get("url"):
            return image_info[0]["url"]

    return url


def game_tasks(data: str, constants: dict[str, str]) -> list[ImageTask]:
    logos = parse_string_map(data, "logosJogos", constants)
    offline = parse_string_map(data, "logosJogosOffline", constants)
    tasks: list[ImageTask] = []

    for game, url in logos.items():
        output = offline.get(game)
        if not output:
            continue
        tasks.append(ImageTask("games", game, url, ROOT / output))

    return tasks


def kof_tasks(data: str, constants: dict[str, str]) -> dict[str, str]:
    ids = parse_string_map(data, "idsKofXV", constants)
    return {
        character: (
            "https://www.snk-corp.co.jp/us/games/kof-xv/characters/img/"
            f"character_{identifier}.png"
        )
        for character, identifier in ids.items()
    }


def character_tasks(data: str, constants: dict[str, str]) -> list[ImageTask]:
    tasks: list[ImageTask] = []

    for config in CHARACTER_CONFIGS:
        game = config["game"]
        folder = config["folder"]
        wiki = config.get("wiki")
        merged: dict[str, str] = {}

        if game == "The King of Fighters XV":
            merged.update(kof_tasks(data, constants))

        for map_name in config["maps"]:
            values = parse_string_map(data, map_name, constants)
            for character, value in values.items():
                merged.setdefault(character, fandom_file_url(wiki, value))

        for character, url in merged.items():
            if not url.startswith(("http://", "https://")):
                continue
            output = (
                ROOT
                / "assets"
                / "offline_images"
                / "characters"
                / folder
                / f"{safe_name(character)}.webp"
            )
            tasks.append(ImageTask("characters", f"{game} / {character}", url, output))

    return tasks


def smash_cover_tasks() -> list[ImageTask]:
    return [
        ImageTask("smash-covers", label, url, ROOT / output)
        for label, url, output in SMASH_COVERS
    ]


def all_tasks(selected: str) -> list[ImageTask]:
    data, _, constants = read_sources()
    groups = {
        "games": game_tasks(data, constants),
        "characters": character_tasks(data, constants),
        "smash-covers": smash_cover_tasks(),
    }
    if selected == "all":
        return [task for tasks in groups.values() for task in tasks]
    return groups[selected]


def download_bytes(url: str, timeout: int) -> bytes:
    resolved_url = resolve_fandom_redirect_url(url, timeout)
    request = Request(resolved_url, headers={"User-Agent": USER_AGENT})
    with urlopen(request, timeout=timeout) as response:
        return response.read()


def save_webp(data: bytes, output: Path, max_width: int, quality: int) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    with Image.open(BytesIO(data)) as image:
        image.load()
        image.thumbnail((max_width, max_width * 4), Image.Resampling.LANCZOS)
        if image.mode not in ("RGB", "RGBA"):
            image = image.convert("RGBA" if "A" in image.getbands() else "RGB")
        image.save(output, "WEBP", quality=quality, method=6)


def run() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--only",
        choices=["all", "games", "characters", "smash-covers"],
        default="all",
    )
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--quality", type=int, default=DEFAULT_QUALITY)
    parser.add_argument("--timeout", type=int, default=20)
    parser.add_argument(
        "--match",
        default="",
        help="Only run tasks whose label or output path contains this text.",
    )
    args = parser.parse_args()

    tasks = all_tasks(args.only)
    if args.match.strip():
        needle = args.match.strip().lower()
        tasks = [
            task
            for task in tasks
            if needle in task.label.lower()
            or needle in str(task.output.relative_to(ROOT)).lower()
        ]
    print(f"Found {len(tasks)} image tasks.", flush=True)

    failures = 0
    skipped = 0
    written = 0

    for task in tasks:
        relative_output = task.output.relative_to(ROOT)
        if task.output.exists() and not args.force:
            skipped += 1
            print(f"SKIP {relative_output}", flush=True)
            continue

        print(f"GET  {task.label} -> {relative_output}", flush=True)
        if args.dry_run:
            continue

        try:
            raw = download_bytes(task.url, args.timeout)
            save_webp(
                raw,
                task.output,
                MAX_WIDTH_BY_KIND[task.kind],
                args.quality,
            )
            written += 1
        except Exception as exc:
            failures += 1
            print(f"FAIL {task.label}: {exc}", file=sys.stderr, flush=True)

    print(f"Done. written={written} skipped={skipped} failed={failures}", flush=True)
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(run())
