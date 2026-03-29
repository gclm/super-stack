import json
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
INIT_PROJECT_SCRIPT = REPO_ROOT / "scripts" / "workflow" / "init-generated-project.sh"
INIT_SCRIPT = REPO_ROOT / "scripts" / "workflow" / "init-harness-task.sh"
CLASSIFY_SCRIPT = REPO_ROOT / "scripts" / "check" / "classify-change-risk.sh"
TEMPLATE_ROOT = REPO_ROOT / "templates" / "generated-project"


class HarnessScaffoldTests(unittest.TestCase):
    def test_generated_project_templates_exist(self):
        expected_files = [
            TEMPLATE_ROOT / "docs" / "index.md",
            TEMPLATE_ROOT / "docs" / "overview" / "project-overview.md",
            TEMPLATE_ROOT / "docs" / "overview" / "roadmap.md",
            TEMPLATE_ROOT / "docs" / "architecture" / "system-overview.md",
            TEMPLATE_ROOT / "docs" / "reference" / "codebase" / "README.md",
            TEMPLATE_ROOT / "docs" / "reference" / "validation" / "README.md",
            TEMPLATE_ROOT / "harness" / "state.md",
            TEMPLATE_ROOT / "harness" / "tasks" / "_task-template" / "brief.md",
            TEMPLATE_ROOT / "harness" / "tasks" / "_task-template" / "evidence-index.json",
        ]
        for path in expected_files:
            self.assertTrue(path.is_file(), f"缺少模板文件：{path}")

    def test_init_generated_project_creates_scaffold(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "target-project"
            result = subprocess.run(
                ["bash", str(INIT_PROJECT_SCRIPT), "--root", str(root)],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertTrue((root / "docs" / "index.md").is_file())
            self.assertTrue((root / "docs" / "overview" / "roadmap.md").is_file())
            self.assertTrue((root / "docs" / "reference" / "codebase" / "README.md").is_file())
            self.assertTrue((root / "docs" / "reference" / "validation" / "README.md").is_file())
            self.assertTrue((root / "harness" / "state.md").is_file())
            self.assertTrue((root / "harness" / "tasks" / "_task-template" / "brief.md").is_file())

    def test_init_generated_project_preserves_existing_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            index_path = root / "docs" / "index.md"
            index_path.parent.mkdir(parents=True, exist_ok=True)
            index_path.write_text("custom index\n", encoding="utf-8")

            result = subprocess.run(
                ["bash", str(INIT_PROJECT_SCRIPT), "--root", str(root)],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(index_path.read_text(encoding="utf-8"), "custom index\n")
            self.assertTrue((root / "harness" / "state.md").is_file())

    def test_init_harness_task_creates_scaffold(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            result = subprocess.run(
                ["bash", str(INIT_SCRIPT), "--root", str(root), "--task-id", "demo-task"],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

            harness_root = root / "harness"
            task_root = harness_root / "tasks" / "demo-task"
            self.assertTrue((harness_root / "state.md").is_file())
            self.assertTrue((task_root / "brief.md").is_file())
            self.assertTrue((task_root / "progress.md").is_file())
            self.assertTrue((task_root / "decisions.md").is_file())

            evidence = json.loads((task_root / "evidence-index.json").read_text(encoding="utf-8"))
            verdict = json.loads((task_root / "verdict.json").read_text(encoding="utf-8"))
            self.assertEqual(evidence["task_id"], "demo-task")
            self.assertEqual(verdict["task_id"], "demo-task")
            self.assertEqual(verdict["status"], "planned")
            self.assertIn("demo-task", (task_root / "brief.md").read_text(encoding="utf-8"))

    def test_init_harness_task_fails_when_task_exists(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            first = subprocess.run(
                ["bash", str(INIT_SCRIPT), "--root", str(root), "--task-id", "dup-task"],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )
            self.assertEqual(first.returncode, 0, first.stdout + first.stderr)

            second = subprocess.run(
                ["bash", str(INIT_SCRIPT), "--root", str(root), "--task-id", "dup-task"],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )
            self.assertNotEqual(second.returncode, 0)
            self.assertIn("任务目录已存在", second.stderr)

    def test_classify_change_risk_uses_expected_levels(self):
        l1 = subprocess.run(
            [
                "bash",
                str(CLASSIFY_SCRIPT),
                "--format",
                "level",
                "docs/architecture/decisions/harness-skill-design.md",
                "skills/harness/task-harness/references/task-artifact-contract.md",
            ],
            text=True,
            capture_output=True,
            cwd=REPO_ROOT,
            check=False,
        )
        self.assertEqual(l1.returncode, 0, l1.stdout + l1.stderr)
        self.assertEqual(l1.stdout.strip(), "L1")

        l2 = subprocess.run(
            [
                "bash",
                str(CLASSIFY_SCRIPT),
                "--format",
                "level",
                "skills/harness/task-harness/SKILL.md",
                "templates/generated-project/docs/index.md",
            ],
            text=True,
            capture_output=True,
            cwd=REPO_ROOT,
            check=False,
        )
        self.assertEqual(l2.returncode, 0, l2.stdout + l2.stderr)
        self.assertEqual(l2.stdout.strip(), "L2")

        l3 = subprocess.run(
            [
                "bash",
                str(CLASSIFY_SCRIPT),
                "--format",
                "level",
                "scripts/install/install.sh",
                "protocols/workflow-governance.md",
            ],
            text=True,
            capture_output=True,
            cwd=REPO_ROOT,
            check=False,
        )
        self.assertEqual(l3.returncode, 0, l3.stdout + l3.stderr)
        self.assertEqual(l3.stdout.strip(), "L3")


if __name__ == "__main__":
    unittest.main()
