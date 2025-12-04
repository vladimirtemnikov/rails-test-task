# frozen_string_literal: true

RSpec.describe Wallets::ChangeBalance, type: :service do
  describe '.call' do
    let(:amount) { 100.0 }
    let(:wallet_id) { 123 }
    let(:query) { instance_double(SafeWalletBalanceUpdateQuery) }
    let(:service) { described_class.new(amount:, wallet_id:) }

    before do
      allow(SafeWalletBalanceUpdateQuery).to receive(:new).and_return(query)
    end

    context 'when balance is increased successfully' do
      before do
        allow(query).to receive(:run).and_return(1)
      end

      it 'creates SafeWalletBalanceUpdateQuery with correct parameters' do
        service.call
        expect(SafeWalletBalanceUpdateQuery).to have_received(:new).with(
          id: wallet_id,
          amount:,
          repo_name: 'Wallet'
        )
      end

      it 'calls run on the query' do
        service.call
        expect(query).to have_received(:run)
      end

      it 'does not raise an error' do
        expect { service.call }.not_to raise_error
      end
    end

    context 'when balance is decreased successfully' do
      let(:amount) { -50.0 }

      before do
        allow(query).to receive(:run).and_return(1)
      end

      it 'updates the balance successfully' do
        expect { service.call }.not_to raise_error
      end

      it 'calls run on the query' do
        service.call
        expect(query).to have_received(:run)
      end
    end

    context 'when insufficient funds (negative amount with zero updates)' do
      let(:amount) { -200.0 }

      before do
        allow(query).to receive(:run).and_return(0)
      end

      it 'raises InsufficientFundsError' do
        expect { service.call }.to raise_error(Wallets::InsufficientFundsError)
      end
    end

    context 'when ActiveRecord::CheckViolation is raised' do
      before do
        allow(query).to receive(:run).and_raise(ActiveRecord::CheckViolation)
      end

      it 'raises InsufficientFundsError' do
        expect { service.call }.to raise_error(Wallets::InsufficientFundsError)
      end
    end

    context 'with custom repo_name' do
      let(:custom_repo_name) { 'CustomWallet' }
      let(:service) { described_class.new(amount:, wallet_id:, repo_name: custom_repo_name) }

      before do
        allow(query).to receive(:run).and_return(1)
      end

      it 'passes custom repo_name to the query' do
        service.call
        expect(SafeWalletBalanceUpdateQuery).to have_received(:new).with(
          id: wallet_id,
          amount:,
          repo_name: custom_repo_name
        )
      end
    end

    context 'when amount is zero' do
      let(:amount) { 0.0 }

      before do
        allow(query).to receive(:run).and_return(1)
      end

      it 'does not raise an error' do
        expect { service.call }.not_to raise_error
      end
    end
  end
end
