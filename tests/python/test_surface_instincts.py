import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SURFACE_SCRIPT = REPO_ROOT / "skills" / "planning" / "codex-record-retrospective" / "scripts" / "surface_instincts.py"


class SurfaceInstinctsTests(unittest.TestCase):
    def test_surfaces_verify_instincts_for_matching_stage_and_signal(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            project_dir = tmp_path / "projects" / "super-stack" / "instincts" / "active"
            output_path = tmp_path / "surface.json"
            project_dir.mkdir(parents=True)

            verify_instinct = {
                "id": "verify-success-message",
                "scope": "project",
                "project_id": "super-stack",
                "project_name": "super-stack",
                "trigger": "when a verify path repeatedly succeeds",
                "action": "Reuse this verification path: real webpage verified with DOM and network evidence",
                "confidence": 0.75,
                "domain": "verify",
                "source": "codex-observation",
                "occurrence_count": 4,
                "negative_feedback_count": 0,
                "last_seen": "2026-04-01T10:00:00Z",
                "status": "active",
                "evidence_refs": ["session:1"],
                "metadata": {},
            }
            workflow_instinct = {
                "id": "tool-start-rg",
                "scope": "project",
                "project_id": "super-stack",
                "project_name": "super-stack",
                "trigger": "when using tool rg",
                "action": "Prefer using rg when this workflow pattern appears.",
                "confidence": 0.5,
                "domain": "workflow",
                "source": "codex-observation",
                "occurrence_count": 3,
                "negative_feedback_count": 0,
                "last_seen": "2026-04-01T10:00:00Z",
                "status": "active",
                "evidence_refs": ["session:2"],
                "metadata": {},
            }
            (project_dir / "verify-success-message.json").write_text(json.dumps(verify_instinct, ensure_ascii=False, indent=2), encoding="utf-8")
            (project_dir / "tool-start-rg.json").write_text(json.dumps(workflow_instinct, ensure_ascii=False, indent=2), encoding="utf-8")

            result = subprocess.run(
                [
                    sys.executable,
                    str(SURFACE_SCRIPT),
                    "--projects-root",
                    str(tmp_path / "projects"),
                    "--project-id",
                    "super-stack",
                    "--stage",
                    "verify",
                    "--signal",
                    "real webpage",
                    "--signal",
                    "network evidence",
                    "--top-k",
                    "2",
                    "--output",
                    str(output_path),
                ],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            payload = json.loads(output_path.read_text(encoding="utf-8"))
            surfaced = payload["surfaced"]
            self.assertEqual(len(surfaced), 2)
            self.assertEqual(surfaced[0]["id"], "verify-success-message")
            self.assertGreater(surfaced[0]["surface_score"], surfaced[1]["surface_score"])
            self.assertEqual(payload["stage"], "verify")
            self.assertEqual(payload["project_id"], "super-stack")

    def test_surface_penalizes_negative_feedback(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            project_dir = tmp_path / "projects" / "super-stack" / "instincts" / "active"
            output_path = tmp_path / "surface.json"
            project_dir.mkdir(parents=True)

            preferred = {
                "id": "tool-start-rg",
                "scope": "project",
                "project_id": "super-stack",
                "project_name": "super-stack",
                "trigger": "when using tool rg",
                "action": "Prefer using rg when this workflow pattern appears.",
                "confidence": 0.55,
                "domain": "workflow",
                "source": "codex-observation",
                "occurrence_count": 3,
                "negative_feedback_count": 0,
                "last_seen": "2026-04-01T10:00:00Z",
                "status": "active",
                "evidence_refs": ["session:1"],
                "metadata": {},
            }
            corrected = {
                "id": "tool-start-delegate-task",
                "scope": "project",
                "project_id": "super-stack",
                "project_name": "super-stack",
                "trigger": "when using tool delegate-task",
                "action": "Prefer using delegate-task when this workflow pattern appears.",
                "confidence": 0.45,
                "domain": "workflow",
                "source": "codex-observation",
                "occurrence_count": 3,
                "negative_feedback_count": 2,
                "last_seen": "2026-04-01T10:00:00Z",
                "status": "pending",
                "evidence_refs": ["session:2"],
                "metadata": {"demotion_reason": "Demoted by 2 user correction signal(s)."},
            }
            (project_dir / "tool-start-rg.json").write_text(json.dumps(preferred, ensure_ascii=False, indent=2), encoding="utf-8")
            (project_dir / "tool-start-delegate-task.json").write_text(json.dumps(corrected, ensure_ascii=False, indent=2), encoding="utf-8")

            result = subprocess.run(
                [
                    sys.executable,
                    str(SURFACE_SCRIPT),
                    "--projects-root",
                    str(tmp_path / "projects"),
                    "--project-id",
                    "super-stack",
                    "--stage",
                    "build",
                    "--signal",
                    "tool",
                    "--top-k",
                    "2",
                    "--include-pending",
                    "--output",
                    str(output_path),
                ],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            payload = json.loads(output_path.read_text(encoding="utf-8"))
            surfaced = surfaced = payload["surfaced"]
            self.assertEqual(surfaced[0]["id"], "tool-start-rg")
            self.assertEqual(surfaced[1]["id"], "tool-start-delegate-task")
            self.assertLess(surfaced[1]["surface_score"], surfaced[0]["surface_score"])

    def test_surface_ignores_pending_by_default(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            project_dir = tmp_path / "projects" / "super-stack" / "instincts"
            output_path = tmp_path / "surface.json"
            (project_dir / "active").mkdir(parents=True)
            (project_dir / "pending").mkdir(parents=True)

            pending = {
                "id": "verify-gap-message",
                "scope": "project",
                "project_id": "super-stack",
                "project_name": "super-stack",
                "trigger": "when verify repeatedly reveals the same gap",
                "action": "Address this recurring verification gap: missing DOM evidence",
                "confidence": 0.3,
                "domain": "verify",
                "source": "codex-observation",
                "occurrence_count": 2,
                "negative_feedback_count": 0,
                "last_seen": "2026-04-01T10:00:00Z",
                "status": "pending",
                "evidence_refs": ["session:1"],
                "metadata": {},
            }
            (project_dir / "pending" / "verify-gap-message.json").write_text(json.dumps(pending, ensure_ascii=False, indent=2), encoding="utf-8")

            result = subprocess.run(
                [
                    sys.executable,
                    str(SURFACE_SCRIPT),
                    "--projects-root",
                    str(tmp_path / "projects"),
                    "--project-id",
                    "super-stack",
                    "--stage",
                    "verify",
                    "--signal",
                    "gap",
                    "--output",
                    str(output_path),
                ],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            payload = json.loads(output_path.read_text(encoding="utf-8"))
            self.assertEqual(payload["surfaced"], [])


if __name__ == "__main__":
    unittest.main()
