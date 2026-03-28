import json
import subprocess
import sys
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT = REPO_ROOT / "scripts" / "config" / "render_managed_config.py"
MANIFEST = REPO_ROOT / "config" / "managed-config.json"


class ManagedConfigRenderingTests(unittest.TestCase):
    def test_manifest_contains_expected_blocks(self):
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        self.assertIn("codex_agents", manifest["blocks"])
        self.assertIn("codex_hooks", manifest["blocks"])
        self.assertIn("claude_hooks", manifest["blocks"])

    def test_render_codex_agents_contains_registered_agents(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--block", "codex_agents"],
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("multi_agent = true", result.stdout)
        self.assertIn('[agents.super_stack_explorer]', result.stdout)
        self.assertIn('config_file = "agents/super-stack-explorer.toml"', result.stdout)
        self.assertIn('config_file = "agents/super-stack-builder.toml"', result.stdout)

    def test_render_codex_hooks_includes_runtime_paths(self):
        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT),
                "--block",
                "codex_hooks",
                "--runtime-root",
                "/tmp/runtime",
            ],
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('python3 \\\"/tmp/runtime/.codex/hooks/super_stack_state.py\\\"', result.stdout)
        self.assertIn('python3 \\\"/tmp/runtime/scripts/hooks/readonly_command_guard.py\\\" --host codex', result.stdout)

    def test_render_claude_hooks_keeps_json_shape(self):
        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT),
                "--block",
                "claude_hooks",
                "--runtime-root",
                "/tmp/runtime",
            ],
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        data = json.loads(result.stdout)
        self.assertIn("hooks", data)
        self.assertIn("SessionStart", data["hooks"])
        pre_tool_use = data["hooks"]["PreToolUse"][0]["hooks"][0]["command"]
        self.assertIn('/tmp/runtime/scripts/hooks/readonly_command_guard.py', pre_tool_use)


if __name__ == "__main__":
    unittest.main()
