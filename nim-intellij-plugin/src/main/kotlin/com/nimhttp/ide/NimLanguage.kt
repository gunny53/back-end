package com.nimhttp.ide

import com.intellij.lang.Language

/**
 * Singleton representing the Nim programming language in the IntelliJ Platform.
 *
 * Registered as `com.nimhttp.ide.NimLanguage` and used as the key to associate
 * file types, parsers, syntax highlighters and other language-specific services.
 */
object NimLanguage : Language("Nim") {
    override fun getDisplayName(): String = "Nim"
    override fun isCaseSensitive(): Boolean = true
}
