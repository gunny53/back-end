package com.nimhttp.ide.lexer

import org.junit.Assert.assertEquals
import org.junit.Test
import com.nimhttp.ide.lexer.NimTokenTypes as T

/**
 * Unit tests for [NimLexer].
 *
 * These are plain JUnit4 tests that do not require a running IDE instance,
 * so they execute quickly in CI without the IntelliJ test framework overhead.
 */
class NimLexerTest {

    private fun lex(source: String): List<Pair<String, String>> {
        val lexer = NimLexer()
        lexer.start(source, 0, source.length, 0)
        val tokens = mutableListOf<Pair<String, String>>()
        while (lexer.tokenType != null) {
            val type = lexer.tokenType!!.toString()
            val text = source.substring(lexer.tokenStart, lexer.tokenEnd)
            tokens += type to text
            lexer.advance()
        }
        return tokens
    }

    @Test
    fun `lex empty string`() {
        assertEquals(emptyList<Pair<String, String>>(), lex(""))
    }

    @Test
    fun `lex proc keyword`() {
        val tokens = lex("proc")
        assertEquals(1, tokens.size)
        assertEquals("proc" to "proc", tokens[0])
    }

    @Test
    fun `lex identifier`() {
        val tokens = lex("myVar")
        assertEquals(1, tokens.size)
        assertEquals(T.IDENT.toString() to "myVar", tokens[0])
    }

    @Test
    fun `lex integer literal`() {
        val tokens = lex("42")
        assertEquals(T.INT_LIT.toString() to "42", tokens[0])
    }

    @Test
    fun `lex float literal`() {
        val tokens = lex("3.14")
        assertEquals(T.FLOAT_LIT.toString() to "3.14", tokens[0])
    }

    @Test
    fun `lex hex literal`() {
        val tokens = lex("0xFF")
        assertEquals(T.INT_LIT.toString() to "0xFF", tokens[0])
    }

    @Test
    fun `lex string literal`() {
        val tokens = lex("\"hello\"")
        assertEquals(T.STRING_LIT.toString() to "\"hello\"", tokens[0])
    }

    @Test
    fun `lex triple string`() {
        val tokens = lex("\"\"\"hello world\"\"\"")
        assertEquals(T.TRIPLE_STRING.toString(), tokens[0].first)
    }

    @Test
    fun `lex line comment`() {
        val tokens = lex("# a comment")
        assertEquals(T.COMMENT.toString() to "# a comment", tokens[0])
    }

    @Test
    fun `lex doc comment`() {
        val tokens = lex("## doc")
        assertEquals(T.DOC_COMMENT.toString() to "## doc", tokens[0])
    }

    @Test
    fun `lex pragma delimiters`() {
        val tokens = lex("{.inline.}")
        assertEquals(T.PRAGMA_OPEN.toString()  to "{.", tokens[0])
        assertEquals(T.IDENT.toString()        to "inline", tokens[1])
        assertEquals(T.PRAGMA_CLOSE.toString() to ".}", tokens[2])
    }

    @Test
    fun `lex all Nim keywords are not IDENT`() {
        val keywords = T.KEYWORDS.keys
        for (kw in keywords) {
            val tokens = lex(kw)
            assertEquals("Expected '$kw' to produce exactly one token", 1, tokens.size)
            assert(tokens[0].first != T.IDENT.toString()) {
                "Expected '$kw' to produce a keyword token, got ${tokens[0].first}"
            }
        }
    }

    @Test
    fun `lex whitespace`() {
        val tokens = lex("   ")
        assertEquals(T.WHITE_SPACE.toString(), tokens[0].first)
    }

    @Test
    fun `lex newline`() {
        val tokens = lex("\n")
        assertEquals(T.NEWLINE.toString(), tokens[0].first)
    }
}
