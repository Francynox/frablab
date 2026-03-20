#!@runtimeShell@
set -e -o pipefail
export PATH=@path@

SOPS_KEY_FILE="@sopsKeyPath@"
SECRETS_URL="@remoteSecretsUrl@"
OUTPUT_FILE="/run/nix-private-access.conf"
TEMP_FILE="/tmp/secrets.yaml"

echo "[fetch-pat] Fetching encrypted secrets from public repo..."

if [ ! -f "$SOPS_KEY_FILE" ]; then
  echo "[fetch-pat] ERROR: Host key not found at $SOPS_KEY_FILE"
  echo "[fetch-pat] Skipping PAT setup — private repo access will not work."
  exit 0
fi

if ! curl -sS -f -o "$TEMP_FILE" "$SECRETS_URL"; then
  echo "[fetch-pat] ERROR: Failed to download secrets from $SECRETS_URL"
  exit 1
fi
AGE_KEY=$(ssh-to-age -private-key -i "$SOPS_KEY_FILE")
PAT=$(SOPS_AGE_KEY="$AGE_KEY" sops -d --extract '["github-pat"]' "$TEMP_FILE")
echo "access-tokens = github.com=$PAT" > "$OUTPUT_FILE"
chmod 600 "$OUTPUT_FILE"

rm -f "$TEMP_FILE"

echo "[fetch-pat] PAT configured successfully."
