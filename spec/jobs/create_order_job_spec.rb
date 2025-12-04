# frozen_string_literal: true

RSpec.describe CreateOrderJob do
  include ActiveJob::TestHelper

  let(:user) { instance_double(User, id: 1) }
  let(:amount) { 100 }

  describe '#perform' do
    before do
      allow(Orders::Create).to receive(:call)
    end

    it 'calls Orders::Create service' do
      perform_enqueued_jobs do
        described_class.perform_later(amount:, user_id: user.id)
      end
      expect(Orders::Create).to have_received(:call).with(amount:, user_id: user.id)
    end
  end
end
