# Install Brickbound Isles on macOS

1. Download `Brickbound-Isles-0.1.0.dmg` from the GitHub Release and open it.
2. Drag **Brickbound Isles.app** to **Applications**.
3. Eject the mounted disk image, then open the app from Applications.

This release is ad-hoc signed so the app bundle has a valid code seal, but it is not notarized or signed under a Brickbound Isles Developer ID. macOS may still show a Gatekeeper warning for the downloaded app. Control-click the app in Finder and choose **Open**. If that option is unavailable, try opening the app once, then go to **System Settings → Privacy & Security** and choose **Open Anyway** for Brickbound Isles. macOS remembers this exception for later launches.

If macOS reports that the app is damaged or cannot be verified, first compare the downloaded disk image's SHA-256 value with `SHA256SUMS.txt` on the release page. If the checksum matches, open Terminal and run `xattr -dr com.apple.quarantine "/Applications/Brickbound Isles.app"`.

For an app downloaded from the internet, only override Gatekeeper if you trust the source and have verified the release asset. The release page provides the project source and a SHA-256 checksum for the disk image.
