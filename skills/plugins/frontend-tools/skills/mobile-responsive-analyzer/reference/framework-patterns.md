# Framework-Specific Responsive Patterns

This reference provides framework-specific patterns and anti-patterns for Next.js 15, Tailwind CSS 4, Radix UI, and shadcn/ui.

## Table of Contents
- [Next.js 15](#nextjs-15)
- [Tailwind CSS 4](#tailwind-css-4)
- [Radix UI](#radix-ui)
- [shadcn/ui](#shadcnui)
- [Integration Patterns](#integration-patterns)

---

## Next.js 15

### Server Components vs Client Components

**Server Components** (default in App Router):
- Cannot use React hooks (useState, useEffect, etc.)
- Cannot use viewport detection
- Must use CSS-only responsive patterns
- Ideal for static content

```tsx
// app/page.tsx (Server Component)
export default async function Page() {
  const data = await fetchData() // Server-side data fetching

  return (
    <div className="grid grid-cols-1 md:grid-cols-2"> {/* CSS-only responsive */}
      {data.map(item => (
        <Card key={item.id}>{item.name}</Card>
      ))}
    </div>
  )
}
```

**Client Components** ('use client'):
- Can use React hooks
- Can detect viewport with useMediaQuery
- Required for interactive UI
- Should be used sparingly

```tsx
'use client'

import { useMediaQuery } from '@/hooks/use-media-query'

export function ResponsiveComponent() {
  const isMobile = useMediaQuery('(max-width: 768px)')

  return isMobile ? <MobileView /> : <DesktopView />
}
```

### Image Optimization

**Always use next/image**:

```tsx
import Image from 'next/image'

{/* Bad: raw img tag */}
<img src="/photo.jpg" alt="Photo" />

{/* Good: Next.js Image */}
<Image
  src="/photo.jpg"
  alt="Photo"
  width={800}
  height={600}
  sizes="(max-width: 768px) 100vw, 50vw"
/>

{/* Good: Fill container */}
<div className="relative h-64 w-full">
  <Image
    src="/photo.jpg"
    alt="Photo"
    fill
    sizes="100vw"
    className="object-cover"
  />
</div>
```

**Priority for above-the-fold images**:

```tsx
<Image
  src="/hero.jpg"
  alt="Hero"
  width={1920}
  height={1080}
  priority // Loads immediately, no lazy loading
  sizes="100vw"
/>
```

### Dynamic Imports for Code Splitting

```tsx
import dynamic from 'next/dynamic'

// Lazy load heavy components
const HeavyChart = dynamic(() => import('@/components/HeavyChart'), {
  loading: () => <Skeleton className="h-64 w-full" />,
  ssr: false // Skip SSR if component has client-only code
})

export default function Page() {
  return (
    <div>
      <h1>Analytics</h1>
      {/* Chart only loads when page is viewed */}
      <HeavyChart />
    </div>
  )
}
```

### Responsive Layouts with App Router

```tsx
// app/layout.tsx
export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>
        {/* Mobile: stack, Desktop: sidebar */}
        <div className="flex flex-col md:flex-row">
          <aside className="w-full md:w-64">
            <Sidebar />
          </aside>
          <main className="flex-1 p-4 md:p-8">
            {children}
          </main>
        </div>
      </body>
    </html>
  )
}
```

### Metadata API (SEO)

```tsx
import { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Page Title',
  description: 'Page description',
  viewport: 'width=device-width, initial-scale=1', // Mobile viewport
}
```

### Anti-Patterns

❌ **Using viewport detection in Server Components**:
```tsx
// BAD: Cannot use hooks in Server Component
export default function Page() {
  const isMobile = useMediaQuery('(max-width: 768px)') // Error!
  return <div>...</div>
}
```

❌ **Using img tags instead of Image**:
```tsx
// BAD: Missing optimization
<img src="/photo.jpg" alt="Photo" />

// GOOD:
<Image src="/photo.jpg" alt="Photo" width={800} height={600} />
```

❌ **Not specifying sizes attribute**:
```tsx
// BAD: Browser doesn't know how to optimize
<Image src="/photo.jpg" alt="Photo" width={800} height={600} />

// GOOD:
<Image
  src="/photo.jpg"
  alt="Photo"
  width={800}
  height={600}
  sizes="(max-width: 768px) 100vw, 50vw"
/>
```

---

## Tailwind CSS 4

### Mobile-First Breakpoints

**Correct order** (base → sm → md → lg → xl → 2xl):

```tsx
{/* Base = mobile (< 640px) */}
{/* sm = 640px+ */}
{/* md = 768px+ */}
{/* lg = 1024px+ */}
{/* xl = 1280px+ */}
{/* 2xl = 1536px+ */}

<div className="
  text-base          {/* mobile: 16px */}
  sm:text-lg         {/* 640px+: 18px */}
  md:text-xl         {/* 768px+: 20px */}
  lg:text-2xl        {/* 1024px+: 24px */}
">
  Responsive text
</div>
```

### Common Responsive Utilities

**Visibility**:
```tsx
{/* Show only on mobile */}
<div className="block md:hidden">Mobile only</div>

{/* Show only on desktop */}
<div className="hidden md:block">Desktop only</div>

{/* Show on tablet and up */}
<div className="hidden sm:block">Tablet+</div>
```

**Flexbox Direction**:
```tsx
{/* Stack on mobile, row on desktop */}
<div className="flex flex-col md:flex-row gap-4">
  <div>Item 1</div>
  <div>Item 2</div>
</div>
```

**Grid Columns**:
```tsx
{/* 1 column mobile, 2 tablet, 3 desktop */}
<div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
  {items.map(item => <Card key={item.id} />)}
</div>
```

**Width/Height**:
```tsx
{/* Full width mobile, fixed desktop */}
<div className="w-full md:w-96">

{/* Responsive height */}
<div className="h-64 md:h-80 lg:h-96">
```

**Padding/Margin**:
```tsx
{/* Small padding mobile, larger desktop */}
<div className="p-4 md:p-6 lg:p-8">

{/* Responsive gap */}
<div className="flex gap-2 md:gap-4 lg:gap-6">
```

**Touch Targets**:
```tsx
{/* Minimum 44px (11 × 4px) */}
<Button className="h-11 w-11 md:h-10 md:w-10"> {/* Slightly smaller on desktop OK */}

{/* With padding */}
<Button className="min-h-11 px-4 py-2">
```

### Arbitrary Values

**Fluid Typography**:
```tsx
<h1 className="text-[clamp(2rem,5vw,4rem)]">
  Fluid Heading
</h1>
```

**Custom Breakpoints**:
```tsx
{/* Show at specific width */}
<div className="hidden [@media(min-width:900px)]:block">
```

**Container Queries**:
```tsx
<div className="@container">
  <div className="@lg:grid-cols-2">
    {/* Changes based on container size, not viewport */}
  </div>
</div>
```

### Anti-Patterns

❌ **Desktop-first (max-width)**:
```tsx
// BAD: Desktop-first approach
<div className="text-xl lg:text-base"> {/* Backwards */}

// GOOD: Mobile-first
<div className="text-base lg:text-xl">
```

❌ **Max-width media queries**:
```tsx
// BAD: Using max-width
<div className="hidden max-md:block">

// GOOD: Use mobile-first show/hide
<div className="block md:hidden">
```

❌ **Fixed sizes without responsive alternatives**:
```tsx
// BAD: Fixed width always
<div className="w-96">

// GOOD: Responsive width
<div className="w-full md:w-96">
```

---

## Radix UI

### Responsive Object Syntax

All Radix Themes layout components (Box, Flex, Grid, Section, Container) support responsive props:

```tsx
import { Flex, Box, Grid } from '@radix-ui/themes'

{/* Responsive width */}
<Flex width={{ initial: "100%", sm: "300px", md: "500px" }}>

{/* Responsive direction */}
<Flex direction={{ initial: "column", md: "row" }}>

{/* Responsive gap */}
<Flex gap={{ initial: "2", md: "4", lg: "6" }}>

{/* Responsive padding */}
<Box p={{ initial: "4", md: "6", lg: "8" }}>
```

### Breakpoint Keys
- `initial` - base (mobile)
- `xs` - 520px+
- `sm` - 768px+
- `md` - 1024px+
- `lg` - 1280px+
- `xl` - 1640px+

### Layout Components

**Flex**:
```tsx
<Flex
  direction={{ initial: "column", md: "row" }}
  gap={{ initial: "4", md: "6" }}
  align={{ initial: "start", md: "center" }}
  justify="between"
>
  <Box>Item 1</Box>
  <Box>Item 2</Box>
</Flex>
```

**Grid**:
```tsx
<Grid
  columns={{ initial: "1", sm: "2", lg: "3" }}
  gap={{ initial: "4", md: "6" }}
  width="100%"
>
  {items.map(item => (
    <Box key={item.id}>{item.name}</Box>
  ))}
</Grid>
```

**Container**:
```tsx
<Container
  size={{ initial: "1", md: "2", lg: "3" }} // Preset sizes
  px={{ initial: "4", md: "6" }}
>
  {children}
</Container>
```

### Component-Specific Patterns

**Dialog**:
```tsx
import { Dialog } from '@radix-ui/react-dialog'

<Dialog.Root>
  <Dialog.Trigger asChild>
    <Button className="min-h-11">Open</Button>
  </Dialog.Trigger>
  <Dialog.Portal>
    <Dialog.Overlay className="fixed inset-0 bg-black/50" />
    <Dialog.Content className="
      fixed
      left-1/2 top-1/2
      -translate-x-1/2 -translate-y-1/2
      w-[90vw] max-w-md
      max-h-[85vh] overflow-auto
      p-6
    ">
      {/* Content */}
    </Dialog.Content>
  </Dialog.Portal>
</Dialog.Root>
```

**Dropdown Menu** (consider Sheet on mobile):
```tsx
{/* Desktop: Dropdown */}
<DropdownMenu.Root>
  <DropdownMenu.Trigger className="hidden md:flex min-h-11">
    Menu
  </DropdownMenu.Trigger>
  <DropdownMenu.Portal>
    <DropdownMenu.Content>
      <DropdownMenu.Item className="min-h-11">
        Item 1
      </DropdownMenu.Item>
    </DropdownMenu.Content>
  </DropdownMenu.Portal>
</DropdownMenu.Root>
```

### Anti-Patterns

❌ **Not using responsive object syntax**:
```tsx
// BAD: Fixed width
<Flex width="500px">

// GOOD: Responsive
<Flex width={{ initial: "100%", md: "500px" }}>
```

❌ **Using Tailwind classes on Radix Themes components**:
```tsx
// BAD: Mixing Radix props and Tailwind (inconsistent)
<Flex width="100%" className="md:w-[500px]">

// GOOD: Use Radix responsive syntax
<Flex width={{ initial: "100%", md: "500px" }}>
```

---

## shadcn/ui

### Responsive Component Patterns

shadcn/ui components are built on Radix primitives + Tailwind styling. Apply responsive patterns using Tailwind classes.

### Dialog → Drawer on Mobile

```tsx
'use client'

import { Dialog, DialogContent, DialogTrigger } from '@/components/ui/dialog'
import { Drawer, DrawerContent, DrawerTrigger } from '@/components/ui/drawer'
import { useMediaQuery } from '@/hooks/use-media-query'
import { Button } from '@/components/ui/button'

export function ResponsiveModal({ children }) {
  const isDesktop = useMediaQuery("(min-width: 768px)")

  if (isDesktop) {
    return (
      <Dialog>
        <DialogTrigger asChild>
          <Button>Open</Button>
        </DialogTrigger>
        <DialogContent className="sm:max-w-[425px]">
          {children}
        </DialogContent>
      </Dialog>
    )
  }

  return (
    <Drawer>
      <DrawerTrigger asChild>
        <Button>Open</Button>
      </DrawerTrigger>
      <DrawerContent>
        <div className="px-4 pb-4">
          {children}
        </div>
      </DrawerContent>
    </Drawer>
  )
}
```

### Navigation Sheet (Mobile Menu)

```tsx
import { Sheet, SheetContent, SheetTrigger } from '@/components/ui/sheet'
import { Button } from '@/components/ui/button'
import { Menu } from 'lucide-react'

export function MobileNav() {
  return (
    <>
      {/* Mobile hamburger */}
      <Sheet>
        <SheetTrigger asChild>
          <Button variant="ghost" className="md:hidden h-11 w-11 p-0">
            <Menu className="h-6 w-6" />
            <span className="sr-only">Toggle menu</span>
          </Button>
        </SheetTrigger>
        <SheetContent side="left" className="w-[300px]">
          <nav className="flex flex-col space-y-1">
            <a href="/" className="flex items-center h-11 px-4 rounded-md hover:bg-accent">
              Home
            </a>
            <a href="/about" className="flex items-center h-11 px-4 rounded-md hover:bg-accent">
              About
            </a>
          </nav>
        </SheetContent>
      </Sheet>

      {/* Desktop nav */}
      <nav className="hidden md:flex gap-6">
        <a href="/" className="flex items-center min-h-11">Home</a>
        <a href="/about" className="flex items-center min-h-11">About</a>
      </nav>
    </>
  )
}
```

### Responsive Card Grid

```tsx
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

export function CardGrid({ items }) {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
      {items.map(item => (
        <Card key={item.id}>
          <CardHeader>
            <CardTitle className="text-lg md:text-xl">{item.title}</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm md:text-base">{item.description}</p>
          </CardContent>
        </Card>
      ))}
    </div>
  )
}
```

### Form Layout

```tsx
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

export function ResponsiveForm() {
  return (
    <form className="space-y-4 max-w-2xl mx-auto p-4 md:p-6">
      {/* Full width on mobile, constrained on desktop */}
      <div className="space-y-2">
        <Label htmlFor="email">Email</Label>
        <Input
          id="email"
          type="email"
          placeholder="you@example.com"
          className="w-full h-11"
        />
      </div>

      {/* Stack on mobile, side-by-side on desktop */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="space-y-2">
          <Label htmlFor="first">First Name</Label>
          <Input id="first" className="h-11" />
        </div>
        <div className="space-y-2">
          <Label htmlFor="last">Last Name</Label>
          <Input id="last" className="h-11" />
        </div>
      </div>

      {/* Full-width button on mobile */}
      <Button type="submit" className="w-full md:w-auto h-11">
        Submit
      </Button>
    </form>
  )
}
```

### Table → Cards on Mobile

```tsx
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

export function ResponsiveTable({ data }) {
  return (
    <>
      {/* Desktop table */}
      <div className="hidden md:block">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Name</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Date</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {data.map(row => (
              <TableRow key={row.id}>
                <TableCell>{row.name}</TableCell>
                <TableCell>{row.status}</TableCell>
                <TableCell>{row.date}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>

      {/* Mobile cards */}
      <div className="md:hidden space-y-4">
        {data.map(row => (
          <Card key={row.id}>
            <CardHeader>
              <CardTitle className="text-lg">{row.name}</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2 text-sm">
              <div>
                <span className="font-medium">Status:</span> {row.status}
              </div>
              <div>
                <span className="font-medium">Date:</span> {row.date}
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </>
  )
}
```

### Touch-Friendly Buttons

```tsx
import { Button } from '@/components/ui/button'

{/* Default size is already touch-friendly (h-10 = 40px, close to 44px) */}
<Button>Default</Button> {/* 40px - slightly small */}

{/* Recommended: explicit min-height */}
<Button className="min-h-11">Touch Friendly</Button> {/* 44px */}

{/* Icon button */}
<Button size="icon" className="h-11 w-11">
  <Icon />
</Button>

{/* Small button - flag as issue if interactive */}
<Button size="sm">Too Small</Button> {/* 36px - needs to be 44px */}
```

### Anti-Patterns

❌ **Using small button sizes for primary actions**:
```tsx
// BAD: Too small for mobile
<Button size="sm">Submit</Button> {/* 36px */}

// GOOD: Touch-friendly
<Button className="min-h-11">Submit</Button> {/* 44px */}
```

❌ **Fixed dialog widths**:
```tsx
// BAD: Fixed width overflows mobile
<DialogContent className="w-[600px]">

// GOOD: Responsive width
<DialogContent className="w-[90vw] max-w-[600px]">
```

❌ **Not providing mobile alternatives for tables**:
```tsx
// BAD: Table only (horizontal scroll on mobile)
<Table>...</Table>

// GOOD: Table + mobile cards
<div className="hidden md:block"><Table>...</Table></div>
<div className="md:hidden">{/* Card layout */}</div>
```

---

## Integration Patterns

### Next.js + Tailwind + shadcn

**Typical page structure**:

```tsx
// app/dashboard/page.tsx
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'

export default function DashboardPage() {
  return (
    <div className="container mx-auto p-4 md:p-6 lg:p-8">
      {/* Responsive heading */}
      <h1 className="text-2xl md:text-3xl lg:text-4xl font-bold mb-6">
        Dashboard
      </h1>

      {/* Responsive grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 md:gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Metric 1</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-3xl font-bold">1,234</p>
          </CardContent>
        </Card>

        {/* More cards... */}
      </div>

      {/* Touch-friendly action */}
      <Button className="mt-6 w-full md:w-auto min-h-11">
        View Details
      </Button>
    </div>
  )
}
```

### Radix + Tailwind + Next.js

```tsx
'use client'

import { Flex, Box, Grid } from '@radix-ui/themes'
import Image from 'next/image'

export function ProductGrid({ products }) {
  return (
    <Grid
      columns={{ initial: "1", sm: "2", lg: "3" }}
      gap={{ initial: "4", md: "6" }}
      p={{ initial: "4", md: "6", lg: "8" }}
    >
      {products.map(product => (
        <Box key={product.id}>
          {/* Next.js Image with Radix Box */}
          <div className="relative aspect-square mb-4">
            <Image
              src={product.image}
              alt={product.name}
              fill
              sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
              className="object-cover rounded-lg"
            />
          </div>
          <Flex direction="column" gap="2">
            <Box className="text-lg font-semibold">{product.name}</Box>
            <Box className="text-2xl font-bold">${product.price}</Box>
          </Flex>
        </Box>
      ))}
    </Grid>
  )
}
```

### useMediaQuery Hook (for Client Components)

```tsx
// hooks/use-media-query.ts
'use client'

import { useState, useEffect } from 'react'

export function useMediaQuery(query: string) {
  const [matches, setMatches] = useState(false)

  useEffect(() => {
    const media = window.matchMedia(query)
    if (media.matches !== matches) {
      setMatches(media.matches)
    }

    const listener = () => setMatches(media.matches)
    media.addEventListener('change', listener)
    return () => media.removeEventListener('change', listener)
  }, [matches, query])

  return matches
}

// Usage
'use client'

import { useMediaQuery } from '@/hooks/use-media-query'

export function ResponsiveComponent() {
  const isMobile = useMediaQuery('(max-width: 768px)')
  const isTablet = useMediaQuery('(min-width: 769px) and (max-width: 1024px)')
  const isDesktop = useMediaQuery('(min-width: 1025px)')

  return (
    <div>
      {isMobile && <MobileView />}
      {isTablet && <TabletView />}
      {isDesktop && <DesktopView />}
    </div>
  )
}
```

---

## Quick Reference

### Touch Target Sizes (Tailwind)
```tsx
h-11 w-11     // 44×44px (minimum)
h-12 w-12     // 48×48px (recommended)
min-h-11      // Minimum 44px height
```

### Common Responsive Patterns
```tsx
// Visibility
block md:hidden         // Mobile only
hidden md:block         // Desktop only

// Layout
flex-col md:flex-row    // Stack → row
grid-cols-1 md:grid-cols-2  // 1 col → 2 cols

// Sizing
w-full md:w-96          // Full → fixed
text-base md:text-lg    // Responsive text
p-4 md:p-6 lg:p-8       // Responsive padding
```

### Radix Responsive Syntax
```tsx
width={{ initial: "100%", md: "500px" }}
direction={{ initial: "column", md: "row" }}
gap={{ initial: "2", md: "4", lg: "6" }}
```

### Next.js Image
```tsx
<Image
  src="/photo.jpg"
  alt="Description"
  width={800}
  height={600}
  sizes="(max-width: 768px) 100vw, 50vw"
  priority // Above fold only
/>
```
