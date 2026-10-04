"""Bake tiled road segments into default.project.json from an exported road model.

Export once from Studio (edit mode, not Play):
  1. Select Workspace.Road (or ServerStorage.RoadTemplate)
  2. Right-click → Save to File…
  3. Save as:  assets/Road.rbxmx   (XML)  or  assets/Road.rbxm

Then run:  python tools/bake_plots.py
"""

from __future__ import annotations

import json
import math
import re
import shutil
import uuid
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(r"c:\Desktop\Roblox\DessertEmpire")
ASSETS = ROOT / "assets"
PROJECT = ROOT / "default.project.json"

# Keep in sync with src/shared/TycoonConfig.luau
PLOT = dict(
    CountPerSide=4,
    Width=280,
    Depth=400,
    Gap=40,
    StreetHalfWidth=40,
    PadHeight=1,
    PadY=3,
)
ROAD = dict(
    YOffset=0.05,
    Overlap=0.25,
)


def studs():
    return {
        s: "Studs"
        for s in (
            "TopSurface",
            "BottomSurface",
            "LeftSurface",
            "RightSurface",
            "FrontSurface",
            "BackSurface",
        )
    }


def cframe(pos, yaw_degrees: float = 0.0):
    theta = math.radians(yaw_degrees)
    c, s = math.cos(theta), math.sin(theta)
    r00, r01, r02 = c, 0.0, s
    r10, r11, r12 = 0.0, 1.0, 0.0
    r20, r21, r22 = -s, 0.0, c
    return [
        float(pos[0]),
        float(pos[1]),
        float(pos[2]),
        r00,
        r01,
        r02,
        r10,
        r11,
        r12,
        r20,
        r21,
        r22,
    ]


def part_props(color, size, pos, yaw_degrees: float = 0.0, **extra):
    return {
        "Anchored": True,
        "Material": "Plastic",
        "Color": [round(c / 255, 5) for c in color],
        "Size": [float(size[0]), float(size[1]), float(size[2])],
        "CFrame": cframe(pos, yaw_degrees),
        **studs(),
        **extra,
    }


def find_road_export() -> Path | None:
    for name in ("Road.rbxmx", "Road.rbxm", "road.rbxmx", "road.rbxm"):
        path = ASSETS / name
        if path.is_file() and path.stat().st_size > 0:
            return path
    return None


def _local_name(tag: str) -> str:
    return tag.split("}")[-1] if "}" in tag else tag


def _parse_vector3(props: ET.Element, name: str) -> tuple[float, float, float] | None:
    want = name.lower()
    for child in props:
        if _local_name(child.tag) != "Vector3":
            continue
        if (child.get("name") or "").lower() != want:
            continue
        comps = {}
        for comp in child:
            comps[_local_name(comp.tag).upper()] = float(comp.text or 0)
        if {"X", "Y", "Z"} <= comps.keys():
            return comps["X"], comps["Y"], comps["Z"]
    return None


def _parse_world_pivot(model_item: ET.Element) -> tuple[float, float, float] | None:
    for props in model_item:
        if _local_name(props.tag) != "Properties":
            continue
        for child in props:
            if _local_name(child.tag) != "OptionalCoordinateFrame":
                continue
            if child.get("name") != "WorldPivotData":
                continue
            for cf in child:
                if _local_name(cf.tag) != "CFrame":
                    continue
                comps = {_local_name(c.tag): float(c.text or 0) for c in cf}
                if {"X", "Y", "Z"} <= comps.keys():
                    return comps["X"], comps["Y"], comps["Z"]
    return None


def measure_rbxmx(path: Path) -> dict:
    """Return size + whether length is on Z (needs 90° yaw)."""
    tree = ET.parse(path)
    root = tree.getroot()
    sizes: list[tuple[float, float, float]] = []
    world_pivot = None

    for item in root.iter():
        if _local_name(item.tag) != "Item":
            continue
        class_name = item.get("class", "")
        if class_name == "Model" and world_pivot is None:
            world_pivot = _parse_world_pivot(item)
        if class_name not in ("Part", "MeshPart", "WedgePart", "CornerWedgePart", "SpawnLocation", "TrussPart"):
            continue
        props = None
        for ch in item:
            if _local_name(ch.tag) == "Properties":
                props = ch
                break
        if props is None:
            continue
        size = _parse_vector3(props, "size") or _parse_vector3(props, "Size")
        if size:
            sizes.append(size)

    if not sizes:
        raise SystemExit(f"Could not read any part sizes from {path}. Re-export as .rbxmx.")

    max_x = max(s[0] for s in sizes)
    max_y = max(s[1] for s in sizes)
    max_z = max(s[2] for s in sizes)
    # This Creator Store road is an ~80x80 slab; tile along street X by that width.
    tile_length = max(max_x, max_z)
    return {
        "size": (max_x, max_y, max_z),
        "tile_length": tile_length,
        "height": max_y,
        "rotate_yaw_90": False,
        "world_pivot": world_pivot or (0.0, 0.0, 0.0),
    }


def uniquify_referents(item: ET.Element) -> None:
    for el in item.iter():
        if el.get("referent"):
            el.set("referent", f"RBX{uuid.uuid4().hex}")


def offset_cframes(item: ET.Element, dx: float, dy: float, dz: float) -> None:
    for el in item.iter():
        name = _local_name(el.tag)
        if name not in ("CoordinateFrame", "CFrame"):
            continue
        comps = {_local_name(c.tag): c for c in el}
        if "X" in comps and "Y" in comps and "Z" in comps:
            comps["X"].text = str(float(comps["X"].text or 0) + dx)
            comps["Y"].text = str(float(comps["Y"].text or 0) + dy)
            comps["Z"].text = str(float(comps["Z"].text or 0) + dz)


def bake_road_segments_rbxmx(export_path: Path, meta: dict, street_length: float, pavement_y: float) -> Path:
    """Build assets/RoadSegments.rbxmx — a Folder of positioned road copies."""
    src_tree = ET.parse(export_path)
    src_root = src_tree.getroot()

    src_item = None
    for ch in src_root:
        if _local_name(ch.tag) == "Item":
            src_item = ch
            break
    if src_item is None:
        raise SystemExit(f"No Item in {export_path}")

    src_xml = ET.tostring(src_item, encoding="unicode")

    tile_length = meta["tile_length"]
    step = max(tile_length - ROAD["Overlap"], tile_length * 0.5)
    origin_x, origin_y, origin_z = meta["world_pivot"]

    out = ET.Element(src_root.tag, src_root.attrib)
    # Keep Meta/External if present
    for ch in src_root:
        if _local_name(ch.tag) != "Item":
            out.append(ch)

    folder = ET.SubElement(out, "Item", {"class": "Folder", "referent": f"RBX{uuid.uuid4().hex}"})
    folder_props = ET.SubElement(folder, "Properties")
    name_el = ET.SubElement(folder_props, "string", {"name": "Name"})
    name_el.text = "RoadSegments"

    start_x = -street_length / 2 + tile_length / 2
    end_x = street_length / 2 - tile_length / 2
    x = start_x
    count = 0
    while x <= end_x + 0.01:
        clone = ET.fromstring(src_xml)
        uniquify_referents(clone)
        for ch in clone:
            if _local_name(ch.tag) == "Properties":
                for prop in ch:
                    if _local_name(prop.tag) == "string" and prop.get("name") == "Name":
                        prop.text = f"Road_{count + 1:02d}"
        # Keep exported height (already sits on the street); only re-center X/Z onto the street line.
        dx = x - origin_x
        dy = 0.0
        dz = 0.0 - origin_z
        offset_cframes(clone, dx, dy, dz)
        folder.append(clone)
        count += 1
        x += step

    out_path = ASSETS / "RoadSegments.rbxmx"
    xml_body = ET.tostring(out, encoding="unicode")
    out_path.write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n' + xml_body + "\n",
        encoding="utf-8",
    )
    print(f"Baked {count} road segments -> {out_path} (tile={tile_length:.1f}, origin={meta['world_pivot']})")
    return out_path


def build_plots_tree(road_segments_path: Path | None):
    count = PLOT["CountPerSide"]
    span = count * PLOT["Width"] + (count - 1) * PLOT["Gap"]
    first = -span / 2 + PLOT["Width"] / 2
    xs = [first + i * (PLOT["Width"] + PLOT["Gap"]) for i in range(count)]
    street_len = span + PLOT["Gap"] * 2
    street_depth = PLOT["StreetHalfWidth"] * 2

    CN, PR = "$className", "$properties"
    pavement_extra = {}
    if road_segments_path is not None:
        pavement_extra["Transparency"] = 1

    street = {
        CN: "Model",
        "Pavement": {
            CN: "Part",
            PR: part_props(
                (70, 70, 75),
                (street_len, PLOT["PadHeight"], street_depth),
                (0, PLOT["PadY"], 0),
                **pavement_extra,
            ),
        },
        "HubSpawn": {
            CN: "SpawnLocation",
            PR: part_props(
                (163, 162, 165),
                (8, 1, 8),
                (0, PLOT["PadY"], 0),
                CanCollide=False,
                Duration=0,
                Neutral=True,
                Enabled=True,
                Transparency=1,
            ),
        },
    }

    if road_segments_path is not None:
        # Path relative to project file
        rel = road_segments_path.relative_to(ROOT).as_posix()
        street["RoadSegments"] = {
            "$path": rel,
        }

    plots = {"Street": street}

    idx = 1
    for x in xs:
        depth = PLOT["Depth"]
        edge = PLOT["StreetHalfWidth"]
        zc = edge + depth / 2
        sz = edge + 6
        plots[f"Plot {idx}"] = {
            CN: "Model",
            "Pad": {
                CN: "Part",
                PR: part_props((220, 200, 160), (PLOT["Width"], PLOT["PadHeight"], depth), (x, PLOT["PadY"], zc)),
            },
            "Spawn": {
                CN: "SpawnLocation",
                PR: part_props(
                    (163, 162, 165),
                    (8, 1, 8),
                    (x, PLOT["PadY"], sz),
                    yaw_degrees=180,
                    CanCollide=False,
                    Duration=0,
                    Neutral=False,
                    Enabled=False,
                    Transparency=1,
                ),
            },
            "Side": {CN: "StringValue", PR: {"Value": "North"}},
        }
        idx += 1
    for x in xs:
        depth = PLOT["Depth"]
        edge = PLOT["StreetHalfWidth"]
        zc = -(edge + depth / 2)
        sz = -(edge + 6)
        plots[f"Plot {idx}"] = {
            CN: "Model",
            "Pad": {
                CN: "Part",
                PR: part_props((200, 190, 170), (PLOT["Width"], PLOT["PadHeight"], depth), (x, PLOT["PadY"], zc)),
            },
            "Spawn": {
                CN: "SpawnLocation",
                PR: part_props(
                    (163, 162, 165),
                    (8, 1, 8),
                    (x, PLOT["PadY"], sz),
                    yaw_degrees=0,
                    CanCollide=False,
                    Duration=0,
                    Neutral=False,
                    Enabled=False,
                    Transparency=1,
                ),
            },
            "Side": {CN: "StringValue", PR: {"Value": "South"}},
        }
        idx += 1

    return plots, street_len, xs


def main():
    ASSETS.mkdir(exist_ok=True)
    export_path = find_road_export()
    road_segments_path = None

    count = PLOT["CountPerSide"]
    span = count * PLOT["Width"] + (count - 1) * PLOT["Gap"]
    street_len = span + PLOT["Gap"] * 2

    if export_path is None:
        print(
            "MISSING assets/Road.rbxmx\n"
            "  In Studio (not Play): select Road → right-click → Save to File…\n"
            f"  Save as: {ASSETS / 'Road.rbxmx'}\n"
            "  Then re-run: python tools/bake_plots.py"
        )
    elif export_path.suffix.lower() == ".rbxm":
        # Keep binary template for ReplicatedStorage; tiling bake needs XML.
        rbxmx = ASSETS / "Road.rbxmx"
        print(
            f"Found {export_path.name}. Please re-save as XML:\n"
            f"  Save to File → {rbxmx}\n"
            "  (In the save dialog, choose Roblox XML Model (.rbxmx) if asked.)"
        )
        # Still copy into project as template for runtime fallback
    else:
        meta = measure_rbxmx(export_path)
        print(f"Road size~={meta['size']} tile_length={meta['tile_length']:.1f}")
        if meta.get("rotate_yaw_90"):
            print(
                "NOTE: road piece is longer on Z than X. In Studio, rotate the template "
                "so its length runs along the street (+X), re-export, and rebake for best results."
            )
        road_segments_path = bake_road_segments_rbxmx(
            export_path,
            meta,
            street_len,
            pavement_y=PLOT["PadY"],
        )

    plots, street_len, xs = build_plots_tree(road_segments_path)

    needed = max(span + 200, PLOT["StreetHalfWidth"] * 2 + PLOT["Depth"] * 2 + 200)
    base_size = max(2048, int((needed // 256) + 1) * 256)
    base_height = 20
    grass_top_y = -4
    base_center_y = grass_top_y - base_height / 2

    CN, PR = "$className", "$properties"
    data = json.loads(PROJECT.read_text(encoding="utf-8"))
    workspace = data["tree"]["Workspace"]
    workspace["$ignoreUnknownInstances"] = True
    workspace.pop("SpawnArea", None)

    workspace["Baseplate"] = {
        CN: "Part",
        PR: {
            "Anchored": True,
            "Locked": True,
            "Material": "Grass",
            "Color": [round(c / 255, 5) for c in (75, 154, 68)],
            "Size": [float(base_size), float(base_height), float(base_size)],
            "CFrame": cframe((0, base_center_y, 0)),
            "TopSurface": "Smooth",
            "BottomSurface": "Smooth",
        },
    }
    workspace["Plots"] = {CN: "Folder", **plots}

    # Keep a single template in ReplicatedStorage for runtime fallback / future use.
    rs = data["tree"].setdefault("ReplicatedStorage", {})
    rs["$ignoreUnknownInstances"] = True
    if "Shared" not in rs:
        rs["Shared"] = {"$path": "src/shared"}
    if export_path is not None:
        rel = export_path.relative_to(ROOT).as_posix()
        rs["RoadTemplate"] = {"$path": rel}

    PROJECT.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    print(f"Updated {PROJECT} (plots={len(xs)*2}, roads_baked={road_segments_path is not None})")


if __name__ == "__main__":
    main()
