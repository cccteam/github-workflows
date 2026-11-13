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
check "alert for a manifest in a subdirectory is skipped" "$(has 'any(.package == "example.com/in-subdirectory") | not')"
check "fixed version with shell metacharacters is dropped" "$(has 'any(.package == "evil/pkg") | not')"
check "fixed Dependabot alert and govulncheck finding merge into one entry" \
  "$(has 'map(select(.package == "golang.org/x/net")) | length == 1 and .[0].fixed == "v0.23.0" and .[0].severity == "high" and (.[0].sources | length == 2)')"
check "stdlib finding selected as go-stdlib with its fixed version" \
  "$(has 'any(.ecosystem == "go-stdlib" and .fixed == "v1.27.4" and (.ids | index("GO-2026-6859")))')"
check "two actionable entries, top severity high" "$([[ "$(jq length "$out")" == 2 && "$(grep -c '^top-severity=high$' "$GITHUB_OUTPUT")" == 1 ]] && echo true || echo false)"

# --- diff guard -------------------------------------------------------------------------------------------
# A failed guard no longer discards the change: it records a problem and keeps the first-pass diff.
step guard
step pr
guard() { # repo dir -> runs the guard in it
  : > "$GITHUB_OUTPUT"
  rm -f "$RUNNER_TEMP/problems.txt"
  (cd "$1" && BASE_SHA=$(git rev-parse HEAD) bash -eo pipefail "$work/guard.sh" > /dev/null 2>&1)
}
clean() { guard "$1"; [[ ! -s "$RUNNER_TEMP/problems.txt" ]] && grep -q '^has-diff=true$' "$GITHUB_OUTPUT"; }
flagged() { # repo dir, pattern: diff kept, problem recorded
  guard "$1"; grep -q '^has-diff=true$' "$GITHUB_OUTPUT" && grep -q "$2" "$RUNNER_TEMP/problems.txt"
}
yes() { "$@" && echo true || echo false; }
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

r=$(new_repo ok)
sed -i 's/v0.20.0/v0.23.0/' "$r/go.mod"
check "minor bump of go.mod passes every guard" "$(yes clean "$r")"
check "summary shows old to new" "$(yes grep -q 'v0.20.0 -> v0.23.0' "$RUNNER_TEMP/summary.md")"

# PR step with a fake gh and a local bare remote: records how the pull request is created
fakebin="$work/bin"; mkdir -p "$fakebin" "$work/remotes/o"
git init -q --bare "$work/remotes/o/r.git"
cat > "$fakebin/gh" <<'GH'
#!/usr/bin/env bash
echo "$*" >> "$GH_LOG"
[[ "$1 $2" == "pr create" ]] && echo "https://example.com/o/r/pull/1"
[[ "$1 $2" == "pr list" ]] && echo "${GH_OPEN_PR:-}"
exit 0
GH
chmod +x "$fakebin/gh"
open_pr() { # repo dir -> runs the PR step in it
  : > "$GITHUB_OUTPUT"; : > "$work/gh.log"
  (cd "$1" && PATH="$fakebin:$PATH" GH_LOG="$work/gh.log" GH_TOKEN=x REPO=o/r GITHUB_SERVER_URL="file://$work/remotes" \
    BRANCH="b-$(basename "$1")" BASE_BRANCH=master TOP_SEVERITY=high LABELS=dependencies,security NEEDS_HUMAN_LABEL=needs-human \
    AUTO_MERGE=true RUN_URL=u bash -eo pipefail "$work/pr.sh" > /dev/null 2>&1)
}
clean "$r"; open_pr "$r"
check "clean path: ready PR (not draft) with auto-merge enabled" \
  "$(yes bash -c "grep -q 'pr create' '$work/gh.log' && ! grep -q -- '--draft' '$work/gh.log' && ! grep -q 'needs-human' '$work/gh.log' && grep -q 'pr merge .* --auto --squash' '$work/gh.log' && grep -q '^needs-human=false$' '$GITHUB_OUTPUT'")"

r=$(new_repo extra)
sed -i 's/v0.20.0/v0.23.0/' "$r/go.mod"
printf '// changed\n' >> "$r/main.go"
check "a source file in the diff is flagged and kept" "$(yes flagged "$r" 'main.go')"
open_pr "$r"
check "guard failure: draft PR labelled needs-human, auto-merge never enabled" \
  "$(yes bash -c "grep -q -- '--draft' '$work/gh.log' && grep -q 'needs-human' '$work/gh.log' && ! grep -q 'pr merge' '$work/gh.log' && grep -q '^needs-human=true$' '$GITHUB_OUTPUT' && grep -q 'main.go' '$RUNNER_TEMP/pr-body.md'")"
check "first-pass branch was pushed" "$(yes git -C "$work/remotes/o/r.git" show-ref --verify -q "refs/heads/b-repo-extra")"

r=$(new_repo update)
sed -i 's/v0.20.0/v0.23.0/' "$r/go.mod"
clean "$r"; GH_OPEN_PR=https://example.com/o/r/pull/1 open_pr "$r"
check "open pull request for the branch: updated, not opened again, not reported again" \
  "$(yes bash -c "grep -q 'pr edit' '$work/gh.log' && ! grep -q 'pr create' '$work/gh.log' && ! grep -q '^pr-url=' '$GITHUB_OUTPUT'")"

r=$(new_repo major)
sed -i 's#golang.org/x/net v0.20.0#golang.org/x/net v1.0.0#' "$r/go.mod"
check "a major version change is flagged and kept" "$(yes flagged "$r" 'major')"

r=$(new_repo nochange)
guard "$r"
check "no change: no diff, problem recorded, no PR" "$(yes bash -c "grep -q '^has-diff=false$' '$GITHUB_OUTPUT' && grep -q 'no change' '$RUNNER_TEMP/problems.txt'")"

# --- bump -------------------------------------------------------------------------------------------------
# The bump step with fake go and npm: records the commands it runs
step fix
for tool in go npm; do printf '#!/usr/bin/env bash\necho "%s $*" >> "$TOOL_LOG"\n' "$tool" > "$fakebin/$tool"; chmod +x "$fakebin/$tool"; done
r=$(new_repo bump)
printf '{"name":"a","dependencies":{"direct":"1.0.0"}}\n' > "$r/package.json"
printf '[{"ecosystem":"go","package":"golang.org/x/net","fixed":"v0.23.0"},{"ecosystem":"go-stdlib","package":"stdlib","fixed":"v1.27.4"},{"ecosystem":"npm","package":"direct","fixed":"1.0.1"},{"ecosystem":"npm","package":"transitive","fixed":"2.0.1"}]' > "$RUNNER_TEMP/actionable.json"
(cd "$r" && PATH="$fakebin:$PATH" TOOL_LOG="$work/tool.log" bash -eo pipefail "$work/fix.sh" > /dev/null 2>&1)
check "bump runs go get for a module and for the go directive, npm install for a direct package and npm update for a transitive one" \
  "$(yes bash -c "grep -qx 'go get golang.org/x/net@v0.23.0' '$work/tool.log' && grep -qx 'go get go@1.27.4' '$work/tool.log' && grep -qx 'npm install direct@1.0.1 --package-lock-only --ignore-scripts' '$work/tool.log' && grep -qx 'npm update transitive --package-lock-only --ignore-scripts' '$work/tool.log'")"

if [[ $failures -gt 0 ]]; then echo "$failures check(s) failed"; exit 1; fi
echo "all checks passed"
