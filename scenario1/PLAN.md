# Forrester Wave Demo - Scenario 1: Developer Requests a Full-Stack Environment

## Context

Forrester Wave Infrastructure Automation Platforms Q4 2026 evaluation. Demo day: Sep 8, 2026. Scenario 1 is a live demo led by Aubrey Trotter on **Aubrey’s AAP and Portal instance**. The Ansible Automation Portal (built on Red Hat Developer Hub / Backstage) syncs AAP job templates into a self-service catalog. Developers browse, configure, and launch automation through guided forms with governance baked in.

Forrester requirements for this scenario:

- **Service catalog**
- **Blueprints / Templates**
- **Controls & policy enforcement** (financial, scope, infra, volume, duration)
- **Approval process**

The approval process is a real AAP workflow with an approval node. The portal job launches that workflow and waits (`wait: true` / poll until complete), so the portal stays in progress while approval is pending. Once approved in AAP, the workflow continues into provisioning. Output (instance URL/IP, SSH, DB endpoint, monitoring, auto-destroy) appears in the portal step logs. The developer then opens the live endpoint.

**No portal code changes are needed.** Everything is configured via AAP job templates, workflow templates, surveys, RBAC, and organizations.

---

## Language (Naveen)

Stay on platform-engineering language. Do not say admin.

| Say | Do not say |
|-----|------------|
| Platform engineer | Admin, AAP admin, ops engineer, sysadmin |
| Governed self-service | Unlimited self-service, ticket queue, click-ops |
| Guardrails / policy at the point of request | After-the-fact review, wiki policy |
| Templates / blueprints published by the platform team | Admin-created jobs, hidden automation |
| Identity-aware catalog | Admin vs user UI |
| Approval as a workflow gate | Email approval, ticket approval |

**Story in one line:** Platform engineers publish governed templates. Developers consume them through an identity-aware catalog. Policy is enforced in the form. Approval is a live workflow node, not a ticket.

Call out **who authored the template** (platform engineering) every time a developer starts a request. The portal is how developers consume platform-engineering work; it is not an admin console.

Policy is two layers. Name both. Use Forrester’s words verbatim: **financial, scope, infra, volume, duration**.

**Front-end (survey):** bounded fields in the portal form.
**Back-end (Policy-as-Code):** assert tasks at the top of the provisioning job. These still run if someone bypasses the portal and hits the API.

| Forrester word | Survey | Playbook task |
|----------------|--------|----------------|
| Scope & infra | Size + region dropdowns | `Policy: Validate Scope & Infra` |
| Financial | Closed instance sizes | `Policy: Verify Financial Budget` |
| Duration | TTL max 72, type 200 | `Policy: Enforce Duration limits` |
| Volume | Identity-aware catalog | `Policy: Check Volume Quotas` |

---

## Enterprise Story

**Acme Global** is a large enterprise with distributed teams, compliance requirements, and infrastructure skills shortages. **Platform engineers** publish governed automation templates. **Developers** consume them through self-service without needing infrastructure expertise.

---

## AAP Setup Required

### Two Organizations
1. **"Platform Engineering"** — owns compute/environment templates
2. **"Network Operations"** — owns network templates

### Two User Personas

| Persona | Role | Sees Templates | How to talk about it |
|---------|------|----------------|----------------------|
| Developer | AAP Execute on developer-facing templates only | Subset (e.g. Provision Full-Stack Dev Environment, Decommission) | Consumer of the catalog |
| Platform Engineer | Execute (and visibility) across the templates they publish | Broader catalog (dev + production + other platform templates) | Publisher of governed blueprints — **not** an admin |

Do not demo this as “admin controls.” If catalog-management actions are visible to the platform engineer, call them **platform-engineering capabilities** (publishing and operating templates), not administration.

### Job Template: "Provision Full-Stack Dev Environment" (Platform Engineering org)

- Labels: `cloud`, `aws`, `provisioning`, `dev-environment`
- Survey:
  - `environment_name` — text, required
  - `instance_size` — multiplechoice: `t3.small | t3.medium | t3.large`, default `t3.medium`
  - `region` — multiplechoice: `us-east-1 | us-west-2 | eu-west-1`, default `us-east-1`
  - `ttl_hours` — integer, min=1, max=72, default=8 ("Environment auto-destroyed after this period")
  - `database_engine` — multiplechoice: `postgresql | mysql | none`, default `postgresql`
  - `enable_monitoring` — multiplechoice: `yes | no`, default `yes`
- Underlying playbook: `provision_cloud_environment.yml` — launches an AAP workflow with an approval node, waits, then provisions for real (EC2 + optional RDS + CloudWatch). Workflow structure: **Approval Node** → **Provisioning continues**.

Additional catalog templates (production, decommission, network) exist so the two personas see **different populated catalogs**. They are for the intro contrast, not launched in this scenario.

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

## Demo Script (Aubrey’s AAP and Portal)

**Story arc:** Open on identity-aware catalogs (developer vs platform engineer), then follow one developer request end-to-end: catalog → governed form → live approval in AAP → provisioned environment the developer can log into.

Total on-script time: **~6 minutes**. Use leftover time to land the four Forrester requirements, not to add extra clicks.

---

### Beat 1 | 0:00–2:00 | Two users, two catalogs

**Shows:** Service catalog and controls

**Story:** "This is the Automation Portal. It is how developers consume work that **platform engineers** have already published. The catalog is identity-aware — different people see different templates, because policy starts before the form. This is not an admin console. It is governed self-service."

**Do:**
- Log in as the **developer**. Show their catalog (developer-facing templates only).
- Log in as the **platform engineer**. Show the broader catalog (the templates that team publishes, including ones developers never see).
- Call out the contrast: same portal, same URL, different populated templates. Volume and scope controls are RBAC, not a hidden menu.
- Switch back to the **developer** for the rest of the demo.

**Forrester:** **Service catalog** (browsable, identity-aware) + **Controls & policy** (RBAC / volume / who can request what)

---

### Beat 2 | 2:00–2:30 | Developer browses the catalog

**Shows:** Blueprints / templates

**Do:**
- As the developer, browse to **"Provision Full-Stack Dev Environment"**.
- Treat the card as the blueprint: name, owner (**Platform Engineering**), tags.
- Do not linger on search unless it helps the sentence. The point is: the developer is selecting a published template, not writing automation.

**Story:** "The developer is not designing infrastructure. They are selecting a blueprint the platform team already defined."

**Forrester:** **Blueprints / Templates**

---

### Beat 3 | 2:30–3:30 | Start — survey with live validation

**Shows:** Controls and policy enforcement

**Do:** Click **Start** on "Provision Full-Stack Dev Environment." Walk the form. Every field is a named control:

| Field | Type | Constraint to say out loud | Policy type |
|-------|------|----------------------------|-------------|
| Environment Name | free text, required | Named, required — no anonymous sprawl | Scope / volume |
| Instance Size | dropdown: t3.small, t3.medium, t3.large | **No other sizes available.** Cost-bounded. | Financial / infra |
| Region | dropdown: us-east-1, us-west-2, eu-west-1 | **Only approved regions.** | Scope |
| TTL in hours | integer, min 1, max 72 | Type **200** to show the live validation error. Dev environments cannot outlive the cap. | Duration / financial |
| Database Engine | dropdown: postgresql, mysql, none | Bounded infra choices | Infra |
| Enable Monitoring | dropdown: yes, no | Observability is an explicit, governed option | Infra |

**Story:** "Policy is at the point of request. Financial limits, geographic scope, duration, and infrastructure choices are in the form. The developer cannot ask for what the platform team has not approved."

**Forrester:** **Controls & policy enforcement** (financial, scope, infra, duration) + **Blueprints / Templates** (guided request)

---

### Beat 4 | 3:30–4:00 | Create — Policy-as-Code before approval

**Shows:** Controls & policy enforcement in code (financial, scope, infra, volume, duration) + Blueprints (execution starts)

**Do:**
- Click **Create**.
- Stay on the portal step logs (or click the live AAP job). The **first** tasks in `provision_cloud_environment.yml` are the four policy asserts. They run **before** anything is sent for approval.
- After they pass, the playbook launches the approval workflow and waits.

**Say (while the four tasks turn green):**

> As the provisioning job starts, you'll see it doesn't just blindly build infrastructure. The first thing AAP does is execute a series of backend Policy-as-Code checks — before this even goes to approval. You can see them passing in the log right now: it's validating the **Scope** and **Infra** to ensure this instance size is allowed in this region. It checks the **Financial** budget, confirms the 72-hour **Duration** limit, and verifies Aubrey's active **Volume** quota.

Expected live output (all `ok`):

```
TASK [Policy: Validate Scope & Infra]
ok: ... Passes: Confirms t3.medium and us-east-1 are approved for Dev scope

TASK [Policy: Verify Financial Budget]
ok: ... Passes: Calculates run cost is under the $500/mo self-service limit

TASK [Policy: Enforce Duration limits]
ok: ... Passes: Confirms TTL is <= 72 hours

TASK [Policy: Check Volume Quotas]
ok: ... Passes: Confirms user has < 3 active environments
```

- Then the log shows **Sending request for approval**. Nothing is provisioned yet.

**Forrester:** **Controls & policy enforcement** (checklist words on screen) + **Blueprints / Templates** (execution)

---

### Beat 5 | 4:00–5:00 | Flip to AAP — approve — show the blocked run

**Shows:** Approval process + volume policy fail (never reached approval)

**Do:**
- Flip to AAP. Show the **workflow visualization** with the **approval node waiting**.
- "Policy already passed. Now this is a workflow gate, not a ticket. The platform team encoded approval into the blueprint."
- **Approve.** Workflow continues; flip back to the portal so provisioning output keeps streaming.
- Open a **second tab** (or Jobs list) on the **pre-run failed job**.

**Say:**

> Because this is enforced in the code, it protects us even if someone bypasses the UI portal via an API. For example, if we look at this run from yesterday, a developer requested a valid environment, but the playbook halted at the Volume check — before approval was even requested. The developer already had three active environments running, so our FinOps policy blocked the build to prevent cloud sprawl.

**Forrester:** **Approval process** + **Controls & policy enforcement** (volume / fail-closed)

---

### Beat 6 | 5:00–6:00 | Environment ready — developer accesses it

**Shows:** Blueprints / Templates (output, end-to-end completion)

**Do:** When provisioning completes, take the developer to the live environment. Call out output in the portal logs, then **log into the endpoint**.

Output to hit verbally and on screen:

- **Instance URL / IP**
- **SSH access**
- **DB endpoint**
- **Monitoring**
- **Auto-destroy schedule** (TTL)

Open the instance URL and show the landing page (or SSH) so it is clearly a real environment, not a mock log line.

**Story:** "The developer requested a full-stack environment through the catalog, stayed inside policy, passed a live approval gate, and is now on the endpoint. What used to be a multi-day ticket is governed self-service with an auto-destroy clock."

**Forrester:** **Blueprints / Templates** (output) — lands all four requirements as a single developer journey

---

### Optional close (if time remains)

Do not introduce new clicks. Restate the four requirements in Naveen language:

"Identity-aware **service catalog**. **Blueprints** published by platform engineers. **Controls** on spend, region, duration, and infra at request time. **Approval** as a live workflow node. The developer is in the environment; the platform team never became a ticket desk."

---

### Beat Summary

| Beat | Time | What happens | Forrester requirement |
|------|------|----------------|----------------------|
| 1 | 2:00 | Two logins: developer vs **platform engineer**, different catalogs | Service catalog, Controls |
| 2 | 0:30 | Developer selects "Provision Full-Stack Dev Environment" | Blueprints / Templates |
| 3 | 1:00 | Survey + TTL validation error (type 200) | Controls (financial, scope, infra, duration) |
| 4 | 0:30 | Create; four policy tasks pass **before** approval is sent | Controls (financial/scope/infra/volume/duration) |
| 5 | 1:00 | Approve in AAP; show yesterday’s volume-fail job (never reached approval) | Approval, Controls |
| 6 | 1:00 | Live env: URL/IP, SSH, DB, monitoring, auto-destroy | Blueprints (output) |

---

## Infrastructure

- **Portal:** Aubrey’s instance (https://100.58.32.132)
- **AAP:** Aubrey’s instance (52.21.70.135)
- **Playbook:** `provision_cloud_environment.yml` — Policy-as-Code first, then approval workflow, then EC2 / RDS / CloudWatch
- **Post-approval job:** `do_provision.yml` — stub after the approval node
- **Decommission:** `decommission_environment.yml` (catalog contrast / cleanup, not a scenario-1 launch)

### How to get one failed job and one passing job

Same playbook (`provision_cloud_environment.yml`). Extra var on the **job template**, then take it off.

**1. Failed job (before demo day)**

AAP job template → Extra Variables:

```yaml
policy_scenario: fail_volume
```

Launch from the portal. Job dies at `Policy: Check Volume Quotas`. Leave it in **Jobs**.

**2. Passing job (live demo)**

Remove `policy_scenario` from the template Extra Variables. Save. Portal **Create** again — all four tasks PASS, then approval.

---

## Pre-Demo Checklist

1. Confirm **developer** and **platform engineer** accounts show **different catalogs** on the same portal URL
2. Pre-login both users in two browser profiles so the 2-minute intro is a switch, not a typing exercise
3. Confirm the provision template survey matches the field table (sizes, regions, TTL 1–72, db, monitoring)
4. Confirm **TTL 200** shows a live validation error
5. Confirm the job launches the **approval workflow** and the portal stays in progress until approve
6. Pre-open AAP on the workflow jobs / visualization view for the flip
7. Sync the AAP project so `provision_cloud_environment.yml` is current
8. Put `policy_scenario: fail_volume` on the job template extra vars, launch from the portal, leave the failed job in Jobs, **then delete that extra var**
9. Rehearse: submit in portal → four policy tasks PASS → approval is sent → approve in AAP → tab to failed volume job → instance URL is reachable
10. Confirm post-provision output includes URL/IP, SSH, DB endpoint, monitoring, auto-destroy
11. Have a fallback env already up in case live provision overruns
12. Say **platform engineer** out loud in Beat 1; never say admin
13. In Beat 4, say **financial, scope, infra, volume, duration** while the tasks are on screen — before the approval flip

## Verification

- Developer login: developer-facing templates only
- Platform engineer login: broader catalog (different templates populated)
- Launch "Provision Full-Stack Dev Environment": all six survey fields with constraints
- Type 200 in TTL: validation error
- After Create: four Policy-as-Code tasks `ok` in the provision job, **then** approval is requested
- Approve in AAP: workflow continues; portal logs show provisioning output
- Pre-run volume-fail job is failed at `Policy: Check Volume Quotas` (3 active environments) and never sent for approval
- Developer can open instance URL/IP and use SSH / DB / monitoring as shown in the logs
- Auto-destroy / TTL is visible in the output
