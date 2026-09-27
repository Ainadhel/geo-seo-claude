# Portage OpenCode, ce qui a changé et comment réconcilier l'amont

Ce document est le garde-fou du portage. Il existe pour une seule raison : empêcher la dérive de
l'amont de revenir en silence. Sans lui, le premier `git pull` ou le premier copier-coller depuis
`zubair-trabzada/geo-seo-claude` réintroduit `~/.claude`, `skills/` et `allowed-tools`, et rien ne
signale l'erreur.

Amont de référence : `zubair-trabzada/geo-seo-claude`, commit `22d4a67`, MIT.
Fork : `Ainadhel/geo-seo-claude`. Branche de portage : `port-opencode`.

L'œuvre de référence, c'est-à-dire la source dont tout le reste dérive, est l'amont. En cas de
désaccord sur une intention plutôt que sur un fait, c'est l'amont qui tranche.

---

## 1. Pourquoi le portage existe

L'amont est un écosystème **Claude Code** : `install.sh` copie `geo/`, `skills/` et `agents/` dans
`~/.claude/`, crée un venv sous `~/.claude/skills/geo/.venv`, réécrit les shebangs des scripts pour
les pointer sur ce venv, puis réécrit les fichiers Markdown pour que les commandes qu'ils contiennent
pointent vers `~/.claude/skills/geo/...`.

Ici, le runtime est **OpenCode** sur **Windows**. La convention de skills est
`.agents/skills/<nom>/SKILL.md`, avec un frontmatter `name` + `description`. Conséquence : la copie
n'est plus nécessaire, et surtout plus souhaitable, parce qu'elle créait deux sources de vérité.

Le portage porte donc **la structure et les chemins**, pas le contenu métier. Les scores, les
pondérations, les checklists de crawlers et les règles `llms.txt` sont intacts.

Deux points de méthode ont été tenus :

- **Aucune réécriture de fond.** L'œuvre des skills amont est reprise telle quelle, aux chemins près.
  Les tirets cadratins déjà présents dans le corpus amont (au moins 300) n'ont pas été remplacés :
  ce serait une divergence de contenu sans rapport avec le portage, et elle rendrait la
  réconciliation plus coûteuse que le gain. Seuls les fichiers écrits pour ce portage en sont
  exempts, et ils n'en contiennent aucun.
- **L'encodage est vérifié, pas supposé.** Chaque fichier produit ou réécrit a été relu en UTF-8
  sans BOM, et les diacritiques français ont été contrôlés un par un après écriture. C'est aussi
  le piège connu de cette machine : PowerShell ne doit jamais écrire un fichier ici, `Set-Content`,
  `Out-File` et `>` corompent les accents de façon silencieuse.

### 1.1 Conventions de rédaction appliquées

Français accentué complet, y compris les diacritiques que la plupart des rédacteurs laissent :
voilà une liste de contrôle, aiguë, âpre, maïs, capharnaüm, c'est dû, l'œuvre est sûre, où l'aiguë
limite, l'idée. Le fichier a été relu après écriture pour confirmer que chacun est bien là.

Règle appliquée : **pas de tiret cadratin** dans ce qui est écrit ici, parce que le fork est public.
La virgule ou la reformulation font le même travail sans introduire un caractère que le
terminal, le PDF et le grep ne traitent pas de la même façon.

---

## 2. Ce qui a changé, fichier par fichier

### 2.1 Arborescence

| Amont | Ici | Nature du changement |
|---|---|---|
| `skills/geo-*/SKILL.md` (15) | `.agents/skills/geo-*/SKILL.md` | `git mv`, contenu inchangé hors chemins et frontmatter |
| `geo/SKILL.md` | `.agents/skills/geo/SKILL.md` | `git mv`, l'orchestrateur devient un skill comme les autres |
| `hooks/` | *inexistant en amont* | aucune référence ne subsiste |
| `.venv` sous `~/.claude/skills/geo/` | `.venv/` (racine du working folder) | venv local, `Scripts/python.exe` sous Windows |
| `~/.geo-prospects/` | `.data/geo-prospects/` | état prospect local et gitignoré |

Aucun doublon ne subsiste à l'ancien emplacement : `skills/` et `geo/` n'existent plus. Vérifiable
par `git ls-files skills geo`, qui doit ne rien renvoyer.

### 2.2 Chemins d'exécution

Dans les 16 `SKILL.md` et les 5 `agents/*.md`, toute invocation de script a changé de forme :

| Amont | Ici (Windows) |
|---|---|
| `python3 ~/.claude/skills/geo/scripts/X.py` | `.venv/Scripts/python.exe scripts/X.py` |
| `python3 -c "..."` | `.venv/Scripts/python.exe -c "..."` |
| `python3 -m X` | `.venv/Scripts/python.exe -m X` |
| `~/.claude/skills/geo/templates/` | `templates/` |

Sur macOS et Linux, seule la forme de l'interpréteur change (`.venv/bin/python3`). Les chemins de
scripts restent identiques.

### 2.3 État prospect

`~/.geo-prospects/` devient `.data/geo-prospects/`. Les skills `geo-prospect`, `geo-proposal`,
`geo-compare` et `geo-update` visent ce chemin. Les deux scripts qui le lisaient en dur ont été
modifiés sur trois lignes chacun :

- `scripts/crm_dashboard.py`
- `scripts/webapp/app.py`

Ils lisent désormais `GEO_PROSPECTS_DIR` si la variable est définie, sinon
`<racine du dépôt>/.data/geo-prospects`. Le comportement métier est inchangé, seule la résolution
du chemin l'est.

### 2.4 Frontmatter

- `allowed-tools:` retiré des 21 fichiers migrés (16 skills + 5 agents). C'est une convention Claude
  Code : un champ inconnu est pire qu'un champ absent.
- Le titre de `.agents/skills/geo/SKILL.md` annonçait « Claude Code Skill (February 2026) ». Il
  annonce maintenant « GEO-SEO Analysis Tool, OpenCode Skill ».

### 2.5 Bootstrap

| Amont | Ici |
|---|---|
| `install.sh` : copie dans `~/.claude/`, réécrit les shebangs et les `.md` avec `sed -i` | `install.sh` : provisionne `.venv/` et `.data/` en place, rien n'est copié |
| `install-win.sh` : suppose Git Bash, `pip install --user` | `install-win.sh` : venv local, détecte `Scripts/python.exe` ou `bin/python3` |
| *absent* | `install-win.ps1` : **entrée principale sur cette machine** |

Aucun shebang n'est réécrit. Les skills référencent l'interpréteur du venv explicitement, donc il
n'y a rien à réécrire et rien à désécrire lors d'une mise à jour.

`uninstall.sh` ne supprime plus les skills, les agents ni les scripts : ce sont des fichiers source
du dépôt. Il retire `.venv/` et demande confirmation avant de toucher `.data/`.

### 2.6 Adaptation Windows

Le corpus amont suppose `curl`, `&&`, `sed -i` et `python3`. Formes retenues ici :

| Besoin amont | Forme qui marche ici |
|---|---|
| Chaîner des commandes (`&&`) | `; if ($?) { ... }` sous PowerShell, ou une seule commande |
| `sed -i` | réécriture par script Python, ou l'outil d'écriture |
| `curl` | `Invoke-WebRequest` (non nécessaire après le portage) |
| `python3` | `.venv/Scripts/python.exe` |
| Shebang `#!/usr/bin/env python3` | laissé tel quel, les scripts sont invoqués via l'interpréteur |

Les 5 fichiers `agents/*.md` et les skills qui lancent un script ont été adaptés. Les blocs de
commande restés en `bash` dans les skills sont ceux qui décrivent une action Leave-it-to-the-operator
(le `geo-update`, par exemple) : ils sont affichés avec leur variante PowerShell à côté.

### 2.7 `.gitignore`

Ajouts, chacun justifié par la nature de ce qu'il contient :

| Motif | Ce qu'il contient |
|---|---|
| `reports/` | Les livrables clients déjà livrés. L'amont avait `/GEO-*.md`, ancré à la racine, donc `reports/GEO-AUDIT-*.md` n'était **pas** ignoré. C'était un trou réel. |
| `.data/` | `prospects.json` et les propositions : données de pipeline client. |
| `.temp/` | Briefs, handoffs, captures, caches de travail. |

`.venv/` et `audit-data*.json` étaient déjà ignorés, ils sont conservés.

---

## 3. Procédure de réconciliation amont

Le but : réintégrer un commit amont sans détruire le port.

### 3.1 Le principe

L'amont et ce dépôt ont **divergé de façon structurelle**, pas seulement de contenu. Un `git merge`
ou un `git rebase` brut produit un arbre incohérent : les skills existent sous deux noms.
La méthode est donc **répertoire par répertoire, jamais en une fois**.

### 3.2 La procédure

1. **Créer une branche de réconciliation**, jamais sur `main`, jamais sur `port-opencode`
   directement.

   ```powershell
   git switch -c reconcile/upstream-YYYY-MM-DD
   ```

2. **Fetcher l'amont** dans une référence dédiée, pour que `git log` reste lisible :

   ```powershell
   git remote add upstream https://github.com/zubair-trabzada/geo-seo-claude.git
   git fetch upstream
   ```

3. **Lister les commits amont à récupérer** :

   ```powershell
   git log --oneline <dernier-commit-amont-intégré>..upstream/main
   ```

4. **Pour chaque commit, juger ce qui est structurel et ce qui est métier** :

   - *Métier* (scores, pondérations, checklists de crawlers, règles `llms.txt`, contenu des skills) :
     cherry-pick normal, puis corriger les chemins si le commit en a touché.
   - *Structurel* (tout ce qui touche `skills/`, `geo/`, `install*.sh`, `uninstall.sh`, le
     frontmatter, ou les chemins) : ne **jamais** cherry-pick tel quel. Prendre le diff, l'appliquer
     à la main, et rejouer la table 2.2 ci-dessus.

5. **Chercher les commits structuraux** avec :

   ```powershell
   git log --oneline <base>..upstream/main -- skills/ geo/ install.sh install-win.sh uninstall.sh
   ```

6. **Après application, vérifier** les cinq points qui signalent une dérive :

   ```powershell
   # 1. aucun doublon à l'ancien emplacement
   git ls-files skills geo

   # 2. aucun chemin vers le profil utilisateur
   rg -n '~/\.claude|~/\.geo-prospects' -g '!.git' .

   # 3. aucun allowed-tools
   rg -n 'allowed-tools' .agents/skills

   # 4. les tests passent
   .\.venv\Scripts\python.exe -m pytest tests\ -q

   # 5. les 5 livrables clients sont toujours ignorés
   git check-ignore -v reports/
   ```

   Chacun de ces cinq doit être vide, vide, vide, vert, et silent.

7. **Si un commit amont ajoute un skill** : il arrive dans `skills/<nom>/SKILL.md` en amont. Le
   déplacer vers `.agents/skills/<nom>/SKILL.md` avec `git mv`, retirer `allowed-tools` du
   frontmatter, et l'ajouter à l'inventaire de la section 2.1.

8. **Si un commit amont ajoute un champ de frontmatter** : vérifier s'il a un sens hors Claude
   Code. `allowed-tools` n'en avait pas et a été retiré. Un champ inconnu dans un frontmatter est
   ignoré silencieusement, donc l'erreur ne se voit pas : le dire ici, dans la section 2.4.

9. **Rejouer le skill `geo-update`** pour le cas courant, plutôt que la procédure
   manuelle. Il contient la table de correspondance amont vers ici, et il réapplique les
   réécritures de chemin après chaque copie. C'est le chemin le moins risqué.

10. **Commit sur la branche de réconciliation, jamais de push sans validation explicite.** Le push
    déclenche un déploiement automatique.

### 3.3 Ce qu'il ne faut jamais faire

- `git checkout upstream/main -- skills/` : cela recrée `skills/` et casse l'inventaire.
- `git checkout upstream/main -- install.sh` : cela réintroduit l'écriture dans `~/.claude/`.
- Supprimer `.agents/` et repartir d'un `git reset --hard` : le port n'est pas réversible par un
  reset, il n'existe que dans les commits de `port-opencode`.
- Modifier les 5 fichiers de `reports/`. Ce sont des livrables clients déjà livrés, ils ne se
  recalculent pas.

---

## 4. Inventaire de référence

Ce qui doit être vrai après n'importe quelle réconciliation :

| Contrôle | Valeur attendue |
|---|---|
| Répertoires dans `.agents/skills/` | 15 `geo-*` plus `geo`, soit 16 |
| Fichiers `agents/geo-*.md` | 5 |
| `skills/` et `geo/` à la racine | absents |
| `allowed-tools` dans `.agents/skills/**` | 0 |
| Références `~/.claude` ou `~/.geo-prospects` | 0 |
| Tests | 14, tous verts |
| Interpréteur documenté | `.venv/Scripts/python.exe` sous Windows |

---

## 5. Hors périmètre de ce portage

Décisions prises, non exécutées. Ne pas les considérer comme des oublis.

- **PDF vers Playwright.** L'amont fait `pandoc` plus Chrome en chemin absolu macOS. Ni `pandoc` ni
  macOS sur cette machine. Le remplacement par Playwright `page.pdf()` est décidé mais pas fait.
  Les chemins de gabarits ont été portés, la chaîne d'outils non.
- **Fan-out des 5 sous-agents vers `.opencode/agent/`.** Les 5 fichiers `agents/*.md` sont lisibles
  en l'état, ils ne sont pas encore branchés sur le mécanisme de dispatch d'OpenCode.
- **Couche agence vers Baserow.** `geo-prospect`, `geo-proposal`, `crm_dashboard.py`,
  `scripts/webapp/` et `white-label/` sont portés tels quels, sans lien vers les outils du vault.
- **Recouvrement avec la stack GEO FFC.** Hors périmètre. Rien n'a été fusionné ni renommé.
