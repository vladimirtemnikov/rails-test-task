# frozen_string_literal: true

class OrdersController < ApplicationController
  before_action :authenticate_user!

  def index
    render :index, locals: { orders: authorized_scope(Order.includes(:user, :purchase_transaction)) }
  end

  def show
    order = Order.find(params[:id])
    authorize! order

    render :show, locals: { order: }
  end

  def new
    order = Order.new

    render :new, locals: { order: }
  end

  def create
    order = Order.new(permitted_params.merge(user: current_user))

    unless order.valid?
      render :new, locals: { order: }
      return
    end

    job = CreateOrderJob.perform_later(amount: permitted_params[:amount].to_d, user_id: current_user.id)

    if job.successfully_enqueued?
      redirect_to orders_path, notice: t('.success')
    else
      render :new, locals: { order: }
    end
  end

  def complete
    order = Order.find(params[:id])
    authorize! order

    job = CompleteOrderJob.perform_later(order_id: order.id)

    if job.successfully_enqueued?
      redirect_to orders_path, notice: t('.success')
    else
      redirect_to order, alert: t('.error')
    end
  end

  def cancel
    order = Order.find(params[:id])
    authorize! order

    job = CancelOrderJob.perform_later(order_id: order.id)

    if job.successfully_enqueued?
      redirect_to orders_path, notice: t('.success')
    else
      redirect_to order, alert: t('.error')
    end
  end

  private

  def permitted_params
    params.expect(order: :amount)
  end
end
