package app.sway.main

import io.flutter.embedding.android.FlutterActivity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.plugin.common.MethodChannel

// IMPORTS À AJOUTER :
import java.io.InputStream
import java.io.File
import java.io.FileOutputStream

class PdfImportActivity : FlutterActivity() {
    private val CHANNEL = "app.sway.main/pdf"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIncomingPdf(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIncomingPdf(intent)
    }

    private fun handleIncomingPdf(intent: Intent?) {
        if (intent?.action == Intent.ACTION_VIEW) {
            val pdfUri: Uri? = intent.data
            if (pdfUri != null) {
                // Ouvrir un flux
                val inputStream = contentResolver.openInputStream(pdfUri)
                if (inputStream != null) {
                    // Copier le flux dans un fichier de ton app
                    val savedFilePath = copyStreamToAppStorage(inputStream, "imported.pdf")
                    
                    // Ensuite, envoyons ce *vrai* chemin à Flutter
                    MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                        .invokeMethod("openPdf", savedFilePath)
                }
            }
        }
    }

    private fun copyStreamToAppStorage(inputStream: InputStream, filename: String): String {
        // Choisis un dossier (ex. interne ou externe)
        val directory = getExternalFilesDir(null) ?: filesDir
        val outFile = File(directory, filename)

        FileOutputStream(outFile).use { fos ->
            inputStream.copyTo(fos)
        }
        return outFile.absolutePath
    }
}
