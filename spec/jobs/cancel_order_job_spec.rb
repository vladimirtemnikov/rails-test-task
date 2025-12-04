# frozen_string_literal: true

RSpec.describe CancelOrderJob do
  include ActiveJob::TestHelper

  describe '#perform' do
    let(:order_id) { 123 }

    before do
      allow(Orders::Cancel).to receive(:call)
    end

    it 'calls Orders::Cancel service' do
      perform_enqueued_jobs do
        described_class.perform_later(order_id:)
      end
      expect(Orders::Cancel).to have_received(:call).with(order_id:)
    end
  end
end
