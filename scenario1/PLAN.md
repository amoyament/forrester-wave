# Forrester Wave Demo - Scenario 1: Developer Requests a Full-Stack Environment

## Context

Forrester Wave Infrastructure Automation Platforms Q4 2026 evaluation. Demo day: Sep 8, 2026. Scenario 1 is a 10-minute live demo led by Aubrey Trotter showing the Ansible Automation Portal (built on Red Hat Developer Hub / Backstage). The portal syncs AAP job templates into a self-service catalog where developers can browse, configure, and launch automation through guided forms with built-in governance.

The Forrester requirements for this scenario: **Service catalog, Blueprints/Templates, Controls & policy enforcement, Approval process.**

The approval process uses a real AAP workflow template with an approval node. A wrapper job template launches the workflow with `wait: true`, so the portal stays "in progress" while approval is pending. Once approved in AAP, the workflow continues, provisioning runs, and output (connection info) appears in the portal step logs.

**No portal code changes are needed.** Everything is configured via AAP job templates, workflow templates, surveys, RBAC, and organizations.

---

## Enterprise Story

**Acme Global** is a large enterprise with distributed teams, compliance requirements, and infrastructure skills shortages. Platform engineers publish governed automation templates. Developers consume them through self-service without needing infrastructure expertise.

---

## AAP Setup Required

### Two Organizations
1. **"Platform Engineering"** - owns compute/environment templates
2. **"Network Operations"** - owns network templates

### Two User Personas

| Persona | Role | Sees Templates | Portal Role |
|---------|------|----------------|-------------|
| Developer | AAP Execute on templates 1 & 3 only | 2 templates | portal-users |
| Ops Engineer | AAP Superuser or Execute on all | 4 templates + admin controls | aap-admins |

### Four Job Templates (all with `survey_enabled: true`)

**Template 1: "Provision Full-Stack Dev Environment"** (Platform Engineering org)
- Labels: `cloud`, `aws`, `provisioning`, `dev-environment`
- Survey:
  - `environment_name` - text, required
  - `instance_size` - multiplechoice: `t3.small | t3.medium | t3.large`, default `t3.medium`
  - `region` - multiplechoice: `us-east-1 | us-west-2 | eu-west-1`, default `us-east-1`
  - `ttl_hours` - integer, min=1, max=72, default=8 ("Environment auto-destroyed after this period")
  - `database_engine` - multiplechoice: `postgresql | mysql | none`, default `postgresql`
  - `enable_monitoring` - multiplechoice: `yes | no`, default `yes`
- Underlying playbook: wrapper that launches a workflow template with approval node (`wait: true`). Workflow structure: **Approval Node** > **Provisioning Job Template** (mock, outputs URL + connectivity info via debug tasks). See `scenario1/` directory in this repo for playbooks.

**Template 2: "Provision Production Environment"** (Platform Engineering org)
- Labels: `cloud`, `aws`, `provisioning`, `production`, `requires-approval`
- Survey (tighter constraints than dev):
  - `environment_name` - text, required
  - `instance_size` - multiplechoice: `m5.large | m5.xlarge | m5.2xlarge` (production-grade minimum)
  - `region` - multiplechoice: `us-east-1 | us-west-2` (US-only for compliance)
  - `ttl_hours` - integer, min=24, max=2160 (90 days), default=720
  - `ha_enabled` - multiplechoice: `yes | no`, default `yes`
  - `compliance_scan` - multiplechoice: `stig | cis | pci-dss`, default `stig`
- **Jordan does NOT have Execute access** - this template is invisible to developers

**Template 3: "Decommission Environment"** (Platform Engineering org)
- Labels: `cloud`, `aws`, `decommission`
- Survey: `environment_name` - text, required

**Template 4: "Request Network Segment"** (Network Operations org)
- Labels: `network`, `provisioning`
- Survey:
  - `project_name` - text, required
  - `cidr_size` - multiplechoice: `/28 | /26 | /24`, default `/26`
  - `zone` - multiplechoice: `dmz | internal | management`, default `internal`

### Portal Config
```yaml
catalog:
  providers:
    aap:
      cloud:
        baseUrl: https://your-aap-instance
        organizations:
          - platform engineering
          - network operations
        surveyEnabled: true
```

---

## 10-Minute Demo Script

**Story arc**: A developer requests and provisions a full-stack environment through self-service. The demo follows this single journey end-to-end, with a brief sidebar showing how RBAC customizes the portal for different roles.

---

### Beat 1 | 0:00-1:00 | Portal Intro + Developer Login

**Story**: "A developer at Acme Global needs a full-stack environment for a new microservice. Instead of filing a ticket and waiting days, they go to the Automation Portal, our self-service platform built on Red Hat Developer Hub."

**Do**: Log in as the **developer** via AAP SSO. Portal loads `/self-service/catalog`.

**Forrester**: Setup / Platform Architecture context

---

### Beat 2 | 1:00-2:30 | Service Catalog

**Story**: "The portal shows only the templates this developer's team has been approved for. They see two templates: one to provision a dev environment and one to decommission it. Production provisioning, network requests, those belong to other teams and aren't visible here. We'll show that in a moment."

**Do**:
- Show catalog with 2 WizardCards visible
- Search/filter demo (search "Provision", show tags: `cloud`, `aws`)
- Click template title to show detail view (description, owner: "Platform Engineering", tags)

**Forrester**: **Service Catalog** (browsable, searchable, categorized) + **Controls & Policy** (RBAC filtering)

---

### Beat 3 | 2:30-4:30 | Launch Wizard + Governance Guardrails

**Story**: "The developer clicks Start and gets a guided form. These aren't free-text fields. The platform team has defined exactly what's available and what guardrails apply."

**Do**:
- Click **"Start"** on "Provision Full-Stack Dev Environment"
- Walk through survey fields, emphasizing governance:
  - **Instance Size**: dropdown with 3 options. "No p4d.24xlarge GPU instances. Only approved, cost-effective sizes."
  - **Region**: dropdown with 3 approved regions. "Only compliance-approved geographies."
  - **TTL (key moment)**: type `200`, show validation error (max=72). "Cost control. Environment auto-destroys after TTL. Dev environments capped at 72 hours."
  - **Database Engine**: dropdown (postgresql/mysql/none)
  - **Monitoring**: yes/no

**Forrester**: **Blueprints/Templates** (guided wizard) + **Controls & Policy Enforcement** (financial limits, scope restrictions, duration caps, infra constraints)

---

### Beat 4 | 4:30-6:30 | Review, Approval, Execute

**Story**: "Before anything runs, the developer reviews every parameter. Now watch what happens when they submit."

**Do**:
- Show **Review step** (summary table of all parameters)
- Click **Create** to launch
- Portal shows "Waiting for result..." in step logs
- Step logs show: "Workflow job launched. Pending manager approval."
- **Flip to AAP** (second tab, pre-opened to workflow jobs view)
  - Show the workflow visualization with the approval node highlighted/waiting
  - "This request is now pending approval from a manager. The automation platform enforces this gate before any infrastructure is provisioned."
  - **Approve the request** in AAP
  - Show the workflow continue past the approval node into the provisioning job
- **Flip back to portal**
  - Step logs update with provisioning output as it runs
  - Job completes, connection info appears in logs (URL, SSH, database endpoint)

**Story (while approving)**: "We use layered governance. First, RBAC controls who can even see this template. Second, survey constraints bound every parameter. And third, for provisioning requests, an approval workflow gates execution. The manager sees what was requested and approves or denies before anything is provisioned."

**Forrester**: **Approval Process** (live approval workflow) + **Blueprints/Templates** (execution + output) + **Controls & Policy** (multi-layer governance)

---

### Beat 5 | 6:30-7:00 | Environment Ready

**Story**: "The environment is up. URL, connectivity info, database endpoint, all in the step logs. What used to be a multi-day ticket with manual approvals over email is now a governed, auditable, self-service flow."

**Do**: Highlight connection info in the step logs output.

**Forrester**: **Blueprints/Templates** (output, end-to-end completion)

---

### Beat 6 | 7:00-8:15 | RBAC Sidebar: Different Role, Different View

**Story**: "I mentioned that this developer can't see production templates. Let me prove that. Here's the same portal, same URL, logged in as an ops engineer on a different team."

**Do**:
- Switch to second browser profile (pre-logged-in as **ops engineer**)
- Show catalog with **4 WizardCards** vs developer's 2
- Point out what's different:
  - "Production provisioning template, not visible to the developer"
  - "Network operations templates from a different org"
  - **"Add Template"** and **"Sync Now"** buttons (admin-only)
- Click **"Start"** on "Provision Production Environment" to briefly show tighter survey constraints:
  - Instance sizes start at m5.large (vs dev's t3)
  - US-only regions (vs dev's 3 including EU)
  - Mandatory compliance scan (not present in dev template)
- **Do not launch.** Point made, move on.

**Forrester**: **Service Catalog** (role-differentiated) + **Controls & Policy** (RBAC, policy tiering across risk levels) + **Approval Process** (separation of duties)

---

### Beat 7 | 8:15-9:15 | Audit Trail

**Story**: "Everything through the portal is tracked. Who ran what, when, with what parameters, and the outcome. Full audit trail for compliance."

**Do**:
- Click **"History"** in sidebar
- Show TaskList with the developer's completed task
- Click into it: show task owner, template used, parameters submitted, execution status, timestamp

**Forrester**: **Controls & Policy** (auditability, compliance reporting)

---

### Beat 8 | 9:15-10:00 | Wrap

**Story**: "One portal, governed self-service for every team. Developers provision what they need in minutes. Different roles see different templates with different constraints. Every parameter is bounded by policy. Every action is auditable. Self-service that scales without sacrificing governance."

**Forrester**: All four requirements summarized

---

### Beat Summary Table

| Beat | What Happens | Templates Shown | Templates Launched | Forrester Requirement |
|------|-------------|----------------|-------------------|----------------------|
| 1 | Login as developer | - | - | Setup |
| 2 | Browse catalog (2 cards) | Dev Env, Decommission | - | Service Catalog, Controls |
| 3 | Launch wizard + guardrails | Dev Env (survey) | - | Blueprints, Controls |
| 4 | Review + approve + execute | Dev Env | **Dev Env (live)** | Approval, Blueprints, Controls |
| 5 | Output shown | - | - | Blueprints |
| 6 | RBAC sidebar (ops login) | All 4 visible, Prod survey | - | Service Catalog, Controls, Approval |
| 7 | Audit trail | - | - | Controls |
| 8 | Wrap | - | - | All |

---

## Infrastructure

- **Portal**: https://100.58.32.132 (running)
- **AAP**: 52.21.70.135 (running)
- **Needed**: Create 4 job templates with surveys, mock playbooks, 2 orgs, 2 users with RBAC

---

## Pre-Demo Checklist

1. **Create 2 orgs, 2 users** with RBAC assignments as specified
2. **Create workflow template** "Provision Full-Stack Dev Environment - Approved" with approval node + provisioning job
3. **Create wrapper job template** that launches the workflow (uses `scenario1/launch_provision_workflow.yml`)
4. **Create provisioning mock playbook** job template (uses `scenario1/provision_fullstack_env.yml`)
5. **Create remaining 3 job templates** (prod, decommission, network) with surveys as specified
6. **Pre-sync templates** to the portal catalog (don't rely on sync during demo)
7. **Pre-run the full approval flow** at least once to verify end-to-end and have a task in History
8. **Set up 2 browser profiles** (Chrome + Incognito, or Chrome + Firefox) for quick persona switching
9. **Pre-login ops engineer** in second browser so switch is instant
10. **Test approval flow timing**: submit in portal, approve in AAP, verify output appears in portal logs
11. **Verify TTL validation error** renders correctly when typing a value > 72
12. **Pre-open AAP workflow jobs page** in a tab for quick flip during approval beat

## Verification

- Log in as developer: should see exactly 2 templates, no admin controls
- Log in as ops engineer: should see 4 templates + "Add Template" + "Sync Now"
- Launch Template 1 as developer: form should show all survey fields with constraints
- Type 200 in TTL field: should show validation error
- After submit, portal shows "Waiting for result" until workflow is approved
- Approve in AAP: workflow continues, provisioning runs, connection info appears in portal step logs
- History page shows completed task with all parameters
