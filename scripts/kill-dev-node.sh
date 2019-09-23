#!/usr/bin/env bash
echo -n "Terminating ganache-cli scripts...";

pgrep -f ganache-cli > /dev/null \
  && kill $(pgrep -f ganache-cli) \
  || echo -n "not running..."

pgrep -f ganache-cli > /dev/null \
  && echo "FAILED" \
  || echo "DONE"
