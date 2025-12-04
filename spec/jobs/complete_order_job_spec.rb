# frozen_string_literal: true

RSpec.describe CompleteOrderJob do
  include ActiveJob::TestHelper

  let(:order) { instance_double(Order, id: 1) }

  describe '#perform' do
    before do
      allow(Orders::Complete).to receive(:call)
    end

    it 'calls Orders::Complete service' do
      perform_enqueued_jobs do
        described_class.perform_later(order_id: order.id)
      end
      expect(Orders::Complete).to have_received(:call).with(order_id: order.id)
    end
  end
end
