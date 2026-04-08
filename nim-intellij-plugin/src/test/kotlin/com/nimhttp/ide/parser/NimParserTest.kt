package com.nimhttp.ide.parser

import com.intellij.testFramework.ParsingTestCase

/**
 * Parser test harness for Phase 0.
 *
 * Extends [ParsingTestCase] which loads `.nim` fixtures from
 * `src/test/resources/testData/parser/` and compares the resulting PSI tree
 * against a golden `.txt` file of the same name.
 *
 * To add a new test case:
 * 1. Create `src/test/resources/testData/parser/<name>.nim` with Nim source.
 * 2. Run the test once – it will fail and print the actual PSI tree.
 * 3. Copy the actual tree into `<name>.txt` as the expected output.
 * 4. Subsequent runs will succeed as long as the parser output is stable.
 *
 * Usage:
 * ```
 * ./gradlew test --tests "com.nimhttp.ide.parser.NimParserTest"
 * ```
 */
class NimParserTest : ParsingTestCase(
    /* dataPath    = */ "testData/parser",
    /* fileExt     = */ "nim",
    /* lowercaseFirstLetter = */ true,
    /* definitions = */ NimParserDefinition()
) {

    override fun getTestDataPath(): String =
        "src/test/resources"

    override fun includeRanges(): Boolean = true

    // -------------------------------------------------------------------------
    // Test cases
    // -------------------------------------------------------------------------

    /** Empty file should produce a valid (empty) PSI tree without errors. */
    fun testEmpty() = doTest(true)

    /** Basic proc declaration. */
    fun testProcDecl() = doTest(true)

    /** Type section with object declaration. */
    fun testTypeSection() = doTest(true)

    /** Import statement. */
    fun testImport() = doTest(true)

    /** Const section. */
    fun testConstSection() = doTest(true)

    /** Pragma on proc. */
    fun testPragma() = doTest(true)

    /** From-import statement. */
    fun testFromImport() = doTest(true)

    /** Comment and doc comment tokens. */
    fun testComments() = doTest(true)
}
