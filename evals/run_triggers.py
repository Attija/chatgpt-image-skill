#!/usr/bin/env python3
"""Trigger evals for the gpt-image-transparent skill. Standard library only.

Reads evals/trigger-evals.json ([{"query": ..., "should_trigger": true|false}], the skill-creator
trigger format) and runs every query through `claude -p` with this plugin loaded. A run counts as
triggered when Claude calls the Skill tool for gpt-image-transparent. The run is stopped at the first
Skill call, and Claude only gets Skill/Read/Glob/Grep, so nothing is generated or written.

Usage: python3 evals/run_triggers.py [--runs 3] [--workers 4] [--timeout 90] [--model M] [--json out.json]
Exit 1 when a query fails (positive: triggered in < half the runs; negative: in >= half).
"""
import argparse
import json
import os
import subprocess
import sys
import tempfile
import threading
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKILL = "gpt-image-transparent"


def run_once(query, timeout, model):
    """True if the first Skill call in this run loads the transparent skill."""
    cmd = ["claude", "-p", query, "--plugin-dir", ROOT, "--output-format", "stream-json",
           "--verbose", "--tools", "Skill", "Read", "Glob", "Grep", "--max-turns", "4",
           "--no-session-persistence"]
    if model:
        cmd += ["--model", model]
    env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}
    with tempfile.TemporaryDirectory() as cwd:
        proc = subprocess.Popen(cmd, cwd=cwd, env=env, stdout=subprocess.PIPE,
                                stderr=subprocess.DEVNULL, text=True)
        timer = threading.Timer(timeout, proc.kill)  # a hung run counts as not triggered
        timer.start()
        try:
            for line in proc.stdout:
                try:
                    event = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if event.get("type") != "assistant":
                    continue
                for block in event.get("message", {}).get("content", []):
                    if block.get("type") == "tool_use" and block.get("name") == "Skill":
                        return SKILL in json.dumps(block.get("input", {}))
            return False
        finally:
            timer.cancel()
            proc.kill()
            proc.wait(timeout=10)


def run_safe(query, timeout, model):
    try:
        return run_once(query, timeout, model)
    except Exception as exc:  # a crashed run counts as not triggered
        print(f"warning: run failed: {exc}", file=sys.stderr)
        return False


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--evals", default=os.path.join(ROOT, "evals", "trigger-evals.json"))
    ap.add_argument("--runs", type=int, default=3)
    ap.add_argument("--workers", type=int, default=4)
    ap.add_argument("--timeout", type=int, default=90)
    ap.add_argument("--model")
    ap.add_argument("--json")
    args = ap.parse_args()

    items = json.load(open(args.evals))
    jobs = [(i, it["query"]) for i, it in enumerate(items) for _ in range(args.runs)]
    with ThreadPoolExecutor(args.workers) as pool:
        hits = list(pool.map(lambda j: run_safe(j[1], args.timeout, args.model), jobs))

    results, failed = [], 0
    for i, it in enumerate(items):
        n = sum(h for (k, _), h in zip(jobs, hits) if k == i)
        rate = n / args.runs
        ok = rate >= 0.5 if it["should_trigger"] else rate < 0.5
        failed += not ok
        results.append({**it, "triggered": n, "runs": args.runs, "pass": ok})
        print(f"{'PASS' if ok else 'FAIL'}  {n}/{args.runs}  "
              f"{'moet' if it['should_trigger'] else 'niet'}  {it['query'][:90]}")
    print(f"\n{len(items) - failed}/{len(items)} geslaagd")
    if args.json:
        json.dump(results, open(args.json, "w"), indent=2, ensure_ascii=False)
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
