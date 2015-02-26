module Agents
  class KeywordAgent < Agent
    cannot_be_scheduled!

    VALID_COMPARISON_TYPES = %w[regex !regex field<value field<=value field==value field!=value field>=value field>value]

    description <<-MD
      Use a KeywordAgent to watch for a list of keywords in an Event payload.

      The `keywords` array contains a list of keywords

      The agent will look in the `title`, `body`, `message` and `description` elements of a message    
    MD

    event_description <<-MD
      Events look like this:

          { "message": "Your message" }
    MD

    def validate_options
     unless options['keywords'].present?
	errors.add(:base, "add at least one keyword")
    end
   end

    def default_options
      {
        'expected_receive_period_in_days' => "2",
        'keywords' => [
                      'space',
                      'spacex',
		      'nasa',
		      'ruby'
                    ],
      }
    end

    def working?
      last_receive_at && last_receive_at > interpolated['expected_receive_period_in_days'].to_i.days.ago && !recent_error_logs?
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        opts = interpolated(event)
	text = ''
	['content','title',  'description', 'body', 'message'].each do |field|
		text += event.payload[field].downcase unless event.payload[field] == nil
	end
        match = opts['keywords'].inject(false) do |memory, keyword|
	  memory |= text =~ /[^0-9a-z]#{keyword}[^0-9a-z]/
        end
        if match
	  payload = event.payload.dup
          create_event :payload => payload
        end
      end
    end
  end
end
