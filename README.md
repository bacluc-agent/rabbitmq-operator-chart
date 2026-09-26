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

By default all namespaced resources are rendered into `.Release.Namespace`; with
the scope value below the operator Role and RoleBinding move to the watched
namespaces. All cluster-scoped resources (ClusterRoles, ClusterRoleBindings) are
suffixed with `.Release.Name`, so multiple operator instances can be installed
into one cluster. Upstream recommends running one operator per cluster.

For multi-instance operation, limit each operator instance to a dedicated set
of namespaces:

```yaml
clusterOperator:
  env:
    OPERATOR_SCOPE_NAMESPACE: tenant-a,tenant-b
```

With that value, the release watches RabbitMQ clusters ONLY in the listed
namespaces and has permissions only there: one Role + one RoleBinding per
watched namespace carrying the same rules as the cluster-wide role, plus the
ServiceBinding lookup role per watched namespace. Note the following:

- The namespaces must exist before install.
- Concurrent releases must use disjoint scope lists.
- Each entry must be a DNS-1123 label (<=63 chars); empty entries,
  duplicates and invalid names fail `helm install` with a clear error.
- Omit or blank the value to keep the cluster-wide watch and the
  cluster-scoped ClusterRole/ClusterRoleBinding (default).
- Prefer values files over `--set-string`; commas must be escaped there.

## Release

Tag `v<version>` to publish the chart to GHCR. The chart version is derived
from the tag.