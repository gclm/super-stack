import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
VALIDATE_SCRIPT = REPO_ROOT / "scripts" / "check" / "validate-skills.py"
LEDGER_SCRIPT = REPO_ROOT / "skills" / "planning" / "codex-record-retrospective" / "scripts" / "append_evolution_ledger.py"


class ValidateSkillsTests(unittest.TestCase):
    def test_validate_skills_passes_for_repo(self):
        result = subprocess.run(
            [sys.executable, str(VALIDATE_SCRIPT)],
            text=True,
            capture_output=True,
            cwd=REPO_ROOT,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("校验通过：0 个错误", result.stdout)

    def test_validate_skills_fails_for_missing_reference(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            skill_dir = root / "skills" / "core" / "fake-skill"
            skill_dir.mkdir(parents=True)
            (skill_dir / "SKILL.md").write_text(
                "---\nname: fake-skill\ndescription: Use when validating fake skill behavior.\n---\n\n- `references/missing.md`\n",
                encoding="utf-8",
            )
            result = subprocess.run(
                [sys.executable, str(VALIDATE_SCRIPT), "--path", "skills"],
                text=True,
                capture_output=True,
                cwd=root,
                check=False,
            )
            self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
            self.assertIn("引用路径不存在", result.stdout)

    def test_validate_skills_fails_for_runtime_preferred_source_path_in_reference(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            skill_dir = root / "skills" / "quality" / "fake-browse"
            refs_dir = skill_dir / "references"
            refs_dir.mkdir(parents=True)
            (skill_dir / "SKILL.md").write_text(
                "---\nname: fake-browse\ndescription: Use when validating path semantics.\n---\n\n- `references/session-guardrails.md`\n",
                encoding="utf-8",
            )
            (refs_dir / "session-guardrails.md").write_text(
                "- `scripts/check/check-browser-capability.sh`\n",
                encoding="utf-8",
            )
            config_dir = root / "config"
            config_dir.mkdir()
            (config_dir / "manifest.json").write_text(
                json.dumps(
                    {
                        "skill_validation": {
                            "ignore_warnings": [],
                            "path_semantics": [
                                {
                                    "repo_path": "scripts/check/check-browser-capability.sh",
                                    "runtime_path": "~/.super-stack/runtime/scripts/check/check-browser-capability.sh",
                                    "preferred_form": "runtime",
                                }
                            ],
                        }
                    },
                    ensure_ascii=False,
                ),
                encoding="utf-8",
            )

            result = subprocess.run(
                [sys.executable, str(VALIDATE_SCRIPT), "--path", "skills"],
                text=True,
                capture_output=True,
                cwd=root,
                check=False,
            )

            self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
            self.assertIn("路径语义不匹配", result.stdout)
            self.assertIn("~/.super-stack/runtime/scripts/check/check-browser-capability.sh", result.stdout)

    def test_validate_skills_fails_for_source_preferred_runtime_path(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            skill_dir = root / "skills" / "core" / "fake-maintenance"
            skill_dir.mkdir(parents=True)
            (skill_dir / "SKILL.md").write_text(
                "---\nname: fake-maintenance\ndescription: Use when validating source-only path semantics.\n---\n\n- `~/.super-stack/runtime/scripts/check/validate-skills.py`\n",
                encoding="utf-8",
            )
            config_dir = root / "config"
            config_dir.mkdir()
            (config_dir / "manifest.json").write_text(
                json.dumps(
                    {
                        "skill_validation": {
                            "ignore_warnings": [],
                            "path_semantics": [
                                {
                                    "repo_path": "scripts/check/validate-skills.py",
                                    "runtime_path": "~/.super-stack/runtime/scripts/check/validate-skills.py",
                                    "preferred_form": "source",
                                }
                            ],
                        }
                    },
                    ensure_ascii=False,
                ),
                encoding="utf-8",
            )

            result = subprocess.run(
                [sys.executable, str(VALIDATE_SCRIPT), "--path", "skills"],
                text=True,
                capture_output=True,
                cwd=root,
                check=False,
            )

            self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
            self.assertIn("路径语义不匹配", result.stdout)
            self.assertIn("scripts/check/validate-skills.py", result.stdout)


class EvolutionLedgerTests(unittest.TestCase):
    def test_append_ledger_from_recommendation_payload(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            input_path = tmp_path / "recommendation.json"
            ledger_path = tmp_path / "artifacts" / "evolution" / "evolution-ledger.jsonl"
            payload = {
                "project_path": "/tmp/demo-project",
                "source_retrospective": "/tmp/demo-retro.json",
                "recommendations": [
                    {
                        "lesson_id": "verify_overclaim",
                        "target_files": ["protocols/verify.md"],
                        "approval_level": "patch-proposed",
                    },
                    {
                        "lesson_id": "premature_completion",
                        "target_files": ["skills/quality/verify/SKILL.md"],
                        "approval_level": "record-only",
                    },
                ],
            }
            input_path.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")

            result = subprocess.run(
                [
                    sys.executable,
                    str(LEDGER_SCRIPT),
                    "--input-json",
                    str(input_path),
                    "--ledger-path",
                    str(ledger_path),
                ],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            lines = ledger_path.read_text(encoding="utf-8").strip().splitlines()
            self.assertEqual(len(lines), 2)
            first = json.loads(lines[0])
            second = json.loads(lines[1])
            self.assertEqual(first["lesson_id"], "verify_overclaim")
            self.assertEqual(first["recommendation_status"], "patch-proposed")
            self.assertEqual(second["lesson_id"], "premature_completion")


if __name__ == "__main__":
    unittest.main()
