import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT = REPO_ROOT / "scripts" / "config" / "validate_manifest.py"
MANIFEST = REPO_ROOT / "config" / "manifest.json"
SCHEMA = REPO_ROOT / "config" / "manifest.schema.json"


class ManifestValidationTests(unittest.TestCase):
    def test_current_manifest_is_valid(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--manifest", str(MANIFEST), "--schema", str(SCHEMA)],
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("manifest ok:", result.stdout)

    def test_manifest_rejects_invalid_manifest_version(self):
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        manifest["manifest_version"] = 2

        with tempfile.TemporaryDirectory() as tmpdir:
            temp_path = Path(tmpdir) / "manifest.json"
            temp_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
            result = subprocess.run(
                [sys.executable, str(SCRIPT), "--manifest", str(temp_path), "--schema", str(SCHEMA)],
                text=True,
                capture_output=True,
                check=False,
            )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must equal 1", result.stderr)

    def test_manifest_rejects_invalid_target_format_via_schema(self):
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        manifest["managed_blocks"]["codex_agents"]["target_format"] = "yaml"

        with tempfile.TemporaryDirectory() as tmpdir:
            temp_path = Path(tmpdir) / "manifest.json"
            temp_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
            result = subprocess.run(
                [sys.executable, str(SCRIPT), "--manifest", str(temp_path), "--schema", str(SCHEMA)],
                text=True,
                capture_output=True,
                check=False,
            )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must be one of", result.stderr)

    def test_manifest_rejects_missing_block_kind(self):
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        del manifest["managed_blocks"]["codex_mcp"]["kind"]

        with tempfile.TemporaryDirectory() as tmpdir:
            temp_path = Path(tmpdir) / "manifest.json"
            temp_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
            result = subprocess.run(
                [sys.executable, str(SCRIPT), "--manifest", str(temp_path), "--schema", str(SCHEMA)],
                text=True,
                capture_output=True,
                check=False,
            )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("managed_blocks.codex_mcp.kind is required", result.stderr)

    def test_manifest_rejects_unknown_mcp_server_reference(self):
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        manifest["managed_blocks"]["codex_mcp"]["content"]["servers"].append("missing-server")

        with tempfile.TemporaryDirectory() as tmpdir:
            temp_path = Path(tmpdir) / "manifest.json"
            temp_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
            result = subprocess.run(
                [sys.executable, str(SCRIPT), "--manifest", str(temp_path), "--schema", str(SCHEMA)],
                text=True,
                capture_output=True,
                check=False,
            )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("references unknown server", result.stderr)

    def test_manifest_rejects_invalid_skill_validation_rule(self):
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        manifest["skill_validation"]["ignore_warnings"][0]["codes"] = "thin_lines"

        with tempfile.TemporaryDirectory() as tmpdir:
            temp_path = Path(tmpdir) / "manifest.json"
            temp_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
            result = subprocess.run(
                [sys.executable, str(SCRIPT), "--manifest", str(temp_path), "--schema", str(SCHEMA)],
                text=True,
                capture_output=True,
                check=False,
            )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must be array", result.stderr)


if __name__ == "__main__":
    unittest.main()
