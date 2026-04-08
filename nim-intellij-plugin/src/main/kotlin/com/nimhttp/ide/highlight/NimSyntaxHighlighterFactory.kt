package com.nimhttp.ide.highlight

import com.intellij.openapi.fileTypes.SyntaxHighlighter
import com.intellij.openapi.fileTypes.SyntaxHighlighterFactory
import com.intellij.openapi.project.Project
import com.intellij.openapi.vfs.VirtualFile

/**
 * Factory that creates [NimSyntaxHighlighter] instances.
 * Registered in `plugin.xml` under `<lang.syntaxHighlighterFactory>`.
 */
class NimSyntaxHighlighterFactory : SyntaxHighlighterFactory() {
    override fun getSyntaxHighlighter(project: Project?, virtualFile: VirtualFile?): SyntaxHighlighter =
        NimSyntaxHighlighter()
}
