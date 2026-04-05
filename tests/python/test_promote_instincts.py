import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
PROMOTE_SCRIPT = REPO_ROOT / "skills" / "planning" / "codex-record-retrospective" / "scripts" / "promote_instincts.py"


class PromoteInstinctsTests(unittest.TestCase):
    def test_promotes_cross_project_instinct_to_global_candidate(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            project_a = tmp_path / "projects" / "proj-a" / "instincts" / "active"
            project_b = tmp_path / "projects" / "proj-b" / "instincts" / "active"
            global_dir = tmp_path / "global" / "instincts" / "active"
            recommendations_dir = tmp_path / "recommendations"
            ledger_path = tmp_path / "ledger.jsonl"
            project_a.mkdir(parents=True)
            project_b.mkdir(parents=True)

            instinct = {
                "id": "tool-start-rg",
                "scope": "project",
                "project_id": "proj-a",
                "project_name": "alpha",
                "trigger": "when using tool rg",
                "action": "Prefer using rg when this workflow pattern appears.",
                "confidence": 0.7,
                "domain": "workflow",
                "source": "codex-observation",
                "occurrence_count": 4,
                "last_seen": "2026-04-01T10:00:00Z",
                "status": "active",
                "evidence_refs": ["session:a"],
            }
            instinct_b = dict(instinct)
            instinct_b["project_id"] = "proj-b"
            instinct_b["project_name"] = "beta"
            instinct_b["evidence_refs"] = ["session:b"]

            (project_a / "tool-start-rg.json").write_text(json.dumps(instinct, ensure_ascii=False, indent=2), encoding="utf-8")
            (project_b / "tool-start-rg.json").write_text(json.dumps(instinct_b, ensure_ascii=False, indent=2), encoding="utf-8")

            result = subprocess.run(
                [
                    sys.executable,
                    str(PROMOTE_SCRIPT),
                    "--projects-root",
                    str(tmp_path / "projects"),
                    "--global-dir",
                    str(global_dir),
                    "--recommendations-dir",
                    str(recommendations_dir),
                    "--ledger",
                    str(ledger_path),
                ],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            global_files = sorted(global_dir.glob("*.json"))
            self.assertEqual(len(global_files), 1)
            promoted = json.loads(global_files[0].read_text(encoding="utf-8"))
            self.assertEqual(promoted["scope"], "global")
            self.assertEqual(promoted["status"], "active")
            self.assertIn("proj-a", promoted["source_projects"])
            self.assertIn("proj-b", promoted["source_projects"])
            ledger_lines = ledger_path.read_text(encoding="utf-8").splitlines()
            self.assertEqual(len(ledger_lines), 1)
            ledger_entry = json.loads(ledger_lines[0])
            self.assertEqual(ledger_entry["recommendation_status"], "accepted")
            self.assertEqual(ledger_entry["lesson_id"], "tool-start-rg")

    def test_generates_recommendation_for_high_confidence_single_project_instinct(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            project_a = tmp_path / "projects" / "proj-a" / "instincts" / "active"
            global_dir = tmp_path / "global" / "instincts" / "active"
            recommendations_dir = tmp_path / "recommendations"
            ledger_path = tmp_path / "ledger.jsonl"
            project_a.mkdir(parents=True)

            instinct = {
                "id": "verify-success-message",
                "scope": "project",
                "project_id": "proj-a",
                "project_name": "alpha",
                "trigger": "when a verify path repeatedly succeeds",
                "action": "Reuse this verification path: real webpage verified with DOM and network evidence",
                "confidence": 0.75,
                "domain": "verify",
                "source": "codex-observation",
                "occurrence_count": 4,
                "last_seen": "2026-04-01T10:00:00Z",
                "status": "active",
                "evidence_refs": ["session:a"],
            }
            (project_a / "verify-success-message.json").write_text(json.dumps(instinct, ensure_ascii=False, indent=2), encoding="utf-8")

            result = subprocess.run(
                [
                    sys.executable,
                    str(PROMOTE_SCRIPT),
                    "--projects-root",
                    str(tmp_path / "projects"),
                    "--global-dir",
                    str(global_dir),
                    "--recommendations-dir",
                    str(recommendations_dir),
                    "--ledger",
                    str(ledger_path),
                ],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            recommendation_files = sorted(recommendations_dir.glob("*.json"))
            self.assertEqual(len(recommendation_files), 1)
            recommendation = json.loads(recommendation_files[0].read_text(encoding="utf-8"))
            self.assertEqual(recommendation["approval_level"], "patch-proposed")
            self.assertEqual(recommendation["project_id"], "proj-a")
            self.assertEqual(recommendation["source_instinct_id"], "verify-success-message")
            self.assertTrue(recommendation["evidence_refs"])
            ledger_lines = ledger_path.read_text(encoding="utf-8").splitlines()
            self.assertEqual(len(ledger_lines), 1)
            ledger_entry = json.loads(ledger_lines[0])
            self.assertEqual(ledger_entry["recommendation_status"], "patch-proposed")
            self.assertEqual(ledger_entry["lesson_id"], "verify-success-message")

    def test_skips_duplicate_recommendation_when_already_exists(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            project_a = tmp_path / "projects" / "proj-a" / "instincts" / "active"
            global_dir = tmp_path / "global" / "instincts" / "active"
            recommendations_dir = tmp_path / "recommendations"
            ledger_path = tmp_path / "ledger.jsonl"
            project_a.mkdir(parents=True)
            recommendations_dir.mkdir(parents=True)

            instinct = {
                "id": "verify-success-message",
                "scope": "project",
                "project_id": "proj-a",
                "project_name": "alpha",
                "trigger": "when a verify path repeatedly succeeds",
                "action": "Reuse this verification path: real webpage verified with DOM and network evidence",
                "confidence": 0.75,
                "domain": "verify",
                "source": "codex-observation",
                "occurrence_count": 4,
                "last_seen": "2026-04-01T10:00:00Z",
                "status": "active",
                "evidence_refs": ["session:a"],
            }
            (project_a / "verify-success-message.json").write_text(json.dumps(instinct, ensure_ascii=False, indent=2), encoding="utf-8")
            (recommendations_dir / "verify-success-message.json").write_text(json.dumps({"existing": True}, ensure_ascii=False, indent=2), encoding="utf-8")

            result = subprocess.run(
                [
                    sys.executable,
                    str(PROMOTE_SCRIPT),
                    "--projects-root",
                    str(tmp_path / "projects"),
                    "--global-dir",
                    str(global_dir),
                    "--recommendations-dir",
                    str(recommendations_dir),
                    "--ledger",
                    str(ledger_path),
                ],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            recommendation_files = sorted(recommendations_dir.glob("*.json"))
            self.assertEqual(len(recommendation_files), 1)
            payload = json.loads(recommendation_files[0].read_text(encoding="utf-8"))
            self.assertEqual(payload, {"existing": True})
            ledger_lines = ledger_path.read_text(encoding="utf-8").splitlines()
            self.assertEqual(len(ledger_lines), 0)


if __name__ == "__main__":
    unittest.main()
