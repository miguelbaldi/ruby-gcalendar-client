include CalendarReader
g = Calendar.new('http://www.google.com/calendar/ical/miguel.horlle%40gmail.com/private-e53bc30e66f953cb535747f6d19b5451/basic.ics')
g.events.length
g.future_events.length
g.events_in_range(5.days.ago, 5.days.from_now).collect {|e| e.summary}
