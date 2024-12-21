require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  test "unique user-organization combination" do
    membership = Membership.new(organization: organizations(:one), user: users(:one))
    assert_not membership.valid?
    assert_includes membership.errors.messages[:user_id], "has already been taken"
    assert_includes membership.errors.messages[:organization_id], "has already been taken"
  end

  test "try_destroy" do
    # does not destroy only admin
    organization = organizations(:one)
    membership = organization.memberships.first
    assert_not membership.try_destroy

    # does not destroy only admin
    # destroys member
    new_membership = organization.memberships.create(user: users(:two), role: "member")
    assert_not membership.try_destroy
    assert new_membership.try_destroy

    # destroys admin if there is another admin
    admin_membership = organization.memberships.create(user: users(:two), role: "admin", invitation_status: "active")
    assert membership.try_destroy
    assert_not admin_membership.try_destroy
  end

  test "cannot_change_role_if_only_admin" do
    organization = organizations(:one)
    membership = organization.memberships.find_by(role: "admin")

    membership.role = "member"
    assert_not membership.save
    assert_includes membership.errors.messages[:base], "Role cannot be changed because this is the only admin."
  end

  test "at_teast_one_admin_must_have_active_invitation_status" do
    organization = organizations(:one)
    admin_membership_statuses = organization.memberships.where(role: "admin").pluck(:invitation_status).uniq

    assert_includes admin_membership_statuses, "active", "No active admin memberships found in the organization."
  end
end
