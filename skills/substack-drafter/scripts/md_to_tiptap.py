#!/usr/bin/env python3
"""
Convert a Markdown or plain text file to Substack-compatible Tiptap JSON.

Usage:
    python3 md_to_tiptap.py <input_file> <output_file>

Input: .md or .txt file
Output: JSON file containing Tiptap document structure

Supported markdown elements:
    - Headings (# through ######)
    - Paragraphs
    - Blockquotes (> ...)
    - Horizontal rules (--- or ***)
    - Bold (**text** or __text__)
    - Italic (*text* or _text_)
    - Links ([text](url))
    - Inline code (`code`)
    - Bullet lists (- or * items)
    - Ordered lists (1. items)
    - Code blocks (``` fenced)
"""

import json
import re
import sys


def parse_inline_marks(text):
    """Parse inline markdown (bold, italic, links, code) into Tiptap text nodes."""
    nodes = []
    if not text:
        return nodes

    # Pattern matches: links, bold, italic, inline code
    # Order matters: bold before italic to handle ** vs *
    pattern = re.compile(
        r'(\[([^\]]+)\]\(([^)]+)\))'   # [text](url) - links
        r'|(`([^`]+)`)'                 # `code` - inline code
        r'|(\*\*([^*]+)\*\*)'           # **bold**
        r'|(__([^_]+)__)'               # __bold__
        r'|(\*([^*]+)\*)'              # *italic*
        r'|(_([^_\s][^_]*)_)'           # _italic_ (not starting with space)
    )

    pos = 0
    for match in pattern.finditer(text):
        start = match.start()

        # Add plain text before this match
        if start > pos:
            plain = text[pos:start]
            if plain:
                nodes.append({"type": "text", "text": plain})

        if match.group(2) is not None:
            # Link: [text](url)
            link_text = match.group(2)
            link_url = match.group(3)
            node = {
                "type": "text",
                "text": link_text,
                "marks": [{"type": "link", "attrs": {"href": link_url}}]
            }
            nodes.append(node)
        elif match.group(5) is not None:
            # Inline code: `code`
            nodes.append({
                "type": "text",
                "text": match.group(5),
                "marks": [{"type": "code"}]
            })
        elif match.group(7) is not None:
            # Bold: **text**
            nodes.append({
                "type": "text",
                "text": match.group(7),
                "marks": [{"type": "bold"}]
            })
        elif match.group(9) is not None:
            # Bold: __text__
            nodes.append({
                "type": "text",
                "text": match.group(9),
                "marks": [{"type": "bold"}]
            })
        elif match.group(11) is not None:
            # Italic: *text*
            nodes.append({
                "type": "text",
                "text": match.group(11),
                "marks": [{"type": "italic"}]
            })
        elif match.group(13) is not None:
            # Italic: _text_
            nodes.append({
                "type": "text",
                "text": match.group(13),
                "marks": [{"type": "italic"}]
            })

        pos = match.end()

    # Add remaining plain text
    if pos < len(text):
        remaining = text[pos:]
        if remaining:
            nodes.append({"type": "text", "text": remaining})

    # If no marks were found, return the whole text as one node
    if not nodes and text:
        nodes.append({"type": "text", "text": text})

    return nodes


def make_paragraph(text):
    """Create a Tiptap paragraph node from markdown text."""
    content = parse_inline_marks(text)
    if not content:
        return {"type": "paragraph"}
    return {"type": "paragraph", "content": content}


def make_heading(text, level):
    """Create a Tiptap heading node."""
    content = parse_inline_marks(text)
    node = {"type": "heading", "attrs": {"level": level}}
    if content:
        node["content"] = content
    return node


def make_blockquote(text):
    """Create a Tiptap blockquote node wrapping a paragraph."""
    return {
        "type": "blockquote",
        "content": [make_paragraph(text)]
    }


def make_horizontal_rule():
    """Create a Tiptap horizontal rule node."""
    return {"type": "horizontal_rule"}


def make_code_block(lines):
    """Create a Tiptap code block node."""
    code_text = "\n".join(lines)
    node = {"type": "code_block"}
    if code_text:
        node["content"] = [{"type": "text", "text": code_text}]
    return node


def make_list_item(text):
    """Create a Tiptap list item node."""
    return {
        "type": "list_item",
        "content": [make_paragraph(text)]
    }


def convert_markdown_to_tiptap(markdown_text):
    """
    Convert markdown text to a Tiptap JSON document.

    Returns a dict representing the Tiptap document structure.
    """
    lines = markdown_text.split('\n')
    nodes = []
    i = 0

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # Empty line - skip (paragraph breaks are implicit)
        if not stripped:
            i += 1
            continue

        # Fenced code block
        if stripped.startswith('```'):
            code_lines = []
            i += 1
            while i < len(lines) and not lines[i].strip().startswith('```'):
                code_lines.append(lines[i])
                i += 1
            nodes.append(make_code_block(code_lines))
            i += 1  # skip closing ```
            continue

        # Horizontal rule: --- or *** or ___ (3+ chars)
        if re.match(r'^(\-{3,}|\*{3,}|_{3,})$', stripped):
            nodes.append(make_horizontal_rule())
            i += 1
            continue

        # Heading: # through ######
        heading_match = re.match(r'^(#{1,6})\s+(.+)$', stripped)
        if heading_match:
            level = len(heading_match.group(1))
            text = heading_match.group(2).strip()
            nodes.append(make_heading(text, level))
            i += 1
            continue

        # Blockquote: > text
        if stripped.startswith('>'):
            # Collect consecutive blockquote lines
            bq_lines = []
            while i < len(lines) and lines[i].strip().startswith('>'):
                bq_text = re.sub(r'^>\s?', '', lines[i].strip())
                bq_lines.append(bq_text)
                i += 1
            # Each blockquote line becomes a separate blockquote node
            # (matching how Substack renders them)
            full_text = ' '.join(bq_lines)
            nodes.append(make_blockquote(full_text))
            continue

        # Unordered list: - item or * item (at start of line)
        ul_match = re.match(r'^[\-\*]\s+(.+)$', stripped)
        if ul_match:
            items = []
            while i < len(lines):
                item_match = re.match(r'^[\-\*]\s+(.+)$', lines[i].strip())
                if not item_match:
                    break
                items.append(make_list_item(item_match.group(1)))
                i += 1
            nodes.append({
                "type": "bullet_list",
                "content": items
            })
            continue

        # Ordered list: 1. item
        ol_match = re.match(r'^(\d+)\.\s+(.+)$', stripped)
        if ol_match:
            items = []
            start_num = int(ol_match.group(1))
            while i < len(lines):
                item_match = re.match(r'^\d+\.\s+(.+)$', lines[i].strip())
                if not item_match:
                    break
                items.append(make_list_item(item_match.group(1)))
                i += 1
            nodes.append({
                "type": "ordered_list",
                "attrs": {"start": start_num},
                "content": items
            })
            continue

        # Regular paragraph - collect consecutive non-empty, non-special lines
        para_lines = []
        while i < len(lines):
            l = lines[i].strip()
            if not l:
                break
            # Stop if next line is a special element
            if (l.startswith('#') or l.startswith('>') or l.startswith('```')
                    or re.match(r'^(\-{3,}|\*{3,}|_{3,})$', l)
                    or re.match(r'^[\-\*]\s+', l)
                    or re.match(r'^\d+\.\s+', l)):
                break
            para_lines.append(l)
            i += 1

        if para_lines:
            full_text = ' '.join(para_lines)
            nodes.append(make_paragraph(full_text))

    return {
        "type": "doc",
        "attrs": {"schemaVersion": "v1"},
        "content": nodes
    }


def main():
    if len(sys.argv) < 3:
        print("Usage: python3 md_to_tiptap.py <input_file> <output_file>")
        print("  input_file:  Path to .md or .txt file")
        print("  output_file: Path for output .json file")
        sys.exit(1)

    input_path = sys.argv[1]
    output_path = sys.argv[2]

    try:
        with open(input_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: Input file not found: {input_path}")
        sys.exit(1)
    except Exception as e:
        print(f"Error reading input file: {e}")
        sys.exit(1)

    tiptap_doc = convert_markdown_to_tiptap(content)
    node_count = len(tiptap_doc.get('content', []))

    try:
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(tiptap_doc, f, ensure_ascii=False)
    except Exception as e:
        print(f"Error writing output file: {e}")
        sys.exit(1)

    output_size = len(json.dumps(tiptap_doc, ensure_ascii=False))
    print(f"Converted: {node_count} nodes, {output_size} chars")
    print(f"Output: {output_path}")


if __name__ == '__main__':
    main()
