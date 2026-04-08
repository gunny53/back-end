package com.nimhttp.ide.lexer

import com.intellij.lexer.LexerBase
import com.intellij.psi.tree.IElementType
import com.nimhttp.ide.lexer.NimTokenTypes as T

/**
 * Hand-written skeleton lexer for Nim source files.
 *
 * **Phase 0 scope**: covers the token types needed for syntax highlighting
 * (keywords, literals, comments, basic operators, indentation markers).
 * A JFlex-based generated lexer will replace this in Phase 1 once the full
 * grammar BNF is finalized.
 *
 * The lexer is *not* indentation-aware at this stage: INDENT/DEDENT tokens
 * are emitted as NEWLINE for now; the parser will handle layout rules later.
 */
class NimLexer : LexerBase() {

    private var buffer: CharSequence = ""
    private var startOffset: Int = 0
    private var endOffset: Int = 0
    private var tokenStart: Int = 0
    private var tokenEnd: Int = 0
    private var tokenType: IElementType? = null

    // -------------------------------------------------------------------------
    // LexerBase contract
    // -------------------------------------------------------------------------

    override fun start(buffer: CharSequence, startOffset: Int, endOffset: Int, initialState: Int) {
        this.buffer = buffer
        this.startOffset = startOffset
        this.endOffset = endOffset
        tokenStart = startOffset
        tokenEnd = startOffset
        tokenType = null
        advance()
    }

    override fun getState(): Int = 0  // stateless skeleton

    override fun getTokenType(): IElementType? = tokenType

    override fun getTokenStart(): Int = tokenStart

    override fun getTokenEnd(): Int = tokenEnd

    override fun advance() {
        tokenStart = tokenEnd
        if (tokenStart >= endOffset) {
            tokenType = null
            return
        }
        tokenType = nextToken()
    }

    override fun getBufferSequence(): CharSequence = buffer
    override fun getBufferEnd(): Int = endOffset

    // -------------------------------------------------------------------------
    // Token recognition helpers
    // -------------------------------------------------------------------------

    private fun ch(offset: Int = tokenStart): Char =
        if (offset < endOffset) buffer[offset] else '\u0000'

    private fun ch2(): Char = ch(tokenStart + 1)

    private fun nextToken(): IElementType {
        val c = ch()

        // Whitespace (excluding newlines)
        if (c == ' ' || c == '\t') {
            tokenEnd = tokenStart + 1
            while (tokenEnd < endOffset && (buffer[tokenEnd] == ' ' || buffer[tokenEnd] == '\t')) tokenEnd++
            return T.WHITE_SPACE
        }

        // Newline
        if (c == '\n' || c == '\r') {
            tokenEnd = tokenStart + 1
            if (c == '\r' && tokenEnd < endOffset && buffer[tokenEnd] == '\n') tokenEnd++
            return T.NEWLINE
        }

        // Comments
        if (c == '#') {
            if (ch2() == '#') {
                return lexLineComment(T.DOC_COMMENT)
            }
            return lexLineComment(T.COMMENT)
        }

        // String literals
        if (c == '"') {
            if (tokenStart + 2 < endOffset && buffer[tokenStart + 1] == '"' && buffer[tokenStart + 2] == '"') {
                return lexTripleString()
            }
            return lexString('"', T.STRING_LIT)
        }
        if (c == '\'') return lexString('\'', T.CHAR_LIT)

        // Raw string  r"…"
        if ((c == 'r' || c == 'R') && ch2() == '"') {
            tokenEnd = tokenStart + 2
            while (tokenEnd < endOffset && buffer[tokenEnd] != '"') {
                if (buffer[tokenEnd] == '\n') break
                tokenEnd++
            }
            if (tokenEnd < endOffset) tokenEnd++ // consume closing "
            return T.RAW_STRING
        }

        // Numeric literals
        if (c.isDigit() || (c == '0' && (ch2() == 'x' || ch2() == 'X' || ch2() == 'b' || ch2() == 'o'))) {
            return lexNumber()
        }

        // Identifiers / keywords
        if (c.isLetter() || c == '_') {
            tokenEnd = tokenStart + 1
            while (tokenEnd < endOffset && (buffer[tokenEnd].isLetterOrDigit() || buffer[tokenEnd] == '_')) tokenEnd++
            val word = buffer.subSequence(tokenStart, tokenEnd).toString()
            return T.KEYWORDS[word] ?: T.IDENT
        }

        // Pragma delimiters {. and .}
        if (c == '{' && ch2() == '.') { tokenEnd = tokenStart + 2; return T.PRAGMA_OPEN }
        if (c == '.' && ch2() == '}') { tokenEnd = tokenStart + 2; return T.PRAGMA_CLOSE }

        // Range operator ..
        if (c == '.' && ch2() == '.') { tokenEnd = tokenStart + 2; return T.DOTDOT }

        // Single-char punctuation
        tokenEnd = tokenStart + 1
        return when (c) {
            '=' -> T.EQ
            ':' -> T.COLON
            ',' -> T.COMMA
            '.' -> T.DOT
            '(' -> T.LPAR
            ')' -> T.RPAR
            '[' -> T.LBRACKET
            ']' -> T.RBRACKET
            '{' -> T.LCURLY
            '}' -> T.RCURLY
            '`' -> T.BACKTICK
            '@' -> T.AT
            '+', '-', '*', '/', '<', '>', '!', '&', '|', '^', '~', '%' -> {
                // consume operator run
                while (tokenEnd < endOffset && isOperatorChar(buffer[tokenEnd])) tokenEnd++
                T.OPERATOR
            }
            else -> T.BAD_CHARACTER
        }
    }

    private fun isOperatorChar(c: Char): Boolean =
        c in "+-*/<>!&|^~%=:"

    private fun lexLineComment(type: IElementType): IElementType {
        tokenEnd = tokenStart
        while (tokenEnd < endOffset && buffer[tokenEnd] != '\n' && buffer[tokenEnd] != '\r') tokenEnd++
        return type
    }

    private fun lexString(delimiter: Char, type: IElementType): IElementType {
        tokenEnd = tokenStart + 1
        while (tokenEnd < endOffset) {
            val sc = buffer[tokenEnd]
            if (sc == '\\') {
                tokenEnd += 2  // skip escape sequence
                continue
            }
            if (sc == delimiter) { tokenEnd++; break }
            if (sc == '\n') break  // unterminated
            tokenEnd++
        }
        return type
    }

    private fun lexTripleString(): IElementType {
        tokenEnd = tokenStart + 3
        while (tokenEnd + 2 < endOffset) {
            if (buffer[tokenEnd] == '"' && buffer[tokenEnd + 1] == '"' && buffer[tokenEnd + 2] == '"') {
                tokenEnd += 3
                return T.TRIPLE_STRING
            }
            tokenEnd++
        }
        tokenEnd = endOffset  // unterminated
        return T.TRIPLE_STRING
    }

    private fun lexNumber(): IElementType {
        tokenEnd = tokenStart
        val c0 = buffer[tokenEnd]
        var isFloat = false
        if (c0 == '0' && tokenEnd + 1 < endOffset) {
            val c1 = buffer[tokenEnd + 1]
            if (c1 == 'x' || c1 == 'X') {
                tokenEnd += 2
                while (tokenEnd < endOffset && buffer[tokenEnd].isHexChar()) tokenEnd++
                return T.INT_LIT
            }
            if (c1 == 'b' || c1 == 'B') {
                tokenEnd += 2
                while (tokenEnd < endOffset && (buffer[tokenEnd] == '0' || buffer[tokenEnd] == '1')) tokenEnd++
                return T.INT_LIT
            }
            if (c1 == 'o' || c1 == 'O') {
                tokenEnd += 2
                while (tokenEnd < endOffset && buffer[tokenEnd] in '0'..'7') tokenEnd++
                return T.INT_LIT
            }
        }
        while (tokenEnd < endOffset && (buffer[tokenEnd].isDigit() || buffer[tokenEnd] == '_')) tokenEnd++
        if (tokenEnd < endOffset && buffer[tokenEnd] == '.') {
            val next = if (tokenEnd + 1 < endOffset) buffer[tokenEnd + 1] else '\u0000'
            if (next.isDigit()) {
                isFloat = true
                tokenEnd++
                while (tokenEnd < endOffset && (buffer[tokenEnd].isDigit() || buffer[tokenEnd] == '_')) tokenEnd++
            }
        }
        if (tokenEnd < endOffset && (buffer[tokenEnd] == 'e' || buffer[tokenEnd] == 'E')) {
            isFloat = true
            tokenEnd++
            if (tokenEnd < endOffset && (buffer[tokenEnd] == '+' || buffer[tokenEnd] == '-')) tokenEnd++
            while (tokenEnd < endOffset && buffer[tokenEnd].isDigit()) tokenEnd++
        }
        // optional type suffix (i32, u8, f64, …)
        if (tokenEnd < endOffset && (buffer[tokenEnd] == 'i' || buffer[tokenEnd] == 'u' ||
                    buffer[tokenEnd] == 'f' || buffer[tokenEnd] == 'I' || buffer[tokenEnd] == 'U')) {
            while (tokenEnd < endOffset && buffer[tokenEnd].isLetterOrDigit()) tokenEnd++
        }
        return if (isFloat) T.FLOAT_LIT else T.INT_LIT
    }

    private fun Char.isHexChar(): Boolean = isDigit() || this in 'a'..'f' || this in 'A'..'F'
}
