{{- /*
rabbitmqOperator.scopeNamespaces
Returns the normalized list of namespaces from clusterOperator.env.OPERATOR_SCOPE_NAMESPACE
as a comma-joined string (no spaces), or "" when unset/blank. Splits on commas, trims
whitespace per segment, rejects empty segments, duplicates, and names that are not
DNS-1123 labels (<=63 chars). Callers turn the string into a list with:
  without (splitList "," (include "rabbitmqOperator.scopeNamespaces" .)) ""
*/ -}}
{{- define "rabbitmqOperator.scopeNamespaces" -}}
{{- $env := default dict .Values.clusterOperator.env -}}
{{- $rawValue := get $env "OPERATOR_SCOPE_NAMESPACE" -}}
{{- if and $rawValue (not (kindIs "string" $rawValue)) -}}
{{- fail "OPERATOR_SCOPE_NAMESPACE must be a comma-separated string, not a YAML list, map, or other non-string value" -}}
{{- end -}}
{{- $raw := default "" $rawValue -}}
{{- if eq (trim $raw) "" -}}
{{- "" -}}
{{- else -}}
{{- $scopes := list -}}
{{- range $segment := splitList "," $raw -}}
{{- $ns := trim $segment -}}
{{- if eq $ns "" -}}
{{- fail "OPERATOR_SCOPE_NAMESPACE contains an empty namespace (check for leading/trailing/double commas)" -}}
{{- end -}}
{{- if gt (len $ns) 63 -}}
{{- fail (printf "OPERATOR_SCOPE_NAMESPACE contains invalid namespace %q: longer than 63 characters" $ns) -}}
{{- end -}}
{{- if not (regexMatch "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$" $ns) -}}
{{- fail (printf "OPERATOR_SCOPE_NAMESPACE contains invalid namespace %q: must be a DNS-1123 label (lowercase alphanumeric, '-', start/end alphanumeric, max 63 chars)" $ns) -}}
{{- end -}}
{{- if has $ns $scopes -}}
{{- fail (printf "OPERATOR_SCOPE_NAMESPACE contains duplicate namespace %q" $ns) -}}
{{- end -}}
{{- $scopes = append $scopes $ns -}}
{{- end -}}
{{- join "," $scopes -}}
{{- end -}}
{{- end -}}

{{- /*
rabbitmqOperator.isScoped
Renders "true" when at least one scoped namespace is configured, "" otherwise.
*/ -}}
{{- define "rabbitmqOperator.isScoped" -}}
{{- if ne (include "rabbitmqOperator.scopeNamespaces" .) "" -}}true{{- end -}}
{{- end -}}
