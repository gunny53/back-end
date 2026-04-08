package com.nimhttp.ide.framework

import com.intellij.openapi.project.Project
import com.intellij.openapi.vfs.VirtualFile
import com.intellij.psi.PsiDirectory
import com.intellij.psi.PsiElement
import com.intellij.psi.search.GlobalSearchScope

/**
 * Framework Adapter API – v1 contract (ADR-002).
 *
 * Implement this interface and register your adapter via the
 * `nimFrameworkAdapter` extension point in your plugin's `plugin.xml`
 * to add framework-specific features (route map, DI graph, scaffold) to
 * the Nim plugin.
 *
 * **Stability**: Experimental – subject to breaking changes until 1.0 GA.
 */
interface NimFrameworkAdapter {

    /** Human-readable framework name shown in UI (e.g. "NimHTTP"). */
    val frameworkName: String

    /**
     * API version this adapter targets.  The core plugin emits a warning
     * if `apiVersion < currentApiVersion - 1`.
     */
    val apiVersion: Int get() = 1

    /**
     * Returns `true` if this adapter is applicable to [project].
     * Called lazily on first IDE interaction; result is cached per project
     * until a file-system change invalidates it.
     */
    fun isApplicable(project: Project): Boolean

    /**
     * Discover all HTTP routes defined in [project].
     * The result is cached by the core plugin using stub indexes; the adapter
     * must not perform its own caching.
     */
    fun discoverRoutes(project: Project): List<NimRouteDescriptor>

    /**
     * Discover all framework-level modules (not Nim language modules)
     * defined in [project].
     */
    fun discoverModules(project: Project): List<NimModuleDescriptor>

    /**
     * Resolve a provider [token] string to its defining PSI element within
     * [scope].  Returns `null` if not found.
     */
    fun resolveProvider(token: String, scope: GlobalSearchScope): PsiElement?

    /**
     * Generate scaffold files for the given [kind] ("controller", "module",
     * "service", "middleware") into [context].
     */
    fun generateScaffold(kind: String, context: NimScaffoldContext): NimScaffoldResult
}

// ---------------------------------------------------------------------------
// Data transfer objects
// ---------------------------------------------------------------------------

data class NimRouteDescriptor(
    val method: String,
    val path: String,
    val handlerElement: PsiElement,
    val moduleElement: PsiElement? = null,
    val tags: List<String> = emptyList()
)

data class NimModuleDescriptor(
    val name: String,
    val psiElement: PsiElement,
    val imports: List<String> = emptyList(),
    val providers: List<String> = emptyList(),
    val controllers: List<String> = emptyList(),
    val exports: List<String> = emptyList()
)

data class NimScaffoldContext(
    val project: Project,
    val targetDirectory: PsiDirectory,
    val name: String,
    val options: Map<String, String> = emptyMap()
)

data class NimScaffoldResult(
    /** Generated files as (relative-filename → content) pairs. */
    val files: List<Pair<String, String>>,
    /** Optional: relative filename to open in editor after creation. */
    val openAfterCreate: String? = null
)
