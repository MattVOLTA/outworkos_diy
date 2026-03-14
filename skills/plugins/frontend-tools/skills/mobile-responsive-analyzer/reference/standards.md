# Mobile Responsive Design Standards (2025)

This document defines the concrete standards used during analysis. All measurements and thresholds are based on 2025 industry best practices.

## Table of Contents
- [Touch Targets](#touch-targets)
- [Typography](#typography)
- [Breakpoints & Layout](#breakpoints--layout)
- [Images](#images)
- [Navigation](#navigation)
- [Performance](#performance)
- [Component Patterns](#component-patterns)

---

## Touch Targets

### Minimum Sizes
- **Baseline minimum**: 44×44px (1936px² area)
- **Google recommendation**: 48×48px (2304px² area)
- **Apple HIG**: 44×44 points (88×88px on Retina)

**Standard used**: 44×44px minimum for all interactive elements

### Spacing
- **Minimum gap**: 8px between adjacent touch targets
- **Recommended gap**: 12px for improved accuracy
- **Dense interfaces**: May use 8px if targets are 48×48px

### What Counts as Interactive
- Buttons (including icon-only buttons)
- Links
- Form inputs
- Checkboxes and radio buttons
- Toggle switches
- Dropdown triggers
- Menu items
- Tab controls
- Sortable table headers
- Pagination controls
- Modal close buttons

### Exceptions
- Read-only text (non-clickable)
- Disabled controls (but should still maintain size for layout consistency)
- Inline text links in paragraphs (48px width not required, but 44px height recommended)

### CSS Implementation Examples

```css
/* Button minimum */
.btn {
  min-height: 44px;
  min-width: 44px;
}

/* Icon button with padding */
.icon-btn {
  height: 44px;
  width: 44px;
  padding: 10px; /* Ensures 24×24 icon has 44×44 touch area */
}

/* Link with adequate height */
.nav-link {
  min-height: 44px;
  display: flex;
  align-items: center;
}
```

### Tailwind CSS Classes

```tsx
{/* Minimum touch target */}
<Button className="min-h-11 min-w-11"> {/* 44px = 11 × 4px */}

{/* Icon button */}
<Button className="h-11 w-11 p-2.5">

{/* Touch-friendly spacing */}
<div className="space-x-3"> {/* 12px gap */}
```

### Severity Levels
- **Critical**: < 36×36px (unusable on mobile)
- **High**: 36×36px to 43×43px (difficult to tap)
- **Pass**: ≥ 44×44px

---

## Typography

### Font Sizes
- **Base text**: 16px minimum (1rem)
- **Small text**: 14px minimum (0.875rem) - use sparingly
- **Tiny text**: 12px - avoid entirely, fail if found
- **Large headings**: Use fluid sizing with `clamp()`

### Line Height
- **Body text**: 1.5× minimum (24px for 16px text)
- **Headings**: 1.2× to 1.3×
- **Tight spacing**: Never below 1.3× for readability

### Fluid Typography
Use CSS `clamp()` for responsive scaling without breakpoints:

```css
/* Fluid heading */
font-size: clamp(1.5rem, 4vw, 3rem);
/* min: 24px, scales with viewport, max: 48px */

/* Fluid body */
font-size: clamp(1rem, 2vw, 1.125rem);
/* min: 16px, scales, max: 18px */
```

### Tailwind Implementation

```tsx
{/* Bad: fixed small size */}
<p className="text-sm">

{/* Good: minimum 16px */}
<p className="text-base">

{/* Good: fluid heading */}
<h1 className="text-[clamp(2rem,5vw,4rem)]">

{/* Good: responsive sizing */}
<h2 className="text-2xl md:text-3xl lg:text-4xl">
```

### Readability Metrics
- **Line length**: 45-75 characters optimal
- **Paragraph spacing**: 1× line height minimum
- **Contrast**: Not checked (out of scope for this skill)

### Severity Levels
- **Critical**: Body text < 14px
- **High**: Body text 14-15px, no line height set
- **Enhancement**: Missing fluid typography for headings

---

## Breakpoints & Layout

### Tailwind CSS 4 Breakpoints
```
sm:  min-width: 640px   (large phone, small tablet)
md:  min-width: 768px   (tablet)
lg:  min-width: 1024px  (laptop)
xl:  min-width: 1280px  (desktop)
2xl: min-width: 1536px  (large desktop)
```

### Mobile-First Approach
**Correct**:
```tsx
{/* Base = mobile, add breakpoints for larger */}
<div className="text-base md:text-lg lg:text-xl">
<div className="flex-col md:flex-row">
```

**Incorrect** (desktop-first):
```tsx
{/* DON'T: max-width approach */}
<div className="hidden max-md:block"> {/* Flag as issue */}
<div className="text-xl md:text-base"> {/* Backwards */}
```

### Layout Patterns

**Single Column → Multi-Column**:
```tsx
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
```

**Stack → Side-by-Side**:
```tsx
<div className="flex flex-col md:flex-row gap-4">
```

**Full Width → Constrained**:
```tsx
<div className="w-full md:w-auto md:max-w-md">
```

**Hide/Show at Breakpoints**:
```tsx
{/* Mobile only */}
<div className="block md:hidden">

{/* Desktop only */}
<div className="hidden md:block">
```

### Container Queries (Modern CSS)
Consider for component-level responsiveness:

```css
.card-container {
  container-type: inline-size;
}

@container (min-width: 400px) {
  .card {
    flex-direction: row;
  }
}
```

### Severity Levels
- **Critical**: Desktop-first approach (max-width queries)
- **High**: No mobile layout for complex components (tables, grids)
- **Enhancement**: Could benefit from container queries

---

## Images

### Next.js 15 Image Component
**Required**: All `<img>` tags should use `<Image>` from `next/image`

### Required Props
```tsx
import Image from 'next/image'

<Image
  src="/photo.jpg"
  alt="Description"
  width={800}
  height={600}
  sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
/>
```

### Responsive Sizing
The `sizes` attribute tells the browser how much space the image occupies:

```tsx
{/* Full width on mobile, 50% on tablet, 33% on desktop */}
sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"

{/* Fixed size across breakpoints */}
sizes="200px"

{/* Full width always */}
sizes="100vw"
```

### Fill Pattern for Unknown Dimensions
```tsx
<div className="relative h-64 w-full">
  <Image
    src="/photo.jpg"
    alt="Description"
    fill
    className="object-cover"
    sizes="(max-width: 768px) 100vw, 50vw"
  />
</div>
```

### Format Optimization
Next.js automatically serves:
- WebP to supporting browsers
- AVIF when optimal
- Original format as fallback

### Priority Loading
Add `priority` to above-the-fold images:

```tsx
<Image
  src="/hero.jpg"
  alt="Hero"
  width={1200}
  height={600}
  priority
/>
```

### Severity Levels
- **High**: Using `<img>` instead of `<Image>`
- **High**: Missing `sizes` attribute
- **Enhancement**: Could add `priority` to hero images

---

## Navigation

### Mobile Menu Patterns

**Hamburger → Drawer/Sheet** (recommended):
```tsx
import { Sheet, SheetContent, SheetTrigger } from '@/components/ui/sheet'

<Sheet>
  <SheetTrigger asChild>
    <Button className="md:hidden h-11 w-11">
      <Menu />
    </Button>
  </SheetTrigger>
  <SheetContent side="left">
    <nav>{/* menu items */}</nav>
  </SheetContent>
</Sheet>

{/* Desktop nav */}
<nav className="hidden md:flex gap-6">
  <Link href="/">Home</Link>
</nav>
```

### Touch-Friendly Menu Items
- **Height**: 44px minimum
- **Padding**: 12px horizontal, 12px vertical
- **Gap**: 8-12px between items

```tsx
<nav className="flex flex-col">
  <Link
    href="/companies"
    className="min-h-11 px-4 py-3 flex items-center"
  >
    Companies
  </Link>
</nav>
```

### Thumb-Reach Zones
On mobile screens (< 768px), position frequent actions in bottom 50% of screen:

```tsx
{/* Bottom-fixed actions */}
<div className="fixed bottom-0 left-0 right-0 p-4 md:static">
  <Button className="w-full md:w-auto">Primary Action</Button>
</div>
```

### Severity Levels
- **Critical**: Menu buttons < 44×44px
- **High**: No mobile navigation pattern
- **Enhancement**: Actions not in thumb-reach zones

---

## Performance

### Bundle Size
- Flag components over 100KB that could be code-split
- Suggest dynamic imports for below-fold content

```tsx
{/* Lazy load heavy components */}
import dynamic from 'next/dynamic'

const HeavyChart = dynamic(() => import('./HeavyChart'), {
  loading: () => <Skeleton className="h-64" />
})
```

### Viewport-Specific Loading
Use Intersection Observer for below-fold images:

```tsx
<Image
  src="/below-fold.jpg"
  alt="Below fold"
  width={800}
  height={600}
  loading="lazy"
/>
```

### Server Components (Next.js 15)
Prefer Server Components for static content:

```tsx
// page.tsx (Server Component by default)
export default async function Page() {
  const data = await fetchData()
  return <StaticContent data={data} />
}
```

Reserve Client Components for interactivity:

```tsx
'use client'

export function InteractiveWidget() {
  const [state, setState] = useState()
  // ...
}
```

### Severity Levels
- **High**: Large components not code-split
- **Enhancement**: Could use Server Components

---

## Component Patterns

### Radix UI Responsive Props

All Radix Themes layout components support responsive object syntax:

```tsx
import { Flex, Box, Grid } from '@radix-ui/themes'

{/* Responsive width */}
<Flex width={{ initial: "100%", sm: "300px", md: "500px" }}>

{/* Responsive direction */}
<Flex direction={{ initial: "column", md: "row" }}>

{/* Responsive gap */}
<Flex gap={{ initial: "2", md: "4", lg: "6" }}>
```

### shadcn/ui Mobile Patterns

**Dialog → Drawer on Mobile**:
```tsx
import { Dialog, DialogContent } from '@/components/ui/dialog'
import { Drawer, DrawerContent } from '@/components/ui/drawer'
import { useMediaQuery } from '@/hooks/use-media-query'

export function ResponsiveModal() {
  const isDesktop = useMediaQuery("(min-width: 768px)")

  if (isDesktop) {
    return (
      <Dialog>
        <DialogContent>{/* content */}</DialogContent>
      </Dialog>
    )
  }

  return (
    <Drawer>
      <DrawerContent>{/* content */}</DrawerContent>
    </Drawer>
  )
}
```

**Dropdown → Sheet on Mobile**:
```tsx
{/* Desktop dropdown */}
<DropdownMenu>
  <DropdownMenuTrigger className="hidden md:flex">
    Menu
  </DropdownMenuTrigger>
  <DropdownMenuContent>
    {/* items */}
  </DropdownMenuContent>
</DropdownMenu>

{/* Mobile sheet */}
<Sheet>
  <SheetTrigger className="md:hidden">
    Menu
  </SheetTrigger>
  <SheetContent>
    {/* items */}
  </SheetContent>
</Sheet>
```

### Data Tables
**TanStack Table**: Always provide mobile alternative

```tsx
{/* Desktop table */}
<table className="hidden md:table">
  <thead>
    <tr>
      <th>Name</th>
      <th>Status</th>
    </tr>
  </thead>
  <tbody>
    {data.map(row => (
      <tr key={row.id}>
        <td>{row.name}</td>
        <td>{row.status}</td>
      </tr>
    ))}
  </tbody>
</table>

{/* Mobile cards */}
<div className="md:hidden space-y-4">
  {data.map(row => (
    <Card key={row.id}>
      <CardHeader>
        <CardTitle>{row.name}</CardTitle>
      </CardHeader>
      <CardContent>
        <p>Status: {row.status}</p>
      </CardContent>
    </Card>
  ))}
</div>
```

### Forms
**Mobile-Optimized Layout**:

```tsx
<form className="space-y-4">
  {/* Full width on mobile, constrained on desktop */}
  <div className="w-full md:w-96">
    <Label htmlFor="email">Email</Label>
    <Input
      id="email"
      type="email"
      className="w-full min-h-11" {/* Touch-friendly height */}
    />
  </div>

  {/* Stack on mobile, side-by-side on desktop */}
  <div className="flex flex-col md:flex-row gap-4">
    <div className="flex-1">
      <Label>First Name</Label>
      <Input className="min-h-11" />
    </div>
    <div className="flex-1">
      <Label>Last Name</Label>
      <Input className="min-h-11" />
    </div>
  </div>

  {/* Full-width button on mobile */}
  <Button type="submit" className="w-full md:w-auto min-h-11">
    Submit
  </Button>
</form>
```

### Severity Levels
- **High**: Radix components without responsive props
- **High**: Tables without mobile alternative
- **High**: Forms not optimized for mobile
- **Enhancement**: Could use Dialog→Drawer pattern

---

## Testing Checklist

When verifying fixes, check:

- [ ] All touch targets ≥ 44×44px
- [ ] Touch target spacing ≥ 8px
- [ ] Base font size ≥ 16px
- [ ] Line height ≥ 1.5× for body text
- [ ] Mobile-first breakpoint usage (no max-width)
- [ ] All images use next/image
- [ ] Images have sizes attribute
- [ ] Tables have mobile alternative
- [ ] Navigation is touch-friendly (≥ 44px height)
- [ ] Forms have mobile-optimized layout
- [ ] No horizontal scroll at 320px width
- [ ] Radix/shadcn components use responsive props
- [ ] Heavy components are code-split
- [ ] No viewport detection hooks in Server Components

---

## Quick Reference

| Standard | Minimum | Recommended |
|----------|---------|-------------|
| Touch target size | 44×44px | 48×48px |
| Touch target gap | 8px | 12px |
| Base font size | 16px | 16-18px |
| Line height (body) | 1.5× | 1.6× |
| Line height (headings) | 1.2× | 1.3× |
| Breakpoint approach | Mobile-first | Mobile-first |
| Image component | next/image | next/image with sizes |
| Menu item height | 44px | 48px |

