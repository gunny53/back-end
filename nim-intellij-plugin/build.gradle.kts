plugins {
    id("org.jetbrains.intellij.platform") version "2.3.0"
    kotlin("jvm") version "2.0.21"
}

group = "com.nimhttp.ide"
version = "0.1.0-alpha"

repositories {
    mavenCentral()
    intellijPlatform {
        defaultRepositories()
    }
}

dependencies {
    intellijPlatform {
        intellijIdeaCommunity("2024.3")
        bundledPlugin("com.intellij.java")
        pluginVerifier()
        zipSigner()
        instrumentationTools()
    }
    testImplementation("junit:junit:4.13.2")
}

intellijPlatform {
    pluginConfiguration {
        name = "Nim Language Support"
        version = project.version.toString()

        ideaVersion {
            sinceBuild = "243"
            untilBuild = "253.*"
        }
    }

    signing {
        // Configure via environment variables CERTIFICATE_CHAIN, PRIVATE_KEY, PRIVATE_KEY_PASSWORD
    }

    publishing {
        token = providers.environmentVariable("PUBLISH_TOKEN")
    }
}

kotlin {
    jvmToolchain(17)
}

tasks.test {
    useJUnit()
    systemProperty("idea.test.execution.policy", "com.intellij.testFramework.UsefulTestCase")
}
