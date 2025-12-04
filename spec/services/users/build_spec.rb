# frozen_string_literal: true

RSpec.describe Users::Build, type: :service do
  describe '.call' do
    let(:params) { { email: 'test@example.com', password: 'password123' } }
    let(:user) { instance_double(User) }
    let(:wallet) { instance_double(Wallet) }

    let(:user_repo) { class_double(User) }
    let(:service) { described_class.new(params:, repo_name: 'User') }

    before do
      allow(service).to receive(:repo).and_return(user_repo)
      allow(user_repo).to receive(:new).with(params).and_return(user)
      allow(user).to receive(:build_wallet).with(balance: described_class::START_BALANCE).and_return(wallet)
    end

    it 'creates a new user with params' do
      service.call
      expect(user_repo).to have_received(:new).with(params)
    end

    it 'builds wallet with START_BALANCE' do
      service.call
      expect(user).to have_received(:build_wallet).with(balance: described_class::START_BALANCE)
    end

    it 'returns the user with built wallet' do
      result = service.call
      expect(result).to eq(user)
    end

    context 'when START_BALANCE constant is used' do
      it 'uses the correct balance value' do
        expect(described_class::START_BALANCE).to eq(1000)
        service.call
        expect(user).to have_received(:build_wallet).with(balance: 1000)
      end
    end
  end
end
