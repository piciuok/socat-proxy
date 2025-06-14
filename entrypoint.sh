#!/bin/bash
set -e

start_socat_proxy() {
  local proto=$1
  local listen_port=$2
  local target_port=$3

  echo "[$proto] Proxying :$listen_port → $TARGET_HOST:$target_port"
  if [[ "$proto" == "TCP" ]]; then
    socat TCP-LISTEN:$listen_port,fork TCP:$TARGET_HOST:$target_port &
  elif [[ "$proto" == "UDP" ]]; then
    socat UDP-LISTEN:$listen_port,fork UDP:$TARGET_HOST:$target_port &
  fi
}

if [[ -z "$TARGET_HOST" ]]; then
  echo "Error: TARGET_HOST must be set."
  exit 1
fi

if [[ -n "$TCP_PORT_MAP" ]]; then
  IFS=',' read -ra TCP_MAPPINGS <<< "$TCP_PORT_MAP"
  for mapping in "${TCP_MAPPINGS[@]}"; do
    mapping=$(echo "$mapping" | xargs)
    IFS=':' read -r listen_port target_port <<< "$mapping"
    [[ -n "$listen_port" && -n "$target_port" ]] && start_socat_proxy "TCP" "$listen_port" "$target_port"
  done
fi

if [[ -n "$UDP_PORT_MAP" ]]; then
  IFS=',' read -ra UDP_MAPPINGS <<< "$UDP_PORT_MAP"
  for mapping in "${UDP_MAPPINGS[@]}"; do
    mapping=$(echo "$mapping" | xargs)
    IFS=':' read -r listen_port target_port <<< "$mapping"
    [[ -n "$listen_port" && -n "$target_port" ]] && start_socat_proxy "UDP" "$listen_port" "$target_port"
  done
fi

# Keep container alive
tail -f /dev/null
