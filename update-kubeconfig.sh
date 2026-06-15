#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KUBE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG="$KUBE_DIR/config"
BACKUP_DIR="$SCRIPT_DIR/backups"
EXTRA_CONFIGS="$SCRIPT_DIR/extra-configs"

# Backup
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/config_$(date +%Y%m%d_%H%M%S).yaml"
cp "$CONFIG" "$BACKUP_FILE"
echo "✓ Backup saved: $BACKUP_FILE"

# Discover extra config files
if [[ ! -d "$EXTRA_CONFIGS" ]]; then
  echo "Extra configs directory not found: $EXTRA_CONFIGS" >&2
  exit 1
fi

EXTRA_CONFIG_FILES=()
while IFS= read -r -d '' FILE; do
  EXTRA_CONFIG_FILES+=("$FILE")
done < <(find "$EXTRA_CONFIGS" -maxdepth 1 -type f ! -name '.*' -print0 | sort -z)

if [[ ${#EXTRA_CONFIG_FILES[@]} -eq 0 ]]; then
  echo "No extra config files found in: $EXTRA_CONFIGS" >&2
  exit 1
fi

# Delete old entries that will be replaced by extra configs
for EXTRA_CONFIG_FILE in "${EXTRA_CONFIG_FILES[@]}"; do
  while IFS= read -r NAME; do
    [[ -n "$NAME" ]] || continue
    kubectl --kubeconfig "$CONFIG" config delete-context "$NAME" >/dev/null 2>&1 && echo "✓ Deleted context: $NAME" || echo "⚠ Context not found: $NAME"
  done < <(kubectl config view --kubeconfig "$EXTRA_CONFIG_FILE" -o jsonpath='{range .contexts[*]}{.name}{"\n"}{end}')

  while IFS= read -r NAME; do
    [[ -n "$NAME" ]] || continue
    kubectl --kubeconfig "$CONFIG" config delete-cluster "$NAME" >/dev/null 2>&1 && echo "✓ Deleted cluster: $NAME" || echo "⚠ Cluster not found: $NAME"
  done < <(kubectl config view --kubeconfig "$EXTRA_CONFIG_FILE" -o jsonpath='{range .clusters[*]}{.name}{"\n"}{end}')

  while IFS= read -r NAME; do
    [[ -n "$NAME" ]] || continue
    kubectl --kubeconfig "$CONFIG" config delete-user "$NAME" >/dev/null 2>&1 && echo "✓ Deleted user: $NAME" || echo "⚠ User not found: $NAME"
  done < <(kubectl config view --kubeconfig "$EXTRA_CONFIG_FILE" -o jsonpath='{range .users[*]}{.name}{"\n"}{end}')
done

# Merge
KUBECONFIG="$(IFS=:; echo "$CONFIG:${EXTRA_CONFIG_FILES[*]}")" \
  kubectl config view --flatten > "$CONFIG.tmp"

mv "$CONFIG.tmp" "$CONFIG"
echo "✓ Config merged successfully"

# Cleanup old backups (keep last 10)
ls -t "$BACKUP_DIR"/config_*.yaml | tail -n +11 | xargs rm -f 2>/dev/null
echo "✓ Old backups cleaned up"
