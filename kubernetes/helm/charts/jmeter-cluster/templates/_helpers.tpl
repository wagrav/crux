{{/* This file holds pod placement rules - hard or soft depending on the run mode */}}
{{/* Generate soft affinity rules - best effort attempt for 1 to 1 placement of pods against nodes */}}
{{- define "best.effort.placement" }}
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 1
              preference:
                matchExpressions:
                  - key: crux.usage
                    operator: In
                    values:
                      - jmeter
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 1
              podAffinityTerm:
                labelSelector:
                  matchExpressions:
                    - key: crux.jmeter_mode
                      operator: In
                      values:
                        - master
                        - slave
                topologyKey: "kubernetes.io/hostname"
{{- end }}

{{/* Generate hard affinity rules - mandatory 1 to 1 placement of pods against nodes - that must occur on given node pool and only on nodes with proper labels if option is set to true */}}
{{- define "required.placement" }}
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  {{ if eq .Values.agentpool.useLabelledNodesOnly true }}
                  - key: crux.usage
                    operator: In
                    values:
                     - jmeter
                  {{ end }}
                  - key: agentpool
                    operator: In
                    values:
                      - {{ .Values.agentpool.name }}
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: crux.jmeter_mode
                operator: In
                values:
                  - master
                  - slave
            topologyKey: "kubernetes.io/hostname"
{{- end }}