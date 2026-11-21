# Android Release Signing and Safe Updates

## Why Signing Must Stay Consistent

Android accepts an APK as an update to an already installed app only when the update has the same application/package ID and is signed by the same signing identity as the installed version (or a compatible signing lineage managed by the distribution platform). Keep the package ID stable (`com.vano3667.hexdistrict` in the current Godot export preset) and use the same private release keystore and key for every release. Increase `version/code` (`versionCode`) on every published update.

If the release keystore is lost or replaced, Android generally rejects an in-place update signed with a different certificate. Users may be forced to uninstall the current app before installing the differently signed APK, and uninstalling can remove local save data. Keep secure offline backups of the original keystore and credential recovery information.

## GitHub Actions Secrets

Add each value under the repository's **Settings → Secrets and variables → Actions → New repository secret**. Store them as Actions **secrets**, not plain repository variables. The names below are exactly the ones supplied for this project:

| Repository secret name | Value to store |
|---|---|
| `HOMEMENU_KEYSTORE_BASE64` | The contents of the release `.jks` keystore encoded as Base64 (encode the binary file; do not commit either form). |
| `HOMEMENU_KEYSTORE_PASSWORD` | Password for the keystore. |
| `HOMEMENU_KEY_ALIAS` | Alias of the release key in the keystore (for example, `homemenu` if that is the alias actually created). |
| `HOMEMENU_KEY_PASSWORD` | Password for the selected key alias. |

The `HOMEMENU_` prefix is retained exactly as requested, even though the game project is named Hex District.

Never put real values in this guide, README, source code, `export_presets.cfg`, issues, commit messages, chat, workflow logs or example files. Do not upload the `.jks`, decoded keystore, signing passwords or a Base64 key file to GitHub. Keep the Base64 value private too: Base64 is encoding, not encryption.

## CI Workflow Requirements

- Keep the existing debug APK workflow for development/testing, clearly label the artifact **debug**, and do not use the CI-generated debug keystore as the public release identity.
- A separate release job/preset should consume the four GitHub Actions secrets only at run time. Decode the keystore to a temporary runner directory (for example, under `$RUNNER_TEMP`), pass the passwords/alias directly through protected environment inputs expected by the export tool, avoid printing environment variables or command lines containing credentials, and remove the temporary key file in an always-run cleanup step.
- Release build signing must be enabled and fail closed: if any required secret is missing, skip or fail the release job clearly. Never silently fall back to an unsigned APK or the debug signing key and call it a release.
- Use a release preset/artifact label distinct from the current `Android Debug` preset and `hex-district-debug-apk` artifact. Do not overwrite debug behavior.
- Release automation can be added to `.github/workflows/build.yml` or a dedicated release workflow. Trigger production signing only for a deliberate release/tag/manual release event; normal pushes may continue to run tests and make debug builds.
- Verify the exported APK signature/certificate and package ID. For upgrade testing, install a prior APK signed with the same release certificate and install the new APK over it; confirm Android accepts it without uninstalling. Also confirm `versionCode` increased. Record results in `HANDOFF.md`. Do not claim update compatibility solely because an APK exported.

## Local Encoding Example

Create a Base64 file outside the repository, then copy its contents directly into the `HOMEMENU_KEYSTORE_BASE64` GitHub secret. On Linux:

```sh
base64 -w 0 release-key.jks > /secure/location/release-key.jks.base64
```

On macOS:

```sh
base64 < release-key.jks > /secure/location/release-key.jks.base64
```

Do not commit the `.jks` or `.base64` file. Remove temporary copies from unprotected locations when finished, and preserve encrypted/offline backups of the original keystore and recovery credentials.

## Current Repository State

The current `.github/workflows/build.yml` exports a **debug APK** using Godot's Android Debug preset. The current preset sets package ID `com.vano3667.hexdistrict` and `version/code=1`. As of this guide's addition, this is not yet a production release-signing pipeline, and the presence/configuration of the four GitHub secrets has not been verified. A future agent must inspect the current workflow/preset before changing them, preserve debug CI, and implement release signing only from Actions secrets.
