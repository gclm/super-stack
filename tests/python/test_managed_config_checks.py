import subprocess
import sys
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT = REPO_ROOT / "scripts" / "config" / "check_managed_config.py"


class ManagedConfigCheckTests(unittest.TestCase):
    def test_codex_agent_config_files_are_listed_from_manifest(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--block", "codex_agents", "--field", "config_files"],
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("agents/super-stack-explorer.toml", result.stdout)
        self.assertIn("agents/super-stack-reviewer.toml", result.stdout)
        self.assertIn("agents/super-stack-planner.toml", result.stdout)
        self.assertIn("agents/super-stack-builder.toml", result.stdout)

    def test_codex_agent_verify_metadata_is_available(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--block", "codex_agents", "--field", "markers"],
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("# BEGIN SUPER-STACK AGENTS", result.stdout)
        self.assertIn("# END SUPER-STACK AGENTS", result.stdout)

    def test_codex_agent_registered_entries_are_available(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--block", "codex_agents", "--field", "registered_entries"],
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('config_file = "agents/super-stack-explorer.toml"', result.stdout)
        self.assertIn('config_file = "agents/super-stack-reviewer.toml"', result.stdout)
        self.assertIn('config_file = "agents/super-stack-builder.toml"', result.stdout)

    def test_codex_agent_managed_files_are_rendered_with_home(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--block", "codex_agents", "--field", "managed_files", "--home", "/tmp/home"],
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("/tmp/home/.codex/agents/super-stack-explorer.toml", result.stdout)
        self.assertIn("/tmp/home/.codex/agents/super-stack-reviewer.toml", result.stdout)
        self.assertIn("/tmp/home/.codex/agents/super-stack-builder.toml", result.stdout)

    def test_codex_hook_commands_include_runtime_root(self):
        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT),
                "--block",
                "codex_hooks",
                "--field",
                "commands",
                "--runtime-root",
                "/tmp/runtime",
            ],
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('/tmp/runtime/.codex/hooks/super_stack_state.py', result.stdout)
        self.assertIn('/tmp/runtime/scripts/hooks/readonly_command_guard.py', result.stdout)

    def test_codex_mcp_markers_are_available(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--block", "codex_mcp", "--field", "markers"],
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("# BEGIN SUPER-STACK CODEX MCP", result.stdout)
        self.assertIn("# END SUPER-STACK CODEX MCP", result.stdout)

    def test_codex_mcp_contains_include_resolved_openspace_marker(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--block", "codex_mcp", "--field", "contains"],
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
        self.assertIn("[mcp_servers.chrome-devtools-mcp]", result.stdout)
        self.assertIn("[mcp_servers.openspace]", result.stdout)

    def test_claude_mcp_contains_are_available(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--block", "claude_mcp", "--field", "contains"],
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('"mcpServers"', result.stdout)
        self.assertIn('"chrome-devtools-mcp"', result.stdout)

    def test_target_file_is_rendered_with_home(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--block", "codex_agents", "--field", "target_file", "--home", "/tmp/home"],
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "/tmp/home/.codex/config.toml")

    def test_claude_hook_commands_include_runtime_root(self):
        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT),
                "--block",
                "claude_hooks",
                "--field",
                "commands",
                "--runtime-root",
                "/tmp/runtime",
            ],
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('/tmp/runtime/scripts/hooks/readonly_command_guard.py', result.stdout)
        self.assertIn('harness/state.md', result.stdout)
        self.assertIn('remember to leave harness/state.md current', result.stdout)


if __name__ == "__main__":
    unittest.main()
