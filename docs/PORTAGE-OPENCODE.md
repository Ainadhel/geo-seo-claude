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

### 2.8 Divergence assumée : le correctif de perte d'espaces

Contrairement au reste de ce document, ce qui suit est une **divergence de fond** et pas une
réécriture de chemins. Elle est assumée, donc elle doit être signalée à chaque réconciliation.

**Le défaut, et il est amont.** Trois scripts extrayaient le texte avec
`element.get_text(strip=True)` sans `separator`. BeautifulSoup concatène alors les chaînes de
texte sans rien mettre entre elles, et deux nœuds voisins deviennent un seul mot. Confirmé en amont
: `git show upstream/main:scripts/citability_scorer.py` présente les deux mêmes lignes. Le portage
ne l'a pas introduit, il l'a hérité.

**Où.** Dix sites d'appel, tous sur le chemin de mesure ou de collecte :
`citability_scorer.py` (titre de section, texte de bloc), `fetch_page.py` (titre, titres h1 à h6,
racine de framework pour la mesure SSR, texte de lien, titre et texte de bloc de
`extract_content_blocks`), `llmstxt_generator.py` (titre du site, texte de lien). Deux sites sont
laissés intacts, et c'est délibéré : la ligne d'extraction de `text_content` dans `fetch_page.py`
porte déjà un `separator` et n'a rien à corriger, et l'extraction du JSON-LD ne doit surtout pas
recevoir de séparateur, sous peine de casser la charge utile.

**Pourquoi c'est grave et pas cosmétique.** La perte d'espaces fausse tout l'aval du
`citability_scorer.py` : `text.split()` compte de faux mots, donc `self_containment` est faux, et
`re.split(r"[.!?]+", text)` ne segmentation plus en phrases, donc `answer_block_quality`, qui pèse
30 % du score, est faux. Sur `https://www.fedecardio.org/`, la mesure avant correctif rendait une
moyenne de 30,9 avec 0 passage de longueur optimale et 9 blocs en F sur 10, et les aperçus
montraient `Informerles publics3 millions de brochuresdiffusées gratuitement`. Ce chiffre était un
artefact, pas une mesure.

**La forme du correctif, et le piège qu'il évite.** Le remède évident,
`get_text(separator=" ")`, insère le séparateur entre *toutes* les chaînes, y compris entre le texte
et une balise en ligne. Il transforme `Le mot <b>gras</b>itique` en `Le mot gras itique`, et sur la
cible réelle il écrit `1 ère cause` là où la source dit `1ère cause`. C'est un second défaut, plus
discret que le premier. Le correctif applique donc la règle inverse, site par site : **séparer au
franchissement d'un élément de niveau bloc, ne rien ajouter au balisage en ligne**. L'espace entre
deux mots n'apparaît que si la source en contient déjà un. Le helper est `scripts/html_text.py`,
`block_aware_text()`.

**Pourquoi le test existe.** `tests/test_text_extraction_spaces.py` épingle les **deux** sens : deux
blocs adjacents produisent bien un espace, et du balisage en ligne dans un même paragraphe n'en
produit pas. Un test qui ne garderait que le premier sens laisserait passer un
`separator=" "` appliqué partout, qui corrigerait le symptôme en introduisant le second défaut. Le
test couvre aussi le troisième piège, celui d'un parcours naïf des enfants du DOM : `Comment` est
une sous-classe de `NavigableString`, donc `<!-- picto evenement -->` se retrouve dans le texte
mesuré si on ne l'exclut pas explicitement.

**Ce qu'il faut faire à la prochaine réconciliation.** Si un commit amont touche
`scripts/citability_scorer.py`, `scripts/fetch_page.py` ou `scripts/llmstxt_generator.py`, un
`git checkout upstream/main -- scripts/` ou un merge non examiné **réintroduit le défaut en
silence** : l'amont n'a toujours pas la correction. Le test le détectera, mais seulement si `pytest`
est lancé, et l'échec se lit alors comme un test cassé plutôt que comme une régression de mesure.
Vérifier explicitement qu'aucun `get_text(strip=True)` sans séparateur n'a réapparu dans ces trois
fichiers.

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
- `git checkout upstream/main -- scripts/` : cela réintroduit la perte d'espaces du § 2.8, en
  silence, puisque l'amont n'a pas la correction.
- Supprimer `.agents/` et repartir d'un `git reset --hard` : le port n'est pas réversible par un
  reset, il n'existe que dans les commits de `port-opencode`.
- Modifier les 5 fichiers de `reports/`. Ce sont des livrables clients déjà livrés, ils ne se
  recalculent pas.

---

## 4. Inventaire de référence

Ce qui doit être vrai après n'importe quelle réconciliation.

**Chaque ligne porte son périmètre**, parce qu'un compte sans périmètre n'est pas reproductible. La
même chaîne donne des résultats différents selon qu'on l'applique aux skills seuls ou à tout le
dépôt, et c'est précisément l'ambiguïté qui a produit les valeurs fausses de la première version de
cette section.

### 4.1 Périmètres

Trois périmètres sont employés :

| Périmètre | Ce qu'il recouvre |
|---|---|
| `.agents/skills/**` | les 16 `SKILL.md`, rien d'autre |
| dépôt hors ce fichier | tous les fichiers suivis par git, **moins** ce document |
| dépôt | tous les fichiers suivis par git, soit 76 au 27/09/2026 |

Ce document est volontairement exclu des comptages de dépôt : il cite le nom du champ et les
chemins interdits pour les définir, donc il s'auto-mentionne et ne peut pas servir de référence à
lui-même. Son propre compte est donné au § 4.3, à recompter après chaque édition de cette section.

### 4.2 Contrôles

| Contrôle | Périmètre | Valeur attendue |
|---|---|---|
| Répertoires dans `.agents/skills/` | dépôt | 15 `geo-*` plus `geo`, soit 16 |
| Fichiers `agents/geo-*.md` | dépôt | 5 |
| `skills/` et `geo/` à la racine | dépôt | absents |
| Clé de frontmatter `allowed-tools:` | `.agents/skills/**` + `agents/**` | **0** sur les 21 fichiers migrés |
| Chaîne `allowed-tools` | `.agents/skills/**` | **3**, toutes dans `geo-update/SKILL.md`, en prose |
| Chaîne `allowed-tools` | dépôt hors ce fichier | **5** : les 3 ci-dessus plus 2 dans `CLAUDE.md` |
| Chaîne `~/.claude` | `.agents/skills/**` | **6**, toutes dans `geo-update/SKILL.md`, qui est le skill de resynchronisation amont |
| Chaîne `~/.claude` | dépôt hors ce fichier | **15** |
| Chaîne `~/.geo-prospects` | `.agents/skills/**` | **1**, dans `geo-update/SKILL.md` |
| Chaîne `~/.geo-prospects` | dépôt hors ce fichier | **1**, la même occurrence |
| Tests | dépôt | 30, tous verts, dont 16 de non-régression sur l'extraction de texte |
| Interpréteur documenté | dépôt | `.venv/Scripts/python.exe` sous Windows |

Le contrôle utile est la **clé de frontmatter à 0**, pas la chaîne à 0. Une vérification
automatique de la forme `rg 'allowed-tools' .agents/skills` doit attendre 3 et non 0, sinon elle
échouera, ou pire, sera « corrigée » à la baisse. La procédure du § 3.2 point 6 a le même défaut :
son `rg -n 'allowed-tools' .agents/skills` doit être lu comme 3 occurrences attendues, à vérifier
par la présence ou l'absence de la clé de frontmatter.

### 4.3 Auto-mention de ce document

Ce fichier cite `allowed-tools`, `~/.claude` et `~/.geo-prospects` pour les définir et pour prescrire
les contrôles. Son propre compte se lit ainsi, à recompter après chaque édition :

| Chaîne | Occurrences dans ce fichier |
|---|---|
| `allowed-tools` | 13 |
| `~/.claude` | 13 |
| `~/.geo-prospects` | 6 |

### 4.4 Incohérence amont connue : `scripts/generate_pdf_report.py`

L'amont documente dans quatre fichiers un script `scripts/generate_pdf_report.py` qui **n'existe
dans aucun commit**, ni en amont ni ici : `git ls-tree -r upstream/main` ne renvoie aucun blob de
ce nom, et `scripts/` ne contient que `brand_scanner.py`, `citability_scorer.py`, `crm_dashboard.py`,
`fetch_page.py`, `llmstxt_generator.py` et `webapp/app.py`.

Cette incohérence est **amont**, elle n'est pas née du portage :

| Fichier | Amont | Ici, hors ce document |
|---|---|---|
| `docs/skills-and-agents.md` | 2 occurrences | 2, inchangé |
| `docs/commands-reference.md` | 1 occurrence | 1, inchangé |
| `README.md` | 1 occurrence | 0, entrée d'arbre retirée au portage |
| `docs/architecture.md` | 1 occurrence | 0, entrée d'arbre retirée au portage |
| **Total** | **5 sur 4 fichiers** | **3 sur 2 fichiers** |

Le portage a retiré les deux entrées d'arbre des deux premiers arbres, sans le déclarer dans son
rapport. C'est une **aggravation** de la panne, pas un nettoyage : en amont les quatre fichiers
étaient cohérents entre eux et affirmaient tous que le script existe, ici la fiction est scindée
entre des arbres qui ne le listent plus et une documentation qui le décrit encore. La forme retenue
est de **documenter l'incohérence, pas de supprimer la documentation** : les mentions restantes sont
du contenu amont, et les retirer créerait plus de divergence que l'incohérence n'en coûte, au sens
du raisonnement du § 1 sur les tirets cadratins. Chacune des trois mentions porte désormais un
avertissement visible renvoyant ici, pour qu'aucun lecteur ne puisse suivre la commande.

Ce document en ajoute 3 de plus, qui décrivent la panne au lieu de la propager : le total du dépôt
passe donc à 6 sur 3 fichiers, dont la moitié est auto-référente.

Ce n'est de toute façon pas une référence à une fonctionnalité perdue. Le skill `geo-report-pdf`
n'utilise pas ReportLab : il est passé à `pandoc` plus Chrome headless et précise « No ReportLab »
dans son propre texte. Les mentions pointent donc vers une implémentation antérieure, déjà
abandonnée par le skill auquel elles étaient rattachées.

Une vérification automatique ne doit pas exiger 0 occurrence de `generate_pdf_report.py` : hors ce
document, elle doit attendre **3 sur 2 fichiers**, toutes deux valant une documentation périmée.

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
