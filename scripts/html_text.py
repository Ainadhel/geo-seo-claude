#!/usr/bin/env python3
"""
Extraction de texte qui distingue le niveau bloc du balisage en ligne.

BeautifulSoup, avec `get_text(strip=True)` et sans `separator`, concatène les chaînes
de texte sans rien mettre entre elles : deux nœuds voisins deviennent un seul mot
(`Motscollés`). Le remède évident, `get_text(separator=" ")`, insère le
séparateur entre *toutes* les chaînes, y compris entre le texte et une balise en
ligne. Sur `<p>Le mot <b>gras</b>itique</p>` il produit `Le mot gras itique`, alors
que la source dit un mot unique. Et sur un ordinal en ligne il écrit `1 ère` là où
la source dit `1<sup>ère</sup>`.

La règle appliquée ici est donc : séparer au franchissement d'un élément de niveau
bloc, et ne rien ajouter au balisage en ligne. L'espace entre deux mots n'apparaît que
si la source en contient déjà un.
"""

import re
from bs4 import NavigableString, Tag
from bs4.element import (
    CData,
    Comment,
    Declaration,
    Doctype,
    ProcessingInstruction,
)

# Sous-classes de NavigableString que BeautifulSoup exclut de get_text() par
# défaut et qu'il faut donc exclure ici aussi : un Comment est un NavigableString,
# un piège qui fait remonter `<!-- marqueur -->` dans le texte mesuré.
NON_TEXT_NODES = (CData, Comment, Declaration, Doctype, ProcessingInstruction)

BLOCK_TAGS = frozenset({
    "address", "article", "aside", "blockquote", "br", "caption", "dd", "details",
    "div", "dl", "dt", "fieldset", "figcaption", "figure", "footer", "form",
    "h1", "h2", "h3", "h4", "h5", "h6", "header", "hgroup", "hr", "li", "main",
    "nav", "ol", "p", "pre", "section", "table", "tbody", "td", "tfoot", "th",
    "thead", "tr", "ul",
})

_WHITESPACE = re.compile(r"\s+")


def _collect(node, out):
    for child in node.children:
        if isinstance(child, NavigableString):
            if isinstance(child, NON_TEXT_NODES):
                continue
            # Ni strip ni séparateur ici : l'espace autour d'un nœud en ligne est
            # souvent la seule séparation que la source fournit.
            out.append(str(child))
        elif isinstance(child, Tag):
            if child.name in BLOCK_TAGS:
                out.append(" ")
                _collect(child, out)
                out.append(" ")
            else:
                _collect(child, out)


def block_aware_text(node) -> str:
    """Texte de `node`, espaces ajoutés aux seuls franchissements de blocs.

    L'espace insécable est normalisé en espace simple, comme le ferait `split()`
    dans le reste des scripts.
    """
    if node is None:
        return ""
    parts = []
    _collect(node, parts)
    return _WHITESPACE.sub(" ", "".join(parts)).strip()
