{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the ccsm chart.
*/}}
{{- define "eric-ccsm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Expand the name of the CCSM Log Config.
*/}}
{{- define "eric-ccsm.log-config.name" -}}
{{- default "eric-ccsm-log-config" ( index .Values "global" "logging" "ccsm" "name" ) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Expand the name of the CNOM Server Dashboard ConfigMap.
*/}}
{{- define "eric-ccsm.cnom-dashboard.name" -}}
{{- default "eric-ccsm-cnom-dashboard" ( index .Values "eric-ccsm-adp" "eric-cnom-server" "dashboards" "configMaps" 0 ) | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Expand the name of the Software Inventory ConfigMap.
*/}}
{{- define "eric-ccsm.swim-config.name" -}}
{{- printf "%s-swim-config" (include "eric-ccsm.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Expand the name of the PM Server ConfigMap.
*/}}
{{- define "eric-ccsm.pm-server-config.name" -}}
{{- default "eric-ccsm-pm-server-config" ( index .Values "eric-ccsm-adp" "eric-pm-server" "server" "configMapOverrideName" ) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Expand the name of the PeerAuthentication.
*/}}
{{- define "eric-ccsm.peer-authentication.name" -}}
{{- printf "%s-peer-authentication" (include "eric-ccsm.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Expand the name of the POD security policy service account.
*/}}
{{- define "eric-ccsm.sa-psp.service-account.name" -}}
{{- printf "%s-sa-psp-service-account" (include "eric-ccsm.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Expand the name of the POD security policy role binding of PSP role to PSP service account
*/}}
{{- define "eric-ccsm.sa-psp.role-binding.name" -}}
{{- printf "%s-sa-psp-role-binding" (include "eric-ccsm.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Expand the name of the PSP role binding of PSP role to default service account
*/}}
{{- define "eric-ccsm.sa-def.role-binding.name" -}}
{{- printf "%s-sa-def-role-binding" (include "eric-ccsm.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Expand the name of the POD security policy role.
*/}}
{{- define "eric-ccsm.sa-psp.role.name" -}}
{{- printf "%s-sa-psp-role" (include "eric-ccsm.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart version as used by the chart label.
*/}}
{{- define "eric-ccsm.version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-ccsm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "eric-ccsm.helm-labels" }}
labels:
  app.kubernetes.io/name: {{ include "eric-ccsm.name" . }}
  app.kubernetes.io/version: {{ include "eric-ccsm.version" . }}
  app.kubernetes.io/instance: {{ .Release.Name }}
  app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end}}

{{/*
Determines if the global security tls is enabled in the adp or ccsm package.
*/}}
{{- define "eric-ccsm.security.tls.enabled" -}}
  {{- if ( index .Values "eric-ccsm-adp" "global" "security" ) }}
    {{- if ( index .Values "eric-ccsm-adp" "global" "security" "tls" ) }}
      {{- if ( index .Values "eric-ccsm-adp" "global" "security" "tls" "enabled" ) }}
        true
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- if .Values.global.security }}
    {{- if .Values.global.security.tls }}
      {{- if .Values.global.security.tls.enabled }}
        true
      {{- end -}}
    {{- end -}}
  {{- end -}}
  false
{{- end -}}

{{/*
Expand the name of the CCSM TAP agent.
*/}}
{{- define "eric-ccsm.tap-agent.name" -}}
eric-tap-agent
{{- end -}}
{{- define "eric-ccsm.tap-agent-pvtb-config.name" -}}
eric-tap-agent-pvtb-config
{{- end -}}

{{/*
Expand the name of ccsm issu config map.
*/}}
{{- define "eric-ccsm.issu.config-name" -}}
eric-ccsm-issu
{{- end -}}

{{/*
Installed ccsm version
*/}}
{{- define "eric-ccsm.issu.installedversion" -}}
{{- $meta := (lookup "v1" "ConfigMap" .Release.Namespace  (include "eric-ccsm.log-config.name" .)  ).metadata }}
{{- if (hasKey $meta "annotations") }}
  {{- print (index $meta.annotations "ericsson.com/semantic-version") }}
{{- else }}
  {{- print (include "eric-ccsm.issu.currentversion" .) }}
{{- end }}
{{- end -}}

{{/*
Current ccsm version
*/}}
{{- define "eric-ccsm.issu.currentversion" -}}
{{- $tmplt := (fromYaml (include "eric-ccsm.helm-annotations" .)) }}
{{- if (hasKey $tmplt "annotations") }}
  {{- print (index $tmplt.annotations "ericsson.com/semantic-version") }}
{{- else }}
  {{- print "1.0.0" }}
{{- end }}
{{- end -}}

{{/*
Issu config data
*/}}
{{- define "eric-ccsm.issu.config-data" -}}
{{- $currentupgrade := dict "from" (include "eric-ccsm.issu.installedversion" .) "to" (include "eric-ccsm.issu.currentversion" .) }}
{{- $upgradesList:= list $currentupgrade }}
{{- if .Release.IsUpgrade }}
  {{- if eq (semver (include "eric-ccsm.issu.installedversion" .) | (semver "1.10.5").Compare) -1 }}
    {{- $dict := (lookup "v1" "ConfigMap" .Release.Namespace  (include "eric-ccsm.issu.config-name" .)  ).data }}
    {{- $config := (get $dict "config.json") }}
    {{- if $config }}
      {{- $configjson := $config | fromJson }}
      {{- if $configjson.upgrades }}
        {{- $upgradesList = concat $configjson.upgrades (list $currentupgrade) }}
      {{- end }}
    {{- end }}
  {{- end -}}
{{- end -}}
{{- toJson (dict "upgrades" $upgradesList) }}
{{- end -}}

{{/*
Check if mtls profile is selected
*/}}
{{- define "eric-ccsm.checkMtls" -}}
  {{- if .Values.global.profiles -}}
    {{- if .Values.global.profiles.mtls -}}
      {{- if .Values.global.profiles.mtls.enabled -}}
        {{- if eq .Values.global.profiles.mtls.enabled true -}}
          {{- "true" -}}
        {{- else -}}
          {{- "false" -}}
        {{- end -}}
      {{- else -}}
        {{- "false" -}}
      {{- end -}}
    {{- else -}}
      {{- "false" -}}
    {{- end -}}
  {{- else -}}
    {{- "false" -}}
  {{- end -}}
{{- end -}}

{{- define "eric-ccsm.checkResources" -}}
  {{- if  .Values.global -}}
    {{- if  .Values.global.profiles -}}
      {{- if
        (or
          (and ( eq ( index .Values "global" "profiles" "small-system" "enabled" ) true ) ( eq ( index .Values "global" "profiles" "std-system" "enabled" ) false ) ( eq ( index .Values "global" "profiles" "ucc-system" "enabled" ) false ))
          (and ( eq ( index .Values "global" "profiles" "std-system" "enabled" ) true ) ( eq ( index .Values "global" "profiles" "small-system" "enabled" ) false ) ( eq ( index .Values "global" "profiles" "ucc-system" "enabled" ) false ))
          (and ( eq ( index .Values "global" "profiles" "ucc-system" "enabled" ) true ) ( eq ( index .Values "global" "profiles" "small-system" "enabled" ) false ) ( eq ( index .Values "global" "profiles" "std-system" "enabled" ) false ))
        )
      -}}
        true
      {{- end -}}
    {{- else -}}
      true
    {{- end -}}
  {{- else -}}
    true
  {{- end -}}
{{- end -}}

{{- define "eric-ccsm.checkSecurity" -}}
  {{- if  .Values.global -}}
    {{- if  .Values.global.profiles -}}
      {{- if not ( eq ( index .Values "global" "profiles" "cleartext" "enabled" ) ( index .Values "global" "profiles" "mtls" "enabled" ) ) -}}
        true
      {{- else if and ( ( eq ( index .Values "global" "profiles" "cleartext" "enabled" ) false ) ( eq ( index .Values "global" "profiles" "mtls" "enabled" ) false ) ) -}}
          true
      {{- end -}}
    {{- else -}}
      true
    {{- end -}}
  {{- else -}}
    true
  {{- end -}}
{{- end -}}

{{- define "eric-ccsm.checkIpVersion" -}}
  {{- if  .Values.global -}}
    {{- if  .Values.global.profiles -}}
      {{- if not ( eq ( index .Values "global" "profiles" "ipv4" "enabled" ) ( index .Values "global" "profiles" "ipv6" "enabled" ) ) -}}
        true
      {{- else if and ( ( eq ( index .Values "global" "profiles" "ipv4" "enabled" ) false ) ( eq ( index .Values "global" "profiles" "ipv6" "enabled" ) false ) ) -}}
          true
      {{- end -}}
    {{- else -}}
      true
    {{- end -}}
  {{- else -}}
    true
  {{- end -}}
{{- end -}}
