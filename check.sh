#!/usr/bin/env bash
# Sanity check for the F-Droid submission bundle.
# Usage: bash mobile_app/f-droid/check.sh
set -u

cd "$(dirname "$0")" || exit 1

appid="nl.studiequiz.app"
meta="metadata/$appid"
recipe="metadata/$appid.yml"
gradle="../app/build.gradle"

status=0
ok()   { printf 'ok    %s\n' "$*"; }
warn() { printf 'WARN  %s\n' "$*"; }
fail() { printf 'FAIL  %s\n' "$*"; status=1; }
chars() { tr -d '\n' < "$1" | wc -m | tr -d ' '; }
# value of "key<value>" on any line, quotes stripped
value_of() {
  awk -v k="$2" '{ for (i = 1; i <= NF; i++) if ($i == k) { print $(i + 1); exit } }' "$1" | tr -d "\"'"
}

[ -f "$gradle" ] || { echo "FAIL  $gradle not found - is the Android project still in mobile_app/app?"; exit 1; }
[ -f "$recipe" ] || { echo "FAIL  $recipe not found"; exit 1; }

# --- versions in app/build.gradle ------------------------------------------
gradle_code=$(value_of "$gradle" versionCode)
gradle_name=$(value_of "$gradle" versionName)

if [ -z "$gradle_code" ] || [ -z "$gradle_name" ]; then
  fail "could not read versionCode/versionName from $gradle"
else
  ok "app/build.gradle: versionName=$gradle_name versionCode=$gradle_code"
fi

# --- versions in the recipe ------------------------------------------------
recipe_code=$(value_of "$recipe" versionCode:)
recipe_name=$(value_of "$recipe" versionName:)
cur_code=$(value_of "$recipe" CurrentVersionCode:)
cur_name=$(value_of "$recipe" CurrentVersion:)
commit=$(value_of "$recipe" commit:)

[ "$recipe_code" = "$gradle_code" ] && ok "recipe Builds.versionCode matches ($recipe_code)" \
  || fail "recipe Builds.versionCode is '$recipe_code', app/build.gradle says '$gradle_code'"
[ "$recipe_name" = "$gradle_name" ] && ok "recipe Builds.versionName matches ($recipe_name)" \
  || fail "recipe Builds.versionName is '$recipe_name', app/build.gradle says '$gradle_name'"
[ "$cur_code" = "$gradle_code" ] && ok "recipe CurrentVersionCode matches" \
  || fail "recipe CurrentVersionCode is '$cur_code', expected '$gradle_code'"
[ "$cur_name" = "$gradle_name" ] && ok "recipe CurrentVersion matches" \
  || fail "recipe CurrentVersion is '$cur_name', expected '$gradle_name'"

# --- localized texts, changelog and icon -----------------------------------
for loc in en-US nl-NL; do
  dir="$meta/$loc"
  [ -f "$dir/title.txt" ]     || fail "$loc/title.txt missing"
  [ -f "$dir/summary.txt" ]   || fail "$loc/summary.txt missing"
  [ -f "$dir/description.txt" ] || fail "$loc/description.txt missing"

  if [ -f "$dir/title.txt" ]; then
    n=$(chars "$dir/title.txt")
    [ "$n" -le 50 ] && ok "$loc title: $n chars" || fail "$loc title is $n chars (max 50)"
  fi
  if [ -f "$dir/summary.txt" ]; then
    n=$(chars "$dir/summary.txt")
    [ "$n" -le 80 ] && ok "$loc summary: $n chars" || fail "$loc summary is $n chars (max 80)"
  fi
  if [ -f "$dir/description.txt" ]; then
    n=$(chars "$dir/description.txt")
    [ "$n" -le 4000 ] && ok "$loc description: $n chars" || fail "$loc description is $n chars (max 4000)"
  fi

  log="$dir/changelogs/${gradle_code:-?}.txt"
  if [ -f "$log" ]; then
    n=$(chars "$log")
    [ "$n" -le 500 ] && ok "$loc changelog $gradle_code: $n chars" || fail "$loc changelog is $n chars (max 500)"
  else
    fail "$loc changelog missing (expected $log, named after versionCode)"
  fi

  if [ -f "$dir/images/icon.png" ]; then
    ok "$loc icon.png present"
  else
    fail "$loc images/icon.png missing"
  fi
done

# --- licence ---------------------------------------------------------------
if [ -f LICENSE ]; then
  ok "LICENSE present in this bundle"
else
  fail "LICENSE missing in this bundle"
fi
if [ -f "../../LICENSE" ] || [ -f "../../LICENSE.md" ] || [ -f "../../COPYING" ]; then
  ok "licence file found in repository root"
else
  warn "no LICENSE/COPYING in the repository root yet - copy f-droid/LICENSE there before submitting"
fi

# --- git state F-Droid needs ----------------------------------------------
if [ "$commit" != "" ] && git -C ../.. rev-parse -q --verify "refs/tags/$commit^{commit}" >/dev/null; then
  ok "git tag $commit exists"
else
  warn "git tag '$commit' does not exist yet: git tag -a $commit -m 'StudieQuiz $gradle_name' && git push origin $commit"
fi

if git -C ../.. ls-files --error-unmatch mobile_app/gradlew >/dev/null 2>&1; then
  ok "mobile_app/gradlew is tracked"
else
  fail "mobile_app/gradlew is not tracked by git - F-Droid cannot build without it"
fi
if git -C ../.. ls-files --error-unmatch mobile_app/gradle/wrapper/gradle-wrapper.jar >/dev/null 2>&1; then
  ok "gradle-wrapper.jar is tracked"
else
  fail "mobile_app/gradle/wrapper/gradle-wrapper.jar is not tracked - F-Droid cannot build without it"
fi
if git -C ../.. ls-files --error-unmatch mobile_app/local.properties >/dev/null 2>&1; then
  fail "mobile_app/local.properties is tracked - remove it from git, it must not be published"
else
  ok "mobile_app/local.properties is not tracked"
fi

echo
if [ "$status" -eq 0 ]; then
  echo "All checks passed (warnings above are manual steps)."
else
  echo "Some checks failed - fix them before submitting."
fi
exit "$status"
