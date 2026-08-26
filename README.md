# Scale Up Recruitment Application Hub

An operations-first recruitment CRM for centralized application handling, candidate ownership, communication SLAs, controlled interviews and offers, secure document collection, and vacancy closure.

## Current MVP

- Operational dashboard and SLA alerts
- Searchable, filterable centralized application inbox
- Primary-owner visibility and contact conflict warning
- Mandatory next-action dates
- Message-first calling workflow with gated call action
- Responsive desktop/mobile layout
- Supabase-backed workflows for referrals, interviews, communications, active pool, offers, onboarding, tasks, reports and templates
- Sales requisition handoff and vacancy records with attached JD links
- Linked internal comments and live record refresh
- Archive and restore workflow with a 30-day recycle bin
- Demo-only automatic purge after the recovery period
- CSV candidate export and live KPI calculations
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
2. Complete dedicated forms for applications, candidates and requisitions
3. Automatic external acknowledgments and email delivery
4. Calendar delivery after interview buddy approval
5. Confidential offer generation and electronic signature
6. Candidate-facing verified status page
7. Production retention policy, backups and live-data approval

## Demo data retention

All current sample records are synthetic and marked `is_demo = true`. Archive actions set a
30-day recovery deadline. A daily Supabase Cron job permanently removes only expired demo
records; it cannot purge future live records. The schema is documented in
`supabase/migrations/20260827010000_demo_workflow_persistence.sql`.
