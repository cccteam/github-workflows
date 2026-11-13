#!/usr/bin/env bash
# Fixture checks for the gate, the bump and the pull request steps of .github/workflows/vuln-autofix.yml.
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
check "two actionable entries, highest severity first" "$([[ "$(jq length "$out")" == 2 && "$(jq -r '.[0].severity' "$out")" == high && "$(grep -c '^count=2$' "$GITHUB_OUTPUT")" == 1 ]] && echo true || echo false)"

# --- bump and check ---------------------------------------------------------------------------------------
# The step runs against small git repositories with fake go, npm and govulncheck commands:
#  go: reads and rewrites go.mod. npm install rewrites every copy in the lock file, npm update changes nothing.
#  govulncheck: prints $GOVULNCHECK_OUT.
step fix
fakebin="$work/bin"; mkdir -p "$fakebin"
cat > "$fakebin/go" <<'GO'
#!/usr/bin/env bash
echo "go $*" >> "$TOOL_LOG"
case "$1 $2" in
  "list -m") awk -v m="$5" '$1 == m {print $2}' go.mod ;;
  "mod edit") jq -n --arg g "$(awk '$1 == "go" {print $2}' go.mod)" '{Go: $g}' ;;
  "get "*)
    mod=${2%@*}; ver=${2#*@}
    if [[ "$mod" == go ]]; then sed -i "s/^go .*/go $ver/" go.mod; else sed -i "s#$mod v[^ ]*#$mod $ver#" go.mod; fi ;;
esac
GO
cat > "$fakebin/npm" <<'NPM'
#!/usr/bin/env bash
echo "npm $*" >> "$TOOL_LOG"
if [[ "$1" == install ]]; then
  jq --arg p "${2%@*}" --arg v "${2##*@}" '.packages |= with_entries(if (.key | endswith("node_modules/" + $p)) then .value.version = $v else . end)' package-lock.json > lock.tmp && mv lock.tmp package-lock.json
fi
NPM
printf '#!/usr/bin/env bash\nprintf "%%s" "${GOVULNCHECK_OUT:-}"\n' > "$fakebin/govulncheck"
chmod +x "$fakebin"/*

new_repo() {
  local d="$work/repo-$1"
  mkdir -p "$d"
  git -C "$d" init -q
  git -C "$d" config user.email t@example.com
  git -C "$d" config user.name t
  printf 'module example.com/app\n\ngo 1.27.1\n\nrequire (\n\tgolang.org/x/net v0.20.0\n\texample.com/old v0.9.0\n)\n' > "$d/go.mod"
  printf '{"name":"a","dependencies":{"direct":"1.0.0"}}\n' > "$d/package.json"
  printf '{"packages":{"":{},"node_modules/direct":{"version":"1.0.0"},"node_modules/transitive":{"version":"2.0.0"},"node_modules/oldmajor":{"version":"1.4.0"}}}\n' > "$d/package-lock.json"
  printf 'FROM golang:1.27.1\n' > "$d/Dockerfile"
  git -C "$d" add -A
  git -C "$d" commit -q -m init
  echo "$d"
}
vuln() { jq -nc --arg e "$1" --arg p "$2" --arg f "$3" '{ecosystem: $e, package: $p, fixed: $f, ids: ["CVE-" + $p], severity: "high"}'; }
fix() { # repo dir, vulnerabilities... -> runs the step
  local d=$1; shift
  printf '%s\n' "$@" | jq -s . > "$RUNNER_TEMP/actionable.json"
  : > "$GITHUB_OUTPUT"; : > "$work/tool.log"
  (cd "$d" && PATH="$fakebin:$PATH" TOOL_LOG="$work/tool.log" bash -eo pipefail "$work/fix.sh" > "$work/fix.log" 2>&1)
}
yes() { "$@" && echo true || echo false; }
reason() { jq -r --arg p "$1" '.[] | select(.package == $p) | .reason' "$RUNNER_TEMP/results.json"; }
at() { git -C "$r" show "$(sed -n "s/^$1=//p" "$GITHUB_OUTPUT"):$2"; } # output name, file -> the file in that commit

r=$(new_repo pass)
fix "$r" "$(vuln go golang.org/x/net v0.23.0)" "$(vuln npm direct 1.0.1)"
check "passing bumps: one commit each, no reason, no first-pass commit" \
  "$([[ "$(reason golang.org/x/net)$(reason direct)" == "" && "$(git -C "$r" rev-list --count HEAD)" == 3 ]] && grep -q '^clean=' "$GITHUB_OUTPUT" && ! grep -q '^draft=' "$GITHUB_OUTPUT" && echo true || echo false)"
check "go module is bumped with go get, a direct npm package with npm install, without install scripts" \
  "$(yes bash -c "grep -qx 'go get golang.org/x/net@v0.23.0' '$work/tool.log' && grep -qx 'npm install direct@1.0.1 --package-lock-only --ignore-scripts --save-exact' '$work/tool.log'")"

r=$(new_repo mixed)
fix "$r" "$(vuln go golang.org/x/net v0.23.0)" "$(vuln go example.com/old v1.2.0)"
check "a major version change is left for a human and does not hold back the other package" \
  "$([[ "$(reason golang.org/x/net)" == "" && "$(reason example.com/old)" == *"major version change"* ]] && at clean go.mod | grep -q 'x/net v0.23.0' && at clean go.mod | grep -q 'old v0.9.0' && echo true || echo false)"
check "the first-pass commit holds the bump that was left out" "$(yes bash -c "git -C '$r' show '$(sed -n 's/^draft=//p' "$GITHUB_OUTPUT")':go.mod | grep -q 'old v1.2.0'")"

r=$(new_repo npm)
fix "$r" "$(vuln npm transitive 2.0.1)" "$(vuln npm oldmajor 2.0.1)"
check "npm: a transitive package is bumped with npm update, and a copy still below the fix is reported" \
  "$([[ "$(reason transitive)" == *"still 2.0.0"* ]] && grep -qx 'npm update transitive --package-lock-only --ignore-scripts' "$work/tool.log" && echo true || echo false)"
check "npm: a copy on an older major than the fix is reported and not bumped" \
  "$([[ "$(reason oldmajor)" == *"major version change, 1.4.0 to 2.0.1"* ]] && ! grep -q '^clean=' "$GITHUB_OUTPUT" && echo true || echo false)"

r=$(new_repo stdlib)
fix "$r" "$(vuln go-stdlib stdlib v1.27.4)"
check "go directive bump with an older golang image in a Dockerfile is left for a human, with a first pass" \
  "$([[ "$(reason stdlib)" == *"Dockerfile uses golang:1.27.1"* ]] && ! grep -q '^clean=' "$GITHUB_OUTPUT" && at draft go.mod | grep -qx 'go 1.27.4' && echo true || echo false)"

r=$(new_repo still)
GOVULNCHECK_OUT='{"osv":{"id":"GO-1","aliases":[]}}{"finding":{"osv":"GO-1","fixed_version":"v0.24.0","trace":[{"module":"golang.org/x/net","function":"F"}]}}' \
  fix "$r" "$(vuln go golang.org/x/net v0.23.0)"
check "a package govulncheck still reports after the bump is left for a human" "$([[ "$(reason golang.org/x/net)" == *"still reports"* ]] && echo true || echo false)"

# --- pull requests ----------------------------------------------------------------------------------------
# The step runs with a fake gh and a local bare repository as the remote
step pr
mkdir -p "$work/remotes/o"
git init -q --bare "$work/remotes/o/r.git"
cat > "$fakebin/gh" <<'GH'
#!/usr/bin/env bash
echo "$*" >> "$GH_LOG"
[[ "$1 $2" == "pr create" ]] && echo "https://example.com/o/r/pull/1"
[[ "$1 $2" == "pr list" && " $* " == *" $GH_OPEN_HEAD "* ]] && echo "https://example.com/o/r/pull/9"
exit 0
GH
chmod +x "$fakebin/gh"
prs() { # repo dir, head branch that has an open pull request -> runs the step on the last fix result
  : > "$work/gh.log"; rm -f "$RUNNER_TEMP/slack.txt"
  (cd "$1" && PATH="$fakebin:$PATH" GH_LOG="$work/gh.log" GH_OPEN_HEAD="${2:-none}" GH_TOKEN=x REPO=o/r GITHUB_SERVER_URL="file://$work/remotes" \
    BRANCH=vuln-autofix BASE_BRANCH=master AUTO_MERGE=true RUN_URL=u \
    BASE="$(sed -n 's/^base=//p' "$GITHUB_OUTPUT")" CLEAN="$(sed -n 's/^clean=//p' "$GITHUB_OUTPUT")" DRAFT="$(sed -n 's/^draft=//p' "$GITHUB_OUTPUT")" \
    bash -eo pipefail "$work/pr.sh" > "$work/pr.log" 2>&1)
}
remote_has() { git -C "$work/remotes/o/r.git" show "$1:go.mod" 2> /dev/null | grep -q "$2"; }

r=$(new_repo pr-mixed)
fix "$r" "$(vuln go golang.org/x/net v0.23.0)" "$(vuln go example.com/old v1.2.0)"
prs "$r"
check "passing packages: ready pull request with auto-merge" \
  "$(yes bash -c "grep -q 'pr create .*--head vuln-autofix --title .*--label dependencies,security\$' '$work/gh.log' && grep -q 'pr merge .* --auto --squash' '$work/gh.log'")"
check "passing branch holds only the passing bump" "$(remote_has vuln-autofix 'x/net v0.23.0' && remote_has vuln-autofix 'old v0.9.0' && echo true || echo false)"
check "packages left for a human: draft pull request labelled needs-human on its own branch, with the reason in the body" \
  "$(yes bash -c "grep -q 'pr create .*--head vuln-autofix-needs-human .*--draft --label dependencies,security,needs-human' '$work/gh.log' && [[ \$(grep -c 'pr merge' '$work/gh.log') == 1 ]] && grep -q 'major version change' '$RUNNER_TEMP/body.md' && grep -q 'v0.9.0 -> v1.2.0' '$RUNNER_TEMP/body.md'")"
check "draft branch holds the first-pass bump" "$(yes remote_has vuln-autofix-needs-human 'old v1.2.0')"
check "Slack text names the package left for a human and the draft pull request" \
  "$(yes bash -c "grep -q 'example.com/old' '$RUNNER_TEMP/slack.txt' && grep -q 'Draft pull request with the first pass: https://example.com/o/r/pull/1' '$RUNNER_TEMP/slack.txt'")"

prs "$r" vuln-autofix
check "open pull request for the branch: updated, not opened again" \
  "$(yes bash -c "grep -q 'pr edit https://example.com/o/r/pull/9' '$work/gh.log' && ! grep -q 'pr create .*--head vuln-autofix --title' '$work/gh.log'")"

prs "$r" vuln-autofix-needs-human
check "open draft pull request: left as it is and not reported again" \
  "$(yes bash -c "! grep -q 'pr create .*needs-human' '$work/gh.log' && ! grep -q 'needs a human' '$RUNNER_TEMP/slack.txt'")"

r=$(new_repo pr-nodiff)
fix "$r" "$(vuln npm oldmajor 2.0.1)"
prs "$r"
check "package left for a human whose bump changed nothing: no pull request, Slack says so" \
  "$(yes bash -c "! grep -q 'pr create' '$work/gh.log' && grep -q 'No pull request holds a first pass' '$RUNNER_TEMP/slack.txt'")"

check "ready pull request with auto-merge: Slack is not told when it opens" "$(yes bash -c "! grep -q 'Security fix pull request' '$RUNNER_TEMP/slack.txt'")"

# --- merged fix -------------------------------------------------------------------------------------------
# The Slack step of the job that runs on a merged fix pull request, with a fake curl that records the payload
step merged
printf '#!/usr/bin/env bash\nprintf "%%s" "${@: -1}" > "$CURL_LOG"\necho "{\\"ok\\":true}"\n' > "$fakebin/curl"; chmod +x "$fakebin/curl"
PATH="$fakebin:$PATH" CURL_LOG="$work/slack.json" SLACK_BOT_TOKEN=x CHANNEL=C1 REPO=o/r PR_URL=https://example.com/o/r/pull/1 \
  PR_BODY="$(printf '## Security fix (automated)\r\n\r\nHighest severity: **critical**\r\n\r\n### Vulnerabilities\r\n- [CRITICAL] CVE-1 `x`: 1.0.0 -> 1.0.1\r\n\r\n### Side effects\r\n- other\r\n')" \
  bash -eo pipefail "$work/merged.sh" > /dev/null 2>&1
check "merged fix: Slack names the severity, the vulnerability, the pull request and the deployment, and not the side effects" \
  "$(jq -r .text "$work/slack.json" | { t=$(cat); [[ "$t" == *"CRITICAL vulnerability fix merged"* && "$t" == *'CVE-1 `x`: 1.0.0 -> 1.0.1'* && "$t" == *"pull/1"* && "$t" == *"needs a deployment"* && "$t" != *other* ]] && echo true || echo false; })"

if [[ $failures -gt 0 ]]; then echo "$failures check(s) failed"; exit 1; fi
echo "all checks passed"
