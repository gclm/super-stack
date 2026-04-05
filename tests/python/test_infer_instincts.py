import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
INFER_SCRIPT = REPO_ROOT / "skills" / "planning" / "codex-record-retrospective" / "scripts" / "infer_instincts.py"


class InferInstinctsTests(unittest.TestCase):
    def test_infer_instincts_promotes_repeated_tool_pattern_to_active(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            observations_path = tmp_path / "observations.jsonl"
            output_dir = tmp_path / "instincts"

            observations = [
                {
                    "schema_version": "v1",
                    "timestamp": f"2026-04-01T10:00:0{i}Z",
                    "project_id": "super-stack",
                    "project_name": "super-stack",
                    "session_id": "session-1",
                    "slice_id": "slice-001",
                    "event_type": "tool_start",
                    "tool": "rg",
                    "summary": "rg: AGENTS.md",
                    "evidence_refs": [f"session:session-1", f"timestamp:{i}"],
                }
                for i in range(3)
            ]
            with observations_path.open("w", encoding="utf-8") as handle:
                for row in observations:
                    handle.write(json.dumps(row, ensure_ascii=False) + "\n")

            result = subprocess.run(
                [sys.executable, str(INFER_SCRIPT), "--observations", str(observations_path), "--output-dir", str(output_dir)],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            active_files = sorted((output_dir / "active").glob("*.json"))
            self.assertEqual(len(active_files), 1)
            instinct = json.loads(active_files[0].read_text(encoding="utf-8"))
            self.assertEqual(instinct["scope"], "project")
            self.assertEqual(instinct["status"], "active")
            self.assertEqual(instinct["occurrence_count"], 3)
            self.assertEqual(instinct["domain"], "workflow")
            self.assertGreaterEqual(instinct["confidence"], 0.5)
            self.assertIn("when using tool rg", instinct["trigger"])

    def test_infer_instincts_keeps_single_observation_as_pending(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            observations_path = tmp_path / "observations.jsonl"
            output_dir = tmp_path / "instincts"

            observations = [
                {
                    "schema_version": "v1",
                    "timestamp": "2026-04-01T10:00:00Z",
                    "project_id": "super-stack",
                    "project_name": "super-stack",
                    "session_id": "session-2",
                    "slice_id": "slice-001",
                    "event_type": "message",
                    "tool": None,
                    "summary": "帮我验证真实网页内容",
                    "evidence_refs": ["session:session-2"],
                }
            ]
            with observations_path.open("w", encoding="utf-8") as handle:
                for row in observations:
                    handle.write(json.dumps(row, ensure_ascii=False) + "\n")

            result = subprocess.run(
                [sys.executable, str(INFER_SCRIPT), "--observations", str(observations_path), "--output-dir", str(output_dir)],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            active_files = sorted((output_dir / "active").glob("*.json"))
            pending_files = sorted((output_dir / "pending").glob("*.json"))
            self.assertEqual(len(active_files), 0)
            self.assertEqual(len(pending_files), 1)
            instinct = json.loads(pending_files[0].read_text(encoding="utf-8"))
            self.assertEqual(instinct["status"], "pending")
            self.assertEqual(instinct["occurrence_count"], 1)
            self.assertEqual(instinct["confidence"], 0.3)

    def test_infer_instincts_boosts_verify_signals(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            observations_path = tmp_path / "observations.jsonl"
            output_dir = tmp_path / "instincts"

            observations = [
                {
                    "schema_version": "v1",
                    "timestamp": "2026-04-01T10:00:00Z",
                    "project_id": "super-stack",
                    "project_name": "super-stack",
                    "session_id": "session-3",
                    "slice_id": "slice-001",
                    "event_type": "verify_success",
                    "tool": None,
                    "summary": "real webpage verified with DOM and network evidence",
                    "evidence_refs": ["session:session-3"],
                },
                {
                    "schema_version": "v1",
                    "timestamp": "2026-04-01T10:10:00Z",
                    "project_id": "super-stack",
                    "project_name": "super-stack",
                    "session_id": "session-4",
                    "slice_id": "slice-001",
                    "event_type": "verify_success",
                    "tool": None,
                    "summary": "real webpage verified with DOM and network evidence",
                    "evidence_refs": ["session:session-4"],
                },
            ]
            with observations_path.open("w", encoding="utf-8") as handle:
                for row in observations:
                    handle.write(json.dumps(row, ensure_ascii=False) + "\n")

            result = subprocess.run(
                [sys.executable, str(INFER_SCRIPT), "--observations", str(observations_path), "--output-dir", str(output_dir)],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            pending_files = sorted((output_dir / "pending").glob("*.json"))
            self.assertEqual(len(pending_files), 1)
            instinct = json.loads(pending_files[0].read_text(encoding="utf-8"))
            self.assertEqual(instinct["domain"], "verify")
            self.assertGreater(instinct["confidence"], 0.3)
            self.assertIn("verify", instinct["trigger"])

    def test_infer_instincts_downweights_correction_patterns(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            observations_path = tmp_path / "observations.jsonl"
            output_dir = tmp_path / "instincts"

            observations = [
                {
                    "schema_version": "v1",
                    "timestamp": f"2026-04-01T10:00:0{i}Z",
                    "project_id": "super-stack",
                    "project_name": "super-stack",
                    "session_id": "session-5",
                    "slice_id": "slice-001",
                    "event_type": "user_correction",
                    "tool": None,
                    "summary": "不要先问我要不要委托",
                    "evidence_refs": [f"session:session-5", f"timestamp:{i}"],
                }
                for i in range(3)
            ]
            with observations_path.open("w", encoding="utf-8") as handle:
                for row in observations:
                    handle.write(json.dumps(row, ensure_ascii=False) + "\n")

            result = subprocess.run(
                [sys.executable, str(INFER_SCRIPT), "--observations", str(observations_path), "--output-dir", str(output_dir)],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            pending_files = sorted((output_dir / "pending").glob("*.json"))
            self.assertEqual(len(pending_files), 1)
            instinct = json.loads(pending_files[0].read_text(encoding="utf-8"))
            self.assertEqual(instinct["status"], "pending")
            self.assertLess(instinct["confidence"], 0.5)
            self.assertEqual(instinct["domain"], "routing")

    def test_infer_instincts_separates_verify_success_and_gap_instincts(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            observations_path = tmp_path / "observations.jsonl"
            output_dir = tmp_path / "instincts"

            observations = [
                {
                    "schema_version": "v1",
                    "timestamp": f"2026-04-01T10:00:0{i}Z",
                    "project_id": "super-stack",
                    "project_name": "super-stack",
                    "session_id": f"session-success-{i}",
                    "slice_id": "slice-001",
                    "event_type": "verify_success",
                    "tool": None,
                    "summary": "real webpage verified with DOM and network evidence",
                    "evidence_refs": [f"session:session-success-{i}"],
                }
                for i in range(3)
            ]
            observations.extend(
                [
                    {
                        "schema_version": "v1",
                        "timestamp": f"2026-04-01T11:00:0{i}Z",
                        "project_id": "super-stack",
                        "project_name": "super-stack",
                        "session_id": f"session-gap-{i}",
                        "slice_id": "slice-002",
                        "event_type": "verify_gap",
                        "tool": None,
                        "summary": "missing DOM or network evidence for real webpage verification",
                        "evidence_refs": [f"session:session-gap-{i}"],
                    }
                    for i in range(2)
                ]
            )
            with observations_path.open("w", encoding="utf-8") as handle:
                for row in observations:
                    handle.write(json.dumps(row, ensure_ascii=False) + "\n")

            result = subprocess.run(
                [sys.executable, str(INFER_SCRIPT), "--observations", str(observations_path), "--output-dir", str(output_dir)],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            active_files = sorted((output_dir / "active").glob("*.json"))
            pending_files = sorted((output_dir / "pending").glob("*.json"))
            self.assertEqual(len(active_files), 1)
            self.assertEqual(len(pending_files), 1)
            active = json.loads(active_files[0].read_text(encoding="utf-8"))
            pending = json.loads(pending_files[0].read_text(encoding="utf-8"))
            self.assertEqual(active["id"], "verify-success-message")
            self.assertEqual(active["status"], "active")
            self.assertEqual(active["occurrence_count"], 3)
            self.assertEqual(pending["id"], "verify-gap-message")
            self.assertEqual(pending["status"], "pending")
            self.assertEqual(pending["occurrence_count"], 2)

    def test_infer_instincts_applies_negative_feedback_to_corrected_tool_pattern(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            observations_path = tmp_path / "observations.jsonl"
            output_dir = tmp_path / "instincts"

            observations = [
                {
                    "schema_version": "v1",
                    "timestamp": f"2026-04-01T10:00:0{i}Z",
                    "project_id": "super-stack",
                    "project_name": "super-stack",
                    "session_id": f"session-tool-{i}",
                    "slice_id": "slice-001",
                    "event_type": "tool_start",
                    "tool": "delegate-task",
                    "summary": "delegate-task: open browser verification",
                    "evidence_refs": [f"session:session-tool-{i}"],
                }
                for i in range(3)
            ]
            observations.extend(
                [
                    {
                        "schema_version": "v1",
                        "timestamp": f"2026-04-01T10:10:0{i}Z",
                        "project_id": "super-stack",
                        "project_name": "super-stack",
                        "session_id": f"session-correction-{i}",
                        "slice_id": "slice-001",
                        "event_type": "user_correction",
                        "tool": None,
                        "summary": "不要先问我要不要委托",
                        "evidence_refs": [f"session:session-correction-{i}"],
                        "metadata": {
                            "corrects_event_type": "tool_start",
                            "corrects_tool": "delegate-task",
                        },
                    }
                    for i in range(2)
                ]
            )
            with observations_path.open("w", encoding="utf-8") as handle:
                for row in observations:
                    handle.write(json.dumps(row, ensure_ascii=False) + "\n")

            result = subprocess.run(
                [sys.executable, str(INFER_SCRIPT), "--observations", str(observations_path), "--output-dir", str(output_dir)],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            active_files = sorted((output_dir / "active").glob("*.json"))
            pending_files = sorted((output_dir / "pending").glob("*.json"))
            self.assertEqual(len(active_files), 0)
            self.assertEqual(len(pending_files), 2)

            by_id = {
                json.loads(path.read_text(encoding="utf-8"))["id"]: json.loads(path.read_text(encoding="utf-8"))
                for path in pending_files
            }
            corrected = by_id["tool-start-delegate-task"]
            self.assertEqual(corrected["status"], "pending")
            self.assertEqual(corrected["occurrence_count"], 3)
            self.assertEqual(corrected["negative_feedback_count"], 2)
            self.assertLess(corrected["confidence"], 0.5)
            self.assertIn("user correction", corrected["metadata"]["demotion_reason"])


if __name__ == "__main__":
    unittest.main()
