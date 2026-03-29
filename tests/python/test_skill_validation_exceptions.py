import subprocess
import sys
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT = REPO_ROOT / "scripts" / "check" / "validate-skills.py"


class SkillValidationExceptionTests(unittest.TestCase):
    def test_openspace_upstream_warning_is_ignored_via_config(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPT)],
            text=True,
            capture_output=True,
            cwd=REPO_ROOT,
            check=False,
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(
            "已按例外规则忽略 warning: thin_lines",
            result.stdout,
        )
        self.assertIn(
            "校验通过：0 个错误，0 个警告，1 个已忽略 warning",
            result.stdout,
        )
        self.assertNotIn(
            "[WARN] .agents/skills/openspace/delegate-task",
            result.stdout,
        )


if __name__ == "__main__":
    unittest.main()
