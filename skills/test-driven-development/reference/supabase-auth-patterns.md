# Supabase Authentication Testing Patterns

**Reference:** `docs/architecture/auth-best-practices.md` for architectural patterns

## Required Test Categories

### 1. Tenant Isolation Tests (HIGHEST PRIORITY)

```typescript
test('RLS prevents cross-tenant data access', async () => {
  // Create two users in different tenants
  const user1 = await createTestUser({
    email: 'user1@test.com',
    tenant_id: TENANT_1_ID
  })
  const user2 = await createTestUser({
    email: 'user2@test.com',
    tenant_id: TENANT_2_ID
  })

  // User 1 creates a company
  const company = await createCompanyAs(user1, {
    business_name: 'Test Co'
  })

  // User 2 tries to access it - should fail
  const result = await getCompanyAs(user2, company.id)

  expect(result).toBeNull()
})
```

### 2. JWT Claims Tests

```typescript
test('JWT contains tenant_id claim after login', async () => {
  const user = await signUp({
    email: 'test@example.com',
    password: 'password',
    metadata: { tenant_id: TENANT_1_ID }
  })

  const session = await signIn({
    email: 'test@example.com',
    password: 'password'
  })

  const jwt = decodeJwt(session.access_token)
  expect(jwt.tenant_id).toBe(TENANT_1_ID)
})
```

### 3. Data Access Layer Tests

```typescript
test('DAL requireAuth() throws for unauthenticated requests', async () => {
  await expect(getCompanies()).rejects.toThrow('Unauthorized')
})

test('DAL returns data for authenticated user', async () => {
  const user = await createAuthenticatedUser()
  const companies = await getCompanies()
  expect(companies).toBeDefined()
})
```

### 4. Database Trigger Tests

```typescript
test('signing up creates public.users record with tenant_id', async () => {
  const { user } = await supabase.auth.signUp({
    email: 'test@example.com',
    password: 'password',
    options: {
      data: {
        tenant_id: TENANT_1_ID,
        first_name: 'John',
        last_name: 'Doe'
      }
    }
  })

  // Check public.users table (not auth.users)
  const { data } = await supabase
    .from('users')
    .select('tenant_id, first_name, last_name')
    .eq('id', user.id)
    .single()

  expect(data.tenant_id).toBe(TENANT_1_ID)
  expect(data.first_name).toBe('John')
})
```

## Auth Test Data Cleanup

```typescript
// ALWAYS clean up auth.users and public.users
const testUserIds = new Set<string>()

afterEach(async () => {
  for (const userId of testUserIds) {
    await adminClient.auth.admin.deleteUser(userId)
    // Cascade deletes public.users via FK
  }
  testUserIds.clear()
})

async function createTestUser(data) {
  const { data: { user } } = await supabase.auth.signUp(data)
  testUserIds.add(user.id) // Track for cleanup
  return user
}
```

## Common Mistakes

### Using real client without cleanup

```typescript
// BAD - Leaves users in auth.users table
test('creates user', async () => {
  await supabase.auth.signUp({ email: 'test@example.com', password: '123' })
  // No cleanup!
})

// GOOD - Cleans up after test
const adminClient = createClient(URL, SERVICE_ROLE_KEY)

afterEach(async () => {
  for (const userId of testUserIds) {
    await adminClient.auth.admin.deleteUser(userId)
  }
})
```

### Not testing RLS policies

```typescript
// BAD - Tests application logic but not database security
test('getCompanies returns companies', async () => {
  const companies = await getCompanies()
  expect(companies).toBeDefined()
})

// GOOD - Verifies RLS blocks cross-tenant access
test('RLS prevents unauthorized access', async () => {
  const user1Company = await createCompanyAs(user1, {})
  const result = await getCompanyAs(user2, user1Company.id)
  expect(result).toBeNull() // RLS blocked it
})
```

## TDD Cycle for Auth Features

1. **RED**: Write test for tenant isolation FIRST
2. **Verify RED**: Confirm test fails (users CAN access other tenant's data)
3. **GREEN**: Add RLS policy to block access
4. **Verify GREEN**: Test passes (users CANNOT access other tenant's data)
5. **REFACTOR**: Clean up policy, add comments

**Key Principle:** If you didn't see the test fail when RLS was missing, you don't know the test actually validates tenant isolation.
