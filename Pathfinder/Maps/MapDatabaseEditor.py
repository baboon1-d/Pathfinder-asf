#!/usr/bin/env python3
"""Local web editor for Pathfinder map links and travel interactions.

Run this file with Python. It opens MapDatabaseEditor.html in the default
browser and saves compatible edits back to MapLink.lua, SubstituteMaps.lua,
NpcExceptions.lua, and MapTravelLog.json. Only changed source-map blocks are
rewritten, so the existing regional comments and untouched Lua stay intact.
"""

from __future__ import print_function

import argparse
import datetime as dt
import json
import re
import shutil
import threading
import webbrowser
from collections import OrderedDict
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parent
FILES = {
    "links": ROOT / "MapLink.lua",
    "substitutes": ROOT / "MapExceptions" / "SubstituteMaps.lua",
    "npc": ROOT / "MapExceptions" / "NpcExceptions.lua",
    "travel": ROOT / "MapTravelLog.json",
}
HTML_FILE = ROOT / "MapDatabaseEditor.html"


def lua_string(value):
    return json.dumps(str(value), ensure_ascii=False)


def decode_lua_string(raw):
    try:
        return json.loads('"' + raw + '"')
    except Exception:
        return raw.replace(r'\"', '"').replace("\\\\", "\\")


def skip_space(text, index, end=None):
    end = len(text) if end is None else end
    while index < end:
        if text[index].isspace() or text[index] == ",":
            index += 1
            continue
        if text.startswith("--", index):
            newline = text.find("\n", index)
            return end if newline < 0 or newline >= end else skip_space(text, newline + 1, end)
        break
    return index


def matching_brace(text, start):
    if start >= len(text) or text[start] != "{":
        raise ValueError("Expected table at offset {}".format(start))
    depth = 0
    quote = None
    escaped = False
    index = start
    while index < len(text):
        char = text[index]
        if quote:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
        elif char in ('"', "'"):
            quote = char
        elif text.startswith("--[[", index):
            close = text.find("]]", index + 4)
            if close < 0:
                raise ValueError("Unclosed Lua block comment")
            index = close + 1
        elif text.startswith("--", index):
            newline = text.find("\n", index)
            if newline < 0:
                return len(text) - 1
            index = newline
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return index
        index += 1
    raise ValueError("Unclosed Lua table at offset {}".format(start))


KEY_RE = re.compile(r'\[\s*"((?:\\.|[^"\\])*)"\s*\]\s*=')


def parse_keyed_table(text, table_start, table_end=None):
    table_end = matching_brace(text, table_start) if table_end is None else table_end
    entries = []
    index = table_start + 1
    while index < table_end:
        index = skip_space(text, index, table_end)
        match = KEY_RE.match(text, index)
        if not match:
            index += 1
            continue
        key = decode_lua_string(match.group(1))
        value_start = skip_space(text, match.end(), table_end)
        if value_start >= table_end:
            break
        if text[value_start] == "{":
            try:
                value_end = matching_brace(text, value_start) + 1
            except ValueError:
                # Keep an already-malformed legacy value visible/editable
                # instead of preventing the rest of the database from loading.
                value_end = table_end
        elif text[value_start] in ('"', "'"):
            quote = text[value_start]
            value_end = value_start + 1
            escaped = False
            while value_end < table_end:
                char = text[value_end]
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == quote:
                    value_end += 1
                    break
                value_end += 1
        else:
            value_end = value_start
            while value_end < table_end and text[value_end] not in ",\n":
                value_end += 1
        entries.append({
            "key": key,
            "raw": text[value_start:value_end].strip(),
            "start": index,
            "end": value_end,
        })
        index = value_end
    return entries


ASSIGNMENT_RE = re.compile(r'(?m)^[ \t]*{name}\s*\[\s*"((?:\\.|[^"\\])*)"\s*\]\s*=\s*\{{'.format(name=r"(?P<var>mapLink|npcExce)"))


def assignment_blocks(text, variable):
    pattern = re.compile(r'(?m)^[ \t]*' + re.escape(variable) + r'\s*\[\s*"((?:\\.|[^"\\])*)"\s*\]\s*=\s*\{')
    blocks = OrderedDict()
    for match in pattern.finditer(text):
        brace = text.find("{", match.start(), match.end())
        try:
            close = matching_brace(text, brace)
            end = close + 1
        except ValueError:
            # Some legacy snapshots contain a bad closing bracket on one-line
            # entries. Bound that block to its line and preserve its raw value.
            newline = text.find("\n", brace)
            end = len(text) if newline < 0 else newline
            close = end
        if end < len(text) and text[end] == "\r":
            end += 1
        if end < len(text) and text[end] == "\n":
            end += 1
        source = decode_lua_string(match.group(1))
        blocks[source] = {
            "source": source,
            "start": match.start(),
            "end": end,
            "table_start": brace,
            "table_end": close,
            "raw": text[match.start():end],
        }
    return blocks


def return_table_blocks(text):
    match = re.search(r'\breturn\s*\{', text)
    if not match:
        raise ValueError("SubstituteMaps.lua has no return table")
    brace = text.find("{", match.start(), match.end())
    close = matching_brace(text, brace)
    blocks = OrderedDict()
    for entry in parse_keyed_table(text, brace, close):
        raw = entry["raw"]
        if not raw.startswith("{"):
            continue
        blocks[entry["key"]] = {
            "source": entry["key"],
            "start": entry["start"],
            "end": entry["end"],
            "table_start": text.find("{", entry["start"], entry["end"]),
            "table_end": entry["end"] - 1,
            "raw": text[entry["start"]:entry["end"]],
        }
    return blocks, close


def numeric_points(raw):
    if not (raw.startswith("{{") and raw.endswith("}}")):
        return []
    points = []
    for group in re.findall(r'\{\s*(-?\d+(?:\s*,\s*-?\d+){1,3})\s*\}', raw[1:-1]):
        values = [int(value.strip()) for value in group.split(",")]
        if len(values) in (2, 4):
            points.append(values)
    return points


def split_table_values(raw):
    if not raw.startswith("{"):
        return []
    end = matching_brace(raw, 0)
    values = []
    index = 1
    while index < end:
        index = skip_space(raw, index, end)
        if index >= end:
            break
        start = index
        if raw[index] == "{":
            index = matching_brace(raw, index) + 1
        elif raw[index] in ('"', "'"):
            quote = raw[index]
            index += 1
            escaped = False
            while index < end:
                char = raw[index]
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == quote:
                    index += 1
                    break
                index += 1
        else:
            while index < end and raw[index] != ",":
                index += 1
        values.append(raw[start:index].strip())
        index += 1
    return values


def simple_lua_value(raw):
    raw = raw.strip()
    if len(raw) >= 2 and raw[0] == raw[-1] == '"':
        return decode_lua_string(raw[1:-1])
    if re.fullmatch(r'-?\d+(?:\.\d+)?', raw):
        return float(raw) if "." in raw else int(raw)
    return raw


class MapDatabase(object):
    def __init__(self):
        self.text = {}
        self.blocks = {}
        self.records = {}
        self.substitute_close = None
        self.backup_dir = None
        self.load()

    def load(self):
        self.text["links"] = FILES["links"].read_text(encoding="utf-8-sig")
        self.text["substitutes"] = FILES["substitutes"].read_text(encoding="utf-8-sig")
        self.text["npc"] = FILES["npc"].read_text(encoding="utf-8-sig")
        self.blocks["links"] = assignment_blocks(self.text["links"], "mapLink")
        self.blocks["npc"] = assignment_blocks(self.text["npc"], "npcExce")
        self.blocks["substitutes"], self.substitute_close = return_table_blocks(self.text["substitutes"])
        self.records["links"] = self._edge_records("links")
        self.records["substitutes"] = self._edge_records("substitutes")
        self.records["npc"] = self._npc_records()

    def _edge_records(self, kind):
        records = []
        text = self.text[kind]
        for source, block in self.blocks[kind].items():
            for entry in parse_keyed_table(text, block["table_start"], block["table_end"]):
                raw = entry["raw"]
                preset = ""
                match = re.fullmatch(r'\{\s*(K_SUBWAY|H_TELE|S_TELE)\s*\}', raw)
                if match:
                    preset = match.group(1)
                records.append({
                    "source": source,
                    "destination": entry["key"],
                    "raw": raw,
                    "points": numeric_points(raw),
                    "preset": preset,
                })
        return records

    def _npc_records(self):
        records = []
        text = self.text["npc"]
        for source, block in self.blocks["npc"].items():
            for entry in parse_keyed_table(text, block["table_start"], block["table_end"]):
                values = split_table_values(entry["raw"])
                point = []
                if values and values[0].startswith("{"):
                    point = [int(x) for x in re.findall(r'-?\d+', values[0])[:2]]
                records.append({
                    "source": source,
                    "destination": entry["key"],
                    "x": point[0] if len(point) > 0 else 0,
                    "y": point[1] if len(point) > 1 else 0,
                    "answer": simple_lua_value(values[1]) if len(values) > 1 else "",
                    "prompt": simple_lua_value(values[2]) if len(values) > 2 else "",
                    "extras": [simple_lua_value(value) for value in values[3:]],
                    "raw": entry["raw"],
                })
        return records

    def travel_log(self):
        if not FILES["travel"].exists():
            return []
        try:
            data = json.loads(FILES["travel"].read_text(encoding="utf-8-sig"))
            return data if isinstance(data, list) else []
        except Exception:
            return []

    def payload(self):
        links = self.records["links"]
        substitutes = self.records["substitutes"]
        npc = self.records["npc"]
        node_names = sorted(set(
            [row["source"] for row in links] + [row["destination"] for row in links]
            + [row["source"] for row in substitutes] + [row["destination"] for row in substitutes]
        ))
        return {
            "links": links,
            "substitutes": substitutes,
            "npc": npc,
            "travel": self.travel_log(),
            "nodes": node_names,
            # Source assignments are tracked separately so the editor can
            # create and retain valid empty nodes: mapLink["Name"] = {}.
            "linkNodes": sorted(self.blocks["links"].keys()),
            "files": {key: str(path) for key, path in FILES.items()},
        }

    @staticmethod
    def _group(rows):
        grouped = OrderedDict()
        for row in rows:
            source = str(row.get("source") or "").strip()
            destination = str(row.get("destination") or "").strip()
            if not source or not destination:
                raise ValueError("Every record requires source and destination maps")
            grouped.setdefault(source, []).append(row)
        return grouped

    @staticmethod
    def _identity(rows):
        return [(row.get("source"), row.get("destination"), row.get("raw")) for row in rows]

    def _backup(self):
        if self.backup_dir is not None:
            return self.backup_dir
        stamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
        destination = ROOT / ".map-editor-backups" / stamp
        destination.mkdir(parents=True, exist_ok=True)
        for path in FILES.values():
            if path.exists():
                shutil.copy2(str(path), str(destination / path.name))
        self.backup_dir = destination
        return destination

    @staticmethod
    def _atomic_write(path, text):
        temporary = path.with_suffix(path.suffix + ".tmp")
        temporary.write_text(text, encoding="utf-8", newline="\n")
        temporary.replace(path)

    def _serialize_parent(self, kind, source, rows):
        if kind == "links":
            body = ", ".join("[{}] = {}".format(lua_string(row["destination"]), row["raw"].strip()) for row in rows)
            return "mapLink[{}] = {{{}}}\n".format(lua_string(source), body)
        if kind == "substitutes":
            lines = ["    [{}] = {{".format(lua_string(source))]
            lines.extend("        [{}] = {},".format(lua_string(row["destination"]), row["raw"].strip()) for row in rows)
            lines.append("    },")
            return "\n".join(lines)
        lines = ["npcExce[{}] = {{".format(lua_string(source))]
        lines.extend("    [{}] = {},".format(lua_string(row["destination"]), row["raw"].strip()) for row in rows)
        lines.append("}")
        return "\n".join(lines) + "\n"

    def _update_kind(self, kind, rows, explicit_nodes=None):
        old_group = self._group(self.records[kind])
        new_group = self._group(rows)
        text = self.text[kind]
        replacements = []
        additions = []
        old_sources = set(self.blocks[kind])
        new_sources = set(new_group)
        if kind == "links":
            if explicit_nodes is None:
                new_sources.update(old_sources)
            else:
                new_sources.update(str(node).strip() for node in explicit_nodes if str(node).strip())
        for source in old_sources | new_sources:
            old_rows = old_group.get(source, [])
            new_rows = new_group.get(source, [])
            block = self.blocks[kind].get(source)
            if source not in new_sources:
                if block:
                    replacements.append((block["start"], block["end"], ""))
                continue
            if block and self._identity(old_rows) == self._identity(new_rows):
                continue
            serialized = self._serialize_parent(kind, source, new_rows)
            if block:
                replacements.append((block["start"], block["end"], serialized))
            else:
                additions.append(serialized)
        for start, end, replacement in sorted(replacements, reverse=True):
            text = text[:start] + replacement + text[end:]
        if additions:
            if kind == "links":
                marker = text.rfind("return mapLink")
            elif kind == "npc":
                marker = text.rfind("return npcExce")
            else:
                marker = text.rfind("}")
            if marker < 0:
                raise ValueError("Could not find insertion point in {}".format(FILES[kind].name))
            heading = "\n-- Added with MapDatabaseEditor\n" if kind != "substitutes" else "\n    -- Added with MapDatabaseEditor\n"
            text = text[:marker] + heading + "".join(additions) + "\n" + text[marker:]
        return text

    def save(self, payload):
        for kind in ("links", "substitutes", "npc"):
            if not isinstance(payload.get(kind), list):
                raise ValueError("{} must be an array".format(kind))
        self._validate_unique(payload)
        backup = self._backup()
        updated = {
            "links": self._update_kind("links", payload["links"], payload.get("linkNodes")),
            "substitutes": self._update_kind("substitutes", payload["substitutes"]),
            "npc": self._update_kind("npc", payload["npc"]),
        }
        # Reparse before replacing live files; catches malformed table output.
        assignment_blocks(updated["links"], "mapLink")
        return_table_blocks(updated["substitutes"])
        assignment_blocks(updated["npc"], "npcExce")
        for kind, text in updated.items():
            self._atomic_write(FILES[kind], text)
        travel = payload.get("travel") or []
        self._atomic_write(FILES["travel"], json.dumps(travel, ensure_ascii=False, indent=2) + "\n")
        self.load()
        return {"ok": True, "backup": str(backup), "counts": {key: len(self.records[key]) for key in self.records}}

    @staticmethod
    def _validate_unique(payload):
        for kind in ("links", "substitutes", "npc"):
            seen = set()
            for row in payload[kind]:
                key = (str(row.get("source") or "").strip(), str(row.get("destination") or "").strip())
                if not all(key):
                    raise ValueError("Blank source/destination in {}".format(kind))
                if key in seen:
                    raise ValueError("Duplicate {} edge: {} -> {}".format(kind, key[0], key[1]))
                seen.add(key)


class EditorHandler(BaseHTTPRequestHandler):
    database = None

    def log_message(self, fmt, *args):
        print("[MapEditor] " + fmt % args)

    def _send(self, status, body, content_type="application/json; charset=utf-8"):
        data = body if isinstance(body, bytes) else body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        path = urlparse(self.path).path
        if path in ("/", "/MapDatabaseEditor.html"):
            self._send(200, HTML_FILE.read_bytes(), "text/html; charset=utf-8")
        elif path == "/api/database":
            self._send(200, json.dumps(self.database.payload(), ensure_ascii=False))
        else:
            self._send(404, json.dumps({"error": "Not found"}))

    def do_POST(self):
        path = urlparse(self.path).path
        try:
            length = int(self.headers.get("Content-Length", "0"))
            payload = json.loads(self.rfile.read(length).decode("utf-8")) if length else {}
            if path == "/api/save":
                result = self.database.save(payload)
                self._send(200, json.dumps(result, ensure_ascii=False))
            elif path == "/api/reload":
                self.database.load()
                self._send(200, json.dumps(self.database.payload(), ensure_ascii=False))
            else:
                self._send(404, json.dumps({"error": "Not found"}))
        except Exception as error:
            self._send(400, json.dumps({"error": str(error)}, ensure_ascii=False))


def main():
    parser = argparse.ArgumentParser(description="Run the Pathfinder map database editor")
    parser.add_argument("--port", type=int, default=0, help="Local port; 0 chooses an available port")
    parser.add_argument("--no-browser", action="store_true", help="Do not open the default browser")
    args = parser.parse_args()
    if not HTML_FILE.exists():
        raise SystemExit("Missing {}".format(HTML_FILE))
    EditorHandler.database = MapDatabase()
    server = ThreadingHTTPServer(("127.0.0.1", args.port), EditorHandler)
    url = "http://127.0.0.1:{}/".format(server.server_port)
    print("Pathfinder Map Database Editor")
    print("Open: {}".format(url))
    print("Press Ctrl+C to stop.")
    if not args.no_browser:
        threading.Timer(0.35, lambda: webbrowser.open(url)).start()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
