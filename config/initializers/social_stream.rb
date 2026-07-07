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
    ],
    "site" => [
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
      "member" =>     { name: "Member",     permissions: [ [ "read", "activity" ] ],                                                                     receiver_type: "Group" },
      "friend" =>     { name: "Friend",     permissions: [ [ "create", "activity" ], [ "read", "activity" ], [ "follow", nil ] ],                       receiver_type: "Profile" },
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
          [ "read", "activity" ],
          [ "create", "activity" ]
        ],
        receiver_type: "Profile"
      }
    },
    "site" => {
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
      "editor" => {
        name: "Editor",
        permissions: [
          [ "create", "activity" ],
          [ "read",   "activity" ],
          [ "update", "activity" ]
        ],
        receiver_type: "Profile"
      },
      "moderator" => {
        name: "Moderator",
        permissions: [
          [ "read",   "activity" ],
          [ "destroy", "activity" ]
        ],
        receiver_type: "Profile"
      },
      "member" => {
        name: "Member",
        permissions: [
          [ "read",   "activity" ],
          [ "create", "activity" ]
        ],
        receiver_type: "Profile"
      },
      "silenced" => {
        name: "Silenced",
        permissions: [
          [ "read", "activity" ]
        ],
        receiver_type: "Profile"
      },
      "banned" => {
        name: "Banned",
        permissions: [],
        receiver_type: "Profile"
      }
    }
  }.freeze

  self.system_relations = {}.freeze
  self.suggested_models = [ :profile ]
end
