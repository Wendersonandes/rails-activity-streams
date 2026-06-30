ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all

    def create_profile_for(user, name: nil)
      ProfileCreation.new(user, name: name || user.email.split("@").first).call
    end

    def seed_permissions_and_relations
      Permission.instances([
        [ :create, :activity ],
        [ :read,   :activity ],
        [ :update, :activity ],
        [ :destroy, :activity ],
        [ :follow, nil ],
        [ :represent, nil ]
      ])

      # Clear singleton caches for fresh records per test
      [ Relation::Public, Relation::Follow, Relation::Reject ].each do |klass|
        klass.instance_variable_set(:@instance, nil)
      end

      Relation::Public.instance
      Relation::Follow.instance
      Relation::Reject.instance
    end
  end
end
