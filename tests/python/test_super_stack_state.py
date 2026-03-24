import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT_PATH = REPO_ROOT / ".codex" / "hooks" / "super_stack_state.py"


class SuperStackStateHookTests(unittest.TestCase):
    def test_sessionstart_reads_state_and_records_log(self):
        with tempfile.TemporaryDirectory() as tmp:
            cwd = Path(tmp)
            planning = cwd / ".planning"
            planning.mkdir()
            state_file = planning / "STATE.md"
            state_file.write_text("# STATE\n- status: testing\n", encoding="utf-8")

            result = subprocess.run(
                [sys.executable, str(SCRIPT_PATH)],
                input=json.dumps({"hook_event_name": "SessionStart", "cwd": str(cwd)}),
                text=True,
                capture_output=True,
                cwd=cwd,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            response = json.loads(result.stdout)
            self.assertIn("[super-stack] resuming from .planning/STATE.md", response["additionalContext"])
            self.assertIn("status: testing", response["additionalContext"])

            hook_log = (planning / ".super-stack-codex-hooks.log").read_text(encoding="utf-8")
            self.assertIn("sessionstart", hook_log)

    def test_stop_emits_reminder_when_state_exists(self):
        with tempfile.TemporaryDirectory() as tmp:
            cwd = Path(tmp)
            planning = cwd / ".planning"
            planning.mkdir()
            (planning / "STATE.md").write_text("# STATE\n", encoding="utf-8")

            result = subprocess.run(
                [sys.executable, str(SCRIPT_PATH)],
                input=json.dumps({"hook_event_name": "stop", "cwd": str(cwd)}),
                text=True,
                capture_output=True,
                cwd=cwd,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            response = json.loads(result.stdout)
            self.assertEqual(
                response["additionalContext"],
                "[super-stack] remember to leave STATE.md current",
            )

    def test_no_planning_directory_returns_empty_object(self):
        with tempfile.TemporaryDirectory() as tmp:
            cwd = Path(tmp)

            result = subprocess.run(
                [sys.executable, str(SCRIPT_PATH)],
                input=json.dumps({"hook_event_name": "SessionStart", "cwd": str(cwd)}),
                text=True,
                capture_output=True,
                cwd=cwd,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(json.loads(result.stdout), {})


if __name__ == "__main__":
    unittest.main()

