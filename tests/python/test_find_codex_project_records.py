import json
import tempfile
import unittest
from pathlib import Path
import importlib.util
import sys

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT_PATH = REPO_ROOT / "skills" / "planning" / "codex-record-retrospective" / "scripts" / "find_codex_project_records.py"

spec = importlib.util.spec_from_file_location("find_codex_project_records", SCRIPT_PATH)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = module
spec.loader.exec_module(module)


class FindCodexProjectRecordsTests(unittest.TestCase):
    def test_prefers_exact_path_and_cwd_evidence_over_term_noise(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            codex_home = tmp_path / ".codex"
            sessions_dir = codex_home / "sessions" / "2026" / "03" / "31"
            sessions_dir.mkdir(parents=True)
            (codex_home / "archived_sessions").mkdir(parents=True)

            project_path = Path("/work/super-stack")
            exact_session = sessions_dir / "exact.jsonl"
            noisy_session = sessions_dir / "noise.jsonl"

            exact_rows = [
                {"type": "session_meta", "payload": {"id": "session-exact", "cwd": str(project_path)}},
                {"type": "response_item", "payload": {"type": "message", "role": "user", "content": [{"type": "input_text", "text": f"请看 {project_path}"}]}},
            ]
            noisy_rows = [
                {"type": "session_meta", "payload": {"id": "session-noise", "cwd": "/other/project"}},
            ]
            noisy_rows.extend(
                {
                    "type": "response_item",
                    "payload": {
                        "type": "message",
                        "role": "assistant",
                        "content": [{"type": "output_text", "text": "super-stack super-stack super-stack"}],
                    },
                }
                for _ in range(20)
            )

            for path, rows in ((exact_session, exact_rows), (noisy_session, noisy_rows)):
                with path.open("w", encoding="utf-8") as handle:
                    for row in rows:
                        handle.write(json.dumps(row, ensure_ascii=False) + "\n")

            report = module.build_report(project_path=project_path, alias_paths=[], codex_home=codex_home, max_samples=5)
            candidates = report["candidate_sessions"]
            self.assertEqual(candidates[0]["session_id"], "session-exact")
            self.assertGreater(candidates[0]["score"], candidates[1]["score"])
            self.assertEqual(candidates[0]["signals"]["session_meta_cwd"], 1)
            self.assertEqual(candidates[1]["signals"]["term_match"], 20)

    def test_deduplicates_sample_matches_with_same_signal_and_snippet(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            codex_home = tmp_path / ".codex"
            sessions_dir = codex_home / "sessions" / "2026" / "03" / "31"
            sessions_dir.mkdir(parents=True)
            (codex_home / "archived_sessions").mkdir(parents=True)

            project_path = Path("/work/super-stack")
            session_path = sessions_dir / "dupe.jsonl"
            rows = [
                {"type": "session_meta", "payload": {"id": "session-dupe", "cwd": "/elsewhere"}},
                {
                    "type": "response_item",
                    "payload": {
                        "type": "message",
                        "role": "assistant",
                        "content": [{"type": "output_text", "text": "super-stack mention"}],
                    },
                },
                {
                    "type": "response_item",
                    "payload": {
                        "type": "message",
                        "role": "assistant",
                        "content": [{"type": "output_text", "text": "super-stack mention"}],
                    },
                },
            ]
            with session_path.open("w", encoding="utf-8") as handle:
                for row in rows:
                    handle.write(json.dumps(row, ensure_ascii=False) + "\n")

            report = module.build_report(project_path=project_path, alias_paths=[], codex_home=codex_home, max_samples=5)
            self.assertEqual(len(report["sample_matches"]), 1)
            self.assertEqual(report["sample_matches"][0]["signal"], "term_match")


if __name__ == "__main__":
    unittest.main()
