# logstash-filter-private_geoip

Extends or overwrites the GeoIP event data. If you have a large network with _mixed_ calls from **public** and **private** 
IP address the **private** IP addresses are NOT resolved by GeoIP.
   
If you supply the different local networks they will get mapped.
   
## Filter definition   
```json
    filter {
        private_geoip {
            source => "client_ip"
            database => "/path/to/network_file.json"
            target => 'geoip'
            merge => false
        }
    }
```  

* source: field that contains the ip address that needs to be mapped. This can be http_clientip, http_x_forwarded_for or ...
* database: location of the the JSON mapping file.
* target: where should the mapping result be stored. default = private_geoip but you could change it to geoip
* merge: should the target be overwritten with the mapping result. default = true
  
## Mapping definition
```JSON
    [
        {"cidr":"10.33.104.0/22",
         "data":{"organization_name":"XYZ Faculty",
                 "city_name":"Leuven",
                 "country_name":"Belgium",
                 ...
                }
        },
        ...
    ]
``` 
 
 * cidr: contains the network 
 * data: can contain any key/value pair. If you want to extend/overwrite GeoIP take those fields ...
   
   
# Install
   
```sh
   bin/plugin install /your/local/plugin/logstash-filter-private_geoip.gem
```   

Restart LogStash.