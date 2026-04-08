package com.nimhttp.ide.parser

import com.intellij.lang.ASTNode
import com.intellij.lang.LightPsiParser
import com.intellij.lang.PsiBuilder
import com.intellij.lang.PsiParser
import com.intellij.psi.tree.IElementType
import com.nimhttp.ide.lexer.NimTokenTypes as T
import com.nimhttp.ide.psi.NimElementTypes as E

/**
 * Skeleton Nim parser (Phase 0).
 *
 * **Scope**: recognises top-level `proc`/`func`/`method`/`iterator`/
 * `macro`/`template`/`converter` declarations, `type`/`const`/`let`/`var`
 * sections, and `import`/`include`/`export`/`from` statements — enough to
 * build the PSI tree for syntax-based navigation and stub indexing.
 *
 * Everything not explicitly matched is consumed as an opaque expression
 * block. A full recursive-descent parser covering all Nim grammar rules will
 * be generated from `nim.bnf` (GrammarKit) in Phase 1.
 */
class NimParser : PsiParser, LightPsiParser {

    override fun parse(root: IElementType, builder: PsiBuilder): ASTNode {
        parseLight(root, builder)
        return builder.treeBuilt
    }

    override fun parseLight(root: IElementType, builder: PsiBuilder) {
        val file = builder.mark()
        builder.setDebugMode(false)
        while (!builder.eof()) {
            parseTopLevel(builder)
        }
        file.done(root)
    }

    // -------------------------------------------------------------------------
    // Top-level dispatch
    // -------------------------------------------------------------------------

    private fun parseTopLevel(b: PsiBuilder) {
        skipNewlines(b)
        if (b.eof()) return
        when (b.tokenType) {
            T.KW_PROC       -> parseProcLike(b, E.PROC_DEF)
            T.KW_FUNC       -> parseProcLike(b, E.FUNC_DEF)
            T.KW_METHOD     -> parseProcLike(b, E.METHOD_DEF)
            T.KW_ITERATOR   -> parseProcLike(b, E.ITERATOR_DEF)
            T.KW_MACRO      -> parseProcLike(b, E.MACRO_DEF)
            T.KW_TEMPLATE   -> parseProcLike(b, E.TEMPLATE_DEF)
            T.KW_CONVERTER  -> parseProcLike(b, E.CONVERTER_DEF)
            T.KW_TYPE       -> parseTypeSection(b)
            T.KW_CONST      -> parseVarLikeSection(b, E.CONST_SECTION)
            T.KW_LET        -> parseVarLikeSection(b, E.LET_SECTION)
            T.KW_VAR        -> parseVarLikeSection(b, E.VAR_SECTION)
            T.KW_IMPORT     -> parseImportLike(b, E.IMPORT_STMT)
            T.KW_INCLUDE    -> parseImportLike(b, E.INCLUDE_STMT)
            T.KW_EXPORT     -> parseImportLike(b, E.EXPORT_STMT)
            T.KW_FROM       -> parseFromImport(b)
            else            -> consumeLine(b)
        }
    }

    // -------------------------------------------------------------------------
    // Proc-like declarations (proc / func / method / iterator / macro / template / converter)
    // -------------------------------------------------------------------------

    private fun parseProcLike(b: PsiBuilder, kind: IElementType) {
        val m = b.mark()
        b.advanceLexer()  // consume keyword
        // optional name
        if (b.tokenType == T.IDENT || b.tokenType == T.BACKTICK) {
            b.advanceLexer()
        }
        // optional generic params [T]
        if (b.tokenType == T.LBRACKET) skipMatched(b, T.LBRACKET, T.RBRACKET)
        // optional param list (…)
        if (b.tokenType == T.LPAR) skipMatched(b, T.LPAR, T.RPAR)
        // optional return type  : TypeExpr
        if (b.tokenType == T.COLON) {
            b.advanceLexer()
            parseTypeExpr(b)
        }
        // optional pragmas {. … .}
        if (b.tokenType == T.PRAGMA_OPEN) skipMatched(b, T.PRAGMA_OPEN, T.PRAGMA_CLOSE)
        // optional body — consume rest of indented block
        consumeBlock(b)
        m.done(kind)
    }

    // -------------------------------------------------------------------------
    // type section
    // -------------------------------------------------------------------------

    private fun parseTypeSection(b: PsiBuilder) {
        val section = b.mark()
        b.advanceLexer()  // consume `type`
        consumeBlock(b)
        section.done(E.TYPE_SECTION)
    }

    // -------------------------------------------------------------------------
    // const / let / var sections
    // -------------------------------------------------------------------------

    private fun parseVarLikeSection(b: PsiBuilder, kind: IElementType) {
        val m = b.mark()
        b.advanceLexer()
        consumeBlock(b)
        m.done(kind)
    }

    // -------------------------------------------------------------------------
    // import / include / export
    // -------------------------------------------------------------------------

    private fun parseImportLike(b: PsiBuilder, kind: IElementType) {
        val m = b.mark()
        b.advanceLexer()
        consumeLine(b)
        m.done(kind)
    }

    private fun parseFromImport(b: PsiBuilder) {
        val m = b.mark()
        b.advanceLexer()  // from
        consumeLine(b)    // <module> import <names>
        m.done(E.FROM_IMPORT)
    }

    // -------------------------------------------------------------------------
    // Minimal type-expression parser (enough for return-type annotation)
    // -------------------------------------------------------------------------

    private fun parseTypeExpr(b: PsiBuilder) {
        val m = b.mark()
        if (!b.eof() && b.tokenType != T.NEWLINE && b.tokenType != T.PRAGMA_OPEN
            && b.tokenType != T.EQ && b.tokenType != T.LBRACKET
        ) {
            b.advanceLexer()
        }
        m.done(E.TYPE_EXPR)
    }

    // -------------------------------------------------------------------------
    // Utility helpers
    // -------------------------------------------------------------------------

    private fun skipNewlines(b: PsiBuilder) {
        while (!b.eof() && (b.tokenType == T.NEWLINE || b.tokenType == T.WHITE_SPACE
                    || b.tokenType == T.INDENT || b.tokenType == T.DEDENT)
        ) b.advanceLexer()
    }

    /** Consume tokens until end-of-line (exclusive of the NEWLINE token). */
    private fun consumeLine(b: PsiBuilder) {
        while (!b.eof() && b.tokenType != T.NEWLINE) b.advanceLexer()
    }

    /**
     * Very rough "consume an indented block" — advances past anything that
     * looks like it is part of the current block (lines that are indented or
     * blank). This is a placeholder until the real indentation-tracking parser
     * is implemented in Phase 1.
     */
    private fun consumeBlock(b: PsiBuilder) {
        consumeLine(b)  // consume the rest of the declaration line
        // Advance through any continuation lines – heuristic only
        while (!b.eof()) {
            val tt = b.tokenType
            if (tt == T.NEWLINE || tt == T.INDENT || tt == T.DEDENT || tt == T.WHITE_SPACE) {
                b.advanceLexer()
                continue
            }
            // If we see a top-level keyword at column 0, stop
            if (isTopLevelKeyword(tt)) break
            b.advanceLexer()
        }
    }

    /** Skip a matched pair (open … close), handling nesting. */
    private fun skipMatched(b: PsiBuilder, open: IElementType, close: IElementType) {
        if (b.tokenType != open) return
        b.advanceLexer()
        var depth = 1
        while (!b.eof() && depth > 0) {
            when (b.tokenType) {
                open  -> depth++
                close -> depth--
            }
            b.advanceLexer()
        }
    }

    private fun isTopLevelKeyword(tt: IElementType?): Boolean = tt in TOP_LEVEL_KW

    companion object {
        private val TOP_LEVEL_KW = setOf(
            T.KW_PROC, T.KW_FUNC, T.KW_METHOD, T.KW_ITERATOR,
            T.KW_MACRO, T.KW_TEMPLATE, T.KW_CONVERTER,
            T.KW_TYPE, T.KW_CONST, T.KW_LET, T.KW_VAR,
            T.KW_IMPORT, T.KW_INCLUDE, T.KW_EXPORT, T.KW_FROM
        )
    }
}
