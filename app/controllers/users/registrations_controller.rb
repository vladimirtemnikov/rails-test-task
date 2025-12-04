# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    protected

    def build_resource(params = {})
      self.resource = Users::Build.call(params:)
    end
  end
end
