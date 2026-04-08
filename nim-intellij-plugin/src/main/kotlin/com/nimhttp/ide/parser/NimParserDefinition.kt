package com.nimhttp.ide.parser

import com.intellij.lang.ASTNode
import com.intellij.lang.ParserDefinition
import com.intellij.lang.PsiParser
import com.intellij.lexer.Lexer
import com.intellij.openapi.project.Project
import com.intellij.psi.FileViewProvider
import com.intellij.psi.PsiElement
import com.intellij.psi.PsiFile
import com.intellij.psi.tree.IFileElementType
import com.intellij.psi.tree.TokenSet
import com.nimhttp.ide.lexer.NimLexer
import com.nimhttp.ide.lexer.NimTokenTypes
import com.nimhttp.ide.psi.NimElementTypes
import com.nimhttp.ide.psi.NimFile

/**
 * Entry point that wires together the Nim [Lexer], [PsiParser], and PSI
 * factory for the IntelliJ Platform.
 *
 * Registered in `plugin.xml` under `<lang.parserDefinition>`.
 */
class NimParserDefinition : ParserDefinition {

    override fun createLexer(project: Project): Lexer = NimLexer()

    override fun createParser(project: Project): PsiParser = NimParser()

    override fun getFileNodeType(): IFileElementType = NimElementTypes.FILE

    override fun getCommentTokens(): TokenSet = COMMENTS

    override fun getStringLiteralElements(): TokenSet = STRINGS

    override fun createElement(node: ASTNode): PsiElement =
        NimPsiFactory.createElement(node)

    override fun createFile(viewProvider: FileViewProvider): PsiFile = NimFile(viewProvider)

    companion object {
        val COMMENTS: TokenSet = TokenSet.create(
            NimTokenTypes.COMMENT,
            NimTokenTypes.DOC_COMMENT
        )

        val STRINGS: TokenSet = TokenSet.create(
            NimTokenTypes.STRING_LIT,
            NimTokenTypes.CHAR_LIT,
            NimTokenTypes.RAW_STRING,
            NimTokenTypes.TRIPLE_STRING
        )

        val WHITE_SPACES: TokenSet = TokenSet.create(
            NimTokenTypes.WHITE_SPACE,
            NimTokenTypes.NEWLINE,
            NimTokenTypes.INDENT,
            NimTokenTypes.DEDENT
        )
    }
}
