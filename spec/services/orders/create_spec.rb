# frozen_string_literal: true

RSpec.describe Orders::Create, type: :service do
  describe '.call' do
    let(:amount) { 100.0 }
    let(:user_id) { 123 }
    let(:order) { instance_double(Order, id: 456, amount:, user_id:) }

    let(:order_repo) { class_double(Order) }
    let(:service) { described_class.new(amount:, user_id:, repo_name: 'Order') }

    before do
      allow(service).to receive(:repo).and_return(order_repo)
    end

    context 'when order is created successfully' do
      before do
        allow(order_repo).to receive(:create).with(amount:, user_id:).and_return(order)
      end

      it 'calls repo.create with correct parameters' do
        service.call
        expect(order_repo).to have_received(:create).with(amount:, user_id:)
      end

      it 'returns the created order' do
        result = service.call
        expect(result).to eq(order)
      end
    end

    context 'when creation fails' do
      let(:error) { ActiveRecord::RecordInvalid.new }

      before do
        allow(order_repo).to receive(:create).with(amount:, user_id:).and_raise(error)
      end

      it 'raises the error' do
        expect { service.call }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
