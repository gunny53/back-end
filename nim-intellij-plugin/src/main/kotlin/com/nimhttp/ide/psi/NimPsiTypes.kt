package com.nimhttp.ide.psi

import com.intellij.psi.tree.IElementType
import com.intellij.psi.tree.IFileElementType
import com.nimhttp.ide.NimLanguage

/**
 * All composite (non-leaf) PSI element types for Nim.
 *
 * **Phase 0 scope**: skeleton set covering top-level declarations.
 * The full set will be generated from `nim.bnf` via GrammarKit in Phase 1.
 */
object NimElementTypes {

    // ---- File root ------------------------------------------------------------
    @JvmField val FILE = IFileElementType("NIM_FILE", NimLanguage)

    // ---- Top-level declarations -----------------------------------------------
    @JvmField val PROC_DEF      = IElementType("PROC_DEF",      NimLanguage)
    @JvmField val FUNC_DEF      = IElementType("FUNC_DEF",      NimLanguage)
    @JvmField val METHOD_DEF    = IElementType("METHOD_DEF",    NimLanguage)
    @JvmField val ITERATOR_DEF  = IElementType("ITERATOR_DEF",  NimLanguage)
    @JvmField val MACRO_DEF     = IElementType("MACRO_DEF",     NimLanguage)
    @JvmField val TEMPLATE_DEF  = IElementType("TEMPLATE_DEF",  NimLanguage)
    @JvmField val CONVERTER_DEF = IElementType("CONVERTER_DEF", NimLanguage)
    @JvmField val TYPE_SECTION  = IElementType("TYPE_SECTION",  NimLanguage)
    @JvmField val TYPE_DEF      = IElementType("TYPE_DEF",      NimLanguage)
    @JvmField val CONST_SECTION = IElementType("CONST_SECTION", NimLanguage)
    @JvmField val LET_SECTION   = IElementType("LET_SECTION",   NimLanguage)
    @JvmField val VAR_SECTION   = IElementType("VAR_SECTION",   NimLanguage)
    @JvmField val IMPORT_STMT   = IElementType("IMPORT_STMT",   NimLanguage)
    @JvmField val INCLUDE_STMT  = IElementType("INCLUDE_STMT",  NimLanguage)
    @JvmField val EXPORT_STMT   = IElementType("EXPORT_STMT",   NimLanguage)
    @JvmField val FROM_IMPORT   = IElementType("FROM_IMPORT",   NimLanguage)

    // ---- Expressions ----------------------------------------------------------
    @JvmField val CALL_EXPR     = IElementType("CALL_EXPR",     NimLanguage)
    @JvmField val DOT_EXPR      = IElementType("DOT_EXPR",      NimLanguage)
    @JvmField val BRACKET_EXPR  = IElementType("BRACKET_EXPR",  NimLanguage)
    @JvmField val INFIX_EXPR    = IElementType("INFIX_EXPR",    NimLanguage)
    @JvmField val PREFIX_EXPR   = IElementType("PREFIX_EXPR",   NimLanguage)
    @JvmField val PAREN_EXPR    = IElementType("PAREN_EXPR",    NimLanguage)
    @JvmField val IF_EXPR       = IElementType("IF_EXPR",       NimLanguage)
    @JvmField val BLOCK_EXPR    = IElementType("BLOCK_EXPR",    NimLanguage)
    @JvmField val TUPLE_CONSTR  = IElementType("TUPLE_CONSTR",  NimLanguage)
    @JvmField val ARRAY_CONSTR  = IElementType("ARRAY_CONSTR",  NimLanguage)

    // ---- Statements -----------------------------------------------------------
    @JvmField val ASSIGN_STMT   = IElementType("ASSIGN_STMT",   NimLanguage)
    @JvmField val RETURN_STMT   = IElementType("RETURN_STMT",   NimLanguage)
    @JvmField val RAISE_STMT    = IElementType("RAISE_STMT",    NimLanguage)
    @JvmField val DISCARD_STMT  = IElementType("DISCARD_STMT",  NimLanguage)
    @JvmField val IF_STMT       = IElementType("IF_STMT",       NimLanguage)
    @JvmField val WHEN_STMT     = IElementType("WHEN_STMT",     NimLanguage)
    @JvmField val FOR_STMT      = IElementType("FOR_STMT",      NimLanguage)
    @JvmField val WHILE_STMT    = IElementType("WHILE_STMT",    NimLanguage)
    @JvmField val TRY_STMT      = IElementType("TRY_STMT",      NimLanguage)
    @JvmField val CASE_STMT     = IElementType("CASE_STMT",     NimLanguage)
    @JvmField val BLOCK_STMT    = IElementType("BLOCK_STMT",    NimLanguage)

    // ---- Sub-nodes ------------------------------------------------------------
    @JvmField val PARAM_LIST    = IElementType("PARAM_LIST",    NimLanguage)
    @JvmField val PARAM_DEF     = IElementType("PARAM_DEF",     NimLanguage)
    @JvmField val PRAGMA_BLOCK  = IElementType("PRAGMA_BLOCK",  NimLanguage)
    @JvmField val OBJECT_BODY   = IElementType("OBJECT_BODY",   NimLanguage)
    @JvmField val FIELD_DEF     = IElementType("FIELD_DEF",     NimLanguage)
    @JvmField val IDENT_DEF     = IElementType("IDENT_DEF",     NimLanguage)
    @JvmField val TYPE_EXPR     = IElementType("TYPE_EXPR",     NimLanguage)
}
