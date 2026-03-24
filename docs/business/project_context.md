# PROJECT_CONTEXT

## Project type

ERP application built with:

- Flutter (frontend)
- Supabase / PostgreSQL (backend)

The system manages the commercial lifecycle of engineering and automation projects.

---

# Main current scope

Current priority is to close the operational flow up to **adjudication** before expanding deeper into project execution and production.

Core business flow:

customers  
→ orders  
→ order_versions  
→ proposals  
→ adjudications  

---

# Product status

- CRM is one of the most mature modules.
- Budgeting / estimation is currently under active refactor.
- Proposal flow and adjudication alignment are key priorities.
- Backend schema must be treated as the real source of truth.

Future areas like project execution and production exist conceptually but are not yet the main focus.

---

# Core backend entities

The main entities driving the ERP workflow are:

orders  
order_versions  
proposals  
adjudications  

Supporting entities include:

customers  
contacts  
customer_sites  
order_budget_assignments  
workflow_phases  

These represent the lifecycle of a commercial opportunity.

---

# Backend rules

Source of truth:

supabase_schema.sql

Guidelines:

- Read operations may use direct queries.
- Write operations should use RPC / stored procedures whenever available.
- Never invent fields, tables, or relations not present in the schema.
- If there is any conflict between documentation and schema, the schema is correct.

---

# Flutter architecture

Typical project structure:

lib/
    core/
    features/
        crm/
        budgeting/
        proposals/
        adjudications/
    services/
    repositories/
    models/

General patterns:

- repository layer interacts with Supabase
- RPC functions are used for write operations
- models mirror backend entities
- features are separated by domain

---

# Coding rules for AI agents (Codex)

AI agents must follow these rules:

1. Do not scan the entire repository unless explicitly requested.

2. Prefer using these files as main context:
   - PROJECT_CONTEXT.md
   - actual_state.md
   - schema_summary.md

3. Preserve existing behaviour outside the requested scope.

4. Prefer focused, local changes over large refactors.

5. If a request is ambiguous, list assumptions before modifying code.

6. Always align Flutter code with the Supabase schema and RPC patterns.

7. Never invent backend fields or tables.

---

# Prompting policy

When generating prompts or executing tasks:

- use limited context
- restrict allowed files whenever possible
- avoid architectural rewrites unless explicitly requested
- prefer small iterative improvements
- ensure backend interactions respect schema and RPC patterns

---

# Recommended context priority

When working with AI tools or Codex:

1. PROJECT_CONTEXT.md
2. actual_state.md
3. schema_summary.md
4. overview.md
5. supabase_schema.sql (only when necessary)

The goal is to avoid loading large context unnecessarily.