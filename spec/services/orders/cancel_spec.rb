# frozen_string_literal: true

RSpec.describe Orders::Cancel, type: :service do
  describe '.call' do
    let(:order_id) { 123 }
    let(:wallet_id) { 456 }
    let(:purchase_transaction_id) { 789 }
    let(:amount) { 100.0 }

    let(:wallet) { instance_double(Wallet, id: wallet_id) }
    let(:user) { instance_double(User, wallet:) }
    let(:purchase_transaction) do
      instance_double(WalletTransaction, id: purchase_transaction_id)
    end
    let(:order) do
      instance_double(
        Order,
        id: order_id,
        user:,
        amount:,
        purchase_transaction:,
        may_cancel?: true,
        cancel!: true
      )
    end

    let(:order_repo) { class_double(Order) }
    let(:service) { described_class.new(order_id:, repo_name: 'Order') }

    before do
      allow(service).to receive(:repo).and_return(order_repo)
      allow(ApplicationRecord).to receive(:transaction).and_yield
    end

    context 'when order is found and can be cancelled' do
      before do
        allow(order_repo).to receive(:find_by).with(id: order_id).and_return(order)
        allow(WalletTransactions::Reverse).to receive(:call).with(id: purchase_transaction_id)
        allow(Wallets::ChangeBalance).to receive(:call).with(amount:, wallet_id:)
      end

      it 'finds the order' do
        service.call
        expect(order_repo).to have_received(:find_by).with(id: order_id)
      end

      it 'checks if order can be cancelled' do
        service.call
        expect(order).to have_received(:may_cancel?)
      end

      it 'checks for purchase transaction' do
        service.call
        expect(order).to have_received(:purchase_transaction).twice
      end

      it 'calls WalletTransactions::Reverse with purchase transaction id' do
        service.call
        expect(WalletTransactions::Reverse).to have_received(:call).with(id: purchase_transaction_id)
      end

      it 'calls Wallets::ChangeBalance with correct amount and wallet_id' do
        service.call
        expect(Wallets::ChangeBalance).to have_received(:call).with(
          amount:,
          wallet_id:
        )
      end

      it 'cancels the order' do
        service.call
        expect(order).to have_received(:cancel!)
      end

      it 'executes within a transaction' do
        service.call
        expect(ApplicationRecord).to have_received(:transaction)
      end

      it 'returns successfully' do
        expect { service.call }.not_to raise_error
      end
    end

    context 'when order is not found' do
      before do
        allow(order_repo).to receive(:find_by).with(id: order_id).and_return(nil)
        allow(Wallets::ChangeBalance).to receive(:call)
        allow(WalletTransactions::Reverse).to receive(:call)
      end

      it 'raises OrderNotFoundError' do
        expect { service.call }.to raise_error(
          Orders::Cancel::OrderNotFoundError,
          "Order #{order_id} not found"
        )
      end

      it 'does not call WalletTransactions::Reverse' do
        expect { service.call }.to raise_error(Orders::Cancel::OrderNotFoundError)
        expect(WalletTransactions::Reverse).not_to have_received(:call)
      end

      it 'does not call Wallets::ChangeBalance' do
        expect { service.call }.to raise_error(Orders::Cancel::OrderNotFoundError)
        expect(Wallets::ChangeBalance).not_to have_received(:call)
      end
    end

    context 'when order cannot be cancelled' do
      let(:order_cannot_cancel) do
        instance_double(Order, id: order_id, may_cancel?: false)
      end

      before do
        allow(order_repo).to receive(:find_by).with(id: order_id).and_return(order_cannot_cancel)
        allow(WalletTransactions::Reverse).to receive(:call)
      end

      it 'raises InvalidOrderStateError' do
        expect { service.call }.to raise_error(
          Orders::Cancel::InvalidOrderStateError,
          "Order #{order_id} cannot be cancelled"
        )
      end

      it 'does not call WalletTransactions::Reverse' do
        expect { service.call }.to raise_error(Orders::Cancel::InvalidOrderStateError)
        expect(WalletTransactions::Reverse).not_to have_received(:call)
      end
    end

    context 'when order has no purchase transaction' do
      let(:order_no_transaction) do
        instance_double(
          Order,
          id: order_id,
          may_cancel?: true,
          purchase_transaction: nil
        )
      end

      before do
        allow(order_repo).to receive(:find_by).with(id: order_id).and_return(order_no_transaction)
        allow(WalletTransactions::Reverse).to receive(:call)
      end

      it 'raises MissingPurchaseTransactionError' do
        expect { service.call }.to raise_error(
          Orders::Cancel::MissingPurchaseTransactionError,
          "Order #{order_id} has no purchase transaction"
        )
      end

      it 'does not call WalletTransactions::Reverse' do
        expect { service.call }.to raise_error(Orders::Cancel::MissingPurchaseTransactionError)
        expect(WalletTransactions::Reverse).not_to have_received(:call)
      end
    end

    context 'when ActiveRecord::RecordInvalid is raised' do
      let(:error_message) { 'Record invalid' }
      let(:record_invalid_error) { ActiveRecord::RecordInvalid.new }

      before do
        allow(order_repo).to receive(:find_by).with(id: order_id).and_return(order)
        allow(WalletTransactions::Reverse).to receive(:call).and_raise(record_invalid_error)
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error' do
        expect { service.call }.to raise_error(ActiveRecord::RecordInvalid)
        expect(Rails.logger).to have_received(:error).with("Failed to cancel order #{order_id}: #{error_message}")
      end

      it 're-raises the error' do
        expect { service.call }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when wallet is accessed' do
      before do
        allow(order_repo).to receive(:find_by).with(id: order_id).and_return(order)
        allow(WalletTransactions::Reverse).to receive(:call)
        allow(Wallets::ChangeBalance).to receive(:call)
      end

      it 'accesses wallet through user' do
        service.call
        expect(order).to have_received(:user)
        expect(user).to have_received(:wallet)
      end
    end
  end
end
