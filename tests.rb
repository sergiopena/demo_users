#!/usr/bin/ruby

require 'rubygems'
require 'abiquo.rb'
require 'uuid'
require 'rubygems'
require 'builder'
require 'logger'
require 'rest-client'
require 'xmlsimple'
require 'sqlite3'

AbiServer = '10.60.13.5'
AbiUser = 'admin'
AbiPass = 'xabiquo'
IdDatacenter = 1

$log = Logger.new(STDOUT)
$log.level = Logger::INFO
# $log.level = Logger::DEBUG

uuid = UUID.new

abq = Abiquo.new(AbiServer,AbiUser,AbiPass)

#
# Creation tests
#
# Define enterprise
 enterprise = Abiquo::Enterprise.new(uuid.generate)
# Create enterprise API
 enterprise.create

 enterprise.persist_enterprise

# Assign datacenter 1 to enterprise
 enterprise.allow_datacenter(IdDatacenter)

# Instanciate roles object to look for the roles links
roles = Abiquo::Roles.new

# Define user
user = Abiquo::User.new(	enterprise.name+"_user", 'xabiquo','user_name',
							'user_surname','email@email.com',
							enterprise.link, 
							roles.get_link_by_name('USER') )
# Create user
user.create

# Define admin
admin = Abiquo::User.new(	enterprise.name+"_admin", 'xabiquo','admin_name',
							'admin_surname','email@email.com',
							enterprise.link, 
							roles.get_link_by_name('ENTERPRISE_ADMIN') )						
# Create admin
admin.create

vdc = Abiquo::VirtualDatacenter.new(enterprise.link,IdDatacenter)

enterprise.assign_ip(vdc.attach_publicIP)


$log.info "Checking for expired enterprises"
$log.debug enterprise.get_expired_enterprises.inspect
enterprise.get_expired_enterprises.each do |expired|
	$log.info "Trying to delete enterprise #{expired.to_s}"
	cmd = "java -jar tenant-cleanup-jar-with-dependencies.jar http://#{AbiServer}/api #{AbiUser} #{AbiPass} #{expired.to_s}"
    delete_api = `#{cmd}`


    if delete_api.match /Done!/
    	$log.info "Enterprise #{expired.to_s} deleted from Abiquo"
		enterprise.volatilize_enterprise(expired.to_s)
    else
    	$log.error "Enterprise #{expired.to_s} could not be deleted from Abiquo"
    end
end

=begin
	
rescue Exception => e
	
end
#
# Deletion test
#
# Get Enterprise link by id
$log.info "Creating Enterprise dummy object"
target = Abiquo::Enterprise.new
$log.info "Retrieving link for idEnterprise 2"
p target.get_link_by_id('2')
$log.info "Retrieving all Vapps for enterprise 2"
target.get_vapps.each do |x|
	$log.info "Looking state of vapp #{x['href']}"
	vapp = Abiquo::VirtualAppliance.new(x['href'])
	p vapp.get_state
	vapp.delete
end

# Get Vapps of an enterprise
=end
