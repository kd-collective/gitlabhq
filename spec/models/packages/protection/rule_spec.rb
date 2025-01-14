# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Protection::Rule, type: :model, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  it_behaves_like 'having unique enum values'

  describe 'relationships' do
    it { is_expected.to belong_to(:project).inverse_of(:package_protection_rules) }
  end

  describe 'enums' do
    it {
      is_expected.to define_enum_for(:package_type).with_values(
        conan: Packages::Package.package_types[:conan],
        npm: Packages::Package.package_types[:npm],
        pypi: Packages::Package.package_types[:pypi]
      )
    }

    it {
      is_expected.to(
        define_enum_for(:minimum_access_level_for_push)
          .with_values(
            maintainer: Gitlab::Access::MAINTAINER,
            owner: Gitlab::Access::OWNER,
            admin: Gitlab::Access::ADMIN
          )
          .with_prefix(:minimum_access_level_for_push)
      )
    }
  end

  describe 'validations' do
    subject { build(:package_protection_rule) }

    describe '#package_name_pattern' do
      it { is_expected.to validate_presence_of(:package_name_pattern) }
      it { is_expected.to validate_uniqueness_of(:package_name_pattern).scoped_to(:project_id, :package_type) }
      it { is_expected.to validate_length_of(:package_name_pattern).is_at_most(255) }

      context 'for different package types' do
        subject { build(:package_protection_rule, package_type: package_type) }

        where(:package_type, :package_name_pattern, :allowed) do
          :npm  | '@my-scope/my-package'                            | true
          :npm  | '@my-scope/*my-package-with-wildcard-inbetween'   | true
          :npm  | '@my-scope/*my-package-with-wildcard-start'       | true
          :npm  | '@my-scope/my-*package-*with-wildcard-multiple-*' | true
          :npm  | '@my-scope/my-package-with_____underscore'        | true
          :npm  | '@my-scope/my-package-with-regex-characters.+'    | true
          :npm  | '@my-scope/my-package-with-wildcard-end*'         | true
          :npm  | '@my-scope/my-package-with-percent-sign-%'        | false
          :npm  | '*@my-scope/my-package-with-wildcard-start'       | false
          :npm  | '@my-scope/my-package-with-backslash-\*'          | false

          :pypi | 'my-scope/my-package'                             | true
          :pypi | 'my-scope/*my-package-with-wildcard-inbetween'    | true
          :pypi | 'my-scope/*my-package-with-wildcard-start'        | true
          :pypi | 'my-scope/my-*package-*with-wildcard-multiple-*'  | true
          :pypi | 'my-scope/my-package-with_____underscore'         | true
          :pypi | 'my-scope/my-package-with-wildcard-end*'          | true
          :pypi | '*my-scope/my-package-with-wildcard-start'        | false
          :pypi | 'my-scope/my-package-with-backslash-\*'           | false
          :pypi | 'my-scope/my-package-with-percent-sign-%'         | false
          :pypi | 'my-scope/my-package-with-regex-characters.+'     | false
          :pypi | '$my-scope/my-package-with-dollar-sign'           | false
          :pypi | '$my-scope/my-package-with space sign'            | false
          :pypi | 'my-scope/my-package-with-@at@-sign'              | false
          :pypi | 'my-scope/my-package-with-@at@-sign-and-widlcard' | false
        end

        with_them do
          if params[:allowed]
            it { is_expected.to allow_value(package_name_pattern).for(:package_name_pattern) }
          else
            it {
              is_expected.not_to(
                allow_value(package_name_pattern)
                .for(:package_name_pattern)
                .with_message(/should be a valid #{package_type} package name with optional wildcard characters./i)
              )
            }
          end
        end
      end
    end

    describe '#package_type' do
      it { is_expected.to validate_presence_of(:package_type) }
    end

    describe '#minimum_access_level_for_push' do
      it { is_expected.to validate_presence_of(:minimum_access_level_for_push) }
    end
  end

  describe '.for_package_name' do
    let_it_be(:package_protection_rule) do
      create(:package_protection_rule, package_name_pattern: '@my-scope/my_package')
    end

    let_it_be(:ppr_with_wildcard_start) do
      create(:package_protection_rule, package_name_pattern: '@my-scope/*my_package-with-wildcard-start')
    end

    let_it_be(:ppr_with_wildcard_end) do
      create(:package_protection_rule, package_name_pattern: '@my-scope/my_package-with-wildcard-end*')
    end

    let_it_be(:ppr_with_wildcard_inbetween) do
      create(:package_protection_rule, package_name_pattern: '@my-scope/my_package*with-wildcard-inbetween')
    end

    let_it_be(:ppr_with_wildcard_multiples) do
      create(:package_protection_rule, package_name_pattern: '@my-scope/**my_package**with-wildcard-multiple**')
    end

    let_it_be(:ppr_with_underscore) do
      create(:package_protection_rule, package_name_pattern: '@my-scope/my_package-with_____underscore')
    end

    let_it_be(:ppr_with_regex_characters) do
      create(:package_protection_rule, package_name_pattern: '@my-scope/my_package-with-regex-characters.+')
    end

    let(:package_name) { package_protection_rule.package_name_pattern }

    subject { described_class.for_package_name(package_name) }

    context 'with several package protection rule scenarios' do
      where(:package_name, :expected_package_protection_rules) do
        '@my-scope/my_package'                                       | [ref(:package_protection_rule)]
        '@my-scope/my2package'                                       | []
        '@my-scope/my_package-2'                                     | []

        # With wildcard pattern at the start
        '@my-scope/my_package-with-wildcard-start'                   | [ref(:ppr_with_wildcard_start)]
        '@my-scope/my_package-with-wildcard-start-any'               | []
        '@my-scope/any-my_package-with-wildcard-start'               | [ref(:ppr_with_wildcard_start)]
        '@my-scope/any-my_package-with-wildcard-start-any'           | []

        # With wildcard pattern at the end
        '@my-scope/my_package-with-wildcard-end'                     | [ref(:ppr_with_wildcard_end)]
        '@my-scope/my_package-with-wildcard-end:1234567890'          | [ref(:ppr_with_wildcard_end)]
        '@my-scope/any-my_package-with-wildcard-end'                 | []
        '@my-scope/any-my_package-with-wildcard-end:1234567890'      | []

        # With wildcard pattern inbetween
        '@my-scope/my_packagewith-wildcard-inbetween'                | [ref(:ppr_with_wildcard_inbetween)]
        '@my-scope/my_package-any-with-wildcard-inbetween'           | [ref(:ppr_with_wildcard_inbetween)]
        '@my-scope/any-my_package-my_package-wildcard-inbetween-any' | []

        # With multiple wildcard pattern are used
        '@my-scope/my_packagewith-wildcard-multiple'                 | [ref(:ppr_with_wildcard_multiples)]
        '@my-scope/any-my_package-any-with-wildcard-multiple-any'    | [ref(:ppr_with_wildcard_multiples)]
        '@my-scope/****my_package****with-wildcard-multiple****'     | [ref(:ppr_with_wildcard_multiples)]
        '@other-scope/any-my_package-with-wildcard-multiple-any'     | []

        # With underscore
        '@my-scope/my_package-with_____underscore'                   | [ref(:ppr_with_underscore)]
        '@my-scope/my_package-with_any_underscore'                   | []

        # With regex pattern
        '@my-scope/my_package-with-regex-characters.+'               | [ref(:ppr_with_regex_characters)]
        '@my-scope/my_package-with-regex-characters.'                | []
        '@my-scope/my_package-with-regex-characters'                 | []
        '@my-scope/my_package-with-regex-characters-any'             | []

        # Special cases
        nil                                                          | []
        ''                                                           | []
        'any_package'                                                | []
      end

      with_them do
        it { is_expected.to match_array(expected_package_protection_rules) }
      end
    end

    context 'with multiple matching package protection rules' do
      let!(:package_protection_rule_second_match) do
        create(:package_protection_rule, package_name_pattern: "#{package_name}*")
      end

      it { is_expected.to contain_exactly(package_protection_rule_second_match, package_protection_rule) }
    end
  end

  describe '.for_package_type' do
    let_it_be(:npm_package_rule) { create(:package_protection_rule, package_type: :npm) }

    subject { described_class.for_package_type(package_type) }

    where(:package_type, :expected_package_protection_rules) do
      :npm                   | lazy { [npm_package_rule] }
      'npm'                  | lazy { [npm_package_rule] }

      :maven                 | []
      :invalid_package_type  | []
      nil                    | []
    end

    with_them do
      it { is_expected.to match_array expected_package_protection_rules }
    end
  end

  describe '.for_push_exists?' do
    let_it_be(:project_with_ppr) { create(:project) }
    let_it_be(:project_without_ppr) { create(:project) }

    let_it_be(:ppr_for_developer) do
      create(:package_protection_rule,
        package_name_pattern: '@my-scope/my-package-stage*',
        project: project_with_ppr,
        package_type: :npm,
        minimum_access_level_for_push: :maintainer
      )
    end

    let_it_be(:ppr_for_maintainer) do
      create(:package_protection_rule,
        package_name_pattern: '@my-scope/my-package-prod*',
        project: project_with_ppr,
        package_type: :npm,
        minimum_access_level_for_push: :owner
      )
    end

    let_it_be(:ppr_owner) do
      create(:package_protection_rule,
        package_name_pattern: '@my-scope/my-package-release*',
        project: project_with_ppr,
        package_type: :npm,
        minimum_access_level_for_push: :admin
      )
    end

    let_it_be(:ppr_2_for_developer) do
      create(:package_protection_rule,
        package_name_pattern: '@my-scope/my-package-*',
        project: project_with_ppr,
        package_type: :npm,
        minimum_access_level_for_push: :maintainer
      )
    end

    subject do
      project
        .package_protection_rules
        .for_push_exists?(
          access_level: access_level,
          package_name: package_name,
          package_type: package_type
        )
    end

    describe 'with different users and protection levels' do
      where(:project, :access_level, :package_name, :package_type, :push_protected) do
        ref(:project_with_ppr)    | Gitlab::Access::REPORTER   | '@my-scope/my-package-stage-sha-1234' | :npm   | true
        ref(:project_with_ppr)    | Gitlab::Access::DEVELOPER  | '@my-scope/my-package-stage-sha-1234' | :npm   | true
        ref(:project_with_ppr)    | Gitlab::Access::MAINTAINER | '@my-scope/my-package-stage-sha-1234' | :npm   | false
        ref(:project_with_ppr)    | Gitlab::Access::MAINTAINER | '@my-scope/my-package-stage-sha-1234' | :npm   | false
        ref(:project_with_ppr)    | Gitlab::Access::OWNER      | '@my-scope/my-package-stage-sha-1234' | :npm   | false
        ref(:project_with_ppr)    | Gitlab::Access::ADMIN      | '@my-scope/my-package-stage-sha-1234' | :npm   | false

        ref(:project_with_ppr)    | Gitlab::Access::DEVELOPER  | '@my-scope/my-package-prod-sha-1234'  | :npm   | true
        ref(:project_with_ppr)    | Gitlab::Access::MAINTAINER | '@my-scope/my-package-prod-sha-1234'  | :npm   | true
        ref(:project_with_ppr)    | Gitlab::Access::OWNER      | '@my-scope/my-package-prod-sha-1234'  | :npm   | false
        ref(:project_with_ppr)    | Gitlab::Access::ADMIN      | '@my-scope/my-package-prod-sha-1234'  | :npm   | false

        ref(:project_with_ppr)    | Gitlab::Access::DEVELOPER  | '@my-scope/my-package-release-v1'     | :npm   | true
        ref(:project_with_ppr)    | Gitlab::Access::OWNER      | '@my-scope/my-package-release-v1'     | :npm   | true
        ref(:project_with_ppr)    | Gitlab::Access::ADMIN      | '@my-scope/my-package-release-v1'     | :npm   | false

        ref(:project_with_ppr)    | Gitlab::Access::DEVELOPER  | '@my-scope/my-package-any-suffix'     | :npm   | true
        ref(:project_with_ppr)    | Gitlab::Access::MAINTAINER | '@my-scope/my-package-any-suffix'     | :npm   | false
        ref(:project_with_ppr)    | Gitlab::Access::OWNER      | '@my-scope/my-package-any-suffix'     | :npm   | false

        # For non-matching package_name
        ref(:project_with_ppr)    | Gitlab::Access::DEVELOPER  | '@my-scope/non-matching-package'      | :npm   | false

        # For non-matching package_type
        ref(:project_with_ppr)    | Gitlab::Access::DEVELOPER  | '@my-scope/my-package-any-suffix'     | :conan | false

        # For no access level
        ref(:project_with_ppr)    | Gitlab::Access::NO_ACCESS  | '@my-scope/my-package-prod'           | :npm   | true

        # Edge cases
        ref(:project_with_ppr)    | nil                        | '@my-scope/my-package-stage-sha-1234' | :npm   | false
        ref(:project_with_ppr)    | Gitlab::Access::DEVELOPER  | nil                                   | :npm   | false
        ref(:project_with_ppr)    | Gitlab::Access::DEVELOPER  | ''                                    | :npm   | false
        ref(:project_with_ppr)    | Gitlab::Access::DEVELOPER  | '@my-scope/my-package-stage-sha-1234' | nil    | false
        ref(:project_with_ppr)    | nil                        | nil                                   | nil    | false

        # For projects that have no package protection rules
        ref(:project_without_ppr) | Gitlab::Access::DEVELOPER  | '@my-scope/my-package-prod'           | :npm   | false
        ref(:project_without_ppr) | Gitlab::Access::MAINTAINER | '@my-scope/my-package-prod'           | :npm   | false
        ref(:project_without_ppr) | Gitlab::Access::OWNER      | '@my-scope/my-package-prod'           | :npm   | false
      end

      with_them do
        it { is_expected.to eq push_protected }
      end
    end
  end

  describe '.for_push_exists_for_multiple_packages' do
    let_it_be(:project_with_ppr) { create(:project) }

    let_it_be(:ppr_for_maintainer) do
      create(:package_protection_rule,
        package_name_pattern: '@my-scope/my-package-prod*',
        project: project_with_ppr,
        package_type: :npm
      )
    end

    let(:package_names) {
      %w[
        @my-scope/my-package-prod-1
        @my-scope/my-package-prod-unmatched-package-type
        @my-scope/unmatched-package-name
        @my-scope/unmatched-package-name-and-package-type
      ]
    }

    let(:package_types) do
      [
        Packages::Package.package_types[:npm],
        Packages::Package.package_types[:maven],
        Packages::Package.package_types[:npm],
        Packages::Package.package_types[:maven]
      ]
    end

    subject do
      described_class
        .for_push_exists_for_multiple_packages(
          project_id: project_with_ppr.id,
          package_names: package_names,
          package_types: package_types
        )
        .to_a
    end

    it do
      is_expected.to eq([
        { "package_name" => '@my-scope/my-package-prod-1',
          "package_type" => Packages::Package.package_types[:npm],
          "protected" => true },
        { "package_name" => '@my-scope/my-package-prod-unmatched-package-type',
          "package_type" => Packages::Package.package_types[:maven],
          "protected" => false },
        { "package_name" => '@my-scope/unmatched-package-name',
          "package_type" => Packages::Package.package_types[:npm],
          "protected" => false },
        { "package_name" => '@my-scope/unmatched-package-name-and-package-type',
          "package_type" => Packages::Package.package_types[:maven],
          "protected" => false }
      ])
    end

    context 'when edge cases' do
      where(:package_names, :package_types, :expected_result) do
        nil                             | nil | []
        []                              | []  | []
        nil                             | []  | []
        %w[@my-scope/my-package-prod-1] | []  | []
      end

      with_them do
        it { is_expected.to eq([]) }
      end
    end
  end
end
