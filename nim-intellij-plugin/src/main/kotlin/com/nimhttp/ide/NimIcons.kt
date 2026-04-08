package com.nimhttp.ide

import com.intellij.openapi.util.IconLoader

/**
 * Central icon registry for the Nim plugin.
 *
 * Icons live in `src/main/resources/icons/`. Use 16x16 SVG or PNG (dark-
 * theme variants end with `_dark`).
 */
object NimIcons {
    /** Icon shown next to `.nim` files in the Project tree. */
    @JvmField
    val FILE = IconLoader.getIcon("/icons/nim_file.svg", NimIcons::class.java)

    /** Icon for Nim procedure/function declarations. */
    @JvmField
    val PROC = IconLoader.getIcon("/icons/nim_proc.svg", NimIcons::class.java)

    /** Icon for Nim type declarations. */
    @JvmField
    val TYPE = IconLoader.getIcon("/icons/nim_type.svg", NimIcons::class.java)

    /** Icon for Nim module (`.nim` used as a module). */
    @JvmField
    val MODULE = IconLoader.getIcon("/icons/nim_module.svg", NimIcons::class.java)
}
