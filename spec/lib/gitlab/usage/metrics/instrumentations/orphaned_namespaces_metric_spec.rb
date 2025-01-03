# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::OrphanedNamespacesMetric, feature_category: :service_ping do
  let(:expected_value) { false }

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }
end
