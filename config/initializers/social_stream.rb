module SocialStream
  mattr_accessor :available_permissions, :custom_relations, :system_relations, :suggested_models

  self.available_permissions = {
    "profile" => [
      [ "create", "activity" ],
      [ "read",   "activity" ],
      [ "follow", nil ],
      [ "represent", nil ]
    ],
    "group" => [
      [ "create", "activity" ],
      [ "read",   "activity" ],
      [ "update", "activity" ],
      [ "destroy", "activity" ],
      [ "follow", nil ],
      [ "represent", nil ]
    ]
  }.freeze

  self.custom_relations = {
    "profile" => {
      "friend" =>     { name: "Friend",     permissions: [ [ "create", "activity" ], [ "read", "activity" ], [ "follow", nil ] ], receiver_type: "Profile" },
      "colleague" =>  { name: "Colleague",  permissions: [ [ "read", "activity" ] ],                                                                     receiver_type: "Profile" },
      "acquaintance" => { name: "Acquaintance", permissions: [ [ "read", "activity" ] ],                                                                 receiver_type: "Profile" }
    },
    "group" => {
      "admin" => {
        name: "Admin",
        permissions: [
          [ "create", "activity" ],
          [ "read",   "activity" ],
          [ "update",  "activity" ],
          [ "destroy", "activity" ],
          [ "represent", nil ]
        ],
        receiver_type: "Profile"
      },
      "moderator" => {
        name: "Moderator",
        permissions: [
          [ "create", "activity" ],
          [ "read",   "activity" ],
          [ "update", "activity" ]
        ],
        receiver_type: "Profile"
      },
      "member" => {
        name: "Member",
        permissions: [
          [ "read", "activity" ]
        ],
        receiver_type: "Profile"
      }
    }
  }.freeze

  self.system_relations = {}.freeze
  self.suggested_models = [ :profile ]
end
