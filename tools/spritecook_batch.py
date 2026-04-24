#!/usr/bin/env python3
# -*- coding: utf-8 -*-
## Batch-generate pixel art via SpriteCook HTTP API and update spritecook-assets.json.
## Requires SPRITECOOK_API_KEY in the environment (or first match in res://.env when run with --from-dotenv).
##
## Usage:
##   python3 tools/spritecook_batch.py --from-dotenv --manifest tools/spritecook_batch_manifest.json
##   python3 tools/spritecook_batch.py --dry-run --manifest tools/spritecook_batch_manifest.json
##   python3 tools/spritecook_batch.py --from-dotenv --limit 5
##
## Docs: https://www.spritecook.ai/api-docs

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any


API_BASE = "https://api.spritecook.ai"
GENERATE_SYNC = f"{API_BASE}/v1/api/generate-sync"
CREDITS = f"{API_BASE}/v1/api/credits"


def _repo_root() -> Path:
	return Path(__file__).resolve().parent.parent


def _load_dotenv_keys(env_path: Path) -> dict[str, str]:
	out: dict[str, str] = {}
	if not env_path.is_file():
		return out
	for raw in env_path.read_text(encoding="utf-8").splitlines():
		line = raw.strip()
		if not line or line.startswith("#"):
			continue
		if "=" not in line:
			continue
		k, _, v = line.partition("=")
		key = k.strip()
		val = v.strip().strip('"').strip("'")
		out[key] = val
	return out


def _sha12(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()[:12]


def _extract_asset_id(resp: Any) -> str:
	if not isinstance(resp, dict):
		return ""
	for k in ("asset_id", "id"):
		v = resp.get(k)
		if isinstance(v, str) and len(v) > 8:
			return v
	blk = resp.get("asset")
	if isinstance(blk, dict):
		for k in ("id", "asset_id"):
			v = blk.get(k)
			if isinstance(v, str) and len(v) > 8:
				return v
	out = resp.get("output")
	if isinstance(out, dict):
		for k in ("asset_id", "id"):
			v = out.get(k)
			if isinstance(v, str) and len(v) > 8:
				return v
	return ""


def _find_presigned_pixel_url(obj: Any) -> str | None:
	"""Return first usable pixel PNG URL from SpriteCook sync response."""
	if isinstance(obj, str) and obj.startswith("http") and (".png" in obj or "pixel" in obj.lower()):
		return obj
	if isinstance(obj, dict):
		for key in (
			"_presigned_pixel_url",
			"presigned_pixel_url",
			"pixel_url",
			"download_url",
			"url",
		):
			if key in obj and isinstance(obj[key], str) and obj[key].startswith("http"):
				return obj[key]
		for v in obj.values():
			u = _find_presigned_pixel_url(v)
			if u:
				return u
	if isinstance(obj, list):
		for item in obj:
			u = _find_presigned_pixel_url(item)
			if u:
				return u
	return None


def _http_json(
	method: str,
	url: str,
	headers: dict[str, str],
	body: dict[str, Any] | None = None,
	timeout: float = 120.0,
) -> tuple[int, Any]:
	payload: bytes | None = None
	if body is not None:
		payload = json.dumps(body).encode("utf-8")
	req = urllib.request.Request(url, data=payload, method=method, headers=headers)
	try:
		with urllib.request.urlopen(req, timeout=timeout) as resp:
			raw = resp.read()
			code = resp.getcode()
			try:
				return code, json.loads(raw.decode("utf-8"))
			except json.JSONDecodeError:
				return code, {"_raw": raw.decode("utf-8", errors="replace")}
	except urllib.error.HTTPError as e:
		err_body = e.read().decode("utf-8", errors="replace")
		try:
			return e.code, json.loads(err_body)
		except json.JSONDecodeError:
			return e.code, {"error": err_body}


def _download(url: str, dest: Path, timeout: float = 120.0) -> None:
	dest.parent.mkdir(parents=True, exist_ok=True)
	req = urllib.request.Request(url, method="GET")
	with urllib.request.urlopen(req, timeout=timeout) as resp:
		data = resp.read()
	dest.write_bytes(data)


def _load_manifest(path: Path) -> dict[str, Any]:
	data = json.loads(path.read_text(encoding="utf-8"))
	if "jobs" not in data or not isinstance(data["jobs"], list):
		raise SystemExit(f"Invalid manifest: {path} (need 'jobs' list)")
	return data


def _merge_manifest(repo: Path, entry: dict[str, Any]) -> None:
	manifest_path = repo / "spritecook-assets.json"
	if manifest_path.is_file():
		existing = json.loads(manifest_path.read_text(encoding="utf-8"))
		if not isinstance(existing, list):
			existing = []
	else:
		existing = []
	label = entry.get("label")
	out: list[dict[str, Any]] = [e for e in existing if e.get("label") != label]
	entry_copy = {k: v for k, v in entry.items() if v is not None}
	out.append(entry_copy)
	manifest_path.write_text(
		json.dumps(out, indent=2) + "\n",
		encoding="utf-8",
	)


def main() -> int:
	ap = argparse.ArgumentParser(description="SpriteCook batch generator for Five More Minutes!")
	ap.add_argument("--manifest", type=Path, default=_repo_root() / "tools" / "spritecook_batch_manifest.json")
	ap.add_argument("--from-dotenv", action="store_true", help="Load SPRITECOOK_API_KEY from repo .env")
	ap.add_argument("--dry-run", action="store_true", help="Print jobs only; no network")
	ap.add_argument("--limit", type=int, default=0, help="Max number of jobs to run (0 = all)")
	ap.add_argument("--sleep", type=float, default=0.5, help="Seconds between API calls (rate limit)")
	ap.add_argument("--verbose", action="store_true", help="Print full API JSON on errors")
	args = ap.parse_args()

	repo = _repo_root()
	key = os.environ.get("SPRITECOOK_API_KEY", "").strip()
	if args.from_dotenv:
		env_keys = _load_dotenv_keys(repo / ".env")
		key = env_keys.get("SPRITECOOK_API_KEY", key).strip()

	if not args.dry_run and not key:
		print(
			"Missing SPRITECOOK_API_KEY. Set it in the environment or add SPRITECOOK_API_KEY=... to .env "
			"and pass --from-dotenv.",
			file=sys.stderr,
		)
		return 1

	manifest = _load_manifest(args.manifest.resolve() if not args.manifest.is_absolute() else args.manifest)
	jobs: list[dict[str, Any]] = manifest["jobs"]
	ref_default = manifest.get("reference_asset_id")
	theme = manifest.get("theme")
	style = manifest.get("style")
	model = manifest.get("model", "gemini-3.1-flash-image-preview")

	headers = {"Content-Type": "application/json", "Authorization": f"Bearer {key}"}

	if not args.dry_run:
		code, cred_body = _http_json("GET", CREDITS, headers, None, timeout=30.0)
		if args.verbose:
			print("GET /credits:", code, cred_body)
		if code != 200:
			print(f"Warning: credits check returned {code}: {cred_body}", file=sys.stderr)

	limit = args.limit if args.limit > 0 else len(jobs)
	done = 0
	for job in jobs[:limit]:
		label = job.get("label", "")
		rel_file = job.get("file", "")
		prompt = job.get("prompt", "")
		width = int(job.get("width", 64))
		height = int(job.get("height", 64))
		ref = job.get("reference_asset_id", ref_default)

		dest = repo / rel_file
		if args.dry_run:
			print(f"[dry-run] {label} -> {rel_file} ({width}x{height})")
			continue

		body: dict[str, Any] = {
			"prompt": prompt,
			"width": width,
			"height": height,
			"pixel": job.get("pixel", True),
			"bg_mode": job.get("bg_mode", "transparent"),
			"smart_crop": job.get("smart_crop", True),
			"model": job.get("model", model),
			"mode": str(job.get("mode", "assets")),
		}
		if theme:
			body["theme"] = theme
		if style:
			body["style"] = style
		if ref:
			body["reference_asset_id"] = ref

		print(f"Generating {label} …", flush=True)
		code, resp = _http_json("POST", GENERATE_SYNC, headers, body, timeout=120.0)
		if code != 200:
			print(f"  FAILED HTTP {code}: {resp}", file=sys.stderr)
			if args.verbose:
				print(json.dumps(resp, indent=2))
			return 1

		url = _find_presigned_pixel_url(resp)
		if not url:
			print(f"  No presigned pixel URL in response for {label}. Keys: {list(resp.keys()) if isinstance(resp, dict) else type(resp)}", file=sys.stderr)
			if args.verbose:
				print(json.dumps(resp, indent=2))
			return 1

		_download(url, dest)
		data = dest.read_bytes()
		aid = _extract_asset_id(resp)
		entry = {
			"asset_id": aid,
			"sha12": _sha12(data),
			"label": label,
			"file": rel_file.replace("\\", "/"),
			"size": f"{width}x{height}",
		}

		_merge_manifest(repo, entry)
		print(f"  OK -> {dest} ({len(data)} bytes)", flush=True)
		done += 1
		if done < len(jobs[:limit]):
			time.sleep(args.sleep)

	if args.dry_run:
		print(f"Dry run: {min(limit, len(jobs))} job(s).")
	else:
		print(f"Done: {done} file(s). Updated spritecook-assets.json")
	return 0


if __name__ == "__main__":
	sys.exit(main())
