#!/usr/bin/env bash
# Run install.sh twice (fresh + re-run) in a clean Ubuntu container, snapshot the
# result, then run test/verify.sh against it.
#   test/run.sh --headless
#   test/run.sh --gui
#   test/run.sh --gui --verify-only   # reuse the last snapshot, only re-run verify.sh
#   PLATFORM=linux/amd64 test/run.sh --gui   # emulate another architecture
set -euo pipefail
cd "$(dirname "$0")/.."

mode="${1:---headless}"
platform=(${PLATFORM:+--platform "$PLATFORM"})
if [[ "${2:-}" != --verify-only ]]; then
    docker build "${platform[@]}" -q -f test/Dockerfile -t machine-setup-test . >/dev/null
    # Drop the previous snapshot first; each one is several GB.
    docker rm -f machine-setup-run >/dev/null 2>&1 || true
    docker rmi machine-setup-installed >/dev/null 2>&1 || true
    docker run "${platform[@]}" --name machine-setup-run machine-setup-test \
        bash -c "./setup/install.sh $mode && ./setup/install.sh $mode >/dev/null"
    docker commit machine-setup-run machine-setup-installed >/dev/null
    docker rm machine-setup-run >/dev/null
fi

# Mount the checks from the host so they can be edited without reinstalling.
docker run "${platform[@]}" --rm -v "$PWD:/home/dev/checks:ro" machine-setup-installed \
    bash /home/dev/checks/test/verify.sh "$mode"
