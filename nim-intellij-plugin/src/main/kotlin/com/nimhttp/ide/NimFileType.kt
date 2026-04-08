package com.nimhttp.ide

import com.intellij.openapi.fileTypes.LanguageFileType
import javax.swing.Icon

/**
 * FileType for `.nim` and `.nims` source files.
 *
 * Registered via `plugin.xml` under `<fileType>` so IntelliJ associates
 * `.nim` extensions with this language automatically.
 */
object NimFileType : LanguageFileType(NimLanguage) {
    override fun getName(): String = "Nim"
    override fun getDescription(): String = "Nim source file"
    override fun getDefaultExtension(): String = "nim"
    override fun getIcon(): Icon = NimIcons.FILE
}
