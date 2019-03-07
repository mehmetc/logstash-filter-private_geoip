# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# The Private GeoIP filter add information about local private IP addresses
# This is a CIDR filter on steroids


class LogStash::Filters::PrivateGeoIP < LogStash::Filters::Base
  config_name "private_geoip"

  #The field that that has the IP address to compare
  config :source, validate: :string, required: true

  #The path to the JSON file. "data" can contain any key/value pair
  #[
  # {
  #   "cidr":"10.32.1.0/24",
  #   "data": {
  #     "organization_name": "MyOrganization or Description",
  #     "city_name": "Leuven",
  #     "country_name": "Belgium",
  #     "country_code2": "BE",
  #     "country_code3": "BEL",
  #     "continent_code": "Europe/Brussels"
  #   }
  # }
  #]
  config :database, validate: :string, required: true

  #contains the target object. it is by default private_geoip but you could change it to geoip
  config :target, validate: :string, default: "private_geoip"

  #if a geoip object exists on the event should it be merged and thus overwritten
  config :merge, validate: :boolean, default: true

  public
  def register
    require 'ip'
    require 'json'

    @cidrs = {}
    JSON.parse(File.read(@database)).each do |entry|
      @cidrs.store(IP::CIDR.new(entry['cidr']), entry['data'])
    end

  rescue Exception => e
    raise "Error registering filter: #{e.message}"
  end

  public
  def filter(event)
    ip = IP::Address::Util.string_to_ip(event.get(@source))

    matched_cidr_data = {}

    @cidrs.each do |cidr, data|
      if cidr.includes?(ip)
        matched_cidr_data = data
        break
      end
    end

    return if matched_cidr_data.nil? || matched_cidr_data.empty?

    geo_data = event.get(@target).nil? ? {} : event.get(@target)

    if @merge
      geo_data.merge!(matched_cidr_data)
      geo_data['ip'] = event.get(@source)
    else
      add_keys = matched_cidr_data.keys - geo_data.keys
      geo_data.merge!(matched_cidr_data.select{|k,v| add_keys.include?(k)})
    end

    event.set(@target, geo_data)

    filter_matched(event)
  end
end
