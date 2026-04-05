import json
import sqlite3
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
BUILD_SCRIPT = REPO_ROOT / "skills" / "planning" / "codex-record-retrospective" / "scripts" / "build_observations.py"


class BuildObservationsTests(unittest.TestCase):
    def test_build_observations_from_session_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            session_file = tmp_path / "session.jsonl"
            output_path = tmp_path / "observations.jsonl"
            project_path = Path("/work/super-stack")

            rows = [
                {
                    "type": "session_meta",
                    "timestamp": "2026-04-01T10:00:00Z",
                    "payload": {"id": "session-1", "cwd": str(project_path)},
                },
                {
                    "type": "response_item",
                    "timestamp": "2026-04-01T10:00:05Z",
                    "payload": {
                        "type": "message",
                        "role": "user",
                        "content": [{"type": "input_text", "text": "帮我验证真实网页内容"}],
                    },
                },
                {
                    "type": "response_item",
                    "timestamp": "2026-04-01T10:00:10Z",
                    "payload": {
                        "type": "function_call",
                        "name": "mcp__chrome-devtools-mcp__take_snapshot",
                        "arguments": "{}",
                    },
                },
                {
                    "type": "response_item",
                    "timestamp": "2026-04-01T10:00:11Z",
                    "payload": {
                        "type": "function_call_output",
                        "call_id": "call-1",
                        "output": "snapshot ok",
                    },
                },
            ]
            with session_file.open("w", encoding="utf-8") as handle:
                for row in rows:
                    handle.write(json.dumps(row, ensure_ascii=False) + "\n")

            result = subprocess.run(
                [
                    sys.executable,
                    str(BUILD_SCRIPT),
                    "--session-file",
                    str(session_file),
                    "--project-path",
                    str(project_path),
                    "--output",
                    str(output_path),
                ],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            lines = output_path.read_text(encoding="utf-8").strip().splitlines()
            self.assertGreaterEqual(len(lines), 3)
            first = json.loads(lines[0])
            self.assertEqual(first["project_name"], "super-stack")
            self.assertEqual(first["project_id"], "super-stack")
            self.assertEqual(first["session_id"], "session-1")
            self.assertEqual(first["slice_id"], "slice-001")
            self.assertEqual(first["event_type"], "message")
            self.assertTrue(first["evidence_refs"])
            self.assertIn("schema_version", first)

    def test_build_observations_deduplicates_same_session_events(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            session_file = tmp_path / "session.jsonl"
            output_path = tmp_path / "observations.jsonl"
            project_path = Path("/work/super-stack")

            rows = [
                {
                    "type": "session_meta",
                    "timestamp": "2026-04-01T10:00:00Z",
                    "payload": {"id": "session-2", "cwd": str(project_path)},
                },
                {
                    "type": "response_item",
                    "timestamp": "2026-04-01T10:00:05Z",
                    "payload": {
                        "type": "message",
                        "role": "user",
                        "content": [{"type": "input_text", "text": "重复文本"}],
                    },
                },
                {
                    "type": "response_item",
                    "timestamp": "2026-04-01T10:00:05Z",
                    "payload": {
                        "type": "message",
                        "role": "user",
                        "content": [{"type": "input_text", "text": "重复文本"}],
                    },
                },
            ]
            with session_file.open("w", encoding="utf-8") as handle:
                for row in rows:
                    handle.write(json.dumps(row, ensure_ascii=False) + "\n")

            result = subprocess.run(
                [
                    sys.executable,
                    str(BUILD_SCRIPT),
                    "--session-file",
                    str(session_file),
                    "--project-path",
                    str(project_path),
                    "--output",
                    str(output_path),
                ],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            lines = output_path.read_text(encoding="utf-8").strip().splitlines()
            self.assertEqual(len(lines), 1)

    def test_build_observations_uses_slice_ids_for_multi_task_session(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            session_file = tmp_path / "session.jsonl"
            output_path = tmp_path / "observations.jsonl"
            project_path = Path("/work/super-stack")

            rows = [
                {
                    "type": "session_meta",
                    "timestamp": "2026-04-01T10:00:00Z",
                    "payload": {"id": "session-3", "cwd": str(project_path)},
                },
                {
                    "type": "response_item",
                    "timestamp": "2026-04-01T10:00:05Z",
                    "payload": {
                        "type": "message",
                        "role": "user",
                        "content": [{"type": "input_text", "text": "先帮我补 observation schema"}],
                    },
                },
                {
                    "type": "response_item",
                    "timestamp": "2026-04-01T10:01:00Z",
                    "payload": {
                        "type": "message",
                        "role": "assistant",
                        "content": [{"type": "output_text", "text": "我先分析下结构。"}],
                    },
                },
                {
                    "type": "response_item",
                    "timestamp": "2026-04-01T10:45:00Z",
                    "payload": {
                        "type": "message",
                        "role": "user",
                        "content": [{"type": "input_text", "text": "另外再帮我加 index.db"}],
                    },
                },
            ]
            with session_file.open("w", encoding="utf-8") as handle:
                for row in rows:
                    handle.write(json.dumps(row, ensure_ascii=False) + "\n")

            result = subprocess.run(
                [
                    sys.executable,
                    str(BUILD_SCRIPT),
                    "--session-file",
                    str(session_file),
                    "--project-path",
                    str(project_path),
                    "--output",
                    str(output_path),
                ],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            rows = [json.loads(line) for line in output_path.read_text(encoding="utf-8").splitlines() if line.strip()]
            slice_ids = {row["slice_id"] for row in rows if row["event_type"] == "message"}
            self.assertEqual(slice_ids, {"slice-001", "slice-002"})

    def test_build_observations_refreshes_minimal_index_db(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            session_file = tmp_path / "session.jsonl"
            output_path = tmp_path / "observations.jsonl"
            index_db = tmp_path / "index.db"
            project_path = Path("/work/super-stack")

            rows = [
                {
                    "type": "session_meta",
                    "timestamp": "2026-04-01T10:00:00Z",
                    "payload": {"id": "session-4", "cwd": str(project_path)},
                },
                {
                    "type": "response_item",
                    "timestamp": "2026-04-01T10:00:05Z",
                    "payload": {
                        "type": "message",
                        "role": "user",
                        "content": [{"type": "input_text", "text": "帮我建立 observation"}],
                    },
                },
            ]
            with session_file.open("w", encoding="utf-8") as handle:
                for row in rows:
                    handle.write(json.dumps(row, ensure_ascii=False) + "\n")

            result = subprocess.run(
                [
                    sys.executable,
                    str(BUILD_SCRIPT),
                    "--session-file",
                    str(session_file),
                    "--project-path",
                    str(project_path),
                    "--output",
                    str(output_path),
                    "--index-db",
                    str(index_db),
                ],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertTrue(index_db.exists())
            conn = sqlite3.connect(index_db)
            try:
                row_count = conn.execute("select count(*) from observations").fetchone()[0]
            finally:
                conn.close()
            self.assertEqual(row_count, 1)

    def test_build_observations_classifies_verify_and_correction_signals(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            session_file = tmp_path / "session.jsonl"
            output_path = tmp_path / "observations.jsonl"
            project_path = Path("/work/super-stack")

            rows = [
                {
                    "type": "session_meta",
                    "timestamp": "2026-04-01T10:00:00Z",
                    "payload": {"id": "session-5", "cwd": str(project_path)},
                },
                {
                    "type": "response_item",
                    "timestamp": "2026-04-01T10:00:05Z",
                    "payload": {
                        "type": "message",
                        "role": "user",
                        "content": [{"type": "input_text", "text": "不要先问我要不要委托"}],
                    },
                },
                {
                    "type": "response_item",
                    "timestamp": "2026-04-01T10:00:10Z",
                    "payload": {
                        "type": "message",
                        "role": "assistant",
                        "content": [{"type": "output_text", "text": "已验证真实网页，页面显示 Example Domain，并看到 network 200。"}],
                    },
                },
                {
                    "type": "response_item",
                    "timestamp": "2026-04-01T10:00:15Z",
                    "payload": {
                        "type": "message",
                        "role": "assistant",
                        "content": [{"type": "output_text", "text": "未验证真实网页，因为还没有 DOM 或 network 证据。"}],
                    },
                },
            ]
            with session_file.open("w", encoding="utf-8") as handle:
                for row in rows:
                    handle.write(json.dumps(row, ensure_ascii=False) + "\n")

            result = subprocess.run(
                [
                    sys.executable,
                    str(BUILD_SCRIPT),
                    "--session-file",
                    str(session_file),
                    "--project-path",
                    str(project_path),
                    "--output",
                    str(output_path),
                ],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            rows = [json.loads(line) for line in output_path.read_text(encoding="utf-8").splitlines() if line.strip()]
            by_event = {row["event_type"]: row for row in rows}
            self.assertIn("user_correction", by_event)
            self.assertIn("verify_success", by_event)
            self.assertIn("verify_gap", by_event)
            self.assertEqual(by_event["user_correction"]["metadata"]["role"], "user")
            self.assertEqual(by_event["verify_success"]["stage"], "verify")
            self.assertEqual(by_event["verify_gap"]["stage"], "verify")

    def test_build_observations_classifies_stage_transition_and_backtrack(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            session_file = tmp_path / "session.jsonl"
            output_path = tmp_path / "observations.jsonl"
            project_path = Path("/work/super-stack")

            rows = [
                {
                    "type": "session_meta",
                    "timestamp": "2026-04-01T10:00:00Z",
                    "payload": {"id": "session-6", "cwd": str(project_path)},
                },
                {
                    "type": "response_item",
                    "timestamp": "2026-04-01T10:00:05Z",
                    "payload": {
                        "type": "message",
                        "role": "assistant",
                        "content": [{"type": "output_text", "text": "这轮按 verify 继续，我先收集真实页面证据。"}],
                    },
                },
                {
                    "type": "response_item",
                    "timestamp": "2026-04-01T10:00:10Z",
                    "payload": {
                        "type": "message",
                        "role": "assistant",
                        "content": [{"type": "output_text", "text": "从 build 回到 verify，先确认结果有没有真实证据。"}],
                    },
                },
            ]
            with session_file.open("w", encoding="utf-8") as handle:
                for row in rows:
                    handle.write(json.dumps(row, ensure_ascii=False) + "\n")

            result = subprocess.run(
                [
                    sys.executable,
                    str(BUILD_SCRIPT),
                    "--session-file",
                    str(session_file),
                    "--project-path",
                    str(project_path),
                    "--output",
                    str(output_path),
                ],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            rows = [json.loads(line) for line in output_path.read_text(encoding="utf-8").splitlines() if line.strip()]
            by_event = {row["event_type"]: row for row in rows}
            self.assertIn("stage_transition", by_event)
            self.assertIn("backtrack", by_event)
            self.assertEqual(by_event["stage_transition"]["stage"], "verify")
            self.assertEqual(by_event["backtrack"]["stage"], "verify")
            self.assertEqual(by_event["backtrack"]["metadata"]["from_stage"], "build")

    def test_build_observations_links_user_correction_to_recent_tool_in_same_slice(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            session_file = tmp_path / "session.jsonl"
            output_path = tmp_path / "observations.jsonl"
            project_path = Path("/work/super-stack")

            rows = [
                {
                    "type": "session_meta",
                    "timestamp": "2026-04-01T10:00:00Z",
                    "payload": {"id": "session-7", "cwd": str(project_path)},
                },
                {
                    "type": "response_item",
                    "timestamp": "2026-04-01T10:00:05Z",
                    "payload": {
                        "type": "function_call",
                        "name": "delegate-task",
                        "arguments": '{"task":"open browser verification"}',
                    },
                },
                {
                    "type": "response_item",
                    "timestamp": "2026-04-01T10:00:07Z",
                    "payload": {
                        "type": "message",
                        "role": "user",
                        "content": [{"type": "input_text", "text": "不要先问我要不要委托"}],
                    },
                },
            ]
            with session_file.open("w", encoding="utf-8") as handle:
                for row in rows:
                    handle.write(json.dumps(row, ensure_ascii=False) + "\n")

            result = subprocess.run(
                [
                    sys.executable,
                    str(BUILD_SCRIPT),
                    "--session-file",
                    str(session_file),
                    "--project-path",
                    str(project_path),
                    "--output",
                    str(output_path),
                ],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            rows = [json.loads(line) for line in output_path.read_text(encoding="utf-8").splitlines() if line.strip()]
            correction = next(row for row in rows if row["event_type"] == "user_correction")
            self.assertEqual(correction["metadata"]["corrects_event_type"], "tool_start")
            self.assertEqual(correction["metadata"]["corrects_tool"], "delegate-task")

    def test_build_observations_does_not_guess_correction_target_without_actionable_prior_event(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            session_file = tmp_path / "session.jsonl"
            output_path = tmp_path / "observations.jsonl"
            project_path = Path("/work/super-stack")

            rows = [
                {
                    "type": "session_meta",
                    "timestamp": "2026-04-01T10:00:00Z",
                    "payload": {"id": "session-8", "cwd": str(project_path)},
                },
                {
                    "type": "response_item",
                    "timestamp": "2026-04-01T10:00:05Z",
                    "payload": {
                        "type": "message",
                        "role": "assistant",
                        "content": [{"type": "output_text", "text": "我先分析一下情况。"}],
                    },
                },
                {
                    "type": "response_item",
                    "timestamp": "2026-04-01T10:00:07Z",
                    "payload": {
                        "type": "message",
                        "role": "user",
                        "content": [{"type": "input_text", "text": "不要先问我要不要委托"}],
                    },
                },
            ]
            with session_file.open("w", encoding="utf-8") as handle:
                for row in rows:
                    handle.write(json.dumps(row, ensure_ascii=False) + "\n")

            result = subprocess.run(
                [
                    sys.executable,
                    str(BUILD_SCRIPT),
                    "--session-file",
                    str(session_file),
                    "--project-path",
                    str(project_path),
                    "--output",
                    str(output_path),
                ],
                text=True,
                capture_output=True,
                cwd=REPO_ROOT,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            rows = [json.loads(line) for line in output_path.read_text(encoding="utf-8").splitlines() if line.strip()]
            correction = next(row for row in rows if row["event_type"] == "user_correction")
            self.assertNotIn("corrects_event_type", correction["metadata"])
            self.assertNotIn("corrects_tool", correction["metadata"])


if __name__ == "__main__":
    unittest.main()
