require 'rubygems'
require 'net/http'
require 'uri'
require 'time'
require 'icalendar'
require 'date'

include Icalendar

class Time
  def self.gcalschema(tzid) # We may not be handling Time Zones in the best way...
     tzid =~ /(\d\d\d\d)(\d\d)(\d\d)T(\d\d)(\d\d)(\d\d)Z/ ? # yyyymmddThhmmss
       # Strange, sometimes it's 4 hours ahead, sometimes 4 hours behind. Need to figure out the timezone piece of ical.
       # Time.xmlschema("#{$1}-#{$2}-#{$3}T#{$4}:#{$5}:#{$6}") - 4*60*60 :
       Time.xmlschema("#{$1}-#{$2}-#{$3}T#{$4}:#{$5}:#{$6}") :
       nil
  end
end

# include CalendarReader
# g = Calendar.new('http://www.google.com/calendar/ical/example%40gmail.com/public/basic.ics')
module CalendarReader
  class Calendar
    attr_accessor :url, :ical, :xml, :product_id, :version, :scale, :method, :time_zone_name, :time_zone_offset, :events,
                  :proxy_host, :proxy_port, :proxy_user, :proxy_pass

    def initialize(cal_url, proxy_host, proxy_port, proxy_user, proxy_pass)
      self.events = []
      unless cal_url.empty?
        self.url = cal_url
        self.proxy_host=proxy_host
        self.proxy_port=proxy_port
        self.proxy_user=proxy_user
        self.proxy_pass=proxy_pass
        self.parse!
      end
    end

    def add_event(event, sortit=true)
      self.events = [] unless self.events.is_a?(Array)
      self.events << event
      @events.sort! {|a,b| a.dtstart <=> b.dtstart } if sortit
      event
    end

    def self.parse(cal_url)
      self.new(cal_url)
    end

    def parse!
      self.url =~ /\.ics(?:\?.+)?$/ ? self.parse_from_ical! : self.parse_from_xml!
    end
    def parse
      self.dup.parse!
    end

    def parse_from_xml!
      return false # THIS IS NOT IMPLEMENTED YET!!
    end
    def parse_from_xml
      self.dup.parse_from_xml!
    end

    def parse_from_ical!
      rawdata = self.calendar_raw_data
      cals = Icalendar.parse(rawdata)
      cal = cals.first

      # Now you can access the cal object in just the same way I created it
      cal.events.each do |event|
        self.add_event(event, false) # (disable sorting until done)
        @events.reject! {|e| e.dtstart.nil?}
        @events.sort! {|a,b| a.dtstart <=> b.dtstart }
      end
    end
    def parse_from_ical
      self.dup.parse_from_ical
    end

    def source_format
      self.ical ? 'ical' : (self.xml ? 'xml' : nil)
    end

    def future_events
      t = DateTime.now
      events.inject([]) {|future,e| e.dtstart > t ? future.push(e) : future}
    end

    def past_events
      t = DateTime.now
      events.inject([]) {|past,e| e.dtstart < t ? past.push(e) : past}
    end

    def events_in_range(start_time, end_time)
      events.inject([]) {|in_range,e| e.dtstart < end_time && e.dtend > start_time ? in_range.push(e) : in_range}
    end

    def calendar_raw_data
      # If you need to use a proxy:
      unless self.proxy_host.nil?
        response = Net::HTTP::Proxy(self.proxy_host, self.proxy_port,
        self.proxy_user, self.proxy_pass).get_response(URI.parse(self.url)) 
        case response
        when Net::HTTPSuccess, Net::HTTPRedirection
          #puts "Data #{data}"
          return response.body 
        else
          response.error!
          return nil
        end
      else
        response = Net::HTTP.get_response(URI.parse(self.url))
        case response
        when Net::HTTPSuccess, Net::HTTPRedirection
          #puts "Data #{data}"
          return response.body
        else
          response.error!
          return nil
        end      
      end
    end

  end

end