class Abiquo::VirtualAppliance < Abiquo
	attr_accessor :url
	attr_accessor :state

	def initialize(url)
		$log.debug "initialize vApps #{url}"
		link = url.to_s.split('/').slice(2,url.length).join("/")
		@url = "http://#{@@username}:#{@@password}@#{link}"
		@state = nil
	end

	def get_state()
		response = RestClient.get(@url)
		xml = XmlSimple.xml_in(response)
		$log.debug "Vapp.getstate #{xml['state']}"
		@state = xml['state']
		return xml['state']
	end

	def delete()
		$log.debug "Trying to delte #{url}"
		self.get_state
		case @state[0]
		when "NOT_DEPLOYED"
			RestClient.delete(@url)
			$log.info "Deleted #{url}"
		when "DEPLOYED"
			$log.info "Vapps is deployed #{url}"
			self.undeploy
			RestClient.delete(@url)

		end
	end

	def undeploy()
		$log.info "Trying to undeploy #{url}"
		builder = Builder::XmlMarkup.new()
		virtualmachinetask = builder.virtualmachinetask { |x| x.forceUndeploy("true")}
		response = RestClient.post( @url+'/action/undeploy', virtualmachinetask, 
				:Accept => "application/vnd.abiquo.acceptedrequest+xml", 
				:Content_type => "application/vnd.abiquo.virtualmachinetask+xml")
		$log.debug response
		xml = XmlSimple.xml_in(response)
		xml['link'].each do |x|
			if x['rel'] == "status"
				while self.check_task(x['href']) == "STARTED" do
					$log.debug "Task #{self.check_task(x['href'])} #{x['href']}"
					sleep 5
				end
			end
		end
	end	

	def check_task(url)
		$log.info "Checking task #{url}"
		link = url.to_s.split('/').slice(2,url.length).join("/")
		task_url = "http://#{@@username}:#{@@password}@#{link}"	
		$log.info "Task returned #{task_url}"
		response = RestClient.get(task_url)
		return XmlSimple.xml_in(response)['state'][0]
	end

end