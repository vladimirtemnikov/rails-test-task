# frozen_string_literal: true

RSpec.describe OrderPolicy do
  let(:policy) { described_class.new(order, user:) }

  let(:user) { build_stubbed(:user, wallet:) }
  let(:another_user) { build_stubbed(:user) }
  let(:wallet) { build_stubbed(:wallet, balance: wallet_balance) }
  let(:order) { build_stubbed(:order, user: order_user, status: order_status) }

  let(:order_user) { user }
  let(:wallet_balance) { 1000 }
  let(:order_status) { :created }

  describe '#show?' do
    subject(:result) { policy.apply(:show?) }

    it { is_expected.to be true }

    context 'when the user is not an owner' do
      let(:order_user) { another_user }

      it { is_expected.to be false }
    end
  end

  describe '#complete?' do
    subject(:result) { policy.apply(:complete?) }

    it { is_expected.to be true }

    context 'when the user is not an owner' do
      let(:order_user) { another_user }

      it { is_expected.to be false }
    end

    context 'when the user is an owner and order state is wrong' do
      let(:order_status) { :completed }

      it { is_expected.to be false }
    end

    context 'when the user is an owner and order state is ok and low balance' do
      let(:wallet_balance) { 10 }

      it { is_expected.to be false }
    end
  end

  describe '#cancel?' do
    subject(:result) { policy.apply(:cancel?) }

    let(:order_status) { :completed }

    it { is_expected.to be true }

    context 'when the user is not an owner' do
      let(:order_user) { another_user }

      it { is_expected.to be false }
    end

    context 'when the user is an owner and order state is wrong' do
      let(:order_status) { :cancelled }

      it { is_expected.to be false }
    end
  end

  describe 'relation scope' do
    subject { policy.apply_scope(target, type: :active_record_relation).pluck(:amount) }

    let(:user) { user1 }

    let(:target) do
      Order.where(amount: [10, 20]).order(:id)
    end

    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    before do
      create(:order, user: user1, amount: 10)
      create(:order, user: user1, amount: 20)
      create(:order, user: user2, amount: 30)
    end

    it { is_expected.to eq([10, 20]) }
  end
end
