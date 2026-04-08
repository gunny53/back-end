package com.nimhttp.ide.parser

import com.intellij.lang.ASTNode
import com.intellij.psi.PsiElement
import com.intellij.psi.impl.source.tree.LeafPsiElement
import com.nimhttp.ide.psi.NimElementTypes as E

/**
 * Factory that maps [ASTNode] element types to concrete PSI element classes.
 *
 * In Phase 0 all composite nodes return a generic [com.intellij.extapi.psi.ASTWrapperPsiElement].
 * Dedicated PSI classes (NimProcDef, NimTypeDef, …) will be introduced in Phase 1
 * as navigation and stub index support requires accessing child nodes by role.
 */
object NimPsiFactory {

    fun createElement(node: ASTNode): PsiElement {
        // Leaf tokens are handled by the platform; composites get a wrapper.
        return com.intellij.extapi.psi.ASTWrapperPsiElement(node)
    }
}
