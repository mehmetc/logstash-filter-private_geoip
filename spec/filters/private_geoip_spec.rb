# encoding: utf-8

require "logstash/devutils/rspec/spec_helper"
require "logstash/filters/private_geoip"
require 'pp'

DATABASE = "spec/resources/cidr.json"

describe LogStash::Filters::PrivateGeoIP do
  describe "does find match" do
    config <<-CONFIG
      filter {
        private_geoip {
          source => "ip"
          database => "#{DATABASE}"
        }
      }
    CONFIG

    sample("ip" => "10.33.108.120") do
      insist {subject}.include?("private_geoip")
      insist {subject["private_geoip"]["organization_name"]}.eql?("centrale bibliotheek")
    end
  end

  describe "does not find match" do
    config <<-CONFIG
      filter {
        private_geoip {
          source => "ip"
          database => "#{DATABASE}"
        }
      }
    CONFIG

    sample("ip" => "10.33.101.120") do
      reject {subject}.include?("private_geoip")

    end
  end

  describe "target = geoip instead of private_geoip" do
    config <<-CONFIG
      filter {
        private_geoip {
          source => "ip"
          database => "#{DATABASE}"
          target => "geoip"
        }
      }
    CONFIG


    sample("ip" => "10.33.108.120") do
      insist {subject}.include?("geoip")
      reject {subject}.include?("private_geoip")
    end
  end

  describe "do merge with overwrite" do
    config <<-CONFIG
      filter {
        private_geoip {
          source => "client_ip"
          database => "#{DATABASE}"
          target => "geoip"
        }
      }
    CONFIG

    sample_data = {
        "client_ip" => "10.33.108.120",
        "geoip" => {
          "ip" => "134.58.179.35",
          "country_code2" => "BE",
          "country_code3" => "BEL",
          "country_name" => "Belgium",
          "continent_code" => "EU",
          "region_name" => "12",
          "city_name" => "Leuven",
          "postal_code" => "3000",
          "latitude" => 50.88329999999999,
          "longitude" => 4.699999999999989,
          "timezone" => "Europe/Brussels",
          "real_region_name" => "Vlaams-Brabant",
          "location" => [
              4.699999999999989,
              50.88329999999999
          ]
        }
    }


    sample(sample_data) do
      #insist {subject}.include?("geoip")
      insist {subject.get("geoip")["city_name"]} == "KULASSOC"
    end
  end

  describe "do merge NO overwrite" do
    config <<-CONFIG
      filter {
        private_geoip {
          source => "client_ip"
          database => "#{DATABASE}"
          target => "geoip"
          merge => false
        }
      }
    CONFIG

    sample_data = {
        "client_ip" => "10.33.108.120",
        "geoip" => {
            "ip" => "134.58.179.35",
            "country_code2" => "BE",
            "country_code3" => "BEL",
            "country_name" => "Belgium",
            "continent_code" => "EU",
            "region_name" => "12",
            "city_name" => "Leuven",
            "postal_code" => "3000",
            "latitude" => 50.88329999999999,
            "longitude" => 4.699999999999989,
            "timezone" => "Europe/Brussels",
            "real_region_name" => "Vlaams-Brabant",
            "location" => [
                4.699999999999989,
                50.88329999999999
            ]
        }
    }

    sample(sample_data) do
      insist {subject}.include?("geoip")
      reject {subject}.include?("private_geoip")
      insist {subject.get("geoip")["city_name"]} == "Leuven"
    end
  end


end
