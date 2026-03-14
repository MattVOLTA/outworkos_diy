# Tiptap JSON Reference for Substack

Substack's editor uses the Tiptap framework. Draft bodies are stored as stringified Tiptap JSON.

## Document Structure

```json
{
  "type": "doc",
  "attrs": { "schemaVersion": "v1" },
  "content": [ ...nodes ]
}
```

## Node Types

### Heading

```json
{
  "type": "heading",
  "attrs": { "level": 2 },
  "content": [{ "type": "text", "text": "Section Title" }]
}
```

Levels: 1-6. Substack typically uses H2 for sections, H3 for subsections.

### Paragraph

```json
{
  "type": "paragraph",
  "content": [{ "type": "text", "text": "Body text here." }]
}
```

Paragraphs can contain multiple text nodes with different marks.

### Blockquote

```json
{
  "type": "blockquote",
  "content": [
    {
      "type": "paragraph",
      "content": [{ "type": "text", "text": "Quoted text." }]
    }
  ]
}
```

Blockquotes wrap paragraph nodes. Each blockquote contains one or more paragraphs.

### Horizontal Rule

```json
{ "type": "horizontal_rule" }
```

No content or attrs. Used as section dividers.

### Bullet List

```json
{
  "type": "bullet_list",
  "content": [
    {
      "type": "list_item",
      "content": [
        {
          "type": "paragraph",
          "content": [{ "type": "text", "text": "Item one" }]
        }
      ]
    }
  ]
}
```

### Ordered List

```json
{
  "type": "ordered_list",
  "attrs": { "start": 1 },
  "content": [
    {
      "type": "list_item",
      "content": [
        {
          "type": "paragraph",
          "content": [{ "type": "text", "text": "First item" }]
        }
      ]
    }
  ]
}
```

### Code Block

```json
{
  "type": "code_block",
  "content": [{ "type": "text", "text": "const x = 1;" }]
}
```

## Text Marks

Marks are applied to text nodes to add formatting. Multiple marks can be combined on a single text node.

### Bold

```json
{ "type": "text", "text": "bold text", "marks": [{ "type": "bold" }] }
```

### Italic

```json
{ "type": "text", "text": "italic text", "marks": [{ "type": "italic" }] }
```

### Link

```json
{
  "type": "text",
  "text": "click here",
  "marks": [{ "type": "link", "attrs": { "href": "https://example.com" } }]
}
```

### Code (inline)

```json
{ "type": "text", "text": "inline code", "marks": [{ "type": "code" }] }
```

### Combined Marks

```json
{
  "type": "text",
  "text": "bold link",
  "marks": [
    { "type": "bold" },
    { "type": "link", "attrs": { "href": "https://example.com" } }
  ]
}
```

## Splitting Text Nodes by Mark

When a paragraph contains mixed formatting, split into separate text nodes:

**Markdown**: `This is **bold** and *italic* text.`

**Tiptap**:
```json
{
  "type": "paragraph",
  "content": [
    { "type": "text", "text": "This is " },
    { "type": "text", "text": "bold", "marks": [{ "type": "bold" }] },
    { "type": "text", "text": " and " },
    { "type": "text", "text": "italic", "marks": [{ "type": "italic" }] },
    { "type": "text", "text": " text." }
  ]
}
```

## Empty Paragraphs

For blank lines / spacing, use an empty paragraph:

```json
{ "type": "paragraph" }
```

Note: no `content` field needed for empty paragraphs.
