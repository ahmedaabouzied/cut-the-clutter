#!/usr/bin/env bash
# Produce the before/after answers quoted in the README.
#
# Each question runs twice in each of two conditions, same model both times:
#
#   baseline  no user/project settings, no CLAUDE.md, no hooks, no plugin,
#             started in an empty temp directory, tools off
#   plugin    the same, plus --plugin-dir pointing at this repo, so the
#             plugin's UserPromptSubmit hook prints SKILL.md before the turn
#
# Answers land in examples/raw/, one file per run, verbatim. The per-run line
# printed here reports the model id the CLI used and which hooks fired, which
# is how you check that the baseline is clean and the plugin hook ran.

set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
raw="$repo/examples/raw"
logs="${LOG_DIR:-$(mktemp -d)}"
work="$(mktemp -d)"   # empty: nothing here for Claude to pick up
mkdir -p "$raw"

common=(-p --model opus --setting-sources "" --tools ""
        --output-format stream-json --include-hook-events --verbose
        --no-session-persistence)

run() { # name condition repetition prompt
  local name=$1 cond=$2 rep=$3 prompt=$4
  local extra=() json="$logs/$name-$cond-$rep.jsonl"
  [ "$cond" = plugin ] && extra=(--plugin-dir "$repo")
  ( cd "$work" && claude "${common[@]}" "${extra[@]}" "$prompt" ) > "$json"
  jq -r 'select(.type=="result") | .result' "$json" > "$raw/$name-$cond-$rep.txt"
  printf '%-26s model=%s hooks=[%s] words=%s\n' \
    "$name-$cond-$rep" \
    "$(jq -r 'select(.type=="result") | .modelUsage | keys[0]' "$json")" \
    "$(jq -r 'select(.subtype=="hook_started") | .hook_name' "$json" | sort -u | tr '\n' ' ' | sed 's/ $//')" \
    "$(wc -w < "$raw/$name-$cond-$rep.txt" | tr -d ' ')"
}

flaky_test=$(cat <<'EOF'
Why is this Go test flaky?

func TestWorker(t *testing.T) {
	var count int
	w := NewWorker()
	w.OnDone(func() { count++ })
	w.Start(3) // runs 3 jobs, each in its own goroutine
	time.Sleep(100 * time.Millisecond)
	if count != 3 {
		t.Fatalf("got %d, want 3", count)
	}
}
EOF
)

git_error=$(cat <<'EOF'
What does this git error mean?

$ git push
 ! [rejected]        main -> main (non-fast-forward)
error: failed to push some refs to 'github.com:me/app.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart.
EOF
)

mutex_channel="In Go, when should I use a mutex and when should I use a channel?"

deploy_failed=$(cat <<'EOF'
Why did my deploy fail?

$ kubectl rollout status deploy/api
Waiting for deployment "api" rollout to finish: 1 of 3 updated replicas are available...
error: deployment "api" exceeded its progress deadline
$ kubectl get pods
api-7d9f4c8b6-2xk4l   0/1   CrashLoopBackOff   5   6m
$ kubectl logs api-7d9f4c8b6-2xk4l
panic: dial tcp 10.0.3.14:5432: connect: connection refused
EOF
)

uuid_or_id="Should I use a UUID or an auto-increment integer as the primary key for a new Postgres table?"

for rep in 1 2; do
  for cond in baseline plugin; do
    run flaky-test    "$cond" "$rep" "$flaky_test"
    run git-error     "$cond" "$rep" "$git_error"
    run mutex-channel "$cond" "$rep" "$mutex_channel"
    run deploy-failed "$cond" "$rep" "$deploy_failed"
    run uuid-or-id    "$cond" "$rep" "$uuid_or_id"
  done
done

echo "raw answers: $raw"
echo "stream logs: $logs"
