# CI/CD for the Fabric project

How the warehouse code moves safely from development to production.

**Status:** this is the plan for the next phase; not yet set up in production.

## Workspaces

| Workspace | Used for | Who changes it |
|---|---|---|
| **Dev** | Building and testing new tables (the practice warehouse) | Developers |
| **Test** | Full pipeline run on a copy of production data, plus business sign-off | Deployment pipeline only |
| **Prod** | Daily scheduled pipeline that Power BI reads from | Deployment pipeline only |

Nobody edits Test or Prod by hand. Every change goes Dev → Test → Prod.

## Step 1: Git integration (Dev workspace)

1. Workspace settings → **Git integration** → connect to the GitHub (or Azure DevOps) repo and pick a branch, for example `dev`.
2. Every warehouse object (tables, views, procedures), pipeline and notebook is saved to the repo as files.
3. Work on a feature branch, open a pull request into `dev`, get it reviewed, then merge.
4. In the workspace, click **Update all** to pull merged changes in.

## Step 2: Checks before merging

A pull request should not be merged until:
- every new Silver table has its `01`–`05` files (check, create, load, DQ, run twice)
- the load ran twice in Dev with run 2 changing nothing
- every DQ test shows `failed_rows = 0` (or an agreed WARN)
- Gold checks pass (Gold cost = Silver cost, no orphan keys)

## Step 3: Deployment pipeline (Dev → Test → Prod)

1. Create a Fabric **deployment pipeline** with three stages linked to the three workspaces.
2. Click **Deploy** from Dev to Test. Fabric compares the items and shows what is new, changed or missing.
3. Use **deployment rules** so each stage points to its own connection (warehouse endpoint and Bronze lakehouse), without editing code.
4. Run the full pipeline in Test, compare the monthly totals with the source system (`05_validation`), and get sign-off.
5. Deploy Test → Prod. Schedule the Prod pipeline after the source extract finishes.

## Step 4: Rollback

- Code: revert the merge in Git and redeploy the previous version.
- Data: Silver loads are idempotent, so re-running the previous version's load rebuilds the tables. Gold tables are only swapped in after the Gold check passes (`04_gold_tables_for_direct_lake`), so a failed refresh leaves the old tables in place.

## Branch naming

```
main            = what is in Prod
dev             = what is in Dev
feature/<table> = one new Silver table or change, e.g. feature/silver-project
```
