# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }

  resources :orders, only: %i[index new show create] do
    member do
      post :complete
      post :cancel
    end
  end

  resources :wallet_transactions, only: :index

  root 'orders#index'
end
