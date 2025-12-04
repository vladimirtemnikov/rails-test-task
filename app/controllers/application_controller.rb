# frozen_string_literal: true

class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  rescue_from ActionPolicy::Unauthorized do
    head :unauthorized
  end
end
