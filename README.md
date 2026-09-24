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

## Release

Tag `v<version>` to publish the chart to GHCR. The chart version is derived
from the tag.