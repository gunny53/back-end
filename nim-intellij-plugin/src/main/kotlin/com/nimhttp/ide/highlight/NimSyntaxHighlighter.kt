package com.nimhttp.ide.highlight

import com.intellij.lexer.Lexer
import com.intellij.openapi.editor.DefaultLanguageHighlighterColors
import com.intellij.openapi.editor.colors.TextAttributesKey
import com.intellij.openapi.editor.colors.TextAttributesKey.createTextAttributesKey
import com.intellij.openapi.fileTypes.SyntaxHighlighterBase
import com.intellij.psi.tree.IElementType
import com.nimhttp.ide.lexer.NimLexer
import com.nimhttp.ide.lexer.NimTokenTypes as T

/**
 * Syntax highlighter for Nim source files.
 *
 * Maps [NimTokenTypes] to [TextAttributesKey] entries so IntelliJ can colour
 * the editor. Users can customise colours via **Settings → Editor → Color Scheme → Nim**.
 */
class NimSyntaxHighlighter : SyntaxHighlighterBase() {

    override fun getHighlightingLexer(): Lexer = NimLexer()

    override fun getTokenHighlights(tokenType: IElementType): Array<TextAttributesKey> =
        TOKEN_HIGHLIGHTS[tokenType] ?: EMPTY_KEYS

    companion object {
        // ---- Text attribute keys (shown in Color Scheme settings) ----------------
        val NIM_KEYWORD    = createTextAttributesKey("NIM_KEYWORD",    DefaultLanguageHighlighterColors.KEYWORD)
        val NIM_COMMENT    = createTextAttributesKey("NIM_COMMENT",    DefaultLanguageHighlighterColors.LINE_COMMENT)
        val NIM_DOC_COMMENT= createTextAttributesKey("NIM_DOC_COMMENT",DefaultLanguageHighlighterColors.DOC_COMMENT)
        val NIM_STRING     = createTextAttributesKey("NIM_STRING",     DefaultLanguageHighlighterColors.STRING)
        val NIM_NUMBER     = createTextAttributesKey("NIM_NUMBER",     DefaultLanguageHighlighterColors.NUMBER)
        val NIM_IDENTIFIER = createTextAttributesKey("NIM_IDENTIFIER", DefaultLanguageHighlighterColors.IDENTIFIER)
        val NIM_OPERATOR   = createTextAttributesKey("NIM_OPERATOR",   DefaultLanguageHighlighterColors.OPERATION_SIGN)
        val NIM_PRAGMA     = createTextAttributesKey("NIM_PRAGMA",     DefaultLanguageHighlighterColors.METADATA)
        val NIM_BAD_CHAR   = createTextAttributesKey("NIM_BAD_CHAR",   DefaultLanguageHighlighterColors.INVALID_STRING_ESCAPE)

        private val EMPTY_KEYS = emptyArray<TextAttributesKey>()

        private val KEYWORD_KEYS = arrayOf(NIM_KEYWORD)
        private val COMMENT_KEYS = arrayOf(NIM_COMMENT)
        private val DOC_COMMENT_KEYS = arrayOf(NIM_DOC_COMMENT)
        private val STRING_KEYS = arrayOf(NIM_STRING)
        private val NUMBER_KEYS = arrayOf(NIM_NUMBER)
        private val IDENT_KEYS = arrayOf(NIM_IDENTIFIER)
        private val OPERATOR_KEYS = arrayOf(NIM_OPERATOR)
        private val PRAGMA_KEYS = arrayOf(NIM_PRAGMA)
        private val BAD_KEYS = arrayOf(NIM_BAD_CHAR)

        private val TOKEN_HIGHLIGHTS: Map<IElementType, Array<TextAttributesKey>> = buildMap {
            // Keywords
            T.KEYWORDS.values.forEach { put(it, KEYWORD_KEYS) }
            // Comments
            put(T.COMMENT,       COMMENT_KEYS)
            put(T.DOC_COMMENT,   DOC_COMMENT_KEYS)
            // Literals
            put(T.STRING_LIT,    STRING_KEYS)
            put(T.CHAR_LIT,      STRING_KEYS)
            put(T.RAW_STRING,    STRING_KEYS)
            put(T.TRIPLE_STRING, STRING_KEYS)
            put(T.INT_LIT,       NUMBER_KEYS)
            put(T.FLOAT_LIT,     NUMBER_KEYS)
            // Identifiers
            put(T.IDENT,         IDENT_KEYS)
            // Operators & punctuation
            put(T.OPERATOR,      OPERATOR_KEYS)
            put(T.EQ,            OPERATOR_KEYS)
            put(T.COLON,         OPERATOR_KEYS)
            put(T.DOT,           OPERATOR_KEYS)
            put(T.DOTDOT,        OPERATOR_KEYS)
            // Pragmas
            put(T.PRAGMA_OPEN,   PRAGMA_KEYS)
            put(T.PRAGMA_CLOSE,  PRAGMA_KEYS)
            // Errors
            put(T.BAD_CHARACTER, BAD_KEYS)
        }
    }
}
