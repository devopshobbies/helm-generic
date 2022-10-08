{{/*
Expand the name of the chart.
*/}}
{{- define "helm-template.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* 
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "helm-template.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}


{{- define "helm-template.namespace" -}}
{{- default  .Values.namespace | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* 
Create chart name and version as used by the chart label.
*/}}
{{- define "helm-template.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "helm-template.labels" -}}
helm.sh/chart: {{ include "helm-template.chart" . }}
{{ include "helm-template.selectorLabels" . }}

{{- range $affinity :=  .Values.Affinity -}}
{{- range $value :=   $affinity.values -}}
{{- if and ($affinity.key) ($value) }}
{{  $affinity.key }}: {{ $value  }}
{{- end }}
{{- end }}
{{- end }}

{{- range $antiaffinity :=  .Values.AntiAffinity -}}
{{- range $value :=   $antiaffinity.values -}}
{{- if and ($antiaffinity.key) ($value) }}
{{  $antiaffinity.key }}: {{ $value  }}
{{- end }}
{{- end }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "helm-template.selectorLabels" -}}
app: {{ include "helm-template.fullname" . }}
{{- end }}


{{/*
affinity
*/}}

{{- define "helm-template.affinity" -}}
{{- range $typelist := list "nodeAffinity" "nodeAntiAffinity" "podAntiAffinity" "podAffinity" }}
{{- $afflag := list 1 -}}
{{- range $rulelist := list "required" "preferred" }}
{{- range $Affinities := .Values.Affinity -}}
{{- if  eq $typelist $Affinities.type -}}
{{- if not (has $typelist $afflag ) -}}
{{ $typelist | nindent 0 }}:
{{- $afflag = append $afflag $Affinities.type  -}}
{{- end -}}
{{- if eq $rulelist $Affinities.rule -}}
{{- if and (not (has $Affinities.rule  $afflag) (eq $Affinities.rule "required") )  -}}
  requiredDuringSchedulingIgnoredDuringExecution:
{{- if has "node" $Affinities.type -}}
    nodeSelectorTerms:
    - matchExpressions: 
{{- else if has "pod" $Affinities.type -}}
  - labelSelector:
      matchExpressions:
{{- end -}}
{{- $afflag = append $afflag  $Affinities.rule  -}}
{{- end }}
{{- if eq $Affinities.rule "required" -}}
      - key: {{ $Affinities.key }}
        operator: {{ $Affinities.operator }}
        values:
        {{- toYaml $Affinities.values | nindent 8 }}
{{- end }}
{{- if and (not (has $Affinities.rule  $afflag) (eq $Affinities.rule "preferred") )  -}}
  preferredDuringSchedulingIgnoredDuringExecution:
{{- $afflag = append $afflag  $Affinities.rule  -}}
{{- end }}
{{- if eq $Affinities.rule "preferred" -}}
{{- if has "node" $Affinities.type -}}
  - weight: {{ $Affinities.weight | default "100"  }}
      preference:
        matchExpressions:
        - key: {{ $Affinities.key }}
          operator: {{ $Affinities.operator }}
          values:
          {{- toYaml $Affinities.values | nindent 8 }} 
{{- else if has "pod" $Affinities.type -}}
  - weight: {{ $Affinities.weight | default "100"  }}
    podAffinityTerm:
      labelSelector:
        matchExpressions:
        - key: {{ $Affinities.key }}
          operator: {{ $Affinities.operator }}
          values:
          {{- toYaml $Affinities.values | nindent 10 }}
{{- end -}}
{{- end -}}

{{- end -}}
{{- end -}}

{{- end }}
{{if has "pod" $typelist -}}
      topologyKey: "kubernetes.io/hostname"
{{- end -}}

{{- end }}
{{- end }}
{{- end -}}



{{/*
Create the name of the service account to use
*/}}
{{- define "helm-template.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "helm-template.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{ define "render-value" }}
  {{- if kindIs "string" .value }}
    {{- tpl .value .context }}
  {{- else }}
    {{- tpl (.value | toYaml) .context }}     
  {{- end }}
{{- end }}