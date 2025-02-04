package co.median.android.files

import android.content.Context
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File


class CapturedImageSaver {
    fun saveCapturedBitmap(context: Context, bitmapUri: Uri): Uri? {

        // notes: Generated image file is only use for temporary storage.
        // There should be only one file instance for the captured image to optimize memory usage.
        // The file should not be deleted immediately as the page may use it indefinitely.
        val imageFileName = "temp_upload_capture_image"
        val extension = "jpg"

        // Save file as cache, should be in "downloads" folder as defined in filepaths.xml
        val downloadsDir = File(context.cacheDir, "downloads")
        if (!downloadsDir.exists()) {
            downloadsDir.mkdirs()  // Create the directory if it doesn't exist
        }
        val captureFile = File(downloadsDir, "$imageFileName.$extension")

        // Copy bitmap to cache file
        val fileUri = FileProvider.getUriForFile(
            context,
            context.applicationContext.packageName + ".fileprovider",
            captureFile
        )
        fileUri?.let {
            context.contentResolver.openOutputStream(it).use { output ->
                context.contentResolver.openInputStream(bitmapUri).use { input ->
                    output?.write(input?.readBytes())
                }
            }
        }

        return fileUri
    }
}