class Abiquo::Enterprise < Abiquo
	attr_accessor 	:name
	attr_accessor	:id
	attr_accessor	:link

	def initialize(	enterprise_name = nil,
					enterprise_id = nil,
					cpuHard = 0,
					cpuSoft = 0,
					hdHard = 0,
					hdSoft = 0,
					publicIpsHard = 0,
					publicIpsSoft = 0,
					ramHard = 0,
					ramSoft = 0,
					storageHard = 0,
					storageSoft = 0,
					vlansHard = 0,
					vlansSoft = 0,
					repositoryHard = 0,
					repositorySoft = 0
				)
		@accept = "application/vnd.abiquo.enterprise+xml"
		@content = "application/vnd.abiquo.enterprise+xml"
		@url = "http://#{@@username}:#{@@password}@#{@@server}/api/admin/enterprises/"
		@name = enterprise_name
		@id = enterprise_id
		$log.info "Instanciated enterprise #{@name}"
	end

	def create 
		builder = Builder::XmlMarkup.new()
		entity = builder.enterprise do |x|
			x.name @name 
			if ! @id.nil? 
				x.id @id 
			end
		end	
		#self.post()
#		self.post()
		$log.info "Built enterprise xml entity #{@name}"
		$log.debug entity

		response = RestClient.post @url, entity, :accept => @accept, :content_type => @content

		if response.code == 201 # Resource created ok
			xml = XmlSimple.xml_in(response)
			self.id = xml['id'][0]
			self.link = xml['link'][0]
			self.link['rel'] = "enterprise"
			$log.info "Enterprise created #{self.name} id #{self.id}"
			$log.debug xml
		end
	end

	def allow_datacenter(datacenter_id, cpuHard = 0, cpuSoft = 0, hdHard = 0, hdSoft = 0, publicIpsHard = 0, publicIpsSoft = 0, ramHard = 0, ramSoft = 0, storageHard = 0, storageSoft = 0, vlansHard = 0, vlansSoft = 0, repositoryHard = 0, repositorySoft = 0 )
		builder = Builder::XmlMarkup.new()
		entity = builder.limit do |x|
			x.cpuHard cpuHard
			x.cpuSoft cpuSoft
			x.hdHard hdHard
			x.hdSoft hdSoft
			x.publicIpsHard publicIpsHard
			x.publicIpsSoft publicIpsSoft
			x.ramHard ramHard
			x.ramSoft ramSoft
			x.storageHard storageHard
			x.storageSoft storageSoft
			x.vlansHard vlansSoft
			x.repositoryHard repositoryHard
			x.repositorySoft repositorySoft
		end
		$log.debug "Entity: #{entity}"
		url = @url+self.id+"/limits?datacenter=#{datacenter_id}"
		$log.debug "url #{url}"
		response = RestClient.post( url, entity, 
				:Accept => "application/vnd.abiquo.limit+xml", 
				:Content_type => "application/vnd.abiquo.limit+xml")

		if response.code == 201 # Resource created ok
			xml = XmlSimple.xml_in(response)
			$log.info "Allow datacenter #{datacenter_id} to enterprise #{self.id}"
			$log.debug xml
		end
	end

	def get_link_by_id(id)
		url = @url+id
		response = RestClient.get(url)
		xml = XmlSimple.xml_in(response)	
		$log.debug xml

		if response.code == 200
			xml['link'].each { |x| 
				if x["rel"] == 'edit'
					@link = x
					@id = id
				end
			}
			return @link
		else
			$log.info "Enterprise #{id} not found"
			return nil
		end
	end

	def get_vapps()
		url = @url+id+"/action/virtualappliances"
		response = RestClient.get(url)		
		data = XmlSimple.xml_in(response)
		$log.debug data
		@vapps_links = []
		if not data["virtualAppliance"]
			$log.info "Enteprise with no vApps"
			return nil
		else
			data['virtualAppliance'].each do |vapp|
				vapp['link'].each do |link|
					if link['rel'] == 'edit'
						@vapps_links << link
						$log.debug "Vapp LINK #{link}"
					end
				end
			end
			return @vapps_links
		end
	end

	def persist_enterprise()
		begin
			db = SQLite3::Database.new 'enterprise_demo.db'
			db.execute "CREATE TABLE IF NOT EXISTS enterprise (enterprise_id INTEGER PRIMARY KEY, enterprise_name VARCHAR(40), timestamp DATETIME)"
			db.execute "INSERT INTO enterprise VALUES (#{self.id},'#{self.name}',DATETIME('now'))"
			$log.debug "INSERT INTO enterprise VALUES (#{self.id},'#{self.name}',DATETIME('now'))"

		rescue SQLite3::Exception => e

			puts "Exception occurred persisting enterprise #{self.id}"
			puts e

		ensure
			db.close if db
		end
	end

	def volatilize_enterprise(ent_name)
		begin
			db = SQLite3::Database.new 'enterprise_demo.db'
	 		stm = db.prepare "DELETE FROM enterprise WHERE enterprise_name like '#{ent_name}'";
	    	rs = stm.execute
	    
		rescue SQLite3::Exception => e

			puts "Exception occurred removing persisted enterprise #{ent_name}"
			puts e

		ensure
			stm.close if stm
			db.close if db
		end
	end
	
	def get_expired_enterprises()
		begin

			db = SQLite3::Database.new 'enterprise_demo.db'
#			stm = db.prepare "SELECT enterprise_id FROM enterprise WHERE timestamp < DATETIME('now','-1 hour')"
			stm = db.prepare "SELECT enterprise_name FROM enterprise WHERE timestamp < DATETIME('now','-1 minute');"
			result = stm.execute


			ids_enterprises_to_delete = Array.new

			result.each do |entry|
				$log.debug "Entry to delete found #{entry.to_s}"
				ids_enterprises_to_delete << entry.to_s
			end

			return ids_enterprises_to_delete

		rescue SQLite3::Exception => e

			$log.error "Exception occurred"
			$log.error e

		ensure
			stm.close if stm
			db.close if db
		end
	end

end