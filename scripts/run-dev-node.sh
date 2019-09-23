#!/usr/bin/env bash
# Source (adopted): openzeppelin-solidity/scripts/test.sh

# Exit script as soon as a command fails.
set -o errexit

# Executes cleanup function at script exit.
trap cleanup EXIT

cleanup() {
  # Kill the ganache instance that we started (if we started one and if it's still running).
  if [ -n "$ganache_pid" ] && ps -p $ganache_pid > /dev/null; then
    kill -9 $ganache_pid
  fi
}

ganache_port=8555

ganache_installed() {
  [ -f node_modules/.bin/ganache-cli ] && true || false
}

ganache_running() {
  nc -z localhost "$ganache_port"
}

install_ganache() {
  echo "ganache-cli is not installed. installing..."
  npm install ganache-cli
}

start_ganache() {
  tenEthers="10000000000000000000"
  thousandEthers="1000000000000000000000"

  # local accounts
  local accounts=(
    --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501200,${thousandEthers}"
    --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501201,${tenEthers}"
    --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501202,${tenEthers}"
    --account="0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501203,${tenEthers}"
  )

  node_modules/.bin/ganache-cli --gasLimit 0xfffffffffff --port "$ganache_port" "${accounts[@]}" &2>1 &
  ganache_pid=$!

  echo "Waiting for ganache (pid=${ganache_pid}) to launch on port "$ganache_port"..."

  while ! ganache_running; do
    sleep 0.1 # wait for 1/10 of the second before check again
  done

  echo "Ganache launched!"
}

if ganache_running; then
  echo "Using existing ganache instance"
else
  echo "Checking if ganache installed"
  ganache_installed || install_ganache
  echo "Starting our own ganache instance"
  start_ganache
  ganache_running && {
    echo "ganache-cli started in background.";
    echo "'kill-dev-node.sh' to kill it";
  }
fi
