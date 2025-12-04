# frozen_string_literal: true

RSpec.describe Wallets::Create, type: :service do
  describe '.call' do
    let(:user_id) { 123 }
    let(:balance) { 0 }
    let(:wallet) { instance_double(wallet_repo, id: 456, user_id:, balance:) }

    let(:wallet_repo) do
      Class.new do
        def self.create!(*); end
        def self.name = 'WalletStub'
        def id; end
        def user_id; end
        def balance; end
      end
    end
    let(:service) { described_class.new(user_id:, balance:, repo_name: 'WalletStub') }

    before do
      allow(service).to receive(:repo).and_return(wallet_repo)
      allow(wallet_repo).to receive(:create!).and_return(wallet)
    end

    context 'when wallet is created successfully' do
      it 'calls repo.create! with correct parameters' do
        service.call
        expect(wallet_repo).to have_received(:create!).with(balance:, user_id:)
      end

      it 'returns the created wallet' do
        result = service.call
        expect(result).to eq(wallet)
      end
    end

    context 'with default balance' do
      let(:service_with_default) { described_class.new(user_id:) }

      before do
        allow(service_with_default).to receive(:repo).and_return(wallet_repo)
      end

      it 'uses default balance of 0' do
        service_with_default.call
        expect(wallet_repo).to have_received(:create!).with(balance: 0, user_id:)
      end
    end

    context 'with custom balance' do
      let(:custom_balance) { 1000.0 }

      let(:service_with_balance) do
        described_class.new(user_id:, balance: custom_balance)
      end

      before do
        allow(service_with_balance).to receive(:repo).and_return(wallet_repo)
      end

      it 'uses the custom balance' do
        service_with_balance.call
        expect(wallet_repo).to have_received(:create!).with(balance: 1000.0, user_id: 123)
      end
    end

    context 'when creation fails' do
      let(:error) { ActiveRecord::RecordInvalid.new }

      before do
        allow(wallet_repo).to receive(:create!).and_raise(error)
      end

      it 'raises the error' do
        expect { service.call }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
