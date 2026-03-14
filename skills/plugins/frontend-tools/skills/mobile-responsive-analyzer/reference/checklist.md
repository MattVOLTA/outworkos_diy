# Analysis Checklist Template

This checklist is used when analyzing each file. Check each category and document findings in the appropriate severity level.

## File Analysis Template

```markdown
## [File Path]

### Critical Issues
[Issues that block mobile usability]

- ❌ **[Category]**: [Description]
  - Line [N]: `[Code snippet]` → `[Fix]`
  - Explanation: [Why this is critical]

### High Priority
[Issues that degrade mobile experience]

- ⚠️ **[Category]**: [Description]
  - Line [N]: `[Code snippet]` → `[Fix]`
  - Explanation: [Why this needs fixing]

### Enhancements
[Nice-to-have improvements]

- 💡 **[Category]**: [Description]
  - Line [N]: `[Code snippet]` → `[Fix]`
  - Explanation: [Why this would help]

### ✅ Passing
[What the file does well]

- [Category]: [What's working correctly]

---
```

## Categories to Check

### 1. Touch Targets
**What to check:**
- All interactive elements (buttons, links, inputs, menu items)
- Icon-only buttons
- Close buttons on modals/dialogs
- Table action buttons
- Pagination controls
- Form controls (checkboxes, radio, toggles)

**How to measure:**
- Look for explicit height/width classes: `h-9`, `h-10`, `h-11`, etc.
- Check computed sizes: `h-9` = 36px, `h-11` = 44px, `h-12` = 48px
- Consider padding: `p-2` adds to touch area

**Severity:**
- **Critical**: < 36×36px (144px²)
- **High**: 36-43px (below 44px minimum)
- **Pass**: ≥ 44px

**Examples:**

❌ **Critical**:
```tsx
<Button size="sm" className="h-9 w-9"> {/* 36×36px */}
```

⚠️ **High**:
```tsx
<Button className="h-10 w-10"> {/* 40×40px - close but not enough */}
```

✅ **Pass**:
```tsx
<Button className="h-11 w-11"> {/* 44×44px */}
<Button className="min-h-11 px-4"> {/* Height OK, width flexible */}
```

---

### 2. Typography
**What to check:**
- Base font sizes (look for `text-xs`, `text-sm`, `text-base`)
- Heading sizes on mobile
- Line height declarations
- Fixed vs. responsive sizing

**How to measure:**
- `text-xs` = 12px (❌ fail)
- `text-sm` = 14px (⚠️ high - acceptable for secondary text only)
- `text-base` = 16px (✅ pass)
- Line height should be ≥ 1.5× for body text

**Severity:**
- **Critical**: Body text < 14px
- **High**: Body text 14-15px, missing line heights
- **Enhancement**: Could use fluid typography (`clamp()`)

**Examples:**

❌ **Critical**:
```tsx
<p className="text-xs"> {/* 12px - too small */}
```

⚠️ **High**:
```tsx
<p className="text-sm leading-tight"> {/* 14px + tight leading */}
```

💡 **Enhancement**:
```tsx
<h1 className="text-4xl"> {/* Could use clamp() */}
→ <h1 className="text-[clamp(2rem,5vw,4rem)]">
```

---

### 3. Layout & Responsiveness
**What to check:**
- Mobile-first vs. desktop-first approach
- Breakpoint usage
- Hide/show patterns
- Flex/grid responsive behavior
- Container widths

**How to identify:**
- **Good**: Base styles + `sm:`, `md:`, `lg:` prefixes
- **Bad**: Using `max-*` breakpoints, backwards sizing

**Severity:**
- **Critical**: Desktop-first approach (backwards breakpoints)
- **High**: No mobile layout for complex components
- **Enhancement**: Could use container queries

**Examples:**

❌ **Critical**:
```tsx
<div className="text-xl md:text-base"> {/* Backwards! */}
<div className="hidden max-md:block"> {/* Desktop-first! */}
```

⚠️ **High**:
```tsx
<table> {/* No mobile alternative */}
  {/* Complex table with many columns */}
</table>
```

✅ **Pass**:
```tsx
<div className="text-base md:text-lg lg:text-xl"> {/* Mobile-first */}
<div className="flex flex-col md:flex-row"> {/* Stack → row */}
```

---

### 4. Images
**What to check:**
- Using `<img>` vs. `<Image>` from next/image
- Presence of `sizes` attribute
- `width` and `height` or `fill` prop
- `priority` for above-fold images

**Severity:**
- **High**: Using `<img>` tag
- **High**: Missing `sizes` attribute on `<Image>`
- **Enhancement**: Missing `priority` on hero images

**Examples:**

⚠️ **High**:
```tsx
<img src="/photo.jpg" alt="Photo" /> {/* Not using next/image */}
```

⚠️ **High**:
```tsx
<Image
  src="/photo.jpg"
  alt="Photo"
  width={800}
  height={600}
  // Missing sizes attribute
/>
```

💡 **Enhancement**:
```tsx
<Image
  src="/hero.jpg"
  alt="Hero"
  width={1920}
  height={1080}
  sizes="100vw"
  // Could add priority for above-fold
/>
```

✅ **Pass**:
```tsx
<Image
  src="/photo.jpg"
  alt="Photo"
  width={800}
  height={600}
  sizes="(max-width: 768px) 100vw, 50vw"
  priority // Above fold
/>
```

---

### 5. Navigation
**What to check:**
- Mobile menu pattern (hamburger → drawer/sheet)
- Menu item touch target sizes
- Desktop vs. mobile navigation
- Touch-friendly spacing

**Severity:**
- **Critical**: Menu items < 44px height
- **High**: No mobile navigation pattern
- **Enhancement**: Actions not in thumb-reach zones

**Examples:**

❌ **Critical**:
```tsx
<nav>
  <a href="/" className="py-1"> {/* Too small */}
    Home
  </a>
</nav>
```

⚠️ **High**:
```tsx
{/* Only desktop nav, no mobile alternative */}
<nav className="flex gap-6">
  <Link href="/">Home</Link>
</nav>
```

✅ **Pass**:
```tsx
{/* Mobile sheet + desktop nav */}
<Sheet>
  <SheetTrigger className="md:hidden h-11 w-11">
    <Menu />
  </SheetTrigger>
  <SheetContent>
    <nav className="flex flex-col">
      <a href="/" className="min-h-11 flex items-center px-4">
        Home
      </a>
    </nav>
  </SheetContent>
</Sheet>

<nav className="hidden md:flex gap-6">
  <Link href="/" className="min-h-11 flex items-center">Home</Link>
</nav>
```

---

### 6. Component Patterns
**What to check:**
- Radix UI responsive props usage
- shadcn Dialog → Drawer pattern on mobile
- Form layouts (stacking on mobile)
- Data table mobile alternatives

**Severity:**
- **High**: Radix components without responsive props
- **High**: Tables without mobile alternative
- **Enhancement**: Could use Dialog→Drawer pattern

**Examples:**

⚠️ **High**:
```tsx
{/* Radix without responsive props */}
<Flex width="500px"> {/* Fixed width */}
```

⚠️ **High**:
```tsx
{/* Table without mobile view */}
<Table>
  <TableBody>
    {data.map(row => (
      <TableRow>
        <TableCell>{row.col1}</TableCell>
        <TableCell>{row.col2}</TableCell>
        <TableCell>{row.col3}</TableCell>
      </TableRow>
    ))}
  </TableBody>
</Table>
```

💡 **Enhancement**:
```tsx
{/* Dialog that could be Drawer on mobile */}
<Dialog>
  <DialogContent>
    {/* Could check viewport and use Drawer on mobile */}
  </DialogContent>
</Dialog>
```

✅ **Pass**:
```tsx
{/* Radix with responsive props */}
<Flex
  width={{ initial: "100%", md: "500px" }}
  direction={{ initial: "column", md: "row" }}
  gap={{ initial: "2", md: "4" }}
>

{/* Table + mobile cards */}
<div className="hidden md:block">
  <Table>{/* ... */}</Table>
</div>
<div className="md:hidden space-y-4">
  {data.map(row => <Card key={row.id}>{/* ... */}</Card>)}
</div>
```

---

### 7. Performance
**What to check:**
- Large components that could be code-split
- Proper use of Server vs. Client Components
- Dynamic imports for heavy components

**Severity:**
- **High**: Large components (charts, editors) not code-split
- **Enhancement**: Could use Server Components

**Examples:**

⚠️ **High**:
```tsx
{/* Heavy chart component always loaded */}
import HeavyChart from './HeavyChart'

export default function Page() {
  return <HeavyChart data={data} />
}
```

💡 **Enhancement**:
```tsx
'use client'

{/* Could be Server Component */}
export default function StaticPage() {
  return <div>{/* Static content */}</div>
}
```

✅ **Pass**:
```tsx
import dynamic from 'next/dynamic'

const HeavyChart = dynamic(() => import('./HeavyChart'), {
  loading: () => <Skeleton />,
  ssr: false
})
```

---

## Analysis Process

1. **Read the file** completely
2. **Identify component type**:
   - Page (layout concerns)
   - Component (reusable patterns)
   - Server vs. Client Component
3. **Check each category** in order:
   - Touch targets first (most critical)
   - Then typography, layout, images, navigation, components, performance
4. **Document line numbers** for every issue
5. **Provide exact fixes** (before → after code)
6. **Categorize by severity**:
   - Critical = blocks mobile usability
   - High = degrades experience
   - Enhancement = nice to have
7. **Note what's working** (✅ Passing section)

## Severity Decision Matrix

| Issue Type | Size/Value | Severity |
|------------|------------|----------|
| Touch target | < 36px | Critical |
| Touch target | 36-43px | High |
| Touch target | ≥ 44px | Pass |
| Font size (body) | < 14px | Critical |
| Font size (body) | 14-15px | High |
| Font size (body) | ≥ 16px | Pass |
| Breakpoint approach | Desktop-first | Critical |
| Breakpoint approach | No mobile layout | High |
| Breakpoint approach | Mobile-first | Pass |
| Images | Using `<img>` | High |
| Images | Missing `sizes` | High |
| Images | Complete `<Image>` | Pass |
| Navigation | Menu < 44px | Critical |
| Navigation | No mobile nav | High |
| Navigation | Touch-friendly | Pass |
| Tables | No mobile view | High |
| Tables | Has mobile cards | Pass |
| Components | No responsive props | High |
| Components | Responsive props | Pass |
| Performance | Large, not split | High |
| Performance | Code-split | Pass |

## Output Format Template

```markdown
## Analysis Summary
Found [X] issues across [Y] files:
- [N] critical (blocks mobile usability)
- [N] high priority (degrades experience)
- [N] enhancements (nice to have)

---

## src/path/to/file.tsx

### Critical Issues

- ❌ **Touch Targets**: Submit button is 36×36px (need 44×44px minimum)
  - Line 67: `<Button size="sm" className="h-9 w-9">Submit</Button>`
  - Fix: `<Button className="h-11 w-11">Submit</Button>`
  - Explanation: Buttons below 44×44px are difficult to tap accurately on mobile devices.

### High Priority

- ⚠️ **Images**: Using img tag instead of next/image
  - Line 34: `<img src="/logo.png" alt="Logo" />`
  - Fix: `<Image src="/logo.png" alt="Logo" width={200} height={50} sizes="200px" />`
  - Explanation: next/image provides automatic optimization, lazy loading, and responsive sizes.

- ⚠️ **Responsive Layout**: Table has no mobile alternative
  - Lines 89-120: `<table>...</table>`
  - Fix: Add mobile card layout:
    ```tsx
    <div className="hidden md:block"><table>...</table></div>
    <div className="md:hidden space-y-4">
      {data.map(row => <Card key={row.id}>...</Card>)}
    </div>
    ```
  - Explanation: Tables with many columns cause horizontal scrolling on mobile.

### Enhancements

- 💡 **Typography**: Consider fluid typography for heading
  - Line 12: `<h1 className="text-4xl">`
  - Suggestion: `<h1 className="text-[clamp(2rem,5vw,4rem)]">`
  - Explanation: Fluid typography scales smoothly between breakpoints without stepped changes.

### ✅ Passing

- **Responsive Breakpoints**: Uses mobile-first approach correctly
- **Navigation**: Touch-friendly menu items (44px height)
- **Form Layout**: Inputs stack properly on mobile

---
```

## Common Patterns to Flag

### Desktop-First Pattern
```tsx
// ❌ Flag as Critical
<div className="text-xl lg:text-base">
<div className="block max-md:hidden">
```

### Missing Mobile Layout
```tsx
// ⚠️ Flag as High
<table className="w-full">
  {/* Many columns, no mobile alternative */}
</table>
```

### Small Touch Targets
```tsx
// ❌ Critical if < 36px
// ⚠️ High if 36-43px
<Button size="sm">Click</Button> {/* Usually 36px */}
<button className="h-8 w-8">X</button> {/* 32px */}
```

### Missing Image Optimization
```tsx
// ⚠️ Flag as High
<img src="/photo.jpg" alt="Photo" />

// Should be:
<Image src="/photo.jpg" alt="Photo" width={800} height={600} sizes="..." />
```

### Fixed Component Widths
```tsx
// ⚠️ Flag as High (Radix without responsive props)
<Flex width="600px">

// Should be:
<Flex width={{ initial: "100%", md: "600px" }}>
```

## Notes

- Always include line numbers
- Provide complete code fixes, not just descriptions
- Explain *why* each fix is needed
- Group related issues together
- Keep passing section brief but specific
- Use emojis consistently: ❌ Critical, ⚠️ High, 💡 Enhancement, ✅ Pass
