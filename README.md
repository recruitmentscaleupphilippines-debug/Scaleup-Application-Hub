# Scale Up Recruitment Application Hub

An operations-first recruitment CRM for centralized application handling, candidate ownership, communication SLAs, controlled interviews and offers, secure document collection, and vacancy closure.

## Current MVP

- Operational dashboard and SLA alerts
- Searchable, filterable centralized application inbox
- Primary-owner visibility and contact conflict warning
- Mandatory next-action dates
- Message-first calling workflow with gated call action
- Responsive desktop/mobile layout
- Navigation architecture for all planned modules
- Live Supabase application reads with passwordless authentication
- RLS-protected internal CRM access

## Run locally

```bash
npm install
npm run dev
```

Open `http://localhost:3000`.

## Environment

Copy `.env.example` to `.env.local` and add the Supabase project URL and publishable key. Authenticated team members see live application data; an empty database displays clearly labeled demo rows for interface preview.

## Priority roadmap

1. Invite the initial administrator and configure approved email access
2. Applications/candidates/vacancies live CRUD forms
3. Automatic acknowledgments and SLA job processing
4. Vacancy closing workflow and checklists
5. Interview buddy review and calendar delivery
6. Confidential offer approvals and restricted compensation fields
7. Candidate-facing verified status page
