package com.nimhttp.ide.lexer

import com.intellij.psi.tree.IElementType
import com.nimhttp.ide.NimLanguage

/**
 * Element types used by [NimLexer].
 *
 * This object is the single source of truth for all token types.  The list
 * intentionally covers only the tokens needed for Phase 0 syntax highlighting;
 * additional tokens will be added incrementally during Phase 1 grammar work.
 */
object NimTokenTypes {
    // ---- Whitespace & comments ------------------------------------------------
    @JvmField val WHITE_SPACE   = IElementType("WHITE_SPACE",   NimLanguage)
    @JvmField val COMMENT       = IElementType("COMMENT",       NimLanguage)  // # …
    @JvmField val DOC_COMMENT   = IElementType("DOC_COMMENT",   NimLanguage)  // ## …

    // ---- Literals -------------------------------------------------------------
    @JvmField val INT_LIT       = IElementType("INT_LIT",       NimLanguage)
    @JvmField val FLOAT_LIT     = IElementType("FLOAT_LIT",     NimLanguage)
    @JvmField val STRING_LIT    = IElementType("STRING_LIT",    NimLanguage)  // "…"
    @JvmField val CHAR_LIT      = IElementType("CHAR_LIT",      NimLanguage)  // '…'
    @JvmField val RAW_STRING    = IElementType("RAW_STRING",    NimLanguage)  // r"…"
    @JvmField val TRIPLE_STRING = IElementType("TRIPLE_STRING", NimLanguage)  // """…"""

    // ---- Identifiers & keywords -----------------------------------------------
    @JvmField val IDENT         = IElementType("IDENT",         NimLanguage)

    // Keywords (exhaustive list as of Nim 2.x)
    @JvmField val KW_ADDR        = IElementType("addr",        NimLanguage)
    @JvmField val KW_AND         = IElementType("and",         NimLanguage)
    @JvmField val KW_AS          = IElementType("as",          NimLanguage)
    @JvmField val KW_ASM         = IElementType("asm",         NimLanguage)
    @JvmField val KW_BIND        = IElementType("bind",        NimLanguage)
    @JvmField val KW_BLOCK       = IElementType("block",       NimLanguage)
    @JvmField val KW_BREAK       = IElementType("break",       NimLanguage)
    @JvmField val KW_CASE        = IElementType("case",        NimLanguage)
    @JvmField val KW_CAST        = IElementType("cast",        NimLanguage)
    @JvmField val KW_CONCEPT     = IElementType("concept",     NimLanguage)
    @JvmField val KW_CONST       = IElementType("const",       NimLanguage)
    @JvmField val KW_CONTINUE    = IElementType("continue",    NimLanguage)
    @JvmField val KW_CONVERTER   = IElementType("converter",   NimLanguage)
    @JvmField val KW_DEFER       = IElementType("defer",       NimLanguage)
    @JvmField val KW_DISCARD     = IElementType("discard",     NimLanguage)
    @JvmField val KW_DISTINCT    = IElementType("distinct",    NimLanguage)
    @JvmField val KW_DIV         = IElementType("div",         NimLanguage)
    @JvmField val KW_DO          = IElementType("do",          NimLanguage)
    @JvmField val KW_ELIF        = IElementType("elif",        NimLanguage)
    @JvmField val KW_ELSE        = IElementType("else",        NimLanguage)
    @JvmField val KW_END         = IElementType("end",         NimLanguage)
    @JvmField val KW_ENUM        = IElementType("enum",        NimLanguage)
    @JvmField val KW_EXCEPT      = IElementType("except",      NimLanguage)
    @JvmField val KW_EXPORT      = IElementType("export",      NimLanguage)
    @JvmField val KW_FINALLY     = IElementType("finally",     NimLanguage)
    @JvmField val KW_FOR         = IElementType("for",         NimLanguage)
    @JvmField val KW_FROM        = IElementType("from",        NimLanguage)
    @JvmField val KW_FUNC        = IElementType("func",        NimLanguage)
    @JvmField val KW_IF          = IElementType("if",          NimLanguage)
    @JvmField val KW_IMPORT      = IElementType("import",      NimLanguage)
    @JvmField val KW_IN          = IElementType("in",          NimLanguage)
    @JvmField val KW_INCLUDE     = IElementType("include",     NimLanguage)
    @JvmField val KW_INTERFACE   = IElementType("interface",   NimLanguage)
    @JvmField val KW_IS          = IElementType("is",          NimLanguage)
    @JvmField val KW_ISNOT       = IElementType("isnot",       NimLanguage)
    @JvmField val KW_ITERATOR    = IElementType("iterator",    NimLanguage)
    @JvmField val KW_LET         = IElementType("let",         NimLanguage)
    @JvmField val KW_MACRO       = IElementType("macro",       NimLanguage)
    @JvmField val KW_METHOD      = IElementType("method",      NimLanguage)
    @JvmField val KW_MIXIN       = IElementType("mixin",       NimLanguage)
    @JvmField val KW_MOD         = IElementType("mod",         NimLanguage)
    @JvmField val KW_NIL         = IElementType("nil",         NimLanguage)
    @JvmField val KW_NOT         = IElementType("not",         NimLanguage)
    @JvmField val KW_NOTIN       = IElementType("notin",       NimLanguage)
    @JvmField val KW_OBJECT      = IElementType("object",      NimLanguage)
    @JvmField val KW_OF          = IElementType("of",          NimLanguage)
    @JvmField val KW_OR          = IElementType("or",          NimLanguage)
    @JvmField val KW_OUT         = IElementType("out",         NimLanguage)
    @JvmField val KW_PROC        = IElementType("proc",        NimLanguage)
    @JvmField val KW_PTR         = IElementType("ptr",         NimLanguage)
    @JvmField val KW_RAISE       = IElementType("raise",       NimLanguage)
    @JvmField val KW_REF         = IElementType("ref",         NimLanguage)
    @JvmField val KW_RETURN      = IElementType("return",      NimLanguage)
    @JvmField val KW_SHL         = IElementType("shl",         NimLanguage)
    @JvmField val KW_SHR         = IElementType("shr",         NimLanguage)
    @JvmField val KW_STATIC      = IElementType("static",      NimLanguage)
    @JvmField val KW_TEMPLATE    = IElementType("template",    NimLanguage)
    @JvmField val KW_TRY         = IElementType("try",         NimLanguage)
    @JvmField val KW_TUPLE       = IElementType("tuple",       NimLanguage)
    @JvmField val KW_TYPE        = IElementType("type",        NimLanguage)
    @JvmField val KW_USING       = IElementType("using",       NimLanguage)
    @JvmField val KW_VAR         = IElementType("var",         NimLanguage)
    @JvmField val KW_WHEN        = IElementType("when",        NimLanguage)
    @JvmField val KW_WHILE       = IElementType("while",       NimLanguage)
    @JvmField val KW_XOR         = IElementType("xor",         NimLanguage)
    @JvmField val KW_YIELD       = IElementType("yield",       NimLanguage)

    // ---- Operators & punctuation ----------------------------------------------
    @JvmField val EQ        = IElementType("EQ",        NimLanguage)  // =
    @JvmField val COLON     = IElementType("COLON",     NimLanguage)  // :
    @JvmField val COMMA     = IElementType("COMMA",     NimLanguage)  // ,
    @JvmField val DOT       = IElementType("DOT",       NimLanguage)  // .
    @JvmField val DOTDOT    = IElementType("DOTDOT",    NimLanguage)  // ..
    @JvmField val LPAR      = IElementType("LPAR",      NimLanguage)  // (
    @JvmField val RPAR      = IElementType("RPAR",      NimLanguage)  // )
    @JvmField val LBRACKET  = IElementType("LBRACKET",  NimLanguage)  // [
    @JvmField val RBRACKET  = IElementType("RBRACKET",  NimLanguage)  // ]
    @JvmField val LCURLY    = IElementType("LCURLY",    NimLanguage)  // {
    @JvmField val RCURLY    = IElementType("RCURLY",    NimLanguage)  // }
    @JvmField val BACKTICK  = IElementType("BACKTICK",  NimLanguage)  // `
    @JvmField val AT        = IElementType("AT",        NimLanguage)  // @
    @JvmField val PRAGMA_OPEN  = IElementType("PRAGMA_OPEN",  NimLanguage) // {.
    @JvmField val PRAGMA_CLOSE = IElementType("PRAGMA_CLOSE", NimLanguage) // .}
    @JvmField val OPERATOR  = IElementType("OPERATOR",  NimLanguage)  // generic op

    // ---- Indentation tokens (used for indent-sensitive parsing) ---------------
    @JvmField val INDENT    = IElementType("INDENT",    NimLanguage)
    @JvmField val DEDENT    = IElementType("DEDENT",    NimLanguage)
    @JvmField val NEWLINE   = IElementType("NEWLINE",   NimLanguage)

    // ---- Error ----------------------------------------------------------------
    @JvmField val BAD_CHARACTER = IElementType("BAD_CHARACTER", NimLanguage)

    // Keyword lookup map for O(1) classification during lexing
    val KEYWORDS: Map<String, IElementType> = mapOf(
        "addr" to KW_ADDR, "and" to KW_AND, "as" to KW_AS, "asm" to KW_ASM,
        "bind" to KW_BIND, "block" to KW_BLOCK, "break" to KW_BREAK,
        "case" to KW_CASE, "cast" to KW_CAST, "concept" to KW_CONCEPT,
        "const" to KW_CONST, "continue" to KW_CONTINUE, "converter" to KW_CONVERTER,
        "defer" to KW_DEFER, "discard" to KW_DISCARD, "distinct" to KW_DISTINCT,
        "div" to KW_DIV, "do" to KW_DO, "elif" to KW_ELIF, "else" to KW_ELSE,
        "end" to KW_END, "enum" to KW_ENUM, "except" to KW_EXCEPT,
        "export" to KW_EXPORT, "finally" to KW_FINALLY, "for" to KW_FOR,
        "from" to KW_FROM, "func" to KW_FUNC, "if" to KW_IF,
        "import" to KW_IMPORT, "in" to KW_IN, "include" to KW_INCLUDE,
        "interface" to KW_INTERFACE, "is" to KW_IS, "isnot" to KW_ISNOT,
        "iterator" to KW_ITERATOR, "let" to KW_LET, "macro" to KW_MACRO,
        "method" to KW_METHOD, "mixin" to KW_MIXIN, "mod" to KW_MOD,
        "nil" to KW_NIL, "not" to KW_NOT, "notin" to KW_NOTIN,
        "object" to KW_OBJECT, "of" to KW_OF, "or" to KW_OR, "out" to KW_OUT,
        "proc" to KW_PROC, "ptr" to KW_PTR, "raise" to KW_RAISE,
        "ref" to KW_REF, "return" to KW_RETURN, "shl" to KW_SHL, "shr" to KW_SHR,
        "static" to KW_STATIC, "template" to KW_TEMPLATE, "try" to KW_TRY,
        "tuple" to KW_TUPLE, "type" to KW_TYPE, "using" to KW_USING,
        "var" to KW_VAR, "when" to KW_WHEN, "while" to KW_WHILE,
        "xor" to KW_XOR, "yield" to KW_YIELD
    )
}
