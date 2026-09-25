#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for cmd in curl git helm yq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "error: '$cmd' is required but not installed. Install it and retry." >&2
    exit 2
  fi
done

yq_version_output="$(yq --version)"
if [[ "$yq_version_output" != *"version v4"* ]]; then
  echo "error: yq must be Mike Farah yq v4 (got: $yq_version_output). Install from https://github.com/mikefarah/yq" >&2
  exit 2
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

cd "$repo_root"

app_version="$(yq '.appVersion' Chart.yaml)"
if [[ -z "$app_version" || "$app_version" == "null" ]]; then
  echo "error: appVersion missing or empty in Chart.yaml" >&2
  exit 2
fi

registry="$(yq '.clusterOperator.image.registry' values.yaml)"
repository="$(yq '.clusterOperator.image.repository' values.yaml)"

for field_val in "registry:$registry" "repository:$repository"; do
  field="${field_val%%:*}"
  val="${field_val#*:}"
  if [[ -z "$val" || "$val" == "null" ]]; then
    echo "error: $field missing or empty in values.yaml" >&2
    exit 2
  fi
done

expected_image="${registry}/${repository}:${app_version}"

case "$registry" in
  ghcr.io)  asset="cluster-operator-ghcr-io.yml" ;;
  quay.io)  asset="cluster-operator-quay-io.yml" ;;
  *)
    echo "error: unsupported registry '$registry'. Expected ghcr.io or quay.io." >&2
    exit 2
    ;;
esac

url="https://github.com/rabbitmq/cluster-operator/releases/download/v${app_version}/${asset}"
echo "Fetching upstream manifest: $url"
curl -fsSL "$url" -o "$tmpdir/upstream-raw.yaml"

deployment_count="$(yq eval-all '[select(.kind == "Deployment" and .metadata.name == "rabbitmq-cluster-operator")] | length' "$tmpdir/upstream-raw.yaml")"
if [[ "$deployment_count" != "1" ]]; then
  echo "error: expected exactly one Deployment named rabbitmq-cluster-operator in upstream manifest, found $deployment_count" >&2
  exit 2
fi

upstream_image="$(yq eval-all 'select(.kind == "Deployment" and .metadata.name == "rabbitmq-cluster-operator") | .spec.template.spec.containers[0].image' "$tmpdir/upstream-raw.yaml")"
if [[ "$upstream_image" != "$expected_image" ]]; then
  echo "error: upstream manifest image '$upstream_image' does not match expected '$expected_image'" >&2
  exit 2
fi

echo "Validated upstream image: $expected_image"

helm template rabbitmq "$repo_root" --namespace rabbitmq-system > "$tmpdir/chart-rendered.yaml"

normalize() {
  local side="$1"
  local input="$2"
  local out_dir="$tmpdir/$side"
  mkdir -p "$out_dir"

  local doc_index=0
  local total
  total="$(yq eval-all '[.] | length' "$input")"

  while (( doc_index < total )); do
    local kind name
    kind="$(yq eval-all "select(document_index == $doc_index) | .kind" "$input")"
    name="$(yq eval-all "select(document_index == $doc_index) | .metadata.name" "$input")"

    if [[ "$kind" != "CustomResourceDefinition" && "$kind" != "null" && -n "$kind" && "$name" != "null" && -n "$name" ]]; then
      mkdir -p "$out_dir/$kind"
      yq eval-all "select(document_index == $doc_index) | ... comments=\"\"" "$input" > "$out_dir/$kind/$name.yaml"
    fi

    (( doc_index++ )) || true
  done
}

normalize "upstream" "$tmpdir/upstream-raw.yaml"
normalize "chart" "$tmpdir/chart-rendered.yaml"

echo ""
echo "=== Compare upstream vs chart ==="
echo "Version:   $app_version"
echo "Source:    $url"
echo "Release:   rabbitmq"
echo "Namespace: rabbitmq-system"
echo ""

set +e
git diff --no-index --find-renames "$tmpdir/upstream" "$tmpdir/chart"
diff_exit=$?
set -e

exit $diff_exit
