package com.nimhttp.ide.highlight

import com.intellij.openapi.editor.colors.TextAttributesKey
import com.intellij.openapi.fileTypes.SyntaxHighlighter
import com.intellij.openapi.options.colors.AttributesDescriptor
import com.intellij.openapi.options.colors.ColorDescriptor
import com.intellij.openapi.options.colors.ColorSettingsPage
import com.nimhttp.ide.NimIcons
import javax.swing.Icon

/**
 * Registers Nim color attributes in **Settings → Editor → Color Scheme → Nim**.
 */
class NimColorSettingsPage : ColorSettingsPage {

    override fun getIcon(): Icon = NimIcons.FILE
    override fun getHighlighter(): SyntaxHighlighter = NimSyntaxHighlighter()
    override fun getDisplayName(): String = "Nim"
    override fun getColorDescriptors(): Array<ColorDescriptor> = ColorDescriptor.EMPTY_ARRAY

    override fun getAttributeDescriptors(): Array<AttributesDescriptor> = DESCRIPTORS

    override fun getAdditionalHighlightingTagToDescriptorMap(): Map<String, TextAttributesKey>? = null

    override fun getDemoText(): String = DEMO

    companion object {
        private val DESCRIPTORS = arrayOf(
            AttributesDescriptor("Keyword",      NimSyntaxHighlighter.NIM_KEYWORD),
            AttributesDescriptor("Comment",      NimSyntaxHighlighter.NIM_COMMENT),
            AttributesDescriptor("Doc comment",  NimSyntaxHighlighter.NIM_DOC_COMMENT),
            AttributesDescriptor("String",       NimSyntaxHighlighter.NIM_STRING),
            AttributesDescriptor("Number",       NimSyntaxHighlighter.NIM_NUMBER),
            AttributesDescriptor("Identifier",   NimSyntaxHighlighter.NIM_IDENTIFIER),
            AttributesDescriptor("Operator",     NimSyntaxHighlighter.NIM_OPERATOR),
            AttributesDescriptor("Pragma",       NimSyntaxHighlighter.NIM_PRAGMA),
            AttributesDescriptor("Bad character",NimSyntaxHighlighter.NIM_BAD_CHAR)
        )

        private val DEMO = """
## Sample Nim file – color-scheme preview
import std/strutils

type
  User* = object
    name*: string
    age*: int

proc greet*(u: User): string {.inline.} =
  ## Returns a greeting string for the user.
  result = "Hello, " & u.name & "!"

let alice = User(name: "Alice", age: 30)
echo greet(alice)           # prints greeting
echo 3.14 + 1.0             # float literal
echo 0xFF                   # hex literal
        """.trimIndent()
    }
}
