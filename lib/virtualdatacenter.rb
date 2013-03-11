class Abiquo::VirtualDatacenter < Abiquo
	attr_accessor :url
	attr_accessor :state
	attr_accessor :editlink
	attr_accessor :topurchaselink

	def initialize(	enterpriselink, iddatacenter )
		@accept = "application/vnd.abiquo.virtualdatacenter+xml"
		@content = "application/vnd.abiquo.virtualdatacenter+xml"
		@url = "http://#{@@username}:#{@@password}@#{@@server}/api/cloud/virtualdatacenters"
		$log.info "Instanciated virtualdatacenter for enterprise #{enterpriselink}"

		builder = Builder::XmlMarkup.new()
		entity = builder.virtualDatacenter  do |x|
			x.link(enterpriselink)
			x.link(:rel => "datacenter", :href => "http://#{@@server}/api/admin/datacenters/#{iddatacenter}") 
			x.hypervisorType("KVM")
			x.name("Default VDC")
			x.network {
				x.address("192.168.1.0")
				x.gateway("192.168.1.1")
				x.mask("24")
				x.name("DefaultNetwork")
				x.type("INTERNAL")
				x.unmanaged("false")
			}
		end

		$log.debug @url
		$log.debug entity
		response = RestClient.post @url, entity, :accept => @accept, :content_type => @content

		if response.code == 201 # Resource created ok
			xml = XmlSimple.xml_in(response)
			$log.debug xml
			xml['link'].each { |x| 
				if x["rel"] == 'topurchase'
					self.topurchaselink = x
				end
				if x["rel"] == 'edit'
					self.editlink = x
				end
			}
			$log.info "Default VirtualDatacenter created OK"
			$log.error self.editlink
		end
	end

	def attach_publicIP()

		temp_url = self.topurchaselink['href'].split('/')
		temp_url[2] = "#{@@username}:#{@@password}@#{@@server}"
		$log.info "Getting available Public IP to purchase"

		response = RestClient.get temp_url.join('/')

		@purchased_ip = 0

		if response.code == 200 # IP List retrieved ok

			xml = XmlSimple.xml_in(response)
			xml['publicip'].each { |x|

				break if @purchased_ip == 1

				if x['available'][0] == 'true'
					x['link'].each { |y|
						if y['rel'] == "purchase"

							temp_url = y['href'].split('/')
							temp_url[2] = "#{@@username}:#{@@password}@#{@@server}"

							$log.debug y['href']

							response_purchase = RestClient.put temp_url.join('/'), nil
							$log.error response_purchase.inspect

							if response_purchase.code == 200 # Public IP purchased ok
								$log.info "Attached public IP #{x['ip'][0]} to the virtualdatacenter"
								@purchased_ip = 1
								return x['ip'][0]
							end
						end
					}
				end
			}

		end
#		$log.error response.inspect


	end

end