{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "secretname" -}}
{{ template "fullname" . }}-secret
{{- end -}}

{{/*
Render structure toYaml or its Tpl if either is present
*/}}
{{- define "renderOptionalYamlOrTpl" -}}
{{- $rawData := get .values .key }}
{{- if not (empty .quote) }}
{{- $rawData = $rawData | toString }}
{{- end }}
{{- $tplData := get .values (print .key "Tpl") }}
{{- if $rawData }}
{{- if empty .skipParent }}
{{ .key }}:{{ printf "\n" }}
{{- end }}
{{- toYaml $rawData | indent (empty .skipParent | ternary 2 0) }}
{{- else if $tplData }}
{{- if empty .skipParent }}
{{ .key }}:{{ printf "\n" }}
{{- end }}
{{- tpl $tplData .context | indent (empty .skipParent | ternary 2 0) }}
{{- end -}}
{{- end -}}

{{/*
Process "env" structure
*/}}
{{- define "env_structure" -}}
{{- $env := get .values .key -}}
{{- if $env -}}
  {{- $secretName := include "secretname" $.root -}}
  {{- range $name, $definition := $env }}
- name: {{ $name | quote }}
  {{- if $definition.sensitive }}
  valueFrom:
    secretKeyRef:
      name: {{ $secretName | quote }}
      key: {{ $definition.key | default $name | quote }}
      {{- if $definition.optional }}
      optional: true
      {{- end }}
  {{- else if or $definition.configMapKeyRef $definition.configMapKeyRefTpl }}
  valueFrom:
{{- include "renderOptionalYamlOrTpl" (dict "context" $.root "values" $definition "key" "configMapKeyRef") | indent 4 }}
  {{- else if or $definition.secretKeyRef $definition.secretKeyRefTpl }}
  valueFrom:
{{- include "renderOptionalYamlOrTpl" (dict "context" $.root "values" $definition "key" "secretKeyRef") | indent 4 }}
  {{- else if or $definition.fieldRef $definition.fieldRefTpl }}
  valueFrom:
{{- include "renderOptionalYamlOrTpl" (dict "context" $.root "values" $definition "key" "fieldRef") | indent 4 }}
  {{- else if or $definition.resourceFieldRef $definition.resourceFieldRefTpl }}
  valueFrom:
{{- include "renderOptionalYamlOrTpl" (dict "context" $.root "values" $definition "key" "resourceFieldRef") | indent 4 }}
  {{- else if or $definition.valueFrom $definition.valueFromTpl }}
{{- include "renderOptionalYamlOrTpl" (dict "context" $.root "values" $definition "key" "valueFrom") | indent 2 }}
  {{- else if or (hasKey $definition "value") (hasKey $definition "valueTpl") }}
  value: {{ include "renderOptionalYamlOrTpl" (dict "context" $.root "values" $definition "key" "value" "skipParent" true "quote" true) }}
  {{- if $definition.optional }}
  optional: true
  {{- end }}
  {{- else }}
  {{- fail (printf "Unable to render variable env.%s: unsupported method" $name) }}
  {{- end }}
  {{- end }}
{{- else -}}
{{- include "renderOptionalYamlOrTpl" (dict "context" .root "values" .values "key" .key "skipParent" true) }}
{{- end -}}
{{- end -}}
