class Abiquo::Roles < Abiquo
	def initialize
		@url = "http://#{@@username}:#{@@password}@#{@@server}/api/admin/roles/"
		@link
	end
	def get_link_by_name(role_name)
		url = @url+"?has='role_name'"
		response = RestClient.get(@url)
		xml = XmlSimple.xml_in(response)
		$log.debug xml
		xml['role'].each do |r|
			if ( r['name'][0] == role_name )
				link = r['link'][0]
				link['rel'] = 'role'
				return link
			end
		end
	end
end