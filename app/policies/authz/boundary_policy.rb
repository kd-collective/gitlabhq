# frozen_string_literal: true

module Authz
  class BoundaryPolicy < ::BasePolicy
    alias_method :token, :user
    alias_method :boundary, :subject

    condition(:granular_pat) do
      token.is_a?(::PersonalAccessToken) && token.granular?
    end

    condition(:member) do
      next true if token.user.can_read_all_resources?

      boundary.member?(token.user)
    end

    condition(:visible, score: 0) do
      boundary.visible_to?(token.user)
    end

    rule { member | visible }.enable :read_boundary

    ::Authz::PermissionGroups::Assignable.all_permissions.each do |permission|
      desc "Token permission that enables #{permission} for boundary"
      condition(permission) do
        token.permitted_for_boundary?(boundary, permission)
      end

      rule { granular_pat & try(permission) & member }.policy do
        enable permission
      end
    end
  end
end
