"""
Non-regression for the block / inline text extraction contract.

Upstream defect: `get_text(strip=True)` with no separator concatenates neighbouring
text nodes, so block siblings fuse into one word. The obvious remedy,
`get_text(separator=" ")`, over-corrects: it also separates inline markup, which
rewrites the page's own words.

The test therefore pins BOTH directions. A test that only proves direction 1 lets a
blanket `separator=" "` through, and a test that only proves direction 2 pins the
upstream defect in place.

Fixtures below are taken from https://www.fedecardio.org/, the page where the
defect was measured on 27/09/2026.
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
  <li><h3>Informer</h3><p>les publics</p></li>
  <li><h3>3 millions de brochures</h3><p>diffusées gratuitement</p></li>
</ul></div>"""

LIST_ITEMS_HTML = "<ul><li>Grand public</li><li>Scolaires</li></ul>"

BR_IN_PARAGRAPH_HTML = (
    "<p>3 millions de brochures <br/>diffusées gratuitement</p>"
)


class TestBlockLevelIsSeparated:
    """Two adjacent block elements must leave a space between their texts."""

    def test_adjacent_blocks_get_a_space(self):
        assert block_aware_text(_el(BLOCK_SIBLINGS_HTML)) == (
            "Informer les publics 3 millions de brochures diffusées gratuitement"
        )

    def test_list_items_get_a_space(self):
        assert block_aware_text(_el(LIST_ITEMS_HTML)) == "Grand public Scolaires"

    def test_line_break_inside_a_paragraph_gets_a_space(self):
        assert block_aware_text(_el(BR_IN_PARAGRAPH_HTML)) == (
            "3 millions de brochures diffusées gratuitement"
        )

    def test_upstream_form_would_have_glued_them(self):
        """Guards the premise: strip=True alone is what produced the defect."""
        assert _el(BLOCK_SIBLINGS_HTML).get_text(strip=True) == (
            "Informerles publics3 millions de brochuresdiffusées gratuitement"
        )


# ---------------------------------------------------------------------------
# Direction 2: inline markup must NOT gain a space
# ---------------------------------------------------------------------------

BOLD_INLINE_HTML = "<p>Le mot <b>gras</b>itique reste un mot.</p>"

SUPERSCRIPT_ORDINAL_HTML = (
    "<p>Les maladies cardiovascules :<br/> 400 morts par jour<br/>"
    " 1<sup>ère</sup> cause de mortalité chez les plus de 65 ans"
    "<br/> 2<sup>ème</sup> cause de mortalité chez les hommes</p>"
)

LINK_GLUE_HTML = "<p>Decouvrir<a href=\"/x\">notre action</a>des publics</p>"


class TestInlineMarkupIsNotSeparated:
    """Inline markup inside a single sentence must stay as the source wrote it."""

    def test_bold_italic_word_is_not_cut_in_two(self):
        assert block_aware_text(_el(BOLD_INLINE_HTML)) == (
            "Le mot grasitique reste un mot."
        )

    def test_superscript_ordinal_stays_glued_to_its_number(self):
        text = block_aware_text(_el(SUPERSCRIPT_ORDINAL_HTML))
        assert "1ère cause" in text
        assert "2ème cause" in text

    def test_inline_link_without_spaces_stays_glued(self):
        assert block_aware_text(_el(LINK_GLUE_HTML)) == (
            "Decouvrirnotre actiondes publics"
        )

    def test_blanket_separator_would_have_corrupted_them(self):
        """Guards the trap: the global remedy breaks what direction 2 protects."""
        assert _el(BOLD_INLINE_HTML).get_text(separator=" ", strip=True) == (
            "Le mot gras itique reste un mot."
        )
        assert "1 ère cause" in _el(SUPERSCRIPT_ORDINAL_HTML).get_text(
            separator=" ", strip=True
        )

    def test_no_space_is_invented_around_empty_decorative_nodes(self):
        assert block_aware_text(_el('<p><span></span><a href="/x">Activité Physique</a></p>')) == (
            "Activité Physique"
        )


# ---------------------------------------------------------------------------
# Neither direction may leak a node that get_text() excludes by default
# ---------------------------------------------------------------------------

COMMENT_HTML = (
    '<p class="picto_prevention"><!-- picto evenement -->'
    '<img src="/x.png"/><!-- picto don -->Les collectivités</p>'
)


class TestCommentsNeverBecomeMeasuredText:
    """A Comment is a NavigableString subclass. Walking children naively promotes
    `<!-- picto evenement -->` into the measured text, which get_text() never did.
    Real markup on the measured target is full of such comments."""

    def test_html_comment_is_excluded(self):
        assert block_aware_text(_el(COMMENT_HTML)) == "Les collectivités"

    def test_get_text_excluded_it_too(self):
        """Pins the premise: this is not a loosening, it matches upstream."""
        assert _el(COMMENT_HTML).get_text(strip=True) == "Les collectivités"


# ---------------------------------------------------------------------------
# The contract as reached through the real scripts, not the helper alone
# ---------------------------------------------------------------------------

MISSIONS_PAGE_HTML = """<!DOCTYPE html>
<html><head><title>Fédération Française de Cardiologie</title></head>
<body>
  <h2>Nos missions</h2>
  <ul>
    <li><h3><span>Informer</span> <br/>les publics</h3>
      <p>Les maladies cardiovasculaires sont la 1<sup>ère</sup> cause de
      mortalité chez les plus de 65 ans et les femmes, ce qui rend la
      sensibilisation aux gestes qui sauvent décisive chaque jour.</p>
      <p>3 millions de brochures <br/>diffusées gratuitement</p>
      <p>Informer le grand public, les patients et leurs proches sur les
      maladies cardiovasculaires, leurs traitements et la prévention au
      quotidien, grâce à des supports accessibles et relayés partout.</p></li>
    <li><h3><span>Sensibiliser</span> <br/>aux gestes qui sauvent</h3>
      <p>Chaque minute compte <br/>pour sauver une vie !</p>
      <p><strong>Mission :</strong> prévenir les maladies cardiovasculaires et
      aider les cardiaques à se réadapter en créant des Clubs cœur et santé
      dans toute la France.</p></li>
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
        blocks = extract_content_blocks(MISSIONS_PAGE_HTML)
        headings = " ".join(str(b["heading"]) for b in blocks)
        assert "Informer les publics" in headings
        assert "Sensibiliser aux gestes qui sauvent" in headings
        assert "Informerles publics" not in headings

    def test_extract_content_blocks_keeps_inline_glued(self):
        content = " ".join(
            str(b["content"]) for b in extract_content_blocks(MISSIONS_PAGE_HTML)
        )
        assert "1ère cause" in content
        assert "1 ère cause" not in content
        assert "Mission : prévenir" in content
        assert "Mission :prévenir" not in content

    def test_fetch_page_headings_are_separated(self):
        result = _fetch_with_html(MISSIONS_PAGE_HTML)
        headings = [h["text"] for h in result["heading_structure"]]
        assert "Informer les publics" in headings
        assert "Informerles publics" not in headings

    def test_fetch_page_text_content_still_uses_its_own_extraction(self):
        """Line 159 of fetch_page.py is deliberately left untouched: it is the
        page-level extraction and already carried a separator."""
        result = _fetch_with_html(MISSIONS_PAGE_HTML)
        assert "3 millions de brochures" in result["text_content"]

    def test_citability_scorer_separates_blocks_on_the_measured_path(self):
        with patch("citability_scorer.requests.get") as mock_get:
            mock_resp = MagicMock()
            mock_resp.status_code = 200
            mock_resp.text = MISSIONS_PAGE_HTML
            mock_resp.raise_for_status = lambda: None
            mock_get.return_value = mock_resp
            result = analyze_page_citability("http://example.com/")

        headings = [b["heading"] for b in result["all_blocks"]]
        assert "Informer les publics" in headings
        previews = " ".join(b["preview"] for b in result["all_blocks"])
        assert "Informer les publics" in previews
        assert "Informerles publics" not in previews
        assert "1ère cause" in previews
        assert "1 ère cause" not in previews
