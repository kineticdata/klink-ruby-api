require 'kinetic_link'

Kinetic::Link.set_connection(
  "Demo",
  "",
  "209.98.36.43:8081",
  "209.98.36.43"
)

Kinetic::Link::create('KLINK_DefaultFormWithDefaults')

puts Kinetic::Link::entries('KLINK_DefaultFormWithDefaults').inspect