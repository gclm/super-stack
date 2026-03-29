import json
import subprocess
import sys
import unittest
from unittest import mock
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT = REPO_ROOT / "scripts" / "config" / "render_managed_config.py"
MANIFEST = REPO_ROOT / "config" / "manifest.json"
SCRIPT_DIR = REPO_ROOT / "scripts" / "config"

if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import managed_config_lib


class ManagedConfigRenderingTests(unittest.TestCase):
    def test_manifest_contains_expected_blocks(self):
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        self.assertEqual(manifest.get("manifest_version"), 1)
        self.assertIn("mcp", manifest)
        self.assertIn("servers", manifest["mcp"])
        self.assertIn("chrome-devtools-mcp", manifest["mcp"]["servers"])
        self.assertIn("managed_blocks", manifest)
        self.assertIn("codex_agents", manifest["managed_blocks"])
        self.assertIn("codex_hooks", manifest["managed_blocks"])
        self.assertIn("codex_mcp", manifest["managed_blocks"])
        self.assertIn("claude_mcp", manifest["managed_blocks"])
        self.assertIn("claude_hooks", manifest["managed_blocks"])
        self.assertIn("skill_validation", manifest)

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
        session_start = data["hooks"]["SessionStart"][0]["hooks"][0]["command"]
        self.assertIn("harness/state.md", session_start)
        pre_tool_use = data["hooks"]["PreToolUse"][0]["hooks"][0]["command"]
        self.assertIn('/tmp/runtime/scripts/hooks/readonly_command_guard.py', pre_tool_use)

    def test_render_codex_mcp_contains_server_block(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--block", "codex_mcp"],
            text=True,
            capture_output=True,
            check=False,
            env={"PATH": "/tmp/bin:/usr/bin:/bin", "CHROME_DEVTOOLS_MCP_BIN": "/tmp/bin/chrome-devtools-mcp"},
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('[mcp_servers.chrome-devtools-mcp]', result.stdout)
        self.assertIn('command = "/tmp/bin/chrome-devtools-mcp"', result.stdout)
        self.assertIn('--autoConnect', result.stdout)

    def test_render_codex_mcp_includes_openspace_when_available(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--block", "codex_mcp"],
            text=True,
            capture_output=True,
            check=False,
            env={
                "PATH": "/tmp/bin:/usr/bin:/bin",
                "CHROME_DEVTOOLS_MCP_BIN": "/tmp/bin/chrome-devtools-mcp",
                "OPENSPACE_MCP_BIN": "/tmp/bin/openspace-mcp",
            },
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('[mcp_servers.chrome-devtools-mcp]', result.stdout)
        self.assertIn('[mcp_servers.openspace]', result.stdout)
        self.assertIn('command = "/tmp/bin/openspace-mcp"', result.stdout)
        self.assertIn('[mcp_servers.openspace.env]', result.stdout)
        self.assertIn('OPENSPACE_HOST_SKILL_DIRS = "/Users/gclm/.agents/skills"', result.stdout)
        self.assertIn('OPENSPACE_WORKSPACE = "/Users/gclm/.super-stack/openspace"', result.stdout)

    def test_render_claude_mcp_keeps_json_shape(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--block", "claude_mcp"],
            text=True,
            capture_output=True,
            check=False,
            env={"PATH": "/tmp/bin:/usr/bin:/bin", "CHROME_DEVTOOLS_MCP_BIN": "/tmp/bin/chrome-devtools-mcp"},
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        data = json.loads(result.stdout)
        self.assertIn("mcpServers", data)
        self.assertIn("chrome-devtools-mcp", data["mcpServers"])
        self.assertEqual(data["mcpServers"]["chrome-devtools-mcp"]["command"], "/tmp/bin/chrome-devtools-mcp")
        # openspace is not part of claude_mcp by default; ensure schema still supports optional env key

    def test_render_codex_mcp_supports_multiple_manifest_servers(self):
        manifest = {
            "mcp": {
                "servers": {
                    "alpha-mcp": {
                        "command_name": "alpha-mcp",
                        "args": ["--alpha"],
                        "enabled": True,
                    },
                    "beta-mcp": {
                        "command_name": "beta-mcp",
                        "args": ["--beta"],
                        "enabled": False,
                    },
                },
            },
            "managed_blocks": {
                "codex_mcp": {
                    "kind": "mcp",
                    "target_format": "toml",
                    "content": {
                        "servers": ["alpha-mcp", "beta-mcp"],
                    }
                }
            },
        }

        with mock.patch.object(managed_config_lib, "load_manifest", return_value=manifest):
            with mock.patch.object(
                managed_config_lib.shutil,
                "which",
                side_effect=lambda name: f"/tmp/bin/{name}",
            ):
                rendered = managed_config_lib.render_codex_mcp("codex_mcp")

        self.assertIn('[mcp_servers.alpha-mcp]', rendered)
        self.assertIn('command = "/tmp/bin/alpha-mcp"', rendered)
        self.assertIn('[mcp_servers.beta-mcp]', rendered)
        self.assertIn('enabled = false', rendered)

    def test_render_codex_mcp_renders_manifest_env_section(self):
        manifest = {
            "mcp": {
                "servers": {
                    "env-mcp": {
                        "command_fixed": "/tmp/bin/env-mcp",
                        "args": [],
                        "enabled": True,
                        "env": {
                            "FOO": "bar",
                            "ABC": "xyz",
                        },
                    },
                },
            },
            "managed_blocks": {
                "codex_mcp": {
                    "kind": "mcp",
                    "target_format": "toml",
                    "content": {
                        "servers": ["env-mcp"],
                    }
                }
            },
        }

        with mock.patch.object(managed_config_lib, "load_manifest", return_value=manifest):
            rendered = managed_config_lib.render_codex_mcp("codex_mcp")

        self.assertIn('[mcp_servers.env-mcp.env]', rendered)
        self.assertIn('ABC = "xyz"', rendered)
        self.assertIn('FOO = "bar"', rendered)


if __name__ == "__main__":
    unittest.main()
