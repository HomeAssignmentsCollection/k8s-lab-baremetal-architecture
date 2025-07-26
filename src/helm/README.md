# Helm Charts (Optional)

This directory contains Helm charts as an alternative to direct YAML manifests.

## Why Helm Charts?

While the project primarily uses direct YAML manifests for simplicity and educational purposes, Helm charts provide:

- **Easier version management** for complex applications
- **Better templating** for different environments
- **Industry standard** for Kubernetes package management
- **Reusable configurations** across projects

## Available Charts

### Jenkins
- **Source**: Official Jenkins Helm chart
- **Customization**: Node selectors, storage, and security configurations
- **Values**: Optimized for bare metal environments

### ArgoCD
- **Source**: Official ArgoCD Helm chart
- **Customization**: HA configuration, RBAC, and monitoring
- **Values**: Production-ready settings

### Monitoring Stack
- **Source**: Prometheus Operator + Grafana
- **Customization**: Storage, retention, and alerting
- **Values**: Optimized for lab environments

### Artifactory
- **Source**: JFrog Artifactory Helm chart
- **Customization**: Storage, security, and HA
- **Values**: Community edition configuration

## Usage

### Prerequisites
```bash
# Install Helm
curl https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz | tar xz
sudo mv linux-amd64/helm /usr/local/bin/

# Add required repositories
helm repo add jenkins https://charts.jenkins.io
helm repo add argo https://argoproj.github.io/argo-helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add jfrog https://charts.jfrog.io
helm repo update
```

### Deploy with Helm
```bash
# Deploy Jenkins
helm install jenkins jenkins/jenkins \
  --namespace jenkins \
  --create-namespace \
  -f charts/jenkins/values.yaml

# Deploy ArgoCD
helm install argocd argo/argo-cd \
  --namespace gitops \
  --create-namespace \
  -f charts/argocd/values.yaml

# Deploy Monitoring Stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f charts/monitoring/values.yaml

# Deploy Artifactory
helm install artifactory jfrog/artifactory \
  --namespace artifacts \
  --create-namespace \
  -f charts/artifactory/values.yaml
```

### Deploy All with Script
```bash
./src/scripts/deploy-helm.sh
```

## Comparison: YAML vs Helm

| Aspect | YAML Manifests | Helm Charts |
|--------|----------------|-------------|
| **Simplicity** | ✅ Direct and clear | ⚠️ Additional abstraction |
| **Learning** | ✅ Educational value | ⚠️ Less transparent |
| **Maintenance** | ⚠️ Manual updates | ✅ Version management |
| **Flexibility** | ✅ Full control | ✅ Templating power |
| **Dependencies** | ✅ None | ⚠️ Requires Helm |
| **Debugging** | ✅ Easy to trace | ⚠️ More complex |
| **Production** | ⚠️ Manual scaling | ✅ Industry standard |

## Migration Path

You can use either approach:

1. **Start with YAML**: Use direct manifests for learning and development
2. **Migrate to Helm**: Switch to Helm charts for production environments
3. **Hybrid approach**: Use YAML for simple components, Helm for complex ones

## Values Customization

Each chart includes custom `values.yaml` files optimized for:
- Bare metal infrastructure
- Node selectors and taints
- Local storage classes
- Security hardening
- Lab environment requirements

## Notes

- Helm charts are **optional** and complement the existing YAML manifests
- Both approaches achieve the same end result
- Choose based on your team's expertise and requirements
- YAML manifests remain the primary approach for this educational project 