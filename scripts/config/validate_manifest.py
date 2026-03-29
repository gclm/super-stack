#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_MANIFEST = REPO_ROOT / "config" / "manifest.json"
DEFAULT_SCHEMA = REPO_ROOT / "config" / "manifest.schema.json"


class ManifestError(ValueError):
    pass


JSON_TYPE_MAP = {
    "object": dict,
    "array": list,
    "string": str,
    "boolean": bool,
    "integer": int,
}


def load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise ManifestError(f"file not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise ManifestError(f"JSON decode failed for {path}: {exc}") from exc


def load_manifest(path: Path) -> dict[str, Any]:
    data = load_json(path)
    if not isinstance(data, dict):
        raise ManifestError("manifest root must be an object")
    return data


def load_schema(path: Path) -> dict[str, Any]:
    data = load_json(path)
    if not isinstance(data, dict):
        raise ManifestError("schema root must be an object")
    return data


def resolve_ref(root_schema: dict[str, Any], ref: str) -> dict[str, Any]:
    if not ref.startswith("#/"):
        raise ManifestError(f"unsupported schema ref: {ref}")
    node: Any = root_schema
    for part in ref[2:].split("/"):
        if not isinstance(node, dict) or part not in node:
            raise ManifestError(f"schema ref not found: {ref}")
        node = node[part]
    if not isinstance(node, dict):
        raise ManifestError(f"schema ref must resolve to object: {ref}")
    return node


def validate_against_schema(value: Any, schema: dict[str, Any], root_schema: dict[str, Any], path: str) -> None:
    if "$ref" in schema:
        validate_against_schema(value, resolve_ref(root_schema, schema["$ref"]), root_schema, path)
        return

    if "oneOf" in schema:
        errors: list[str] = []
        for option in schema["oneOf"]:
            try:
                validate_against_schema(value, option, root_schema, path)
                return
            except ManifestError as exc:
                errors.append(str(exc))
        raise ManifestError(f"{path} does not match any allowed schema: {'; '.join(errors)}")

    schema_type = schema.get("type")
    if schema_type:
        expected = JSON_TYPE_MAP.get(schema_type)
        if expected is None:
            raise ManifestError(f"unsupported schema type: {schema_type}")
        if not isinstance(value, expected):
            raise ManifestError(f"{path} must be {schema_type}")

    if isinstance(value, str):
        min_length = schema.get("minLength")
        if isinstance(min_length, int) and len(value) < min_length:
            raise ManifestError(f"{path} must have length >= {min_length}")
        enum = schema.get("enum")
        if isinstance(enum, list) and value not in enum:
            raise ManifestError(f"{path} must be one of {enum}")
        const = schema.get("const")
        if const is not None and value != const:
            raise ManifestError(f"{path} must equal {const}")

    if isinstance(value, list):
        min_items = schema.get("minItems")
        if isinstance(min_items, int) and len(value) < min_items:
            raise ManifestError(f"{path} must have at least {min_items} items")
        item_schema = schema.get("items")
        if isinstance(item_schema, dict):
            for index, item in enumerate(value):
                validate_against_schema(item, item_schema, root_schema, f"{path}[{index}]")

    if isinstance(value, dict):
        required = schema.get("required", [])
        if isinstance(required, list):
            for key in required:
                if key not in value:
                    raise ManifestError(f"{path}.{key} is required")

        properties = schema.get("properties", {})
        if isinstance(properties, dict):
            for key, subschema in properties.items():
                if key in value and isinstance(subschema, dict):
                    validate_against_schema(value[key], subschema, root_schema, f"{path}.{key}")

        additional = schema.get("additionalProperties", True)
        known = set(properties.keys()) if isinstance(properties, dict) else set()
        for key, item in value.items():
            if key in known:
                continue
            if additional is False:
                raise ManifestError(f"{path}.{key} is not allowed")
            if isinstance(additional, dict):
                validate_against_schema(item, additional, root_schema, f"{path}.{key}")

        min_props = schema.get("minProperties")
        if isinstance(min_props, int) and len(value) < min_props:
            raise ManifestError(f"{path} must have at least {min_props} properties")


def expect_dict(parent: dict[str, Any], key: str, path: str) -> dict[str, Any]:
    value = parent.get(key)
    if not isinstance(value, dict):
        raise ManifestError(f"{path}.{key} must be an object")
    return value


def expect_list(parent: dict[str, Any], key: str, path: str) -> list[Any]:
    value = parent.get(key)
    if not isinstance(value, list):
        raise ManifestError(f"{path}.{key} must be a list")
    return value


def expect_string(value: Any, path: str) -> str:
    if not isinstance(value, str) or not value:
        raise ManifestError(f"{path} must be a non-empty string")
    return value


def expect_optional_string(value: Any, path: str) -> None:
    if value is not None and not isinstance(value, str):
        raise ManifestError(f"{path} must be a string when present")


def expect_bool(value: Any, path: str) -> None:
    if not isinstance(value, bool):
        raise ManifestError(f"{path} must be a boolean")


def validate_server(server_id: str, server: Any) -> None:
    path = f"mcp.servers.{server_id}"
    if not isinstance(server, dict):
        raise ManifestError(f"{path} must be an object")

    command_fields = [
        field for field in ("command_env", "command_fixed", "command_fixed_template", "command_name") if field in server
    ]
    if not command_fields:
        raise ManifestError(f"{path} must define one of command_env/command_fixed/command_fixed_template/command_name")

    for field in command_fields:
        expect_string(server[field], f"{path}.{field}")

    if "args" in server:
        args = server["args"]
        if not isinstance(args, list) or not all(isinstance(item, str) for item in args):
            raise ManifestError(f"{path}.args must be a string list")

    if "env" in server:
        env = server["env"]
        if not isinstance(env, dict) or not all(isinstance(k, str) and isinstance(v, str) for k, v in env.items()):
            raise ManifestError(f"{path}.env must be a string map")

    if "enabled" in server:
        expect_bool(server["enabled"], f"{path}.enabled")


def validate_managed_block(block_id: str, block: Any, server_ids: set[str]) -> None:
    path = f"managed_blocks.{block_id}"
    if not isinstance(block, dict):
        raise ManifestError(f"{path} must be an object")

    kind = expect_string(block.get("kind"), f"{path}.kind")
    if kind not in {"agents", "hooks", "mcp"}:
        raise ManifestError(f"{path}.kind must be one of ['agents', 'hooks', 'mcp']")
    expect_string(block.get("target_format"), f"{path}.target_format")
    content = expect_dict(block, "content", path)

    if "target_file_template" in block:
        expect_string(block["target_file_template"], f"{path}.target_file_template")
    if "begin_marker" in block:
        expect_string(block["begin_marker"], f"{path}.begin_marker")
    if "end_marker" in block:
        expect_string(block["end_marker"], f"{path}.end_marker")
    if "ownership" in block:
        expect_string(block["ownership"], f"{path}.ownership")
    if "managed_files" in block:
        managed_files = block["managed_files"]
        if not isinstance(managed_files, list) or not all(isinstance(item, str) and item for item in managed_files):
            raise ManifestError(f"{path}.managed_files must be a non-empty string list when present")

    verify = block.get("verify")
    if verify is not None:
        if not isinstance(verify, dict):
            raise ManifestError(f"{path}.verify must be an object when present")
        for field in ("agent_config_files_field", "commands_field"):
            expect_optional_string(verify.get(field), f"{path}.verify.{field}")
        for field in ("contains", "markers", "registered_entries"):
            if field in verify:
                value = verify[field]
                if not isinstance(value, list) or not all(isinstance(item, str) and item for item in value):
                    raise ManifestError(f"{path}.verify.{field} must be a non-empty string list when present")
        if "include_resolved_server_markers" in verify:
            expect_bool(verify["include_resolved_server_markers"], f"{path}.verify.include_resolved_server_markers")

    if kind == "mcp":
        servers = expect_list(content, "servers", f"{path}.content")
        for index, entry in enumerate(servers):
            entry_path = f"{path}.content.servers[{index}]"
            if isinstance(entry, str):
                if entry not in server_ids:
                    raise ManifestError(f"{entry_path} references unknown server: {entry}")
                continue
            if not isinstance(entry, dict):
                raise ManifestError(f"{entry_path} must be a string or object")
            server_id = expect_string(entry.get("id"), f"{entry_path}.id")
            if server_id not in server_ids:
                raise ManifestError(f"{entry_path}.id references unknown server: {server_id}")


def validate_skill_validation(section: Any) -> None:
    path = "skill_validation"
    if not isinstance(section, dict):
        raise ManifestError(f"{path} must be an object")
    rules = section.get("ignore_warnings", [])
    if not isinstance(rules, list):
        raise ManifestError(f"{path}.ignore_warnings must be a list")
    for index, rule in enumerate(rules):
        rule_path = f"{path}.ignore_warnings[{index}]"
        if not isinstance(rule, dict):
            raise ManifestError(f"{rule_path} must be an object")
        expect_string(rule.get("path_glob"), f"{rule_path}.path_glob")
        codes = rule.get("codes")
        if not isinstance(codes, list) or not all(isinstance(code, str) and code for code in codes):
            raise ManifestError(f"{rule_path}.codes must be a non-empty string list")
        if "reason" in rule:
            expect_optional_string(rule.get("reason"), f"{rule_path}.reason")


def validate_manifest(data: dict[str, Any], schema: dict[str, Any]) -> None:
    validate_against_schema(data, schema, schema, "manifest")

    if data.get("manifest_version") != 1:
        raise ManifestError("manifest.manifest_version must equal 1")

    mcp = expect_dict(data, "mcp", "manifest")
    servers = expect_dict(mcp, "servers", "manifest.mcp")
    for server_id, server in servers.items():
        validate_server(server_id, server)

    managed_blocks = expect_dict(data, "managed_blocks", "manifest")
    server_ids = set(servers.keys())
    for block_id, block in managed_blocks.items():
        validate_managed_block(block_id, block, server_ids)

    validate_skill_validation(expect_dict(data, "skill_validation", "manifest"))


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate super-stack config manifest")
    parser.add_argument("--manifest", default=str(DEFAULT_MANIFEST), help="Path to manifest.json")
    parser.add_argument("--schema", default=str(DEFAULT_SCHEMA), help="Path to manifest.schema.json")
    args = parser.parse_args()

    manifest_path = Path(args.manifest)
    schema_path = Path(args.schema)
    try:
        manifest = load_manifest(manifest_path)
        schema = load_schema(schema_path)
        validate_manifest(manifest, schema)
    except ManifestError as exc:
        raise SystemExit(f"manifest validation failed: {exc}")

    print(f"manifest ok: {manifest_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
