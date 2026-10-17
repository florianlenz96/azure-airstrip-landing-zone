# Workload landing zones

This directory is reserved for application infrastructure, not platform governance
or connectivity. Organize real workloads by scope and application:

```text
corp/
  hr-platform/    # Resource groups, managed identities, VMs, PaaS, private endpoints
online/
  website/        # Resource group, static web app, application configuration
```

These are ownership examples, not pre-provisioned applications. Add a module for
an actual workload when needed; do not add placeholder Azure resources or a
backend/provider to the `landingzones/`, `corp/`, or `online/` grouping folders.
An application's deployment root (here or in its application repository) decides
its own module composition and workload lifecycle. It must not reuse the platform
backend key.

Platform governance lives in `terraform/modules/governance`. All VNets, subnets,
NSGs, UDRs, peering, and shared private DNS live in the connectivity/spoke modules
and are deployed through `regional_airfield/terraform/`. Workloads consume the
spoke output IDs; they do not create a second copy of the platform network.
