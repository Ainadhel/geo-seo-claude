---
name: geo-update
description: Pull the latest GEO-SEO skill updates from the upstream repository. Compares installed files against the latest release, shows what changed, and updates all skills, agents, scripts, and schema templates in place.
---

# GEO-SEO Update Skill

## Purpose

Updates the locally installed GEO-SEO skills, agents, scripts, and schema templates to the latest version from the upstream repository. Shows a summary of what changed before and after the update.

---

## Update Workflow

### Step 1: Determine the Working Folder Layout

This fork runs from a local clone, not from an install into `~/.claude/`. The toolkit lives at
these paths, all relative to the repository root:

| Component | Path |
|-----------|------|
| Main skill | `.agents/skills/geo/` |
| Sub-skills | `.agents/skills/geo-*/` |
| Agents | `agents/geo-*.md` |
| Scripts | `scripts/` |
| Schema templates | `schema/` |
| Report templates | `templates/` |
| Virtual environment | `.venv/` |
| Prospect data | `.data/geo-prospects/` |

Verify the working folder by checking that `.agents/skills/geo/SKILL.md` exists. If it does not,
tell the user this is not a geo-seo-claude checkout and stop.

**Upstream layout differs.** The upstream repository still uses `skills/` for the sub-skills and
`geo/` for the orchestrator. A raw copy from upstream will therefore land in the wrong place and
will resurrect the old layout. Apply the mapping below on every update. See
`docs/PORTAGE-OPENCODE.md` for the full reconciliation procedure.

| Upstream | This working folder |
|----------|---------------------|
| `geo/` | `.agents/skills/geo/` |
| `skills/geo-*/` | `.agents/skills/geo-*/` |

### Step 2: Clone Latest from Upstream

```bash
TEMP_DIR=$(mktemp -d)
git clone --depth 1 https://github.com/zubair-trabzada/geo-seo-claude.git "$TEMP_DIR/repo"
```

If the clone fails, report the error and stop. Do not modify any file in the working folder.

### Step 3: Compare Working Folder vs Latest

Before copying files, generate a diff summary so the user knows what will change:

1. Compare each component against the cloned files, using `diff -rq` between the upstream source
   path and its mapped destination path (`$SOURCE_DIR/geo` against `.agents/skills/geo`, and
   `$SOURCE_DIR/skills/<name>` against `.agents/skills/<name>`).
2. Categorise changes as:
   - **New files** — exist in upstream but not locally
   - **Modified files** — exist in both but differ
   - **Removed files** — exist locally but not in upstream (these are NOT deleted automatically)
3. Present the summary to the user.

### Step 4: Apply Updates

Copy files from the cloned repo over the mapped destinations, never over the upstream paths:

```bash
SOURCE_DIR="$TEMP_DIR/repo"
DEST_DIR="$(pwd)"

# Main skill: upstream geo/ -> .agents/skills/geo/
mkdir -p "$DEST_DIR/.agents/skills/geo"
cp -r "$SOURCE_DIR/geo/"* "$DEST_DIR/.agents/skills/geo/"

# Sub-skills: upstream skills/ -> .agents/skills/
for skill_dir in "$SOURCE_DIR/skills"/*/; do
    skill_name=$(basename "$skill_dir")
    mkdir -p "$DEST_DIR/.agents/skills/${skill_name}"
    cp -r "$skill_dir"* "$DEST_DIR/.agents/skills/${skill_name}/"
done

# Agents
for agent_file in "$SOURCE_DIR/agents/"*.md; do
    cp "$agent_file" "$DEST_DIR/agents/"
done

# Scripts
if [ -d "$SOURCE_DIR/scripts" ]; then
    cp -r "$SOURCE_DIR/scripts/"* "$DEST_DIR/scripts/"
    chmod +x "$DEST_DIR/scripts/"*.py 2>/dev/null || true
fi

# Schema templates
if [ -d "$SOURCE_DIR/schema" ]; then
    cp -r "$SOURCE_DIR/schema/"* "$DEST_DIR/schema/"
fi

# Report templates
if [ -d "$SOURCE_DIR/templates" ]; then
    cp -r "$SOURCE_DIR/templates/"* "$DEST_DIR/templates/"
fi
```

After copying, re-apply the port rewrites to the files that were just overwritten, otherwise the
updated files will reintroduce `~/.claude` paths and the `allowed-tools` frontmatter field:

- `python3 ~/.claude/skills/geo/scripts/` becomes `.venv/Scripts/python.exe scripts/` on Windows,
  `.venv/bin/python3 scripts/` on POSIX
- `~/.claude/skills/geo/templates/` becomes `templates/`
- `~/.geo-prospects/` becomes `.data/geo-prospects/`
- the `allowed-tools:` key is removed from every `SKILL.md` frontmatter

### Step 5: Update Python Dependencies

If `requirements.txt` exists in the upstream repo and differs from the working folder version:

```powershell
.\.venv\Scripts\python.exe -m pip install -r requirements.txt --quiet
```

Report any failures but do not treat them as fatal.

### Step 6: Clean Up

```bash
rm -rf "$TEMP_DIR"
```

### Step 7: Report Results

Present a summary:

```
GEO-SEO Update Complete
=======================
New files:      [count]
Modified files: [count]
Unchanged:      [count]
Removed upstream (kept locally): [count]

Dependencies: [updated / unchanged / failed]
```

If there were removed files upstream, list them and suggest the user review whether to delete them manually.

---

## Important Notes

- **Never delete locally customised files** that no longer exist upstream. The user may have changed them. List them and let the user decide.
- **Never write outside the working folder.** No copy may land in `~/.claude/`, in the user profile, or in any other project. The path mapping in Step 1 is what guarantees this.
- **Re-apply the port rewrites after every copy** (end of Step 4). A verbatim upstream file reintroduces `~/.claude` paths and the `allowed-tools` frontmatter field, both of which are wrong here.
- **If already up to date** (no diff), report that and skip the copy step.
- **Restart notice:** Remind the user that skill changes take effect in new agent sessions. They should restart their session to pick up the updated skills.
