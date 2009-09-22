require 'rubygems'
require 'net/http'
require 'uri'
require 'time'

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
      puts cal_url
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
      return nil unless rawdata
      self.ical = ICal.new(rawdata)
      self.version  = self.ical.hash['VCALENDAR']['VERSION']
      self.scale    = self.ical.hash['VCALENDAR']['CALSCALE']
      self.method   = self.ical.hash['VCALENDAR']['METHOD']
      self.product_id = self.ical.hash['VCALENDAR']['PRODID']
# These aren't needed for my implementations.
# self.time_zone_name = self.ical.hash['VCALENDAR']['VTIMEZONE']['TZID']
# puts "Time Zone: #{self.time_zone_name}"
# self.time_zone_offset = self.ical.hash['VCALENDAR']['VTIMEZONE']['STANDARD']['TZOFFSETTO']
# puts "Time Zone offset: #{self.time_zone_offset}"
      self.ical.hash['VCALENDAR']['VEVENT'] = [self.ical.hash['VCALENDAR']['VEVENT']] unless self.ical.hash['VCALENDAR']['VEVENT'].is_a?(Array)
      self.ical.hash['VCALENDAR']['VEVENT'].each do |e|
        # DTSTART;VALUE=DATE # format of yyyymmdd
        # DTSTART;TZID=America/Chicago # format of yyyymmddThhmmss
        # DTEND;VALUE=DATE # format of yyyymmdd
        # DTEND;TZID=America/Chicago # format of yyyymmddThhmmss
        # DTSTAMP # format of yyyymmddThhmmssZ - today's date and time!
        # TRANSP # disreguard - transparency: opaque
        # LOCATION # location string
        # LAST-MODIFIED # format of yyyymmddThhmmssZ
        # SEQUENCE # integer - not sure what it is
        # UID # characters@google.com - not sure what it's for, but they're all unique
        # CATEGORIES # in gcal, all = 'http'
        # SUMMARY # summary/title string
        # CLASS # in gcal = PUBLIC or PRIVATE?
        # STATUS # in gcal = CONFIRMED
        # ORGANIZER;CN=Moody Campus # in gcal, all = MAILTO
        # CREATED # format of yyyymmddThhmmssZ
        # DESCRIPTION # description string
        # ATTENDEE;CUTYPE=GROUP;ROLE=REQ-PARTICIPANT;PARTSTAT=ACCEPTED;CN=Moody Campu\ns;X-NUM-GUESTS=0 # so far always nil
        # COMMENT;X-COMMENTER=MAILTO # someone's email address, perhaps if they commented on the event.
        # RRULE # Recurrance Rule - string like 'FREQ=WEEKLY'
        if !e.nil?
          tzadjust = Time.gcalschema("#{e["DTSTART;TZID=#{self.time_zone_name}"] || "#{e['DTSTART;VALUE=DATE']}T000000"}Z").nil? ? -4*3600 : 0
          st = (Time.gcalschema("#{e["DTSTART;TZID=#{self.time_zone_name}"] || "#{e['DTSTART;VALUE=DATE']}T000000"}Z") || Time.gcalschema(e['DTSTART'])) + tzadjust
          et = (Time.gcalschema("#{e["DTEND;TZID=#{self.time_zone_name}"] || "#{e['DTEND;VALUE=DATE']}T000000"}Z") || Time.gcalschema(e['DTEND'])) + tzadjust
          # DTSTART;TZID=America/New_York:20070508T070000
          self.add_event(Event.new(
            :start_time => st,
            :end_time => et,
            :location => e['LOCATION'],
            :created_at => Time.gcalschema(e['CREATED']),
            :updated_at => Time.gcalschema(e['LAST-MODIFIED']),
            :summary => e['SUMMARY'],
            :description => e['DESCRIPTION'],
            :recurrance_rule => e['RRULE']
          ), false) # (disable sorting until done)
          @events.reject! {|e| e.start_time.nil?}
          @events.sort! {|a,b| a.start_time <=> b.start_time }
        end
      end
    end
    def parse_from_ical
      self.dup.parse_from_ical
    end

    def source_format
      self.ical ? 'ical' : (self.xml ? 'xml' : nil)
    end

    def future_events
      t = Time.now
      events.inject([]) {|future,e| e.start_time > t ? future.push(e) : future}
    end

    def past_events
      t = Time.now
      events.inject([]) {|past,e| e.start_time < t ? past.push(e) : past}
    end

    def events_in_range(start_time, end_time)
      events.inject([]) {|in_range,e| e.start_time < end_time && e.end_time > start_time ? in_range.push(e) : in_range}
    end

    def calendar_raw_data
      # If you need to use a proxy:
      unless self.proxy_host.nil?
        Net::HTTP::Proxy(self.proxy_host, self.proxy_port,
        self.proxy_user, self.proxy_pass).start('www.google.com', 80) do |http|
          response = http.get(self.url)
          case response
          when Net::HTTPSuccess, Net::HTTPRedirection
            #puts "Data #{data}"
            return response.body 
          else
            response.error!
            return nil
          end
        end
      else
        Net::HTTP.start('www.google.com', 80) do |http|
          response = http.get(self.url)
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

    class Event
      attr_accessor :start_time, :end_time, :location, :created_at, :updated_at, :summary, :description, :recurrance_rule
      def initialize(attributes={})
        attributes.each do |key, value|
          self.send("#{key.to_s}=", value)
        end
      end
    end
  end

  class ICal
    attr_accessor :hash, :raw
    def initialize(ical_data)
      self.raw  = ical_data
      self.hash = self.parse_ical_data(self.raw)
    end

    def parse_ical_data(data)
      data.gsub!(/\\\n/, "\\n")
      data.gsub!(/[\n\r]+ /, "\\n")
      lines = data.split(/[\n\r]+/)
      structure = [{}]
      keys_path = []
      last_is_array = false
      lines.each do |line|
        line.gsub!(/\\n/, "\n")        
        pair = line.split(':')
        name = pair.shift
        value = pair.join(':')
        case name
        when 'BEGIN'  #Begin Section
          if structure[-1].has_key?(value)
            if structure[-1][value].is_a?(Array)
              structure[-1][value].push({})
              last_is_array = true
            else
              structure[-1][value] = [structure[-1][value], {}]
              last_is_array = true
            end
          else
            structure[-1][value] = {}
          end
          keys_path.push(value)
          structure.push({})
        when 'END'    #End Section
          if last_is_array
            structure[-2][keys_path.pop][-1] = structure.pop
            last_is_array = false
          else
            structure[-2][keys_path.pop] = structure.pop
          end
        else          #Within last Section
          structure[-1][name] = value
        end
      end
      structure[0]
    end
  end
end
=begin
include CalendarReader

unless ARGV.length > 0 
   puts "Numero de parametros invalido."
   puts "Uso: ruby gcalcli.rb <url_feed_google_calendar> \n"
   puts "Exemplo: ruby gcalcli.rb /calendar/ical/miguel.horlle%40gmail.com/private-e53bc30e66f953cbw3574yf619b5451/basic.ics \n"
   exit
end

gcal_url = ARGV[0]

g = Calendar.new(gcal_url)
puts "Events length #{g.events.length}"
puts "Events future_events #{g.future_events.length}"
g.events_in_range(Time.now - 432000, Time.now + 500000).collect {|e| puts "Event\n #{e.summary} e Description #{e.description}"}
=end
