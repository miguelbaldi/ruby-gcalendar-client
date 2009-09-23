require 'rubygems'
require 'net/http'
require 'uri'
require 'time'
require 'ri_cal'
require "tzinfo"

# include CalendarReader
# g = Calendar.new('http://www.google.com/calendar/ical/example%40gmail.com/public/basic.ics')
module GCalendarReader
  class Core
    attr_accessor :url, :ical, :xml, :product_id, :version, :scale, :method, :time_zone_name, :time_zone_offset, :events,
                  :proxy_host, :proxy_port, :proxy_user, :proxy_pass, :limit_date

    def initialize(cal_url, proxy_host, proxy_port, proxy_user, proxy_pass, nro_dias)
      self.events = []
      unless cal_url.empty?
        self.url = cal_url
        self.proxy_host=proxy_host
        self.proxy_port=proxy_port
        self.proxy_user=proxy_user
        self.proxy_pass=proxy_pass
        self.limit_date=Time.now + nro_dias
        self.parse!
      end
    end

    def add_event(event, sortit=true)
      self.events = [] unless self.events.is_a?(Array)
      self.events << event
      @events.sort! {|a,b| a.start_time <=> b.start_time } if sortit
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
      cals = RiCal.parse_string(rawdata)
      cal = cals.first
      cal.events.each do |event|
        unless event.occurrences({:before => self.limit_date}).size > 1
          self.add_event(event, false) # (disable sorting until done)
        else
          event.occurrences({:before => self.limit_date}).each do |ev|  
            self.add_event(ev, false) # (disable sorting until done)
          end
        end
      end
      @events.reject! {|e| e.start_time.nil?}
      @events.sort! {|a,b| a.start_time <=> b.start_time }
    end
    def parse_from_ical
      self.dup.parse_from_ical
    end

    def source_format
      self.ical ? 'ical' : (self.xml ? 'xml' : nil)
    end

    def future_events
      t = DateTime.now
      events.inject([]) {|future,e| e.start_time > t ? future.push(e) : future}
    end

    def past_events
      t = DateTime.now
      events.inject([]) {|past,e| e.start_time < t ? past.push(e) : past}
    end

    def events_in_range(start_time, end_time)
      events.inject([]) {|in_range,e| e.start_time < end_time && e.finish_time > start_time ? in_range.push(e) : in_range}
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