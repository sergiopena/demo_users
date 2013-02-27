class Abiquo::User < Abiquo
	attr_accessor :id
	attr_accessor :link

	def initialize(nick, password, name, surname, email, enterprise_link, role_link, active = true, locale = "en_US")
		link = enterprise_link['href'].to_s.split('/').slice(2,enterprise_link['href'].length).join("/")
		@url = "http://#{@@username}:#{@@password}@#{link}"+"/users"
		@accept = "application/vnd.abiquo.user+xml"
		@content = "application/vnd.abiquo.user+xml"
		@nick = nick
		@password = password
		@name = name
		@surname = surname
		@email = email
		@locale = locale
		@active = active
		@enterprise_link = enterprise_link
		@role_link = role_link
		@id = nil
		@link = nil

		$log.info "Instanciated user #{@nick} of enteprise #{@enterprise_link}"
	end

	def create
		builder = Builder::XmlMarkup.new()
		entity = builder.user do |x|
			x.nick(@nick)
			x.password(@password)
			x.name(@name)
			x.surname(@surname)
			x.email(@email)
			x.locale(@locale)
			x.active(@active)
			x.link(@enterprise_link)
			x.link(@role_link)
		end	
		$log.info "Built user enterprise xml entity #{@nick}"
		$log.debug entity
	
		response = RestClient.post @url, entity, :accept => @accept, :content_type => @content

		if response.code == 201 # Resource created ok
			xml = XmlSimple.xml_in(response)
			$log.debug xml
			self.id = xml['id'][0]
			xml['link'].each { |x| 
				if x["rel"] == 'edit'
					self.link = x
				end
			}
			$log.info "User #{@nick} created #{@link["href"]}"
			$log.debug xml
		end
	end
end




