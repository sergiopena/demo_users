class Abiquo
	def initialize(server,username,password)
		@@server = server
		@@username = username
		@@password = password
	end
end

require 'lib/enterprise'
require 'lib/virtualappliance'
require 'lib/virtualdatacenter'
require 'lib/roles'
require 'lib/user'