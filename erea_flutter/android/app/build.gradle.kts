import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// La clé de signature vit hors du dépôt : android/key.properties pointe
// vers une keystore que git ignore (voir android/.gitignore). Perdre cette
// clé rend l'app impossible à mettre à jour sur le Play Store — elle se
// sauvegarde ailleurs que sur la machine de développement.
//
// Marche à suivre dans docs/FICHE_PLAY_STORE.md.
val proprietesCle = Properties()
val fichierCle = rootProject.file("key.properties")
if (fichierCle.exists()) {
    fichierCle.inputStream().use { proprietesCle.load(it) }
}

android {
    namespace = "com.teiki.erea"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications s'appuie sur les API de date de
        // Java 8, absentes des vieux Android : sans ce désucrage, le build
        // s'arrête net sur « requires core library desugaring ».
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Le même identifiant que sur l'App Store, volontairement.
        applicationId = "com.teiki.erea"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (fichierCle.exists()) {
                keyAlias = proprietesCle.getProperty("keyAlias")
                keyPassword = proprietesCle.getProperty("keyPassword")
                storeFile = file(proprietesCle.getProperty("storeFile"))
                storePassword = proprietesCle.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Sans key.properties — sur une machine neuve, en CI, chez un
            // contributeur — on retombe sur les clés de debug pour que
            // `flutter run --release` continue de fonctionner. Un tel build
            // n'est pas publiable, et c'est justement ce qu'on veut : la
            // publication exige la vraie clé.
            signingConfig = if (fichierCle.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    // Version exigée par flutter_local_notifications 22.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
