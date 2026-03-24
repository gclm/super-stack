import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = REPO_ROOT / "scripts" / "hooks" / "readonly_command_guard.py"


def load_module():
    spec = importlib.util.spec_from_file_location("readonly_command_guard", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class ReadonlyCommandGuardTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.module = load_module()

    def test_command_is_readonly_accepts_wrapped_read_commands(self):
        self.assertTrue(self.module.command_is_readonly("env FOO=bar rg super-stack README.md"))
        self.assertTrue(self.module.command_is_readonly("command git status"))
        self.assertTrue(self.module.command_is_readonly("sudo -u root -- pwd"))

    def test_command_is_readonly_rejects_write_shapes(self):
        self.assertFalse(self.module.command_is_readonly("echo hi > out.txt"))
        self.assertFalse(self.module.command_is_readonly("cat file | tee copy.txt"))
        self.assertFalse(self.module.command_is_readonly("python -c 'print(1)'"))

    def test_classify_command_distinguishes_allow_ask_and_deny(self):
        self.assertEqual(self.module.classify_command("pwd")["verdict"], "allow")
        self.assertEqual(self.module.classify_command("mkdir tmp-build")["verdict"], "ask")
        self.assertEqual(self.module.classify_command("git reset --hard")["verdict"], "deny")

    def test_main_allows_readonly_commands_and_writes_log(self):
        with tempfile.TemporaryDirectory() as tmp:
            cwd = Path(tmp)
            (cwd / ".planning").mkdir()
            payload = {
                "tool_name": "exec_command",
                "tool_input": {"cmd": "pwd"},
                "cwd": str(cwd),
            }

            result = subprocess.run(
                [sys.executable, str(MODULE_PATH), "--host", "codex"],
                input=json.dumps(payload),
                text=True,
                capture_output=True,
                cwd=cwd,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            response = json.loads(result.stdout)
            self.assertEqual(response["permissionDecision"], "allow")
            self.assertEqual(response["decision"], "allow")

            log_text = (cwd / ".planning" / ".super-stack-readonly-hook.log").read_text(encoding="utf-8")
            self.assertIn("allow\tlow\tpwd", log_text)

    def test_main_passes_non_readonly_commands_and_writes_ask_log(self):
        with tempfile.TemporaryDirectory() as tmp:
            cwd = Path(tmp)
            (cwd / ".planning").mkdir()
            payload = {
                "tool_name": "exec_command",
                "tool_input": {"cmd": "echo hi > out.txt"},
                "cwd": str(cwd),
            }

            result = subprocess.run(
                [sys.executable, str(MODULE_PATH), "--host", "claude"],
                input=json.dumps(payload),
                text=True,
                capture_output=True,
                cwd=cwd,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(json.loads(result.stdout), {})

            log_text = (cwd / ".planning" / ".super-stack-readonly-hook.log").read_text(encoding="utf-8")
            self.assertIn("ask\tmedium\techo hi > out.txt", log_text)

    def test_main_denies_high_risk_commands(self):
        with tempfile.TemporaryDirectory() as tmp:
            cwd = Path(tmp)
            (cwd / ".planning").mkdir()
            payload = {
                "tool_name": "exec_command",
                "tool_input": {"cmd": "rm -rf tmp-build"},
                "cwd": str(cwd),
            }

            result = subprocess.run(
                [sys.executable, str(MODULE_PATH), "--host", "codex"],
                input=json.dumps(payload),
                text=True,
                capture_output=True,
                cwd=cwd,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            response = json.loads(result.stdout)
            self.assertEqual(response["permissionDecision"], "deny")
            self.assertEqual(response["decision"], "deny")

            log_text = (cwd / ".planning" / ".super-stack-readonly-hook.log").read_text(encoding="utf-8")
            self.assertIn("deny\thigh\trm -rf tmp-build", log_text)


if __name__ == "__main__":
    unittest.main()
