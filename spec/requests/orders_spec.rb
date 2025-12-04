# frozen_string_literal: true

RSpec.describe 'Orders' do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:order) { create(:order, user: user1) }

  it 'prevents accessing another user\'s order' do
    sign_in user2
    get order_path(order)
    expect(response).to have_http_status(:unauthorized)
  end
end
