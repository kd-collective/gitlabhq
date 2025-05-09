# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:openapi namespace rake tasks', :silence_stdout, feature_category: :api do
  before :all do
    Rake.application.rake_require 'tasks/gitlab/openapi'
    Rake::Task.define_task(:environment)
    Rake::Task.define_task(:enable_feature_flags)
  end

  describe 'gitlab:openapi:check_docs' do
    let(:documentation) { {} }

    before do
      allow(Rake::Task['oapi:fetch']).to receive(:invoke)
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with('tmp/openapi_swagger_doc.json').and_return('{}')
      allow(File).to receive(:read).with('doc/api/openapi/openapi_v2.yaml').and_return(documentation.to_yaml)
    end

    it 'passes when documentation is up to date' do
      expect { run_rake_task('gitlab:openapi:check_docs') }.to output(/OpenAPI documentation is up to date/).to_stdout
    end

    context 'when documentation is outdated' do
      let(:documentation) { { 'outdated' => true } }

      it 'aborts when documentation is outdated' do
        expect { run_rake_task('gitlab:openapi:check_docs') }.to raise_error(SystemExit)
      end

      it 'outputs correct message when documentation is outdated' do
        expected_output = /OpenAPI documentation is outdated!/

        expect { run_rake_task('gitlab:openapi:check_docs') }.to output(expected_output).to_stdout
          .and raise_error(SystemExit)
      end
    end

    context 'when debug is enabled' do
      let(:documentation) { { 'outdated' => true } }
      let(:verbose) { Rake::FileUtilsExt.verbose }
      let(:nowrite) { Rake::FileUtilsExt.nowrite }

      before do
        stub_env('OPENAPI_CHECK_DEBUG', 'true')

        Rake::FileUtilsExt.verbose(false)
        Rake::FileUtilsExt.nowrite(true)
      end

      after do
        Rake::FileUtilsExt.verbose(verbose)
        Rake::FileUtilsExt.nowrite(nowrite)
      end

      it 'outputs a diff' do
        expected_command = 'diff -u doc/api/openapi/openapi_v2.yaml doc/api/openapi/openapi_v2.yaml.generated'

        expect(main_object).to receive(:sh).with(expected_command).and_return(true)
        expect { run_rake_task('gitlab:openapi:check_docs') }.to raise_error(SystemExit)
      end
    end
  end
end
