# Kubernetes Deployment Strategies Comparison

This document provides a comprehensive comparison of the four deployment strategies implemented in this repository: Recreate, Rolling Update, Blue/Green, and Canary.

## Comparison Table

| Feature | Recreate | Rolling Update | Blue/Green | Canary |
|---------|----------|---------------|------------|--------|
| **Downtime** | Yes (complete downtime during deployment) | No (zero downtime) | No (zero downtime) | No (zero downtime) |
| **Resource Usage** | Low (no extra resources needed) | Medium (slightly more during transition) | High (requires double resources) | Medium-High (requires resources for both versions) |
| **Rollback Speed** | Fast (single operation) | Medium (must roll back each pod) | Very Fast (just switch traffic) | Fast (redirect all traffic to stable version) |
| **Complexity** | Low (simplest approach) | Low-Medium | Medium-High | High |
| **Testing in Production** | No | Limited | Yes (can test before switching) | Yes (controlled exposure) |
| **Risk Level** | High (all-or-nothing) | Medium | Low | Very Low |
| **Traffic Control** | None | Limited | Complete switch | Fine-grained percentage control |
| **User Impact** | All users affected at once | Minimal impact, gradual | No impact if done correctly | Only affects subset of users |
| **Suitable For** | Development environments, non-critical applications | Most production workloads | Critical applications, major version changes | Feature testing, high-risk changes |
| **Implementation** | Simple `strategy: type: Recreate` | Default K8s strategy with configurable parameters | Requires separate deployments and service switching | Requires traffic splitting capability (Ingress/Service) |
| **Monitoring Requirements** | Basic | Moderate | Advanced | Very Advanced |
| **Automation Potential** | High | High | Medium | Medium-Low (requires more oversight) |
| **Production Readiness** | Not recommended | Good | Very Good | Excellent |
| **Gradual Rollout** | No | Yes | No (all at once after validation) | Yes (highly controlled) |


---

## Detailed Comparison

### Recreate Strategy

**How it works:**
- Terminates all existing pods before creating new ones
- Simple "all-or-nothing" approach

**Pros:**
- Simplest to implement
- Ensures clean state (no old code running)
- No version mixing
- Lower resource usage

**Cons:**
- Causes downtime
- High risk
- All users affected simultaneously

**Best for:**
- Development/testing environments
- Non-critical applications
- When clean state is required

---

### Rolling Update Strategy

**How it works:**
- Gradually replaces old pods with new ones
- Default strategy in Kubernetes
- Configurable parameters for max unavailable and max surge

**Pros:**
- Zero downtime
- Gradual rollout
- Built into Kubernetes
- Easy to implement

**Cons:**
- Both versions run simultaneously during transition
- Limited control over traffic routing
- Rollback requires cycling through pods again

**Best for:**
- Most production workloads
- Applications with backward compatible changes
- When simplicity is valued

---

### Blue/Green Deployment

**How it works:**
- Deploys new version alongside old version
- Tests new version before switching traffic
- Switches all traffic at once when ready

**Pros:**
- Zero downtime
- Easy and fast rollback
- Complete testing before exposure
- Clean separation between versions

**Cons:**
- Requires double the resources
- More complex to set up
- Requires service switching mechanism

**Best for:**
- Critical applications
- Major version changes
- When thorough testing is required before exposure
- When fast rollback capability is essential

---

### Canary Deployment

**How it works:**
- Deploys new version to a small subset of users
- Gradually increases traffic to new version
- Monitors for issues before full rollout

**Pros:**
- Lowest risk
- Fine-grained control over traffic
- Early issue detection with minimal impact
- Real user testing

**Cons:**
- Most complex to implement
- Requires traffic splitting capability
- Needs advanced monitoring
- Longer deployment time

**Best for:**
- High-risk changes
- Feature testing with real users
- Production environments with diverse user base
- When maximum caution is required

---

## Deployment Strategies Used by Major Tech Companies

| Company | Primary Strategies | Notable Implementation Details |
|---------|-------------------|-------------------------------|
| **Google** | Canary, Rolling | Uses Canary for most services; pioneered gradual rollouts with traffic splitting |
| **Amazon/AWS** | Blue/Green, Canary | AWS CodeDeploy supports both; uses Blue/Green for many critical services |
| **Microsoft** | Rolling, Canary | Azure DevOps uses progressive exposure patterns; GitHub uses Canary deployments |
| **Facebook** | Canary, Dark Launches | Uses sophisticated feature flagging with incremental rollouts |
| **Netflix** | Red/Black (Blue/Green), Canary | Custom "Red/Black" deployment with regional progressive rollouts |
| **Uber** | Rolling, Canary | Uses custom traffic shifting with automated verification |
| **Airbnb** | Incremental Canary | Custom implementation with automated verification and rollback |
| **Etsy** | Continuous Deployment, Dark Launches | Feature flags with incremental exposure |
| **LinkedIn** | Canary, Dark Launches | Uses custom traffic control system called "LiX" |
| **Spotify** | Progressive Delivery (Canary) | Uses custom tooling for gradual rollouts |

Most large tech companies have developed custom deployment platforms that combine elements of multiple strategies, often with sophisticated monitoring, automated verification, and rollback capabilities. The trend is toward progressive delivery approaches (variants of Canary) with automated verification steps.

---

## Choosing the Right Strategy

The choice of deployment strategy depends on several factors:

1. **Application Criticality**: How important is uptime?
2. **Risk Tolerance**: How risky is the change?
3. **Resource Availability**: Can you afford double resources?
4. **Monitoring Capabilities**: Can you effectively monitor partial deployments?
5. **Release Frequency**: How often do you deploy?

For most production applications, Rolling Update provides a good balance of simplicity and availability. For critical applications or major changes, Blue/Green or Canary deployments offer additional safety at the cost of complexity and resources.

---

## Implementation in Kubernetes

Each strategy can be implemented in Kubernetes using different approaches:

- **Recreate**: Set `spec.strategy.type: Recreate` in Deployment
- **Rolling Update**: Set `spec.strategy.type: RollingUpdate` with desired parameters
- **Blue/Green**: Create separate Deployments and switch Service selector
- **Canary**: Use Ingress controllers with traffic splitting or multiple Deployments with label selectors

This repository contains practical examples of each strategy that you can use as a reference for your own implementations.


---

### Key Citations
- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Spacelift Kubernetes Deployment Strategies](https://spacelift.io/blog/kubernetes-deployment-strategies)
- [Spot.io 8 Kubernetes Deployment Strategies](https://spot.io/resources/kubernetes-autoscaling/8-kubernetes-deployment-strategies/)
- [Codefresh Top 6 Kubernetes Deployment Strategies](https://codefresh.io/learn/kubernetes-deployment/top-6-kubernetes-deployment-strategies-and-how-to-choose/)
- [Zeet.co Kubernetes Deployment Strategy Types](https://zeet.co/blog/kubernetes-deployment-strategy-types)
- [Google Cloud Blog Release Canaries](https://cloud.google.com/blog/products/gcp/how-release-canaries-can-save-your-bacon-cre-life-lessons)
- [AWS Deployment Strategies](https://docs.aws.amazon.com/whitepapers/latest/introduction-devops-aws/deployment-strategies.html)
- [InfoQ How Netflix Deploys Code](https://www.infoq.com/news/2013/06/netflix/)
- [The ITAM Review Netflix Deployment](https://itassetmanagement.net/2019/04/23/how-netflix-over-deployed-10000-instances-in-amazon-aws/)