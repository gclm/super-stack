import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
RENDER_SCRIPT = REPO_ROOT / "skills" / "planning" / "codex-record-retrospective" / "scripts" / "render_retrospective_report.py"


class RetrospectiveRenderingTests(unittest.TestCase):
    def test_render_retrospective_report_outputs_markdown(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            input_path = tmp_path / "retro.json"
            output_path = tmp_path / "retro.md"
            payload = {
                "project_path": "/tmp/demo-project",
                "generated_at": "2026-03-27T10:00:00Z",
                "workflow_summary": "补齐 retrospective、recommendation 和 ledger 流水线。",
                "patterns": [
                    {"summary": "验证边界表达过弱", "evidence_refs": ["demo#1"]}
                ],
                "generalized_lessons": [
                    {"lesson_id": "verify_overclaim", "summary": "已实现与已验证混淆"}
                ],
                "recommended_targets": ["protocols/verify.md"],
                "evidence_gaps": ["当前 live session 可能尚未入库"],
            }
            input_path.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")

            result = subprocess.run(
                [
                    sys.executable,
                    str(RENDER_SCRIPT),
                    "--retrospective-json",
                    str(input_path),
                    "--output-md",
                    str(output_path),
                ],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            content = output_path.read_text(encoding="utf-8")
            self.assertIn("# Retrospective Report", content)
            self.assertIn("## Workflow Summary", content)
            self.assertIn("verify_overclaim", content)
            self.assertIn("protocols/verify.md", content)


if __name__ == "__main__":
    unittest.main()
