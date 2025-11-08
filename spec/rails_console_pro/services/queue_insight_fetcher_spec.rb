# frozen_string_literal: true

require 'rails_helper'
require 'active_job'

RSpec.describe RailsConsolePro::Services::QueueInsightFetcher do
  before(:all) do
    unless defined?(SampleQueueJob)
      class SampleQueueJob < ActiveJob::Base
        queue_as :default

        def perform(*args); end
      end
    end
  end

  around do |example|
    previous_adapter = if defined?(ActiveJob::Base)
                         ActiveJob::Base.queue_adapter
                       end

    if defined?(ActiveJob::Base)
      ActiveJob::Base.queue_adapter = :test
      clear_test_adapter!
    end

    example.run
  ensure
    if defined?(ActiveJob::Base) && previous_adapter
      ActiveJob::Base.queue_adapter = previous_adapter
    end
  end

  it 'returns queue insights for ActiveJob test adapter' do
    skip "ActiveJob not available" unless defined?(ActiveJob::Base)

    SampleQueueJob.perform_later('alpha', count: 1)
    fetcher = described_class.new
    result = fetcher.fetch(limit: 5)

    expect(result).to be_a(RailsConsolePro::QueueInsightsResult)
    expect(result.enqueued_jobs.size).to eq(1)
    job = result.enqueued_jobs.first
    expect(job.job_class).to match(/SampleQueueJob/)
    expect(job.args.first).to eq('alpha')
    args_hash = job.args.last
    count_value = args_hash[:count] || args_hash['count']
    expect(count_value).to eq(1)
  end

  it 'caps limit to avoid huge queries' do
    skip "ActiveJob not available" unless defined?(ActiveJob::Base)

    fetcher = described_class.new
    expect(fetcher.fetch(limit: 1000).enqueued_jobs.length).to be <= 200
  end

  context 'when Sidekiq is available but ActiveJob adapter is async' do
    before do
      skip "ActiveJob not available" unless defined?(ActiveJob::Base)

      module Sidekiq; end unless defined?(Sidekiq)
      class Sidekiq::Queue; end unless defined?(Sidekiq::Queue)

      ActiveJob::Base.queue_adapter = ActiveJob::QueueAdapters::AsyncAdapter.new
    end

    it 'falls back to Sidekiq adapter' do
      skip "Sidekiq not stubbed" unless defined?(Sidekiq::Queue)

      fake_result = RailsConsolePro::QueueInsightsResult.new(
        adapter_name: 'Sidekiq',
        adapter_type: 'ActiveJob Adapter',
        enqueued_jobs: [],
        retry_jobs: [],
        recent_executions: [],
        meta: {},
        warnings: []
      )

      sidekiq_adapter = instance_double(RailsConsolePro::Services::QueueInsightFetcher::Adapters::Sidekiq)
      allow(RailsConsolePro::Services::QueueInsightFetcher::Adapters::Sidekiq).to receive(:new).and_return(sidekiq_adapter)
      allow(sidekiq_adapter).to receive(:fetch).and_return(fake_result)

      fetcher = described_class.new(ActiveJob::Base.queue_adapter)
      fetcher.fetch(limit: 5)

      expect(RailsConsolePro::Services::QueueInsightFetcher::Adapters::Sidekiq).to have_received(:new)
    end
  end

  def clear_test_adapter!
    adapter = ActiveJob::Base.queue_adapter
    return unless adapter.respond_to?(:enqueued_jobs)

    adapter.enqueued_jobs.clear
    adapter.performed_jobs.clear if adapter.respond_to?(:performed_jobs)
  end
end


