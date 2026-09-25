# rabbitmq-operator-chart

Helm chart for the RabbitMQ Cluster Operator, wrapping the upstream manifests.
Requires the CRDs from
[rabbitmq-crd-chart](https://github.com/bacluc-agent/rabbitmq-crd-chart).

## Usage

```bash
helm install crds oci://ghcr.io/bacluc-agent/rabbitmq-crd-chart/rabbitmq-crd --version 0.0.1
helm install operator oci://ghcr.io/bacluc-agent/rabbitmq-operator-chart/rabbitmq-operator --version 0.0.1 --create-namespace --namespace rabbitmq-system
```

## Multi-instance support

All namespaced resources are rendered into `.Release.Namespace` and all
cluster-scoped resources (ClusterRoles, ClusterRoleBindings) are suffixed with
`.Release.Name`, so multiple operator instances can be installed into one
cluster. Upstream recommends running one operator per cluster.

## Compare with upstream

Verify that the chart's rendered manifests still match the upstream release:

```bash
./scripts/compare-upstream.sh
```

**Prerequisites:** `curl`, `git`, `helm`, and Mike Farah `yq` v4.

The script reads `appVersion` from `Chart.yaml` and the operator image
`registry`/`repository` from `values.yaml` to select the matching upstream
release asset (`cluster-operator-ghcr-io.yml` for `ghcr.io`,
`cluster-operator-quay-io.yml` for `quay.io`). It downloads that manifest,
validates the Deployment image, renders the chart with `helm template`, strips
`CustomResourceDefinition` resources from both sides (CRDs live in
[rabbitmq-crd-chart](https://github.com/bacluc-agent/rabbitmq-crd-chart)),
normalizes formatting, and runs `git diff`.

Exit codes: `0` = identical, `1` = drift between chart and upstream,
`2` = error (missing dependency, bad version, validation failure).

Helm-specific differences (`.Release.Namespace` / `.Release.Name`
substitutions, labels, and intentionally omitted non-CRD resources such as
cert-manager objects) remain visible in the diff — that is expected.

## Release

Tag `v<version>` to publish the chart to GHCR. The chart version is derived
from the tag.