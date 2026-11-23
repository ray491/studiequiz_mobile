# Publishing StudieQuiz on F-Droid

Everything in this folder is the submission bundle for
[F-Droid](https://f-droid.org): the build recipe (`fdroiddata` metadata) plus the
listing texts, icon, licence and a checker script.

| Path | What it is |
| --- | --- |
| `metadata/nl.studiequiz.app.yml` | Build recipe: repo, tag, Gradle build, licence, anti-features |
| `metadata/nl.studiequiz.app/en-US/`, `nl-NL/` | Listing: `title.txt`, `summary.txt`, `description.txt`, `changelogs/<versionCode>.txt`, `images/icon.png` |
| `LICENSE` | GNU GPL v3 text (see “Licence” below) |
| `check.sh` | Checks that the recipe, changelogs and store texts match `app/build.gradle` |

Run `bash mobile_app/f-droid/check.sh` after any change.

## 1. Before you submit (all of these are required)

1. **Licence in the repository root.** F-Droid only accepts free software, and
   the licence must be published with the source. This bundle assumes
   **GPL-3.0-or-later** (F-Droid's usual default, and the value in the recipe):

   ```bash
   git mv mobile_app/f-droid/LICENSE LICENSE    # or: cp f-droid/LICENSE ../../LICENSE
   ```

   If you prefer another licence (Apache-2.0, MIT, …), put that text in
   `LICENSE` instead **and** change `License:` in the recipe to the matching
   [SPDX identifier](https://spdx.org/licenses/).

2. **Public repository.** The repo must be reachable without logging in. F-Droid
   builds from `https://github.com/ray491/studiequiz`; if it is still private,
   make it public (or submit a mirror) first.

3. **A release tag.** The recipe builds `commit: v1.0.0`. The only tag now is
   `1.0`, which is the web app, so create a new one:

   ```bash
   git tag -a v1.0.0 -m "StudieQuiz Android 1.0.0"
   git push origin v1.0.0
   ```

   Optionally replace `commit: v1.0.0` in the recipe with the full hash from
   `git rev-list -n1 v1.0.0`; F-Droid prefers full hashes.

4. **Nothing machine-specific committed.** `mobile_app/local.properties` and
   `mobile_app/app/build/` must stay untracked — `check.sh` verifies both, and
   that `gradlew` and `gradle/wrapper/gradle-wrapper.jar` *are* tracked.

## 2. Submit to F-Droid

F-Droid is built from merge requests against the `fdroiddata` repo on GitLab.

```bash
# 1. Fork https://gitlab.com/fdroid/fdroiddata in the GitLab UI, then:
git clone https://gitlab.com/<your-gitlab-user>/fdroiddata.git
cd fdroiddata
git checkout -b nl.studiequiz.app

# 2. Copy the recipe and the listing folder into the checkout
cp  /path/to/studiequiz/mobile_app/f-droid/metadata/nl.studiequiz.app.yml metadata/
cp -r /path/to/studiequiz/mobile_app/f-droid/metadata/nl.studiequiz.app     metadata/

# 3. Lint, commit, push
fdroid lint nl.studiequiz.app
git add metadata/nl.studiequiz.app.yml metadata/nl.studiequiz.app
git commit -m "New app: nl.studiequiz.app"
git push -u origin nl.studiequiz.app
```

Then open a merge request from your branch on GitLab and answer the reviewer's
questions. `fdroid` comes from `pipx install fdroidserver` (or use the
`registry.gitlab.com/fdroid/fdroidserver:buildserver` Docker image from the
[fdroiddata docs](https://gitlab.com/fdroid/fdroiddata/-/blob/master/CONTRIBUTING.md)).

Review takes days to weeks. Once merged, the first build is signed and published
automatically; later releases are picked up from your tags
(`AutoUpdateMode: Version`, `UpdateCheckMode: Tags`).

## 3. Things that will surprise you

* **F-Droid signs the app with its own key.** The APK from F-Droid cannot be
  installed over a build you signed yourself (Play Store, your own release
  keystore) — the signature differs, so users must uninstall first. You also
  cannot push updates to the F-Droid build; F-Droid rebuilds tagged releases.
* **Google sign-in must be registered for F-Droid's certificate.** Google
  Credential Manager checks the app's package name *and* signing certificate
  against your Android OAuth client. F-Droid signs with a per-app key, so after
  the first F-Droid release add that certificate's SHA-1 to the same OAuth
  client in Google Cloud (Console → APIs & Services → Credentials → your Android
  client → add fingerprint). Get it with:

  ```bash
  apksigner verify --print-certs nl.studiequiz.app_1.apk | grep SHA-1
  ```

  Until then, e-mail/password login works in the F-Droid build and the Google
  button will fail.
* **Proprietary dependency risk.** The Google sign-in libraries pull in
  `com.google.android.gms`. If the reviewers object, the fix is a `foss` product
  flavour of the app that drops those two dependencies and hides the Google
  button — say the word and it can be added.
* **Anti-feature `TetheredNet`.** The API host is hardcoded to
  `https://studiequiz.online` and cannot be changed in the app, so F-Droid lists
  that anti-feature. Adding a “server URL” setting would remove it.
* **Screenshots are missing.** Only a 192×192 launcher icon is available (F-Droid
  recommends 512×512). Adding `images/phoneScreenshots/1.png` … to both locale
  folders and a 512×512 `icon.png` makes the listing appear on F-Droid's “Latest”
  tab. Grab them from a device or emulator.
* **The build must succeed on F-Droid's buildserver**, offline from Google
  Maven/Maven Central only (already the case: `google()` + `mavenCentral()` in
  `settings.gradle`). Check a release build locally first:

  ```bash
  cd mobile_app && ./gradlew assembleRelease
  ```

  The APK is unsigned, which is exactly what the buildserver expects (there is no
  `signingConfig` in `app/build.gradle`).

## 4. Releasing an update

1. Bump `versionCode` **and** `versionName` in `mobile_app/app/build.gradle`.
2. Add `metadata/nl.studiequiz.app/{en-US,nl-NL}/changelogs/<new versionCode>.txt`
   (max 500 characters; the filename is the version code, no padding).
3. Update `Builds`, `CurrentVersion` and `CurrentVersionCode` in the recipe —
   or let `fdroid checkupdates` do it — and add a new `Builds` entry (keep the
   old ones).
4. Tag and push (`git tag -a v1.0.1 …`), then either wait for the automatic
   update or open a merge request with the changed recipe.
5. Run `bash mobile_app/f-droid/check.sh` before pushing.

## 5. Contact

F-Droid may mail `contact@studiequiz.online` (the address in the recipe) with
build problems, so keep it monitored.
