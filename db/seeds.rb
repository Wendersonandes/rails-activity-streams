puts "Seeding Social Stream core..."

permissions = Permission.instances([
  [ :create, :activity ],
  [ :read,   :activity ],
  [ :update, :activity ],
  [ :destroy, :activity ],
  [ :follow, nil ],
  [ :represent, nil ]
])
puts "  Permissions: #{permissions.size} created"

public_rel = Relation::Public.instance
puts "  Relation::Public: id=#{public_rel.id} permissions=#{public_rel.permissions.count}"

follow_rel = Relation::Follow.instance
puts "  Relation::Follow: id=#{follow_rel.id} permissions=#{follow_rel.permissions.count}"

reject_rel = Relation::Reject.instance
puts "  Relation::Reject: id=#{reject_rel.id}"

puts "Seeding complete."
