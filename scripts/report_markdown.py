"""Escaped Markdown tables and JSON evidence for report output."""

import json


def cell(value):
    if value is None:
        return "Not available"
    return (str(value).replace("&", "&amp;").replace("<", "&lt;")
            .replace(">", "&gt;").replace("|", "&#124;")
            .replace("[", "&#91;").replace("]", "&#93;")
            .replace("`", "&#96;").replace("\r", " ").replace("\n", " "))


def table(headers, rows):
    lines = ["| " + " | ".join(headers) + " |",
             "| " + " | ".join("---" for _ in headers) + " |"]
    lines.extend("| " + " | ".join(cell(v) for v in row) + " |" for row in rows)
    return "\n".join(lines) + "\n"


def collection(value):
    if value is None:
        return []
    return [value] if isinstance(value, dict) else value


def evidence(value):
    # A long fence prevents embedded Markdown in directory strings escaping the block.
    text = json.dumps(value, indent=2, ensure_ascii=False)
    length = max(3, max((len(part) for part in text.split("\n")
                         if part and set(part) == {"`"}), default=0) + 1)
    # Directory strings can contain backticks inside JSON string values.
    while "`" * length in text:
        length += 1
    fence = "`" * length
    return f"\n{fence}json\n{text}\n{fence}\n"


