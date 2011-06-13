require 'chronic_duration'
require 'ri_cal'
require 'chronic'

class Events

  # Takes the target iCal url as an argument
  def initialize(ical_url)
    @ical_url = ical_url
    
    start_refresh_thread(600)
  end

  # Creates a thread to refresh iCal data
  def start_refresh_thread(refresh_interval = 600)
    # Grab calendar synchronously first so it is set if we get called
    @calendar_cache = RiCal.parse(open(@ical_url))

    @refresh_thread ||= Thread.new do 
      while true
        puts "#{refresh_interval} seconds until next calendar refresh"
        sleep refresh_interval
        puts "Refreshing calendar cache"
        @calendar_cache = RiCal.parse(open(@ical_url))
      end
    end
  end

  # Return the next iCal event after the current time
  def next_event(keyword = nil)
    nearest_event = nil
    nearest_seconds_until = nil
    @calendar_cache.first.events.each do |event|
      # Grab the next occurrence for the event
      event = (event.occurrences({:starting => DateTime.now, :count => 1})).first

      if event and event.start_time > DateTime.now
        seconds_until = ((event.start_time - DateTime.now) * 24 * 60 * 60).to_i
        if keyword and event.summary.strip.downcase.include? keyword.downcase
          if !nearest_seconds_until
            nearest_seconds_until = seconds_until
            nearest_event = event
          elsif seconds_until < nearest_seconds_until
            nearest_seconds_until = seconds_until
            nearest_event = event
          end
        elsif !keyword
          if !nearest_seconds_until
            nearest_seconds_until = seconds_until
            nearest_event = event
          elsif seconds_until < nearest_seconds_until
            nearest_seconds_until = seconds_until
            nearest_event = event
          end
        end
      end
    end
    
    nearest_event
  end

  # Return an array of iCal events for today onward
  def upcoming_events
    upcoming_events = []

    @calendar_cache.first.events.each do |event|
      # Grab the next occurrence for the event
      event = (event.occurrences({:starting => Date.today, :count => 1})).first

      if event
        skip = false
        upcoming_events.reject do |e|
          if e.uid == event.uid 
            if e.last_modified < event.last_modified
              # Remove old event if same UID and older modified time
              true
            else
              # Don't add the new event because it was modified longer ago than current
              skip = true
            end
          else
            false
          end
        end

        upcoming_events << event if not skip
      end
    end
    upcoming_events
  end



end
