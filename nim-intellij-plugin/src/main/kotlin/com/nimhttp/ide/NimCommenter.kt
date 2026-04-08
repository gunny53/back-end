package com.nimhttp.ide

import com.intellij.lang.Commenter

/**
 * Tells the IDE that `#` is the Nim line-comment prefix.
 * Enables **Code → Comment with Line Comment** (Ctrl+/).
 */
class NimCommenter : Commenter {
    override fun getLineCommentPrefix(): String = "# "
    override fun getBlockCommentPrefix(): String? = null
    override fun getBlockCommentSuffix(): String? = null
    override fun getCommentedBlockCommentPrefix(): String? = null
    override fun getCommentedBlockCommentSuffix(): String? = null
}
