# Example GitHub Issues

These examples demonstrate how to write comprehensive issues that benefit from your research and provide everything the next developer needs.

## Example 1: Bug Fix

### Title
Fix network page "too many requests" error with circuit breaker pattern

### Body
```markdown
## Problem Description

The network page crashes when loading profiles due to rate limiting errors from Supabase. Users see:
- Browser console error: "Too many requests" (429)
- Infinite retry loop that makes the problem worse
- Page becomes unresponsive

Error occurs consistently when >50 profiles are displayed.

## Root Cause Analysis

Investigation revealed the issue is in `src/lib/supabase/client.ts:89` in the `fetchProfiles` function:

```typescript
// Current problematic code
const fetchProfiles = async () => {
  const { data } = await supabase
    .from('profiles')
    .select('*')
  // No error handling, no rate limiting
}
```

**Key findings:**
1. No retry backoff strategy - retries immediately on failure
2. No circuit breaker to prevent cascading failures
3. Concurrent requests not throttled
4. Error handling just logs and retries infinitely

## Related Code Patterns

The codebase already has a circuit breaker pattern in `src/utils/circuitBreaker.ts:12` used for external API calls. We should apply the same pattern here.

## Proposed Solution

Implement circuit breaker with exponential backoff:

1. Wrap `fetchProfiles` with existing `CircuitBreaker` utility
2. Add exponential backoff: 1s → 2s → 4s → 8s → fail
3. Add max retry limit (3 attempts)
4. Show user-friendly error message on circuit open

**Implementation details:**
- Modify `src/lib/supabase/client.ts:85-120`
- Reuse `src/utils/circuitBreaker.ts` (already tested)
- Add error boundary in `src/app/network/page.tsx:45`
- Display error state with retry button

## User Integration

**User-facing changes after this fix:**

1. **Error State Display** (new):
   - When rate limiting occurs, users see a friendly error message instead of a frozen page
   - Error message: "We're having trouble loading profiles. Please wait a moment and try again."
   - Includes a "Retry" button for manual retry

2. **Loading State** (improved):
   - Loading spinner remains visible during retry attempts
   - No more page freeze or unresponsive UI

3. **Recovery Flow**:
   - After circuit closes (Supabase available again), profiles load automatically
   - User does not need to refresh the page manually

## Testing Strategy

1. **Manual test**: Load network page with >50 profiles
2. **Simulate rate limiting**: Use Supabase rate limit test endpoint
3. **Verify backoff**: Check network tab for increasing delays between retries
4. **Verify circuit**: Confirm circuit opens after 3 failures
5. **Verify recovery**: Confirm circuit closes after successful request

## Acceptance Criteria

- [ ] No infinite retry loops
- [ ] Exponential backoff implemented (verify in network tab)
- [ ] Circuit opens after 3 failures
- [ ] User sees friendly error message when circuit open
- [ ] Page recovers automatically when Supabase available
- [ ] Existing network page functionality unchanged

## References

- Circuit breaker pattern docs: `docs/patterns/circuit-breaker.md`
- Supabase rate limits: https://supabase.com/docs/guides/platform/going-into-prod#rate-limiting
- Related PR: #142 (implemented circuit breaker for external APIs)
```

---

## Example 2: New Feature

### Title
Add "Save to Favorites" feature for builder profiles on network page

### Body
```markdown
## Feature Overview

Enable users to bookmark/favorite builder profiles for quick access later. This addresses user feedback that they can't easily track interesting builders across browsing sessions.

## User Story

As a user browsing the network,
I want to save interesting builder profiles to favorites,
So that I can easily find them later without searching again.

**Acceptance scenario:**
1. User clicks "Save" icon on any builder card
2. Profile is added to their favorites list
3. "My Favorites" section shows saved profiles
4. User can remove profiles from favorites
5. Favorites persist across sessions

## Technical Approach

After researching the existing codebase, this fits the established patterns:

### Database Schema (Supabase)

Create new table following existing schema patterns in `supabase/migrations/`:

```sql
-- New migration: YYYYMMDDHHMMSS_add_favorites.sql
create table public.favorites (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users(id) on delete cascade,
  profile_id uuid references public.profiles(id) on delete cascade,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  unique(user_id, profile_id)
);

-- RLS policies following patterns from profiles table
alter table public.favorites enable row level security;

create policy "Users can view their own favorites"
  on public.favorites for select
  using (auth.uid() = user_id);

create policy "Users can insert their own favorites"
  on public.favorites for insert
  with check (auth.uid() = user_id);

create policy "Users can delete their own favorites"
  on public.favorites for delete
  using (auth.uid() = user_id);
```

### React Components

**New hook** (following pattern from `src/hooks/useProfile.ts`):

```typescript
// src/hooks/useFavorites.ts
export function useFavorites() {
  // Similar structure to useProfile hook
  // - useQuery for fetching favorites
  // - useMutation for add/remove
  // - Optimistic updates
  // - Error handling with toast
}
```

**Update existing component** `src/app/network/components/BuilderCard.tsx:67`:
- Add favorite icon button (heart icon from existing icon set)
- Wire to useFavorites hook
- Show filled/unfilled based on favorite status
- Optimistic UI update on click

**New section** in `src/app/network/page.tsx:120`:
- Add "My Favorites" collapsible section above main directory
- Show favorited builders using existing BuilderCard component
- Empty state: "No favorites yet. Click the heart icon on any profile to save it."

### State Management

Use existing React Query pattern (established in `src/lib/react-query.ts:23`):
- Query key: `['favorites', userId]`
- Mutations: `addFavorite`, `removeFavorite`
- Automatic cache invalidation
- Optimistic updates for instant feedback

## Files to Create/Modify

**Create:**
1. `supabase/migrations/[timestamp]_add_favorites.sql` - database schema
2. `src/hooks/useFavorites.ts` - favorites logic (100-150 lines estimated)
3. `src/app/network/components/FavoritesSection.tsx` - favorites display

**Modify:**
4. `src/app/network/components/BuilderCard.tsx:67` - add favorite button
5. `src/app/network/page.tsx:120` - integrate favorites section
6. `src/lib/supabase/schema.ts:45` - add Favorites type

## Integration Points

- **Auth context**: Reuse existing `useUser()` hook for user_id
- **Toast notifications**: Use existing toast system from `src/components/ui/toast.tsx`
- **Icons**: Use heart icon from `lucide-react` (already in dependencies)
- **Styling**: Follow existing BuilderCard button patterns

## User Integration

**User interaction walkthrough:**

### Adding a Favorite
1. User browses builder cards on the network page
2. User sees a **heart icon** (outline) on each builder card
3. User clicks heart icon → icon fills in immediately (optimistic update)
4. Toast notification appears: "Added to favorites"
5. Builder card now shows filled heart icon

### Viewing Favorites
1. User sees new **"My Favorites" section** at top of network page (above main directory)
2. Section shows all favorited builder cards in a horizontal scrollable row
3. If no favorites, shows: "No favorites yet. Click the heart icon on any profile to save it."
4. Each favorite card displays the same info as regular builder cards

### Removing a Favorite
1. User clicks filled heart icon on any builder card
2. Heart icon becomes outline immediately (optimistic update)
3. Toast notification appears: "Removed from favorites"
4. Card is removed from "My Favorites" section

### Error States
- **Network error on favorite**: Toast shows "Failed to save favorite. Please try again." Heart reverts to previous state.
- **Unauthenticated user clicks heart**: Modal appears prompting sign-in

## Edge Cases to Handle

1. **Unauthenticated users**: Hide favorite buttons, show auth prompt on click
2. **Rate limiting**: Debounce rapid favorite/unfavorite clicks (500ms)
3. **Deleted profiles**: Cascade delete in schema handles cleanup
4. **Network errors**: Show error toast, revert optimistic update
5. **Duplicate favorites**: Database unique constraint prevents duplicates

## Testing Requirements

**Unit tests** (`src/hooks/useFavorites.test.ts`):
- Test add/remove favorite mutations
- Test optimistic updates
- Test error handling and rollback

**Integration tests** (`cypress/e2e/favorites.cy.ts`):
- Test complete favorite/unfavorite flow
- Test favorites persistence across page refresh
- Test favorites section display
- Test unauthenticated user behavior

**Manual QA checklist:**
- [ ] Click favorite on builder card adds to favorites
- [ ] Favorites section shows favorited builders
- [ ] Removing favorite updates UI immediately
- [ ] Favorites persist after page refresh
- [ ] Works on mobile and desktop
- [ ] Handles network errors gracefully

## Performance Considerations

- Favorites query uses index on `user_id` (included in schema)
- Lazy load favorites section (only fetch when user is authenticated)
- Optimistic updates prevent UI lag on favorite toggle
- Expected impact: <50ms for favorite toggle, <200ms for initial load

## Open Questions

None - approach is clear and follows established patterns.

## References

- Similar pattern: Profile edit feature (`src/app/profile/edit/page.tsx`)
- Database migrations: `supabase/migrations/` (see existing for format)
- React Query patterns: `src/hooks/useProfile.ts` (use as template)
```

---

## What Makes These Examples Great

Both examples demonstrate:

✅ **Complete context** - Next developer understands the full picture
✅ **Specific references** - Exact file paths and line numbers
✅ **Research findings** - What you discovered during investigation
✅ **Code snippets** - Show current state and proposed changes
✅ **User Integration** - Clear trace from user entry point to outcome
✅ **Integration points** - How it fits with existing code
✅ **Testing strategy** - Clear verification approach
✅ **Edge cases** - Anticipated problems and solutions
✅ **Rationale** - Why decisions were made

These issues allow another developer to implement immediately without redoing your research.
