{{/*
Expand the name of the chart.
*/}}
{{- define "helm-template.name" -}}
{{- default .Chart.Name .Values.name | trunc 63 | trimSuffix "-" }}
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
{{- $name := default .Chart.Name .Values.name }}
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

{{- range $akey , $avalue :=  .Values.affinitylable }}
{{  $akey }}: {{ $avalue }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}

{{- define "helm-template.selectorLabels" -}}
app: {{ include "helm-template.name" . }}
{{- end }}

{{/*
Pars Affinity
*/}}
{{- define "helm-template.affinity" -}}
{{- range $typelist := (list "nodeAffinity" "nodeAntiAffinity" "podAntiAffinity" "podAffinity") -}}
{{- $afflag := list 1 -}}
{{- range $rulelist := (list "required" "preferred") -}}
{{- range $Affinities := $.Values.Affinity -}}
{{- if  eq $typelist $Affinities.type -}}
{{- if not (has $typelist $afflag ) -}}
{{- $typelist | nindent 0 -}}:
{{- $afflag = append $afflag $Affinities.type  -}}
{{- end -}}
{{- if eq $rulelist $Affinities.rule -}}
{{- if and (not (has $Affinities.rule  $afflag)) (eq $Affinities.rule "required")   }}
  requiredDuringSchedulingIgnoredDuringExecution:
  {{- if contains "node" $Affinities.type }}
    nodeSelectorTerms:
      - matchExpressions: 
  {{- else if contains "pod" $Affinities.type }}
    - labelSelector:
        matchExpressions:
 {{- end }}
 {{- $afflag = append $afflag  $Affinities.rule  -}}
 {{- end }}
 {{- if eq $Affinities.rule "required" }}
        - key: {{ $Affinities.key }}
          operator: {{ $Affinities.operator }}
          values:
          {{- toYaml $Affinities.values | nindent 10 }}
{{- end }}
{{- if and (not (has $Affinities.rule  $afflag)) (eq $Affinities.rule "preferred")   }}
  preferredDuringSchedulingIgnoredDuringExecution:
{{- $afflag = append $afflag  $Affinities.rule  -}}
{{- end }}
{{- if eq $Affinities.rule "preferred" }}
{{- if contains "node" $Affinities.type }}
  - weight: {{ $Affinities.weight | default "100"  }}
    preference:
      matchExpressions:
      - key: {{ $Affinities.key }}
        operator: {{ $Affinities.operator }}
        values:
        {{- toYaml $Affinities.values | nindent 8 }} 
{{- else if contains "pod" $Affinities.type }}
  - weight: {{ $Affinities.weight | default "100"  }}
    podAffinityTerm:
      labelSelector:
        matchExpressions:
        - key: {{ $Affinities.key }}
          operator: {{ $Affinities.operator }}
          values:
          {{- toYaml $Affinities.values | nindent 12 }}
{{- end }}
{{- end }}
    {{- if and  (contains "pod" $Affinities.type) (eq $Affinities.rule "preferred") }}
      topologyKey: "kubernetes.io/hostname"
    {{- $afflag = append $afflag  "topology"  -}}
    {{- end }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
ENV Secret
*/}}

{{- define "helm-template.envsecrets" -}}
{{- range $key, $val := .Values.secretdata }}
- name: {{  $key | replace "." "_" | upper }}
  valueFrom:
    configMapKeyRef:
      key: {{ $key }}
      name: {{ include "helm-template.name" $ }}-secrets
{{- end }}
{{- end }}

{{/*
Secret Data
*/}}
{{- define "helm-template.secretdata" -}}
{{- range $key, $val := .Values.secretdata }}
{{ $key | indent 2}}: {{ $val | quote }}
{{- end }}
{{- end }}

{{/*
Volume Mounts
*/}}

{{- define "helm-template.volumemount" -}}
{{- if .Values.volumes }}
volumeMounts:
{{- end }}
{{- range $vol := .Values.volumes }}
- mountPath: /opt/{{ $vol.name }}
  name: {{ $vol.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "helm-template.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "helm-template.name" .) .Values.serviceAccount.name }}
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