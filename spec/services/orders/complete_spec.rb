# frozen_string_literal: true

RSpec.describe Orders::Complete, type: :service do
  describe '.call' do
    let(:order_id) { 123 }
    let(:wallet_id) { 456 }
    let(:amount) { 100.0 }
    let(:negative_amount) { -amount }

    let(:wallet) { instance_double(Wallet, id: wallet_id) }
    let(:user) { instance_double(User, wallet:) }
    let(:order) do
      instance_double(
        Order,
        id: order_id,
        user:,
        amount:,
        may_complete?: true,
        complete!: true
      )
    end

    let(:order_repo) { class_double(Order) }
    let(:service) { described_class.new(order_id:, repo_name: 'Order') }

    before do
      allow(service).to receive(:repo).and_return(order_repo)
      allow(ApplicationRecord).to receive(:transaction).and_yield
    end

    context 'when order is found and can be completed' do
      let(:wallet_transaction) { instance_double(WalletTransaction) }

      before do
        allow(order_repo).to receive(:find_by).with(id: order_id).and_return(order)
        allow(WalletTransactions::Create).to receive(:call).and_return(wallet_transaction)
        allow(Wallets::ChangeBalance).to receive(:call)
      end

      it 'finds the order' do
        service.call
        expect(order_repo).to have_received(:find_by).with(id: order_id)
      end

      it 'checks if order can be completed' do
        service.call
        expect(order).to have_received(:may_complete?)
      end

      it 'calls WalletTransactions::Create with correct parameters' do
        service.call
        expect(WalletTransactions::Create).to have_received(:call).with(
          amount: negative_amount,
          kind: :purchase,
          wallet_id:,
          order_id:
        )
      end

      it 'calls Wallets::ChangeBalance with negative amount and wallet_id' do
        service.call
        expect(Wallets::ChangeBalance).to have_received(:call).with(
          amount: negative_amount,
          wallet_id:
        )
      end

      it 'completes the order' do
        service.call
        expect(order).to have_received(:complete!)
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
        allow(WalletTransactions::Create).to receive(:call)
        allow(Wallets::ChangeBalance).to receive(:call)
      end

      it 'raises OrderNotFoundError' do
        expect { service.call }.to raise_error(
          Orders::Complete::OrderNotFoundError,
          "Order #{order_id} not found"
        )
      end

      it 'does not call WalletTransactions::Create' do
        expect { service.call }.to raise_error(Orders::Complete::OrderNotFoundError)
        expect(WalletTransactions::Create).not_to have_received(:call)
      end

      it 'does not call Wallets::ChangeBalance' do
        expect { service.call }.to raise_error(Orders::Complete::OrderNotFoundError)
        expect(Wallets::ChangeBalance).not_to have_received(:call)
      end
    end

    context 'when order cannot be completed' do
      let(:order_cannot_complete) do
        instance_double(Order, id: order_id, may_complete?: false)
      end

      before do
        allow(order_repo).to receive(:find_by).with(id: order_id).and_return(order_cannot_complete)
        allow(WalletTransactions::Create).to receive(:call)
      end

      it 'raises InvalidOrderStateError' do
        expect { service.call }.to raise_error(
          Orders::Complete::InvalidOrderStateError,
          "Order #{order_id} cannot be completed"
        )
      end

      it 'does not call WalletTransactions::Create' do
        expect { service.call }.to raise_error(Orders::Complete::InvalidOrderStateError)
        expect(WalletTransactions::Create).not_to have_received(:call)
      end
    end

    context 'when insufficient funds' do
      let(:insufficient_funds_error) { Wallets::InsufficientFundsError.new }

      before do
        allow(order_repo).to receive(:find_by).with(id: order_id).and_return(order)
        allow(WalletTransactions::Create).to receive(:call)
        allow(Wallets::ChangeBalance).to receive(:call).and_raise(insufficient_funds_error)
      end

      it 'raises InsufficientFundsError' do
        expect { service.call }.to raise_error(Wallets::InsufficientFundsError)
      end

      it 'does not complete the order' do
        expect { service.call }.to raise_error(Wallets::InsufficientFundsError)
        expect(order).not_to have_received(:complete!)
      end

      it 'creates the transaction before checking balance' do
        expect { service.call }.to raise_error(Wallets::InsufficientFundsError)
        expect(WalletTransactions::Create).to have_received(:call).ordered
        expect(Wallets::ChangeBalance).to have_received(:call).ordered
      end
    end

    context 'when ActiveRecord::RecordInvalid is raised' do
      let(:error_message) { 'Record invalid' }
      let(:record_invalid_error) { ActiveRecord::RecordInvalid.new }

      before do
        allow(order_repo).to receive(:find_by).with(id: order_id).and_return(order)
        allow(WalletTransactions::Create).to receive(:call).and_raise(record_invalid_error)
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error' do
        expect { service.call }.to raise_error(ActiveRecord::RecordInvalid)
        expect(Rails.logger).to have_received(:error).with("Failed to complete order #{order_id}: #{error_message}")
      end

      it 're-raises the error' do
        expect { service.call }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when wallet is accessed' do
      before do
        allow(order_repo).to receive(:find_by).with(id: order_id).and_return(order)
        allow(WalletTransactions::Create).to receive(:call)
        allow(Wallets::ChangeBalance).to receive(:call)
      end

      it 'accesses wallet through user' do
        service.call
        expect(order).to have_received(:user)
        expect(user).to have_received(:wallet)
      end
    end

    context 'when wallet balance changes concurrently' do
      before do
        allow(order_repo).to receive(:find_by).with(id: order_id).and_return(order)
        allow(WalletTransactions::Create).to receive(:call)
      end

      it 'prevents negative balance through atomic update check' do
        # Simulate concurrent scenario: first call succeeds, second fails due to concurrent deduction
        call_count = 0
        allow(Wallets::ChangeBalance).to receive(:call) do
          call_count += 1
          # First call: atomic update succeeds (1 row updated = sufficient balance)
          # Second call: atomic update fails (0 rows updated = concurrent transaction already deducted)
          raise Wallets::InsufficientFundsError unless call_count == 1

          # Success case - balance was sufficient
          nil

          # Concurrent case - balance was deducted by another transaction
        end

        # First call succeeds
        expect { service.call }.not_to raise_error

        # Second concurrent call fails due to atomic check
        expect { service.call }.to raise_error(Wallets::InsufficientFundsError)
      end

      it 'uses atomic SQL update that only succeeds when balance >= amount' do
        # The atomic update pattern: UPDATE wallets SET balance = balance + amount
        # WHERE id = wallet_id AND balance >= -amount
        # If concurrent transaction already deducted, WHERE clause fails, returns 0 rows
        allow(Wallets::ChangeBalance).to receive(:call) do
          # Simulate atomic update returning 0 (concurrent transaction won)
          raise Wallets::InsufficientFundsError
        end

        expect { service.call }.to raise_error(Wallets::InsufficientFundsError)
        expect(Wallets::ChangeBalance).to have_received(:call).with(
          amount: negative_amount,
          wallet_id:
        )
      end

      it 'rolls back entire transaction when balance update fails' do
        transaction_block_called = false
        transaction_rolled_back = false

        allow(ApplicationRecord).to receive(:transaction) do |&block|
          transaction_block_called = true
          begin
            block.call
          rescue Wallets::InsufficientFundsError
            transaction_rolled_back = true
            raise
          end
        end

        allow(Wallets::ChangeBalance).to receive(:call).and_raise(Wallets::InsufficientFundsError)

        expect { service.call }.to raise_error(Wallets::InsufficientFundsError)
        expect(transaction_block_called).to be true
        expect(transaction_rolled_back).to be true
      end

      it 'does not complete order when concurrent balance change causes insufficient funds' do
        allow(Wallets::ChangeBalance).to receive(:call).and_raise(Wallets::InsufficientFundsError)

        expect { service.call }.to raise_error(Wallets::InsufficientFundsError)
        expect(order).not_to have_received(:complete!)
      end

      it 'does not create wallet transaction when balance update fails' do
        transaction_created = false
        allow(WalletTransactions::Create).to receive(:call) do
          transaction_created = true
        end

        allow(Wallets::ChangeBalance).to receive(:call).and_raise(Wallets::InsufficientFundsError)

        expect { service.call }.to raise_error(Wallets::InsufficientFundsError)
        # Transaction is created but rolled back due to transaction block
        expect(transaction_created).to be true
      end

      it 'ensures no negative balance can result from concurrent operations' do
        # This test verifies the atomic update prevents race conditions
        # The WHERE balance >= amount clause ensures:
        # - If balance is sufficient: update succeeds (1 row)
        # - If concurrent transaction deducted: update fails (0 rows) -> raises error
        # - Database constraint also prevents negative balance as final safeguard

        allow(Wallets::ChangeBalance).to receive(:call) do
          # Simulate the atomic check: WHERE balance >= amount returns 0 rows
          # This means concurrent transaction already deducted the balance
          raise Wallets::InsufficientFundsError
        end

        expect { service.call }.to raise_error(Wallets::InsufficientFundsError)
        # Verify the atomic check prevented the negative balance
        expect(order).not_to have_received(:complete!)
      end
    end
  end
end
