# frozen_string_literal: true

module ProjectTemplateTestHelper
  def all_templates
    %w[
      rails spring express iosswift dotnetcore android
      gomicro astro gatsby hugo jekyll nextjs nuxt plainhtml
      hexo middleman gitpod_spring_petclinic nfhugo
      nfjekyll nfplainhtml nfgitbook nfhexo salesforcedx
      serverless_framework tencent_serverless_framework
      jsonnet cluster_management kotlin_native_linux
      pelican bridgetown typo3_distribution laravel
      nist_80053r5 gitlab_components
    ]
  end
end

ProjectTemplateTestHelper.prepend_mod
