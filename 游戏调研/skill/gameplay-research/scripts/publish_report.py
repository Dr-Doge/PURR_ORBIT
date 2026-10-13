"""Commit explicit report paths and push to the current branch's upstream."""
import argparse
import json
from pathlib import Path
import subprocess
import sys


def publish(repo, paths, message):
    def git(*args):
        result = subprocess.run(
            ["git", "-C", str(repo), *args], capture_output=True,
            encoding="utf-8", errors="replace", timeout=120,
        )
        if result.returncode:
            raise RuntimeError(result.stderr.strip() or result.stdout.strip())
        return result.stdout.strip()

    root = Path(git("rev-parse", "--show-toplevel")).resolve()
    if root != repo:
        raise RuntimeError("--repo must be the repository root")
    allowed = []
    for name in paths:
        path = (root / name).resolve()
        if path == root or not path.is_relative_to(root) or ".git" in path.relative_to(root).parts:
            raise RuntimeError("Report paths must be inside the repository, excluding its root and .git")
        allowed.append(":(literal)" + path.relative_to(root).as_posix())
    if git("diff", "--cached", "--name-only"):
        raise RuntimeError("Existing staged changes: preserve them and resolve before publishing")
    branch = git("symbolic-ref", "--quiet", "--short", "HEAD")
    remote = git("config", "--get", f"branch.{branch}.remote")
    target = git("config", "--get", f"branch.{branch}.merge")
    if remote == "." or not target.startswith("refs/heads/"):
        raise RuntimeError("A remote branch upstream is required")
    git("fetch", remote)
    before = git("rev-parse", "HEAD")
    remote_head = git("ls-remote", "--exit-code", remote, target).split()[0]
    if before != remote_head:
        raise RuntimeError("Local HEAD differs from upstream: review and integrate before publishing")
    git("var", "GIT_AUTHOR_IDENT")
    git("var", "GIT_COMMITTER_IDENT")
    git("add", "--", *allowed)
    changed = bool(git("diff", "--cached", "--name-only"))
    if changed:
        git("commit", "-m", message, "--only", "--", *allowed)
    head = git("rev-parse", "HEAD")
    git("push", remote, f"HEAD:{target}")
    confirmed = git("ls-remote", "--exit-code", remote, target).split()[0]
    if confirmed != head:
        raise RuntimeError("Remote changed before verification: publication needs review")
    return {"status": "published", "commit_created": changed, "commit": head,
            "branch": branch, "remote": remote, "target": target, "paths": paths}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, required=True)
    parser.add_argument("--message", required=True)
    parser.add_argument("paths", nargs="+")
    args = parser.parse_args()
    try:
        result = publish(args.repo.resolve(), args.paths, args.message)
    except (RuntimeError, subprocess.TimeoutExpired, OSError) as exc:
        print(f"Publication stopped; preserve local files/commits and report the issue: {exc}", file=sys.stderr)
        return 1
    print(json.dumps(result, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
