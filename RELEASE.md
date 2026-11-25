# Release checklist (for the repository owner)

1. Push the repository to GitHub (public).
2. Build the distributable ZIP locally:

   ```powershell
   .\build.ps1 -CliPath 'C:\path\to\spicetify-cli'
   ```

   For the published build, Spicetify CLI **2.46.7** was used.
3. Create a GitHub Release with tag `v1.0.0` and attach:

   ```text
   Spotify-AdBlock-Portable.zip
   ```

4. SHA256 of the current asset:

   ```text
   4218129C469CFECEBFF5CCD5336A3A1AEDFB9F604BF2A896D973F48A05D4FBC8
   ```

5. Release notes draft:

   > Portable Spotify ad-block setup based on Spicetify Marketplace `adblockify`.
   > Works with standalone Spotify only (not Microsoft Store).
   > Updates stay enabled; repair runs at Spotify launch. No admin rights,
   > no background watcher. See README for install/uninstall instructions.

6. If you rebuild the ZIP, recompute the SHA-256 and replace the value above:

   ```powershell
   Get-FileHash .\dist\Spotify-AdBlock-Portable.zip -Algorithm SHA256
   ```
