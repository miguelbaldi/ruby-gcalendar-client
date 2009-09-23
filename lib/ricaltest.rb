require 'rubygems'
require 'net/http'
require 'uri'
require 'ri_cal'
require 'tzinfo'

url='http://www.google.com/calendar/ical/miguel.horlle%40gmail.com/private-9562d0b3d7d34a0987adee46ce8175ff/basic.ics'
# Net::HTTP::Proxy(proxy_host, proxy_port, proxy_user, proxy_pass).start('www.google.com', 80) do |http|
response = Net::HTTP.get_response(URI.parse(url))
case response
when Net::HTTPSuccess, Net::HTTPRedirection
  #puts "Data #{response.body}"
  puts "Request successful!"
else
  response.error!
end

# Parser returns an array of calendars because a single file
# can have multiple calendars.
#puts data
cals = RiCal.parse_string(response.body)
cal = cals.first
puts "There are #{cals.size} calendars"

# Now you can access the cal object in just the same way I created it
cal.default_tzid="America/Sao_Paulo"
puts "Calendar TZ #{cal.default_tzid}"
puts "Event class #{cal.events.first.class}"
#puts "Event methods #{cal.events.first.public_methods.sort.each {|m| puts m}}"
cal.events.each do |event|
  #p event.public_methods.sort
  unless event.occurrences({:count => 10}).size > 1
    puts "summary: " + event.summary
    puts "\tstart: " + event.start_time.strftime("%d/%m/%Y %I:%M%p")
  else
    event.occurrences({:count => 10}).each do |ev|  
      puts "summary: " + ev.summary
      puts "\tstart: " + ev.start_time.strftime("%d/%m/%Y %I:%M%p")
    end
  end
end