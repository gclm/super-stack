import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
RENDER_SCRIPT = REPO_ROOT / "scripts" / "browser" / "renderers" / "render_browser_report.py"


class BrowserReportRendererTests(unittest.TestCase):
    def test_renderer_outputs_adapter_and_content_sections(self):
        evidence = {
            "schemaVersion": "1.0",
            "adapter": "generic-page",
            "kind": "generic-page",
            "title": "Example Domain",
            "author": "Example Author",
            "summary": "Summary text",
            "body": "Body text",
            "commentTotal": "",
            "comments": [],
            "imageUrls": ["https://example.com/image.png"],
            "notes": ["generic-page extractor test note"],
        }

        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            evidence_path = tmp_path / "evidence.json"
            output_path = tmp_path / "report.md"
            evidence_path.write_text(json.dumps(evidence, ensure_ascii=False), encoding="utf-8")

            result = subprocess.run(
                [
                    sys.executable,
                    str(RENDER_SCRIPT),
                    str(evidence_path),
                    "https://example.com",
                    "https://example.com",
                    "Example Domain",
                    "super-stack-browser",
                    str(output_path),
                ],
                text=True,
                capture_output=True,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            output = output_path.read_text(encoding="utf-8")
            self.assertIn("adapter：`generic-page`", output)
            self.assertIn("## 正文内容", output)
            self.assertIn("https://example.com/image.png", output)


if __name__ == "__main__":
    unittest.main()
