package com.nimhttp.ide.psi

import com.intellij.extapi.psi.PsiFileBase
import com.intellij.openapi.fileTypes.FileType
import com.intellij.psi.FileViewProvider
import com.nimhttp.ide.NimFileType
import com.nimhttp.ide.NimLanguage

/**
 * PSI file node for `.nim` files.
 *
 * All PSI trees for Nim source files are rooted at [NimFile].
 * It is instantiated by [com.nimhttp.ide.parser.NimParserDefinition] and
 * backed by a [NimElementTypes.FILE] element type.
 */
class NimFile(viewProvider: FileViewProvider) : PsiFileBase(viewProvider, NimLanguage) {
    override fun getFileType(): FileType = NimFileType
    override fun toString(): String = "NimFile(${virtualFile?.name ?: "<no-file>"})"
}
