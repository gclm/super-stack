# PDF Task Routing

Use this reference to choose the correct PDF workflow before installing dependencies or starting extraction.

## 1. Lightweight Text Extraction

Use this path when the task is mainly about content rather than appearance.

Typical examples:
- batch resume screening
- extracting names, dates, titles, or project descriptions
- keyword scanning or structured field extraction
- quick checks on document text

Preferred tools:
- `pypdf`
- `pdfplumber`

Dependency strategy:
- prefer the project's or user's default Python environment
- install the minimum Python package set needed for extraction
- avoid installing `poppler` unless rendering is actually required

Important limits:
- extracted text does not prove the page layout is correct
- image-based or scanned PDFs may need OCR or rendering fallback
- table structure may degrade during extraction

## 2. Full PDF Review Or Generation

Use this path when layout, visual fidelity, or PDF output quality matters.

Typical examples:
- checking margins, tables, fonts, headers, or page breaks
- reviewing scanned PDFs or image-heavy documents
- generating polished reports or exported documents
- validating that a generated PDF renders cleanly on real pages

Preferred tools:
- `pdftoppm` from `poppler`
- `reportlab` for generation
- `pypdf` or `pdfplumber` only as helpers, not as layout proof

Dependency strategy:
- install `poppler` only when page rendering is needed
- install generation libraries only when creating or editing PDFs
- if OCR is needed, say so explicitly instead of pretending extraction is complete

## 3. Environment Choice

Before creating a temporary environment, check:
- whether the repository already defines a Python environment
- whether the user has a default `conda` environment preference
- whether the task is one-off or likely to repeat

Recommended order:
1. project-declared environment
2. user default environment such as `conda`
3. temporary `venv` for isolated fallback work

## 4. Reporting Expectations

Always report:
- the chosen workflow path
- whether the answer relies on extracted text, rendered pages, or both
- which dependencies were missing or installed
- any quality limits, especially for scanned PDFs or OCR gaps
