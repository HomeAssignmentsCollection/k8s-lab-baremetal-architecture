# Detailed Architecture Diagrams

## 1. High-Level System Architecture

```mermaid
graph TB
    subgraph "Infrastructure Layer"
        TF[Terraform Infrastructure]
        ANS[Ansible Configuration]
        LB[Load Balancer]
    end
    
    subgraph "Kubernetes Platform"
        CP[Control Plane]
        WK[Worker Nodes]
        NS[Namespaces]
    end
    
    subgraph "Platform Services"
        NET[Networking: MetalLB + CNI]
        STOR[Storage: Local + NFS]
        SEC[Security: RBAC + Policies]
    end
    
    subgraph "Application Layer"
        CICD[CI/CD: Jenkins]
        GITOPS[GitOps: ArgoCD]
        MON[Monitoring: Prometheus + Grafana]
        LOG[Logging: ELK Stack]
        ART[Artifacts: Artifactory]
        TROUBLESHOOT[Logging & Troubleshooting]
    end
    
    TF --> ANS
    ANS --> CP
    ANS --> WK
    LB --> CP
    CP --> WK
    NS --> CP
    NS --> WK
    NET --> CP
    NET --> WK
    STOR --> WK
    SEC --> NS
    CICD --> NS
    GITOPS --> NS
    MON --> NS
    LOG --> NS
    ART --> NS
    TROUBLESHOOT --> NS
```

---

## 2. Infrastructure Provisioning Block

```mermaid
graph LR
    subgraph "Terraform Configuration"
        TFV[Variables]
        TFM[Main Config]
        TFT[Templates]
    end
    
    subgraph "Generated Artifacts"
        INV[Ansible Inventory]
        K8SC[Kubernetes Config]
        NETC[Network Config]
    end
    
    subgraph "Ansible Automation"
        PREP[System Preparation]
        PKG[Package Installation]
        K8S[Kubernetes Setup]
        CNI[CNI Installation]
    end
    
    TFV --> TFM
    TFM --> TFT
    TFT --> INV
    TFT --> K8SC
    TFT --> NETC
    INV --> PREP
    INV --> PKG
    INV --> K8S
    INV --> CNI
```

---

## 3. Kubernetes Cluster Architecture

```mermaid
graph TB
    subgraph "Control Plane"
        API[API Server]
        SCH[Scheduler]
        CM[Controller Manager]
        ETCD[etcd]
    end
    
    subgraph "Worker Nodes"
        KUBELET[Kubelet]
        KUBEPROXY[Kube-proxy]
        CONTAINERD[Container Runtime]
    end
    
    subgraph "Load Balancer"
        HA[Haproxy/Keepalived]
    end
    
    subgraph "Namespaces"
        MON[monitoring]
        JENKINS[jenkins]
        GITOPS[gitops]
        ARTIFACTS[artifacts]
        LAB[lab-stands]
        INGRESS[ingress-nginx]
    end
    
    HA --> API
    API --> SCH
    API --> CM
    API --> ETCD
    API --> KUBELET
    KUBELET --> CONTAINERD
    KUBELET --> KUBEPROXY
    MON --> KUBELET
    JENKINS --> KUBELET
    GITOPS --> KUBELET
    ARTIFACTS --> KUBELET
    LAB --> KUBELET
    INGRESS --> KUBELET
```

---

## 4. Networking Architecture

```mermaid
graph TB
    subgraph "External Network"
        INTERNET[Internet]
        LAN[Local Network]
    end
    
    subgraph "Load Balancer Layer"
        METALLB[MetalLB]
        INGRESS[Ingress Controller]
    end
    
    subgraph "CNI Layer"
        CALICO[Calico]
        CILIUM[Cilium]
        FLANNEL[Flannel]
    end
    
    subgraph "Service Layer"
        CLUSTERIP[ClusterIP Services]
        NODEPORT[NodePort Services]
        LOADBALANCER[LoadBalancer Services]
    end
    
    subgraph "Pod Network"
        PODS[Pods]
        NETPOL[Network Policies]
    end
    
    INTERNET --> LAN
    LAN --> METALLB
    LAN --> INGRESS
    METALLB --> LOADBALANCER
    INGRESS --> CLUSTERIP
    CALICO --> PODS
    CILIUM --> PODS
    FLANNEL --> PODS
    CLUSTERIP --> PODS
    NODEPORT --> PODS
    LOADBALANCER --> PODS
    NETPOL --> PODS
```

---

## 5. Storage Architecture

```mermaid
graph TB
    subgraph "Storage Classes"
        LOCAL[Local Storage]
        NFS[NFS Storage]
        SSD[SSD Storage]
        HDD[HDD Storage]
    end
    
    subgraph "Persistent Volumes"
        PV1[PV - Local 1]
        PV2[PV - Local 2]
        PV3[PV - NFS]
        PV4[PV - SSD]
        PV5[PV - HDD]
    end
    
    subgraph "Applications"
        JENKINS[Jenkins PVC]
        GRAFANA[Grafana PVC]
        ARTIFACTORY[Artifactory PVC]
        POSTGRES[PostgreSQL PVC]
        REDIS[Redis PVC]
    end
    
    subgraph "Node Labels"
        BIG[node-type=big]
        MEDIUM[node-type=medium]
        SMALL[node-type=small]
        SSD_LABEL[storage-type=ssd]
        HDD_LABEL[storage-type=hdd]
    end
    
    LOCAL --> PV1
    LOCAL --> PV2
    NFS --> PV3
    SSD --> PV4
    HDD --> PV5
    BIG --> SSD_LABEL
    MEDIUM --> HDD_LABEL
    SMALL --> HDD_LABEL
    PV1 --> JENKINS
    PV2 --> GRAFANA
    PV3 --> ARTIFACTORY
    PV4 --> POSTGRES
    PV5 --> REDIS
```

---

## 6. CI/CD Pipeline Architecture

```mermaid
graph LR
    subgraph "Source Code"
        GIT[Git Repository]
        WEBHOOK[Webhook]
    end
    
    subgraph "Jenkins Pipeline"
        BUILD[Build Stage]
        TEST[Test Stage]
        SCAN[Security Scan]
        PACKAGE[Package Stage]
    end
    
    subgraph "Artifact Management"
        ARTIFACTORY[Artifactory]
        DOCKER[Docker Registry]
        HELM[Helm Charts]
    end
    
    subgraph "Deployment"
        ARGOCD[ArgoCD]
        K8S[Kubernetes]
        ROLLBACK[Rollback]
    end
    
    GIT --> WEBHOOK
    WEBHOOK --> BUILD
    BUILD --> TEST
    TEST --> SCAN
    SCAN --> PACKAGE
    PACKAGE --> ARTIFACTORY
    PACKAGE --> DOCKER
    PACKAGE --> HELM
    ARTIFACTORY --> ARGOCD
    DOCKER --> ARGOCD
    HELM --> ARGOCD
    ARGOCD --> K8S
    K8S --> ROLLBACK
```

---

## 7. Monitoring & Observability Architecture

```mermaid
graph TB
    subgraph "Data Sources"
        K8S_API[Kubernetes API]
        NODES[Nodes]
        PODS[Pods]
        SERVICES[Services]
        CONTAINERS[Containers]
    end
    
    subgraph "Metrics Collection"
        PROMETHEUS[Prometheus]
        NODE_EXPORTER[Node Exporter]
        KUBE_STATE_METRICS[Kube State Metrics]
        CADVISOR[cAdvisor]
    end
    
    subgraph "Logging"
        FLUENTD[Fluentd]
        ELASTICSEARCH[Elasticsearch]
        LOGSTASH[Logstash]
        KIBANA[Kibana]
    end
    
    subgraph "Visualization & Alerting"
        GRAFANA[Grafana]
        ALERTMANAGER[Alertmanager]
        DASHBOARDS[Dashboards]
        ALERTS[Alerts]
    end
    
    K8S_API --> PROMETHEUS
    NODES --> NODE_EXPORTER
    PODS --> KUBE_STATE_METRICS
    CONTAINERS --> CADVISOR
    NODE_EXPORTER --> PROMETHEUS
    KUBE_STATE_METRICS --> PROMETHEUS
    CADVISOR --> PROMETHEUS
    PODS --> FLUENTD
    FLUENTD --> ELASTICSEARCH
    ELASTICSEARCH --> LOGSTASH
    LOGSTASH --> KIBANA
    PROMETHEUS --> GRAFANA
    PROMETHEUS --> ALERTMANAGER
    GRAFANA --> DASHBOARDS
    ALERTMANAGER --> ALERTS
```

---

## 8. Security Architecture

```mermaid
graph TB
    subgraph "Authentication & Authorization"
        RBAC[RBAC]
        SA[Service Accounts]
        TOKENS[Tokens]
    end
    
    subgraph "Network Security"
        NETPOL[Network Policies]
        INGRESS_POLICY[Ingress Policies]
        EGRESS_POLICY[Egress Policies]
    end
    
    subgraph "Pod Security"
        PSP[Pod Security Policies]
        SECURITY_CONTEXT[Security Context]
        CAPABILITIES[Capabilities]
    end
    
    subgraph "Secrets Management"
        K8S_SECRETS[Kubernetes Secrets]
        EXTERNAL_SECRETS[External Secrets Operator]
        VAULT[Hashicorp Vault]
    end
    
    subgraph "Compliance"
        AUDIT[Audit Logging]
        SCANNING[Security Scanning]
        POLICY[Policy Enforcement]
    end
    
    RBAC --> SA
    SA --> TOKENS
    NETPOL --> INGRESS_POLICY
    NETPOL --> EGRESS_POLICY
    PSP --> SECURITY_CONTEXT
    SECURITY_CONTEXT --> CAPABILITIES
    K8S_SECRETS --> EXTERNAL_SECRETS
    EXTERNAL_SECRETS --> VAULT
    AUDIT --> POLICY
    SCANNING --> POLICY
```

---

## 9. GitOps Workflow Architecture

```mermaid
graph LR
    subgraph "Git Repository"
        MANIFESTS[Kubernetes Manifests]
        HELM_CHARTS[Helm Charts]
        KUSTOMIZE[Kustomize Configs]
    end
    
    subgraph "ArgoCD"
        APPLICATION[Application Controller]
        SERVER[ArgoCD Server]
        REPO[Repository]
        SYNC[Sync Controller]
    end
    
    subgraph "Kubernetes Cluster"
        NAMESPACES[Namespaces]
        DEPLOYMENTS[Deployments]
        SERVICES[Services]
        CONFIGMAPS[ConfigMaps]
        SECRETS[Secrets]
    end
    
    subgraph "Monitoring"
        HEALTH[Health Checks]
        STATUS[Status Monitoring]
        NOTIFICATIONS[Notifications]
    end
    
    MANIFESTS --> REPO
    HELM_CHARTS --> REPO
    KUSTOMIZE --> REPO
    REPO --> APPLICATION
    APPLICATION --> SERVER
    SERVER --> SYNC
    SYNC --> NAMESPACES
    SYNC --> DEPLOYMENTS
    SYNC --> SERVICES
    SYNC --> CONFIGMAPS
    SYNC --> SECRETS
    DEPLOYMENTS --> HEALTH
    HEALTH --> STATUS
    STATUS --> NOTIFICATIONS
```

---

## 10. Node Architecture & Resource Allocation

```mermaid
graph TB
    subgraph "Control Plane Nodes"
        CP1[CP-01<br/>High Performance]
        CP2[CP-02<br/>High Performance]
        CP3[CP-03<br/>High Performance]
    end
    
    subgraph "Worker Nodes - Big"
        WB1[Worker-Big-01<br/>SSD Storage]
        WB2[Worker-Big-02<br/>SSD Storage]
        WB3[Worker-Big-03<br/>SSD Storage]
    end
    
    subgraph "Worker Nodes - Medium"
        WM1[Worker-Medium-01<br/>HDD Storage]
        WM2[Worker-Medium-02<br/>HDD Storage]
        WM3[Worker-Medium-03<br/>HDD Storage]
    end
    
    subgraph "Worker Nodes - Small"
        WS1[Worker-Small-01<br/>HDD Storage]
        WS2[Worker-Small-02<br/>HDD Storage]
        WS3[Worker-Small-03<br/>HDD Storage]
    end
    
    subgraph "Workload Distribution"
        JENKINS[Jenkins<br/>node-type=big]
        MONITORING[Monitoring<br/>node-type=big]
        ARTIFACTORY[Artifactory<br/>node-type=big]
        LAB_APPS[Lab Apps<br/>node-type=medium]
        INGRESS[Ingress<br/>node-type=medium]
        UTILS[Utilities<br/>node-type=small]
    end
    
    CP1 --> JENKINS
    CP2 --> MONITORING
    CP3 --> ARTIFACTORY
    WB1 --> JENKINS
    WB2 --> MONITORING
    WB3 --> ARTIFACTORY
    WM1 --> LAB_APPS
    WM2 --> INGRESS
    WM3 --> LAB_APPS
    WS1 --> UTILS
    WS2 --> UTILS
    WS3 --> UTILS
```

---

## 11. Deployment Flow Architecture

```mermaid
graph TD
    subgraph "Development"
        CODE[Code Changes]
        PR[Pull Request]
        REVIEW[Code Review]
    end
    
    subgraph "CI Pipeline"
        BUILD[Build Image]
        TEST[Run Tests]
        SCAN[Security Scan]
        PUSH[Push to Registry]
    end
    
    subgraph "GitOps"
        MANIFEST[Update Manifests]
        COMMIT[Commit to Git]
        ARGOCD[ArgoCD Detects Changes]
    end
    
    subgraph "Deployment"
        VALIDATE[Validate Manifests]
        APPLY[Apply to Cluster]
        VERIFY[Verify Deployment]
        ROLLBACK[Rollback if Failed]
    end
    
    subgraph "Monitoring"
        METRICS[Collect Metrics]
        LOGS[Collect Logs]
        ALERTS[Send Alerts]
    end
    
    CODE --> PR
    PR --> REVIEW
    REVIEW --> BUILD
    BUILD --> TEST
    TEST --> SCAN
    SCAN --> PUSH
    PUSH --> MANIFEST
    MANIFEST --> COMMIT
    COMMIT --> ARGOCD
    ARGOCD --> VALIDATE
    VALIDATE --> APPLY
    APPLY --> VERIFY
    VERIFY --> ROLLBACK
    APPLY --> METRICS
    APPLY --> LOGS
    METRICS --> ALERTS
    LOGS --> ALERTS
```

---

## 12. Disaster Recovery Architecture

```mermaid
graph TB
    subgraph "Primary Cluster"
        PC_CP[Control Plane]
        PC_WK[Worker Nodes]
        PC_STOR[Storage]
    end
    
    subgraph "Backup & Recovery"
        ETCD_BACKUP[etcd Backup]
        MANIFEST_BACKUP[Manifest Backup]
        SECRET_BACKUP[Secrets Backup]
    end
    
    subgraph "Secondary Cluster"
        SC_CP[Control Plane]
        SC_WK[Worker Nodes]
        SC_STOR[Storage]
    end
    
    subgraph "Recovery Process"
        RESTORE_ETCD[Restore etcd]
        RESTORE_MANIFESTS[Restore Manifests]
        RESTORE_SECRETS[Restore Secrets]
        VERIFY_RECOVERY[Verify Recovery]
    end
    
    PC_CP --> ETCD_BACKUP
    PC_WK --> MANIFEST_BACKUP
    PC_STOR --> SECRET_BACKUP
    ETCD_BACKUP --> RESTORE_ETCD
    MANIFEST_BACKUP --> RESTORE_MANIFESTS
    SECRET_BACKUP --> RESTORE_SECRETS
    RESTORE_ETCD --> SC_CP
    RESTORE_MANIFESTS --> SC_WK
    RESTORE_SECRETS --> SC_STOR
    SC_CP --> VERIFY_RECOVERY
    SC_WK --> VERIFY_RECOVERY
    SC_STOR --> VERIFY_RECOVERY
```

---

## 13. Logging and Troubleshooting Architecture

```mermaid
graph TB
    subgraph "Health Check Components"
        HW_CHECK[Hardware Health Check]
        CONFIG_CHECK[Configuration Health Check]
        K8S_CHECK[Kubernetes Health Check]
    end
    
    subgraph "Backup and Recovery"
        ETCD_BACKUP[etcd Backup Tool]
        BACKUP_VERIFY[Backup Verification]
        RESTORE_TEST[Restore Testing]
    end
    
    subgraph "Log Collection"
        SYS_LOGS[System Logs]
        K8S_LOGS[Kubernetes Logs]
        APP_LOGS[Application Logs]
        LOG_AGG[Log Aggregation]
    end
    
    subgraph "Diagnostic Tools"
        TROUBLESHOOT_TOOLBOX[Main Toolbox Script]
        METHODOLOGY[Troubleshooting Methodology]
        LOGGING_STRATEGY[Logging Strategy]
    end
    
    subgraph "Reporting and Analysis"
        HEALTH_REPORT[Health Reports]
        DIAGNOSTIC_REPORT[Diagnostic Reports]
        RECOMMENDATIONS[Recommendations]
    end
    
    HW_CHECK --> TROUBLESHOOT_TOOLBOX
    CONFIG_CHECK --> TROUBLESHOOT_TOOLBOX
    K8S_CHECK --> TROUBLESHOOT_TOOLBOX
    ETCD_BACKUP --> TROUBLESHOOT_TOOLBOX
    BACKUP_VERIFY --> TROUBLESHOOT_TOOLBOX
    RESTORE_TEST --> TROUBLESHOOT_TOOLBOX
    
    SYS_LOGS --> LOG_AGG
    K8S_LOGS --> LOG_AGG
    APP_LOGS --> LOG_AGG
    LOG_AGG --> TROUBLESHOOT_TOOLBOX
    
    METHODOLOGY --> TROUBLESHOOT_TOOLBOX
    LOGGING_STRATEGY --> TROUBLESHOOT_TOOLBOX
    
    TROUBLESHOOT_TOOLBOX --> HEALTH_REPORT
    TROUBLESHOOT_TOOLBOX --> DIAGNOSTIC_REPORT
    TROUBLESHOOT_TOOLBOX --> RECOMMENDATIONS
```

---

## Summary

These detailed diagrams provide a comprehensive view of:

1. **High-Level System Architecture** - Overall system design
2. **Infrastructure Provisioning** - Terraform and Ansible automation
3. **Kubernetes Cluster** - Control plane and worker node architecture
4. **Networking** - CNI, MetalLB, and service mesh
5. **Storage** - Persistent volumes and storage classes
6. **CI/CD Pipeline** - Jenkins and ArgoCD integration
7. **Monitoring & Observability** - Prometheus, Grafana, and ELK stack
8. **Security** - RBAC, network policies, and secrets management
9. **GitOps Workflow** - ArgoCD application management
10. **Node Architecture** - Resource allocation and workload distribution
11. **Deployment Flow** - End-to-end deployment process
12. **Disaster Recovery** - Backup and recovery procedures
13. **Logging and Troubleshooting** - Health checks, diagnostics, and maintenance tools

Each diagram shows the relationships between components and the data flow within the system, providing a complete understanding of the bare metal Kubernetes lab architecture. 