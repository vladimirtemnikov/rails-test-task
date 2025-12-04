# frozen_string_literal: true

RSpec.describe SafeWalletBalanceUpdateQuery do
  describe '#run' do
    let(:user) { create(:user) }
    let(:wallet) { user.wallet }
    let(:amount) { 100.0 }
    let(:query) { described_class.new(amount:, id: wallet.id) }

    context 'when increasing balance (positive amount)' do
      let(:amount) { 50.0 }
      let(:initial_balance) { 100.0 }

      before do
        wallet.update!(balance: initial_balance)
      end

      it 'increases the wallet balance' do
        expect { query.run }.to change { wallet.reload.balance }.from(initial_balance).to(initial_balance + amount)
      end

      it 'returns the number of updated rows' do
        expect(query.run).to eq(1)
      end
    end

    context 'when decreasing balance with sufficient funds' do
      let(:amount) { -30.0 }
      let(:initial_balance) { 100.0 }

      before do
        wallet.update!(balance: initial_balance)
      end

      it 'decreases the wallet balance' do
        expect { query.run }.to change { wallet.reload.balance }.from(initial_balance).to(initial_balance + amount)
      end

      it 'returns the number of updated rows' do
        expect(query.run).to eq(1)
      end
    end

    context 'when decreasing balance with insufficient funds' do
      let(:amount) { -150.0 }
      let(:initial_balance) { 100.0 }

      before do
        wallet.update!(balance: initial_balance)
      end

      it 'does not update the wallet balance' do
        expect { query.run }.not_to(change { wallet.reload.balance })
      end

      it 'returns 0 (no rows updated)' do
        expect(query.run).to eq(0)
      end
    end

    context 'when decreasing balance to exactly zero' do
      let(:amount) { -100.0 }
      let(:initial_balance) { 100.0 }

      before do
        wallet.update!(balance: initial_balance)
      end

      it 'decreases the balance to zero' do
        expect { query.run }.to change { wallet.reload.balance }.from(initial_balance).to(0.0)
      end

      it 'returns the number of updated rows' do
        expect(query.run).to eq(1)
      end
    end

    context 'when wallet does not exist' do
      let(:non_existent_id) { 999_999 }
      let(:query) { described_class.new(amount:, id: non_existent_id) }

      it 'returns 0 (no rows updated)' do
        expect(query.run).to eq(0)
      end

      it 'does not affect any wallets' do
        expect { query.run }.not_to(change(Wallet, :count))
      end
    end

    context 'when updating specific wallet among multiple wallets' do
      let(:other_user) { create(:user) }
      let(:other_wallet) { other_user.wallet }
      let(:amount) { 50.0 }
      let(:target_balance) { 100.0 }
      let(:other_balance) { 200.0 }

      before do
        wallet.update!(balance: target_balance)
        other_wallet.update!(balance: other_balance)
      end

      it 'only updates the specified wallet' do
        query.run
        expect(wallet.reload.balance).to eq(target_balance + amount)
        expect(other_wallet.reload.balance).to eq(other_balance)
      end
    end

    context 'when amount is zero' do
      let(:amount) { 0.0 }
      let(:initial_balance) { 100.0 }

      before do
        wallet.update!(balance: initial_balance)
      end

      it 'does not change the balance' do
        expect { query.run }.not_to(change { wallet.reload.balance })
      end

      it 'returns the number of updated rows' do
        expect(query.run).to eq(1)
      end
    end

    context 'with custom repo_name' do
      let(:custom_wallet_class) do
        Class.new(Wallet) do
          self.table_name = 'wallets'
        end
      end
      let(:amount) { 25.0 }
      let(:initial_balance) { 50.0 }
      let(:query) { described_class.new(amount:, id: wallet.id, repo_name: 'Wallet') }

      before do
        wallet.update!(balance: initial_balance)
      end

      it 'updates using the specified repository' do
        expect { query.run }.to change { wallet.reload.balance }.from(initial_balance).to(initial_balance + amount)
      end
    end

    context 'when balance constraint would be violated' do
      let(:amount) { -50.0 }
      let(:initial_balance) { 30.0 }

      before do
        wallet.update!(balance: initial_balance)
      end

      it 'returns 0 due to WHERE clause check' do
        # The WHERE balance >= -amount clause prevents the update
        # balance (30) >= -amount (50) is false, so 0 rows updated
        expect(query.run).to eq(0)
      end

      it 'does not update the balance' do
        expect { query.run }.not_to(change { wallet.reload.balance })
      end
    end

    context 'with decimal precision' do
      let(:amount) { 0.01 }
      let(:initial_balance) { 99.99 }

      before do
        wallet.update!(balance: initial_balance)
      end

      it 'handles decimal amounts correctly' do
        expect { query.run }.to change { wallet.reload.balance }.from(initial_balance).to(100.0)
      end
    end

    context 'when id is nil' do
      let(:query) { described_class.new(amount:, id: nil) }

      before do
        create_list(:user, 3) # Creates 3 wallets
      end

      it 'does not update any wallets' do
        expect(query.run).to eq(0)
      end
    end
  end
end
