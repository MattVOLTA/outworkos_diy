# Table Dependency Graph

This reference shows foreign key relationships that must be respected during cleanup.

## Dependency Tree

```
auth.users
├── public.users (1:1, auto-sync via trigger)
│   ├── user_sessions
│   │   └── (user_id → users.id)
│   ├── organization_members
│   │   └── (user_id → users.id)
│   ├── report_sessions
│   │   └── (created_by → users.id)
│   ├── reports
│   │   └── (created_by → users.id)
│   ├── forms
│   │   └── (created_by → users.id)
│   └── fireflies_staged_meetings
│       └── (excluded_by_user_id → users.id)

tenants (organizations)
├── organization_members
│   └── (organization_id → tenants.id)
├── tenant_config
│   └── (tenant_id → tenants.id)
├── companies
│   └── (tenant_id → tenants.id)
├── contacts
│   └── (tenant_id → tenants.id)
├── programs
│   └── (tenant_id → tenants.id)
├── forms
│   └── (tenant_id → tenants.id)
├── report_sessions
│   └── (tenant_id → tenants.id)
├── reports
│   └── (tenant_id → tenants.id)
├── milestone_tracks
│   └── (tenant_id → tenants.id)
├── milestone_definitions
│   └── (tenant_id → tenants.id)
└── fireflies_staged_meetings
    └── (tenant_id → tenants.id)

companies
├── contacts
│   └── (company_id → companies.id)
├── interactions
│   └── (company_id → companies.id)
├── program_enrollments
│   └── (company_id → companies.id)
├── company_milestones
│   └── (company_id → companies.id)
├── interaction_companies
│   └── (company_id → companies.id)
└── form_submissions
    └── (company_id → companies.id)

contacts
├── contact_emails
│   └── (contact_id → contacts.id)
└── interaction_contacts
    └── (contact_id → contacts.id)

interactions
├── meeting_transcripts
│   └── (interaction_id → interactions.id)
├── interaction_contacts
│   └── (interaction_id → interactions.id)
├── interaction_companies
│   └── (interaction_id → interactions.id)
└── fireflies_staged_meetings
    └── (imported_to_interaction_id → interactions.id)

meeting_transcripts
└── meeting_speakers
    └── (transcript_id → meeting_transcripts.id)

report_sessions
└── reports
    └── (session_id → report_sessions.id)

programs
├── program_enrollments
│   └── (program_id → programs.id)
├── contacts (via primary_program_id)
│   └── (primary_program_id → programs.id)
└── milestone_tracks
    └── (program_id → programs.id)

milestone_tracks
└── milestone_definitions
    └── (track_id → milestone_tracks.id)

milestone_definitions
└── company_milestones
    └── (milestone_definition_id → milestone_definitions.id)

forms
└── form_submissions
    └── (form_id → forms.id)
```

## Safe Cleanup Order (Leaf to Root)

Execute deletes in this order:

```typescript
const CLEANUP_ORDER = [
  // Level 1: Deepest children (no dependencies)
  'meeting_speakers',
  'company_milestones',
  'form_submissions',
  'interaction_contacts',
  'interaction_companies',
  'contact_emails',
  'program_enrollments',

  // Level 2: Middle layer
  'meeting_transcripts',
  'fireflies_staged_meetings',
  'reports',

  // Level 3: Parent tables
  'interactions',
  'report_sessions',
  'milestone_definitions',
  'contacts',

  // Level 4: Core entities
  'companies',
  'forms',
  'milestone_tracks',
  'programs',

  // Level 5: Organization/User layer
  'organization_members',
  'user_sessions',
  'tenant_config',

  // Level 6: Root tables (rarely delete in tests)
  // 'tenants',  // Usually keep test tenants
  // 'users',    // Use auth.admin.deleteUser() instead
]
```

## Tables That Should NOT Be Cleaned

These tables contain system/seed data:

- `tenants` - Keep test tenants (Acme, Beta, Gamma)
- `users` - Use `auth.admin.deleteUser()` for test users
- `feature_flags` - System configuration
- `invitations` - Usually test via separate flows
