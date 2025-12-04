# frozen_string_literal: true

RSpec.describe WalletTransactions::Reverse, type: :service do
  describe '.call' do
    let(:transaction_id) { 123 }
    let(:wallet_id) { 456 }
    let(:order_id) { 789 }
    let(:original_amount) { -100.0 }
    let(:reversed_amount) { 100.0 }

    let(:original_transaction) do
      instance_double(
        WalletTransaction,
        id: transaction_id,
        amount: original_amount,
        wallet_id:,
        order_id:
      )
    end

    let(:reversal_transaction) { instance_double(WalletTransaction) }

    let(:transaction_repo) { class_double(WalletTransaction) }
    let(:service) { described_class.new(id: transaction_id, repo_name: 'WalletTransaction') }

    before do
      allow(service).to receive(:repo).and_return(transaction_repo)
      allow(transaction_repo).to receive(:find).with(transaction_id).and_return(original_transaction)
      allow(original_transaction).to receive(:slice).with(:wallet_id, :order_id).and_return(
        { 'wallet_id' => wallet_id, 'order_id' => order_id }
      )
      allow(WalletTransactions::Create).to receive(:call).and_return(reversal_transaction)
    end

    context 'when reversal is created successfully' do
      it 'finds the original transaction' do
        service.call
        expect(transaction_repo).to have_received(:find).with(transaction_id)
      end

      it 'slices wallet_id and order_id from original transaction' do
        service.call
        expect(original_transaction).to have_received(:slice).with(:wallet_id, :order_id)
      end

      it 'calls WalletTransactions::Create with reversed amount' do
        service.call
        expect(WalletTransactions::Create).to have_received(:call).with(
          amount: reversed_amount,
          original_transaction_id: transaction_id,
          kind: :reversal,
          wallet_id:,
          order_id:
        )
      end

      it 'returns the reversal transaction' do
        result = service.call
        expect(result).to eq(reversal_transaction)
      end
    end

    context 'when original transaction has positive amount' do
      let(:original_amount) { 50.0 }
      let(:reversed_amount) { -50.0 }

      it 'reverses the sign correctly' do
        service.call
        expect(WalletTransactions::Create).to have_received(:call).with(
          hash_including(amount: reversed_amount)
        )
      end
    end

    context 'when original transaction is not found' do
      let(:error) { ActiveRecord::RecordNotFound.new }

      before do
        allow(transaction_repo).to receive(:find).with(transaction_id).and_raise(error)
      end

      it 'raises the error' do
        expect { service.call }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'does not call WalletTransactions::Create' do
        expect { service.call }.to raise_error(ActiveRecord::RecordNotFound)
        expect(WalletTransactions::Create).not_to have_received(:call)
      end
    end

    context 'when Create service fails' do
      let(:error) { ActiveRecord::RecordInvalid.new }

      before do
        allow(WalletTransactions::Create).to receive(:call).and_raise(error)
      end

      it 'raises the error' do
        expect { service.call }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
