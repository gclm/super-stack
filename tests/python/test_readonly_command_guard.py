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

    # -- segment-level --

    def test_segment_is_readonly_basic(self):
        self.assertTrue(self.module.segment_is_readonly("pwd"))
        self.assertTrue(self.module.segment_is_readonly("git status"))
        self.assertTrue(self.module.segment_is_readonly("rg -n TODO file.txt"))
        self.assertTrue(self.module.segment_is_readonly("cat file.txt"))
        self.assertTrue(self.module.segment_is_readonly("sed -n '1,5p' file.txt"))

    def test_segment_is_readonly_rejects_write(self):
        self.assertFalse(self.module.segment_is_readonly("echo hi > out.txt"))
        self.assertFalse(self.module.segment_is_readonly("cat file | tee copy.txt"))
        self.assertFalse(self.module.segment_is_readonly("echo $(cat file)"))
        self.assertFalse(self.module.segment_is_readonly("echo `cat file`"))

    def test_segment_is_readonly_allows_stderr_null(self):
        self.assertTrue(self.module.segment_is_readonly("cat file.txt 2>/dev/null"))

    def test_segment_is_readonly_rejects_stderr_to_file(self):
        self.assertFalse(self.module.segment_is_readonly("cat file.txt 2>errors.log"))

    def test_segment_is_readonly_wrapped_commands(self):
        self.assertTrue(self.module.segment_is_readonly("env FOO=bar rg super-stack README.md"))
        self.assertTrue(self.module.segment_is_readonly("command git status"))
        self.assertTrue(self.module.segment_is_readonly("sudo -u root -- pwd"))

    # -- classify_command --

    def test_classify_allows_readonly(self):
        self.assertEqual(self.module.classify_command("pwd")["verdict"], "allow")
        self.assertEqual(self.module.classify_command("git status")["verdict"], "allow")
        self.assertEqual(self.module.classify_command("rg TODO file.txt")["verdict"], "allow")
        self.assertEqual(self.module.classify_command("cat file.txt 2>/dev/null")["verdict"], "allow")

    def test_classify_asks_non_readonly(self):
        self.assertEqual(self.module.classify_command("mkdir tmp-build")["verdict"], "ask")
        self.assertEqual(self.module.classify_command("git add .")["verdict"], "ask")
        self.assertEqual(self.module.classify_command("echo hi > out.txt")["verdict"], "ask")

    def test_classify_asks_high_risk(self):
        # No deny tier: high-risk commands just become "ask"
        self.assertEqual(self.module.classify_command("rm -rf tmp-build")["verdict"], "ask")
        self.assertEqual(self.module.classify_command("git reset --hard")["verdict"], "ask")
        self.assertEqual(self.module.classify_command("dd if=/dev/zero of=test.img")["verdict"], "ask")

    def test_classify_git_branch_mutating_flags(self):
        self.assertEqual(self.module.classify_command("git branch -d old")["verdict"], "ask")
        self.assertEqual(self.module.classify_command("git branch -D old")["verdict"], "ask")
        self.assertEqual(self.module.classify_command("git branch")["verdict"], "allow")

    def test_classify_pipeline_all_readonly(self):
        self.assertEqual(self.module.classify_command("git status | head -5")["verdict"], "allow")
        self.assertEqual(self.module.classify_command("pwd && rg TODO README.md")["verdict"], "allow")

    def test_classify_pipeline_mixed(self):
        self.assertEqual(self.module.classify_command("pwd && mkdir tmp")["verdict"], "ask")

    def test_classify_empty(self):
        self.assertEqual(self.module.classify_command("")["verdict"], "ask")
        self.assertEqual(self.module.classify_command("  ")["verdict"], "ask")

    def test_classify_package_managers(self):
        self.assertEqual(self.module.classify_command("npm list")["verdict"], "allow")
        self.assertEqual(self.module.classify_command("brew info node")["verdict"], "allow")
        self.assertEqual(self.module.classify_command("pip list")["verdict"], "allow")
        self.assertEqual(self.module.classify_command("npm install")["verdict"], "ask")
        self.assertEqual(self.module.classify_command("brew install node")["verdict"], "ask")

    # -- hook integration via subprocess --

    def test_main_allows_readonly_and_writes_log(self):
        with tempfile.TemporaryDirectory() as tmp:
            cwd = Path(tmp)
            (cwd / "harness").mkdir()
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

            log_text = (cwd / "harness" / ".runtime" / "super-stack-readonly-hook.log").read_text(encoding="utf-8")
            self.assertIn("allow\tlow\tpwd", log_text)

    def test_main_passes_non_readonly_through(self):
        with tempfile.TemporaryDirectory() as tmp:
            cwd = Path(tmp)
            (cwd / "harness").mkdir()
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

            log_text = (cwd / "harness" / ".runtime" / "super-stack-readonly-hook.log").read_text(encoding="utf-8")
            self.assertIn("ask\tmedium\techo hi > out.txt", log_text)

    def test_main_asks_high_risk_no_deny(self):
        with tempfile.TemporaryDirectory() as tmp:
            cwd = Path(tmp)
            (cwd / "harness").mkdir()
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
            # No deny tier: returns empty JSON (ask / pass-through)
            self.assertEqual(json.loads(result.stdout), {})

            log_text = (cwd / "harness" / ".runtime" / "super-stack-readonly-hook.log").read_text(encoding="utf-8")
            self.assertIn("ask\tmedium\trm -rf tmp-build", log_text)

    def test_classify_flag(self):
        result = subprocess.run(
            [sys.executable, str(MODULE_PATH), "--host", "codex", "--classify", "pwd"],
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        data = json.loads(result.stdout)
        self.assertEqual(data["verdict"], "allow")

    def test_main_ignores_non_shell_tools(self):
        with tempfile.TemporaryDirectory() as tmp:
            cwd = Path(tmp)
            (cwd / "harness").mkdir()
            payload = {
                "tool_name": "Write",
                "tool_input": {"file_path": "/tmp/test.txt", "content": "hello"},
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


if __name__ == "__main__":
    unittest.main()
