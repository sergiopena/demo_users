#!/usr/bin/ruby
#
# Author: Sergio Pena
#
#
# Script to create demo enterprise on Abiquo 2.3
#
# * Prerequisites
# - A datacenter with kinton id configured on this file must exist on Abiquo
# - A public IP network must be created on Abiquo.
#
# * Funtions
# - It will create an enterprise with
# -- User "enterprisename_user"
# -- Enterprise admin "enteprisename_admin"
# -- One defaultVDC
# -- It will purchase one public IP to the default VDC
# -- Persist enterprise name, public IP consumed and creation date into sqlite database
#
# - When called to purge old enteprise
# -- It will delete all enterprise orlder than especified parameter
#
# 


require 'rubygems'
require 'abiquo.rb'
require 'uuid'
require 'rubygems'
require 'builder'
require 'logger'
require 'rest-client'
require 'xmlsimple'
require 'sqlite3'
require 'getoptlong'
require 'taulukko'


#
# Configuration options
#########################################################
AbiServer = '10.60.13.5'
AbiUser = 'admin'
AbiPass = 'xabiquo'
IdDatacenter = 1

$log = Logger.new(STDOUT)
$log.level = Logger::INFO
# $log.level = Logger::DEBUG


#########################################################
#            DO NOT EDIT BEHIND THIS LINE
#########################################################

def create_enterprise(name)
	abq = Abiquo.new(AbiServer,AbiUser,AbiPass)
	# Define enterprise
	enterprise = Abiquo::Enterprise.new(name)

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
end

def list_all_enterprises
	abq = Abiquo.new(AbiServer,AbiUser,AbiPass)
	# Define enterprise
	enterprise = Abiquo::Enterprise.new
	enterprise.get_all_enterprises
end

def list_active_enterprises
	abq = Abiquo.new(AbiServer,AbiUser,AbiPass)
	# Define enterprise
	enterprise = Abiquo::Enterprise.new
	enterprise.get_active_enterprises
end


def print_help
	puts "Manage demo enterprises"
	puts "\t-c --create enterprise_name\t\t\tGenerates a new enterprise"
	puts "\t-a --all\t\t\t\tPrint historic of all created enterprises"
	puts "\t-l --list\t\t\t\tList active enterprises"
	puts "\t-p --purge\t\t\t\tPurge all expired enterprises"
	puts "\t-h --help\t\t\t\tDisplays this menu"
end
 
def purge_enterprises
	abq = Abiquo.new(AbiServer,AbiUser,AbiPass)
	enterprise = Abiquo::Enterprise.new('x')
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
end

opts = GetoptLong.new(
	[ '--help', '-h', GetoptLong::NO_ARGUMENT ],
	[ '--create', '-c', GetoptLong::REQUIRED_ARGUMENT ],
	[ '--all', '-a', GetoptLong::NO_ARGUMENT ],
	[ '--list', '-l', GetoptLong::NO_ARGUMENT ],
	[ '--purge', '-p', GetoptLong::NO_ARGUMENT ]
)

opts.each do |opt, arg|
	case opt
		when '--create'
			create_enterprise(arg.to_s)
		when '--all'
			list_all_enterprises
	 	when '--list'
			list_active_enterprises
		when '--purge'
			purge_enterprises
		when '--help'
			print_help()
	end
end






