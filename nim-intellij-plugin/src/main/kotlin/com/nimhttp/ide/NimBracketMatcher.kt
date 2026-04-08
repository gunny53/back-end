package com.nimhttp.ide

import com.intellij.lang.BracketPair
import com.intellij.lang.PairedBracketMatcher
import com.intellij.psi.tree.IElementType
import com.nimhttp.ide.lexer.NimTokenTypes as T

/**
 * Defines matching bracket pairs for Nim so IntelliJ highlights the
 * matching bracket and auto-closes pairs during typing.
 */
class NimBracketMatcher : PairedBracketMatcher {

    override fun getPairs(): Array<BracketPair> = PAIRS

    override fun isPairedBracesAllowedBeforeType(lbraceType: IElementType, contextType: IElementType?): Boolean = true

    override fun getCodeConstructStart(file: com.intellij.psi.PsiFile, openingBraceOffset: Int): Int = openingBraceOffset

    companion object {
        private val PAIRS: Array<BracketPair> = arrayOf(
            BracketPair(T.LPAR,     T.RPAR,     false),
            BracketPair(T.LBRACKET, T.RBRACKET, false),
            BracketPair(T.LCURLY,   T.RCURLY,   false),
            BracketPair(T.PRAGMA_OPEN, T.PRAGMA_CLOSE, false)
        )
    }
}
