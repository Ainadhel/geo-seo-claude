"""
Non-regression for the block / inline text extraction contract.

Upstream defect: `get_text(strip=True)` with no separator concatenates neighbouring
text nodes, so block siblings fuse into one word. The obvious remedy,
`get_text(separator=" ")`, over-corrects: it also separates inline markup, which
rewrites the page's own words.

The test therefore pins BOTH directions. A test that only proves direction 1 lets a
blanket `separator=" "` through, and a test that only proves direction 2 pins the
upstream defect in place.

The structures below mirror a real production page where the defect was measured.
The wording is synthetic and names no one: this file pins an extraction contract,
not any particular homepage.
"""

import os
import sys
from unittest.mock import MagicMock, patch

# Ensure scripts/ is importable from the worktree
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "scripts"))

from bs4 import BeautifulSoup  # noqa: E402

from citability_scorer import analyze_page_citability  # noqa: E402
from fetch_page import extract_content_blocks, fetch_page  # noqa: E402
from html_text import block_aware_text  # noqa: E402


def _el(html: str):
    return BeautifulSoup(html, "lxml").body.find(True)


# ---------------------------------------------------------------------------
# Direction 1: block siblings must be separated
# ---------------------------------------------------------------------------

BLOCK_SIBLINGS_HTML = """<div><ul>
  <li><h3>Chapitre un</h3><p>texte de référence</p></li>
  <li><h3>Chapitre deux</h3><p>texte de démonstration</p></li>
</ul></div>"""

LIST_ITEMS_HTML = "<ul><li>Modèle de base</li><li>Modèle dérivé</li></ul>"

BR_IN_PARAGRAPH_HTML = (
    "<p>Référentiel d'exemple <br/>dossier de démonstration</p>"
)


class TestBlockLevelIsSeparated:
    """Two adjacent block elements must leave a space between their texts."""

    def test_adjacent_blocks_get_a_space(self):
        assert block_aware_text(_el(BLOCK_SIBLINGS_HTML)) == (
            "Chapitre un texte de référence Chapitre deux texte de démonstration"
        )

    def test_list_items_get_a_space(self):
        assert block_aware_text(_el(LIST_ITEMS_HTML)) == (
            "Modèle de base Modèle dérivé"
        )

    def test_line_break_inside_a_paragraph_gets_a_space(self):
        assert block_aware_text(_el(BR_IN_PARAGRAPH_HTML)) == (
            "Référentiel d'exemple dossier de démonstration"
        )

    def test_upstream_form_would_have_glued_them(self):
        """Guards the premise: strip=True alone is what produced the defect."""
        assert _el(BLOCK_SIBLINGS_HTML).get_text(strip=True) == (
            "Chapitre untexte de référenceChapitre deuxtexte de démonstration"
        )


# ---------------------------------------------------------------------------
# Direction 2: inline markup must NOT gain a space
# ---------------------------------------------------------------------------

BOLD_INLINE_HTML = "<p>Le mot <b>gras</b>itique reste un mot.</p>"

SUPERSCRIPT_ORDINAL_HTML = (
    "<p>Repères du référentiel :<br/> 3 paliers par défaut<br/>"
    " 1<sup>ère</sup> étape du parcours de démonstration"
    "<br/> 2<sup>ème</sup> étape du parcours de démonstration</p>"
)

LINK_GLUE_HTML = "<p>Consulter<a href=\"/x\">le référentiel</a>de démonstration</p>"


class TestInlineMarkupIsNotSeparated:
    """Inline markup inside a single sentence must stay as the source wrote it."""

    def test_bold_italic_word_is_not_cut_in_two(self):
        assert block_aware_text(_el(BOLD_INLINE_HTML)) == (
            "Le mot grasitique reste un mot."
        )

    def test_superscript_ordinal_stays_glued_to_its_number(self):
        text = block_aware_text(_el(SUPERSCRIPT_ORDINAL_HTML))
        assert "1ère étape" in text
        assert "2ème étape" in text

    def test_inline_link_without_spaces_stays_glued(self):
        assert block_aware_text(_el(LINK_GLUE_HTML)) == (
            "Consulterle référentielde démonstration"
        )

    def test_blanket_separator_would_have_corrupted_them(self):
        """Guards the trap: the global remedy breaks what direction 2 protects."""
        assert _el(BOLD_INLINE_HTML).get_text(separator=" ", strip=True) == (
            "Le mot gras itique reste un mot."
        )
        assert "1 ère étape" in _el(SUPERSCRIPT_ORDINAL_HTML).get_text(
            separator=" ", strip=True
        )

    def test_no_space_is_invented_around_empty_decorative_nodes(self):
        assert block_aware_text(_el('<p><span></span><a href="/x">Lien décoratif</a></p>')) == (
            "Lien décoratif"
        )


# ---------------------------------------------------------------------------
# Neither direction may leak a node that get_text() excludes by default
# ---------------------------------------------------------------------------

COMMENT_HTML = (
    '<p class="picto"><!-- marqueur un -->'
    '<img src="/x.png"/><!-- marqueur deux -->Texte de synthèse</p>'
)


class TestCommentsNeverBecomeMeasuredText:
    """A Comment is a NavigableString subclass. Walking children naively promotes
    `<!-- marqueur un -->` into the measured text, which get_text() never did.
    Real markup on a production page is full of such comments."""

    def test_html_comment_is_excluded(self):
        assert block_aware_text(_el(COMMENT_HTML)) == "Texte de synthèse"

    def test_get_text_excluded_it_too(self):
        """Pins the premise: this is not a loosening, it matches upstream."""
        assert _el(COMMENT_HTML).get_text(strip=True) == "Texte de synthèse"


# ---------------------------------------------------------------------------
# The contract as reached through the real scripts, not the helper alone
# ---------------------------------------------------------------------------

SYNTHETIC_PAGE_HTML = """<!DOCTYPE html>
<html><head><title>Référentiel d'exemple</title></head>
<body>
  <h2>Contenu de démonstration</h2>
  <ul>
    <li><h3><span>Présenter</span> <br/>le référentiel</h3>
      <p>Ce paragraphe est la 1<sup>ère</sup> partie de la démonstration, à lire
      comme un modèle réduit : l'intérêt du jeu d'essai est que les accents é, è,
      ê, à, ç, œ et û y sont tous présents.</p>
      <p>Deuxième paragraphe <br/>avec un saut de ligne interne</p>
      <p>Un troisième paragraphe se termine par un saut de ligne <br/></p>
      <p>Présenter le référentiel, ses annexes et ses métadonnées, avec des
      exemples déjà rédigés et des adresses de démonstration incluses.</p></li>
    <li><h3><span>Documenter</span> <br/>les usages</h3>
      <p>Chaque étape compte <br/>pour la relecture !</p>
      <p><strong>Usage :</strong> montrer le mécanisme sur un cœur de
      démonstration et créer des jeux d'essai dans tout le référentiel, au
      coût d'un geste répété.</p></li>
  </ul>
</body></html>"""


def _fetch_with_html(html: str) -> dict:
    mock_resp = MagicMock()
    mock_resp.status_code = 200
    mock_resp.text = html
    mock_resp.history = []
    mock_resp.headers = {}
    mock_resp.url = "http://example.com/"
    with patch("fetch_page.requests.get", return_value=mock_resp):
        return fetch_page("http://example.com/")


class TestScriptsUseTheBlockInlineContract:
    """The two production paths must carry the same contract as the helper."""

    def test_extract_content_blocks_separates_blocks(self):
        blocks = extract_content_blocks(SYNTHETIC_PAGE_HTML)
        headings = " ".join(str(b["heading"]) for b in blocks)
        assert "Présenter le référentiel" in headings
        assert "Documenter les usages" in headings
        assert "Présenterle référentiel" not in headings

    def test_extract_content_blocks_keeps_inline_glued(self):
        content = " ".join(
            str(b["content"]) for b in extract_content_blocks(SYNTHETIC_PAGE_HTML)
        )
        assert "1ère partie" in content
        assert "1 ère partie" not in content
        assert "Usage : montrer" in content
        assert "Usage :montrer" not in content

    def test_fetch_page_headings_are_separated(self):
        result = _fetch_with_html(SYNTHETIC_PAGE_HTML)
        headings = [h["text"] for h in result["heading_structure"]]
        assert "Présenter le référentiel" in headings
        assert "Présenterle référentiel" not in headings

    def test_fetch_page_text_content_still_uses_its_own_extraction(self):
        """Line 159 of fetch_page.py is deliberately left untouched: it is the
        page-level extraction and already carried a separator."""
        result = _fetch_with_html(SYNTHETIC_PAGE_HTML)
        assert "Deuxième paragraphe" in result["text_content"]

    def test_citability_scorer_separates_blocks_on_the_measured_path(self):
        with patch("citability_scorer.requests.get") as mock_get:
            mock_resp = MagicMock()
            mock_resp.status_code = 200
            mock_resp.text = SYNTHETIC_PAGE_HTML
            mock_resp.raise_for_status = lambda: None
            mock_get.return_value = mock_resp
            result = analyze_page_citability("http://example.com/")

        headings = [b["heading"] for b in result["all_blocks"]]
        assert "Présenter le référentiel" in headings
        previews = " ".join(b["preview"] for b in result["all_blocks"])
        assert "Présenter le référentiel" in previews
        assert "Présenterle référentiel" not in previews
        assert "1ère partie" in previews
        assert "1 ère partie" not in previews
