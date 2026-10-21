# macOS Code Signing & GitHub Release Pipeline Guide

KeyHUD uses GitHub Actions (`.github/workflows/release.yml`) to compile, sign with Apple Developer ID, package into a DMG and ZIP, notarize via Apple's `notarytool`, staple the ticket, and publish release binaries.

---

## 1. Required GitHub Secrets

To enable production code signing and notarization in your GitHub repository, configure the following secrets under **Settings → Secrets and variables → Actions**:

| Secret Name | Description | Example |
|---|---|---|
| `APPLE_CERTIFICATE_P12_BASE64` | Base64-encoded `.p12` file containing your **Developer ID Application** certificate and private key | `MIIKogIBAzCCCm...` |
| `APPLE_CERTIFICATE_PASSWORD` | The export password chosen when exporting the `.p12` certificate | `YourStrongPassword123!` |
| `APPLE_DEVELOPER_ID_NAME` | The exact Common Name of your Developer ID certificate | `Developer ID Application: Your Name (TEAM_ID)` |
| `NOTARY_KEY_ID` | The 10-character Key ID of your App Store Connect API Key | `AB12CD34EF` |
| `NOTARY_ISSUER_ID` | The UUID Issuer ID from App Store Connect | `57246542-96fe-1a63-e053-0824d011072a` |
| `NOTARY_API_KEY_BASE64` | Base64-encoded `.p8` private key file downloaded from App Store Connect | `LS0tLS1CRUdJTi...` |

*(Note: If these secrets are not set, the pipeline automatically falls back to an ad-hoc signed build so PRs and branch pushes can still verify compilation).*

---

## 2. Generating the Secrets

### A. Exporting your Developer ID Certificate (`.p12`)
1. Open **Keychain Access** on your Mac.
2. In the sidebar, select **login** keychain and the **My Certificates** tab.
3. Locate your certificate named **Developer ID Application: Your Name (Team ID)**.
4. Expand it to ensure the private key is attached underneath.
5. Right-click the certificate and choose **Export "Developer ID Application..."**.
6. Format: **Personal Information Exchange (.p12)**.
7. Enter an export password (save this for `APPLE_CERTIFICATE_PASSWORD`).
8. In terminal, convert the file to base64:
   ```bash
   base64 -i ~/Desktop/developer_id.p12 | pbcopy
   ```
   Paste this value into `APPLE_CERTIFICATE_P12_BASE64`.

### B. Creating an App Store Connect API Key (for Notarization)
1. Sign in to [App Store Connect](https://appstoreconnect.apple.com).
2. Navigate to **Users and Access** → **Integrations** (or **Keys**) tab.
3. Under **App Store Connect API**, click the **+** button to generate a new key:
   - **Name**: `KeyHUD Notarization Key`
   - **Access**: `Developer` (or `App Manager`)
4. Copy the **Key ID** (`NOTARY_KEY_ID`) and **Issuer ID** (`NOTARY_ISSUER_ID`).
5. Download the `.p8` file (e.g. `AuthKey_AB12CD34EF.p8`). Note: Apple only allows downloading this file once!
6. In terminal, convert the `.p8` file to base64:
   ```bash
   base64 -i ~/Downloads/AuthKey_AB12CD34EF.p8 | pbcopy
   ```
   Paste this value into `NOTARY_API_KEY_BASE64`.

---

## 3. Triggering a Release

### Automatic (Git Tag)
Create and push a git tag:
```bash
git tag v1.0.0
git push origin v1.0.0
```
The workflow will:
1. Build `KeyHUD.app`.
2. Sign the app with Hardened Runtime and `KeyHUD.entitlements`.
3. Package `KeyHUD-1.0.0.dmg` and `KeyHUD-1.0.0.zip`.
4. Submit to Apple Notary Service and wait for the "Approved" ticket.
5. Staple the ticket to the DMG.
6. Compute SHA256 checksums.
7. Publish a GitHub Release attaching the DMG, ZIP, and checksums.

### Manual (`workflow_dispatch`)
1. Go to the **Actions** tab on your GitHub repo.
2. Select **Build & Release KeyHUD**.
3. Click **Run workflow** and optionally specify a version tag (e.g. `1.0.1`).
