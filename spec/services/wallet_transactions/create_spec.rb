# frozen_string_literal: true

RSpec.describe WalletTransactions::Create, type: :service do
  describe '.call' do
    let(:amount) { 100.0 }
    let(:wallet_id) { 123 }
    let(:order_id) { 456 }
    let(:kind) { :purchase }
    let(:original_transaction_id) { nil }
    let(:idempotency_key) { SecureRandom.uuid }
    let(:wallet_transaction) { instance_double(WalletTransaction) }

    let(:transaction_repo) { class_double(WalletTransaction) }
    let(:service) do
      described_class.new(
        amount:,
        wallet_id:,
        order_id:,
        kind:,
        original_transaction_id:,
        idempotency_key:,
        repo_name: 'WalletTransaction'
      )
    end

    before do
      allow(service).to receive(:repo).and_return(transaction_repo)
      allow(transaction_repo).to receive(:create!).and_return(wallet_transaction)
    end

    context 'when transaction is created successfully' do
      it 'calls repo.create! with correct parameters' do
        service.call
        expect(transaction_repo).to have_received(:create!).with(
          amount:,
          wallet_id:,
          order_id:,
          kind:,
          original_transaction_id:,
          idempotency_key:
        )
      end

      it 'returns the created transaction' do
        result = service.call
        expect(result).to eq(wallet_transaction)
      end
    end

    context 'with default parameters' do
      let(:service_with_defaults) do
        described_class.new(
          amount:,
          wallet_id:,
          order_id:
        )
      end

      before do
        allow(service_with_defaults).to receive(:repo).and_return(transaction_repo)
      end

      it 'uses default kind :purchase' do
        service_with_defaults.call
        expect(transaction_repo).to have_received(:create!).with(
          hash_including(kind: :purchase)
        )
      end

      it 'uses default original_transaction_id as nil' do
        service_with_defaults.call
        expect(transaction_repo).to have_received(:create!).with(
          hash_including(original_transaction_id: nil)
        )
      end

      it 'generates a uuid for idempotency_key' do
        service_with_defaults.call
        expect(transaction_repo).to have_received(:create!) do |args|
          expect(args[:idempotency_key]).to be_a(String)
          expect(args[:idempotency_key].length).to eq(36) # UUID format
        end
      end
    end

    context 'when creation fails' do
      let(:error) { ActiveRecord::RecordInvalid.new }

      before do
        allow(transaction_repo).to receive(:create!).and_raise(error)
      end

      it 'raises the error' do
        expect { service.call }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'with reversal kind' do
      let(:kind) { :reversal }
      let(:original_transaction_id) { 789 }

      it 'creates reversal transaction with original_transaction_id' do
        service.call
        expect(transaction_repo).to have_received(:create!).with(
          hash_including(
            kind: :reversal,
            original_transaction_id:
          )
        )
      end
    end
  end
end
