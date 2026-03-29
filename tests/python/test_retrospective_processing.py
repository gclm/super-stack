import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
PROCESS_SCRIPT = REPO_ROOT / "skills" / "planning" / "codex-record-retrospective" / "scripts" / "process_retrospective.py"


class RetrospectiveProcessingTests(unittest.TestCase):
    def test_process_retrospective_generates_outputs_and_ledger(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            retrospective_path = tmp_path / "retro.json"
            recommendation_json = tmp_path / "artifacts" / "evolution" / "recommendations.json"
            recommendation_md = tmp_path / "artifacts" / "evolution" / "recommendations.md"
            ledger_path = tmp_path / "artifacts" / "evolution" / "evolution-ledger.jsonl"

            payload = {
                "project_path": "/tmp/demo-project",
                "topic": "daily-retro",
                "generalized_lessons": [
                    {"lesson_id": "verify_overclaim", "summary": "验证结论过度乐观"}
                ],
                "patterns": [],
                "classifications": [],
            }
            retrospective_path.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")

            result = subprocess.run(
                [
                    sys.executable,
                    str(PROCESS_SCRIPT),
                    "--retrospective-json",
                    str(retrospective_path),
                    "--output-json",
                    str(recommendation_json),
                    "--output-md",
                    str(recommendation_md),
                    "--ledger-path",
                    str(ledger_path),
                ],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            summary = json.loads(result.stdout)
            self.assertEqual(summary["topic"], "daily-retro")
            self.assertTrue(Path(summary["retrospective_md"]).exists())
            self.assertTrue(recommendation_json.exists())
            self.assertTrue(recommendation_md.exists())
            self.assertTrue(ledger_path.exists())

            reco = json.loads(recommendation_json.read_text(encoding="utf-8"))
            self.assertEqual(reco["recommendations"][0]["lesson_id"], "verify_overclaim")
            ledger_lines = ledger_path.read_text(encoding="utf-8").strip().splitlines()
            self.assertEqual(len(ledger_lines), 1)

    def test_process_retrospective_prefers_generalized_lessons_over_patterns(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            retrospective_path = tmp_path / "retro.json"
            recommendation_json = tmp_path / "artifacts" / "evolution" / "recommendations.json"
            ledger_path = tmp_path / "artifacts" / "evolution" / "evolution-ledger.jsonl"

            payload = {
                "project_path": "/tmp/demo-project",
                "topic": "slice-priority",
                "patterns": [
                    {"summary": "同一 session 内先讨论自动任务进度，后续又切到 commit 和 ID 策略"}
                ],
                "classifications": [
                    {"summary": "复盘单元边界需要从 session 升级为 slice"}
                ],
                "generalized_lessons": [
                    {"lesson_id": "record_path_migration_gap", "summary": "需要带历史路径 alias 扫描"},
                    {"lesson_id": "missing_progress_artifacts", "summary": "长任务需要稳定进度产物"},
                    {"lesson_id": "session_slice_required", "summary": "同一 session 应先切 slice 再复盘"}
                ],
            }
            retrospective_path.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")

            result = subprocess.run(
                [
                    sys.executable,
                    str(PROCESS_SCRIPT),
                    "--retrospective-json",
                    str(retrospective_path),
                    "--output-json",
                    str(recommendation_json),
                    "--ledger-path",
                    str(ledger_path),
                ],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            reco = json.loads(recommendation_json.read_text(encoding="utf-8"))
            lesson_ids = [item["lesson_id"] for item in reco["recommendations"]]
            self.assertEqual(
                lesson_ids,
                ["record_path_migration_gap", "missing_progress_artifacts", "session_slice_required"],
            )
            self.assertEqual(reco["unmapped_lessons"], [])
            self.assertEqual(reco["recommendations"][2]["matched_mapping"], True)
            self.assertEqual(reco["recommendations"][2]["approval_level"], "patch-proposed")
            ledger_lines = ledger_path.read_text(encoding="utf-8").strip().splitlines()
            self.assertEqual(len(ledger_lines), 3)


if __name__ == "__main__":
    unittest.main()
