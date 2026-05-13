---
stage: Release Notes
group: Monthly Release
title: "GitLab 19.0 release notes - not yet released"
description: "Summary of features included in 19.0"
---

The following features are being delivered for GitLab 19.0.
These features are now available on GitLab.com.

<!-- Copy this template, and paste it into the doc section where it belongs:

Primary feature, Agentic Core, Scale and Deployments, or Unified DevOps and Security.

Update all the information as needed.

### Feature explanation here

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../ci/yaml/_index.md), [Related issue](https://gitlab.com/groups/gitlab-org/-/work_items/17754)

{{< /details >}}

Now write 125 words or fewer to explain the value of this improvement.
Use phrases that start with, "In previous versions of GitLab, you couldn't... Now you can..."

Use present tense, and speak about "you" instead of "the user."
-->

<!-- ## Primary features

The first person to add a feature in this area, please make the title visible and delete this comment -->

## Agentic Core

### Filter exact code search results by repository

<!-- categories: Global Search -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/search/exact_code_search.md#syntax), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/488467)

{{< /details >}}

You can now filter exact code search results by repository. With the `repo:` syntax,
you can directly scope your search query to specific repositories or repository patterns
without having to go to individual projects.

For example, searching for `def authenticate repo:my-group/my-project` returns results
only from that repository. You can also use partial paths or patterns to match multiple repositories.

### Claude Opus 4.7 now available in GitLab Duo Agent Platform

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/duo_agent_platform/model_selection.md#supported-models), [Related issue](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/work_items/2177)

{{< /details >}}

Claude Opus 4.7 is now available in GitLab Duo Agent Platform. Opus 4.7 delivers meaningful improvements to complex, multistep tasks that require sustained reasoning, precise instruction following, and self-verification before surfacing results. This includes flows supporting CI/CD pipelines, code review, vulnerability resolution, and more.

### Expanded open source model support in GitLab Duo Agent Platform

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models), [Related issue](https://gitlab.com/groups/gitlab-org/-/work_items/21186)

{{< /details >}}

GitLab Duo Agent Platform now supports additional open source models for self-hosted deployments, including Devstral 2 123B, GLM-5.1-FP8, and others. This helps customers power agentic workflows across a variety of environments, including offline and network-restricted deployments.

## Scale and Deployments

### PostgreSQL 17 minimum requirement

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/package_information/postgresql_versions.md), [Related issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/9792)

{{< /details >}}

The minimum supported version of PostgreSQL is now version 17. If you use the packaged PostgreSQL 16,
[upgrade the packaged PostgreSQL server](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server)
before installing GitLab 19.0.

### Linux package support for Ubuntu 20.04 discontinued

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../install/package/_index.md#supported-platforms), [Related issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8915)

{{< /details >}}

Ubuntu 20.04 reached end of standard support in May 2025. From GitLab 19.0, Linux packages are no
longer provided for Ubuntu 20.04. GitLab 18.11 is the last release with packages for this
distribution. Before upgrading to GitLab 19.0, migrate to Ubuntu 22.04 or another
[supported operating system](../../install/package/_index.md#supported-platforms).

### Redis 6 support removed

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../install/requirements.md), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/585839)

{{< /details >}}

Support for Redis 6 is removed in GitLab 19.0. If you use an external Redis 6 deployment, migrate
to Redis 7.2 or Valkey 7.2 before upgrading. The bundled Redis included with the Linux package has
used Redis 7 since GitLab 16.2 and is not affected.

### Mattermost removed from the Linux package

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.mattermost.com/administration-guide/onboard/migrate-gitlab-omnibus.html), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/590798)

{{< /details >}}

Bundled Mattermost is removed from the Linux package in GitLab 19.0. If you currently use the
bundled Mattermost, refer to
[Migrating from the Linux package to Mattermost Standalone](https://docs.mattermost.com/administration-guide/onboard/migrate-gitlab-omnibus.html)
for migration instructions. Customers not using the bundled Mattermost are not impacted.

### Linux package support for SUSE distributions discontinued

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../install/docker/installation.md), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/590801)

{{< /details >}}

Linux package support for SUSE distributions ends in GitLab 19.0, which affects openSUSE Leap 15.6,
SUSE Linux Enterprise Server 12.5, and SUSE Linux Enterprise Server 15.6. GitLab 18.11 is the last
version with Linux packages for these distributions. To continue to use SUSE distributions, migrate
to a [Docker deployment of GitLab](../../install/docker/installation.md).

### Spamcheck removed from Linux package and GitLab Helm chart

<!-- categories: Omnibus Package, Cloud Native Installation -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/reporting/spamcheck.md), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/590796)

{{< /details >}}

[Spamcheck](../../administration/reporting/spamcheck.md) is removed from the Linux package and
GitLab Helm chart in GitLab 19.0. Customers not currently using Spamcheck are not impacted. If you
use the bundled Spamcheck, you can deploy it separately using
[Docker](https://gitlab.com/gitlab-org/gl-security/security-engineering/security-automation/spam/spamcheck).
No data migration is required.

### NGINX Ingress replaced by Gateway API with Envoy Gateway

<!-- categories: Cloud Native Installation -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/charts/), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/590800)

{{< /details >}}

Gateway API with Envoy Gateway becomes the default networking configuration in the GitLab Helm chart
in GitLab 19.0, replacing NGINX Ingress which reached end-of-life in March 2026. If migration to
Envoy Gateway is not immediately feasible, you can explicitly re-enable the bundled NGINX Ingress,
which remains available until its planned removal in GitLab 20.0. This change does not impact the
NGINX used in the Linux package, or Helm chart instances using an externally managed Ingress or
Gateway API controller.

### Bundled PostgreSQL, Redis, and MinIO removed from GitLab Helm chart

<!-- categories: Cloud Native Installation -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/charts/installation/migration/bundled_chart_migration/), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/590797)

{{< /details >}}

The bundled Bitnami PostgreSQL, Bitnami Redis, and MinIO charts are removed from the GitLab Helm
chart and GitLab Operator in GitLab 19.0 with no replacement. These components were intended only
for proof-of-concept and test environments and are not recommended for production use. If you run an
instance with any of these bundled services, follow the
[migration guide](https://docs.gitlab.com/charts/installation/migration/bundled_chart_migration/)
to configure external services before upgrading to GitLab 19.0.

## Unified DevOps and Security

### Dependency scanning in security configuration profiles

<!-- categories: Security Testing Configuration -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/configuration/security_configuration_profiles.md), [Related issue](https://gitlab.com/groups/gitlab-org/-/work_items/19952)

{{< /details >}}

GitLab 18.11 introduced security configuration profiles for SAST and secret detection.
Now, dependency scanning is also available with the **Dependency Scanning - Default** profile.
This profile gives you a unified control surface to apply standardized SCA coverage across all
of your projects without editing a single CI/CD configuration file.

The profile activates two scan triggers:

- **Merge Request Pipelines**: Automatically runs a dependency scanning scan each time new commits are pushed to a branch with an open merge request. Results include only new vulnerabilities introduced by the merge request.
- **Branch Pipelines (default only)**: Runs automatically when changes are merged or pushed to the default branch, providing a complete view of your default branch's dependency posture.

### Improved array support for CI/CD inputs

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../ci/inputs/_index.md#access-individual-array-elements), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/587657)

{{< /details >}}

CI/CD inputs now have improved support for working with arrays.
Use the array index operator `[]` to access specific elements within array inputs.
This enhancement provides more flexible and powerful input interpolation capabilities in your pipeline configurations,
enabling you to reference individual array items directly without additional processing steps.

### Select multiple values for pipeline inputs

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../ci/inputs/_index.md#array-inputs-with-options), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/566155)

{{< /details >}}

Previously, you could only select a single value when selecting input options in the UI,
limiting flexibility for pipelines with more complex options.

Now when you run a pipeline with inputs from the UI, you can select multiple values from a dropdown list
and the selected values are combined into an array, for example `["option1","option2"]`.
This makes it easy to restart services on multiple instances, build multiple Docker images,
run tests with multiple tag combinations, or perform any operation across multiple targets
in a single pipeline run.

### Configure parallel pipeline limits for merge trains

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../administration/instance_limits.md#merge-train-parallel-pipeline-limit),
 [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/374188)

{{< /details >}}

In previous versions of GitLab, you couldn't change the maximum of 20 parallel pipelines in a merge train,
which forced you to either overwhelm your runners or skip merge trains entirely.
Now you can configure the parallel pipeline limit per merge train to balance runner load and merge throughput.
You can set the limit per project or instance-wide.
Setting the limit to 1 means each merge request runs one at a time, against a clean target branch.

Thanks to [Norman Debald (@Modjo85)](https://gitlab.com/Modjo85) for this community contribution.

### Secure webhooks with HMAC signing tokens

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/project/integrations/webhooks.md#signing-tokens), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/19367)

{{< /details >}}

The existing `X-Gitlab-Token` header sends a static secret in plain text,
making webhooks susceptible to interception and replay attacks.

You can now add a signing token to any webhook. GitLab uses
the signing token to compute an HMAC-SHA256 signature over:

- The unique webhook ID.
- The request timestamp.
- The webhook payload.

GitLab then sends the result in the `webhook-signature` header alongside
`webhook-id` and `webhook-timestamp` headers, following the
[Standard Webhooks](https://www.standardwebhooks.com/) specification.

You can recompute the signature to confirm requests genuinely came from GitLab
and that the payload has not been modified. By also validating the timestamp, you can reject replayed requests.

Thanks to [Van Anderson](https://gitlab.com/van.m.anderson) and
[Norman Debald](https://gitlab.com/Modjo85) for their community contributions!
