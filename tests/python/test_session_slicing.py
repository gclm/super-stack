import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
SLICE_SCRIPT = REPO_ROOT / "skills" / "planning" / "codex-record-retrospective" / "scripts" / "slice_codex_session.py"


class SessionSlicingTests(unittest.TestCase):
    def test_slice_codex_session_splits_on_gap_and_user_boundary(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            session_file = tmp_path / "session.jsonl"
            rows = [
                {"type": "session_meta", "timestamp": "2026-03-27T10:00:00Z", "payload": {"id": "demo", "cwd": "/tmp/project"}},
                {"type": "response_item", "timestamp": "2026-03-27T10:00:05Z", "payload": {"type": "message", "role": "user", "content": [{"type": "input_text", "text": "先帮我补自动更新设计"}]}},
                {"type": "response_item", "timestamp": "2026-03-27T10:01:00Z", "payload": {"type": "message", "role": "assistant", "content": [{"type": "output_text", "text": "我来先分析文档。"}]}},
                {"type": "response_item", "timestamp": "2026-03-27T10:45:00Z", "payload": {"type": "message", "role": "user", "content": [{"type": "input_text", "text": "另外再帮我看一下技能自动化"}]}},
                {"type": "response_item", "timestamp": "2026-03-27T10:46:00Z", "payload": {"type": "message", "role": "assistant", "content": [{"type": "output_text", "text": "我继续处理自动化。"}]}},
            ]
            with session_file.open("w", encoding="utf-8") as handle:
                for row in rows:
                    handle.write(json.dumps(row, ensure_ascii=False) + "\n")

            result = subprocess.run(
                [
                    sys.executable,
                    str(SLICE_SCRIPT),
                    "--session-file",
                    str(session_file),
                    "--format",
                    "json",
                ],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            payload = json.loads(result.stdout)
            self.assertEqual(payload["slice_count"], 2)
            self.assertEqual(payload["slices"][0]["slice_id"], "slice-001")
            self.assertEqual(payload["slices"][1]["slice_id"], "slice-002")


if __name__ == "__main__":
    unittest.main()
