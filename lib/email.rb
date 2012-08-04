module Support
  class Email
    attr_accessor :headers, :original

    def initialize(message)
      @original = message
      @headers = []
      parse_headers message
    end

    def to
      @headers.detect {|i| i[:key] =~ /^[Tt]o$/}[:value]
    end

    def to_email
      @headers.detect {|i| i[:key] =~ /^X-Original-To$/}[:value]
    end

    def from
      @headers.detect {|i| i[:key] =~ /^[Ff]rom$/}[:value]
    end

    def subject
      @headers.detect {|i| i[:key] =~ /^[Ss]ubject$/}[:value]
    end

    private
    def strip_out_email(full_email)
      /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i.match full_email
    end

    def parse_headers(message)
      # split message at new lines
      lines = message.split(/\n/)

      # loop over lines and break to key value at ':'
      lines.each do |l|
        # loop until the end of the headers
        # TODO fix this to include multi lineheaders
        break l if l == ""
        unless /^.*:.*$/.match(l) == nil
          header = l.split(/:/)
          @headers << {:key => header[0].strip, :value => header[1].strip}      
        end
      end
    end

    def parse_body(message)
      content_type = @headers.select \
                     {|i| i[:key] =~ /^[Cc]ontent-*[Tt]ype$/}[0][:value]


      if content_type =~ /text\/plain/
        # plain text email only

      elsif content_type =~ /text\/html/
        # html email only

      elsif content_type =~ /multipart\/alternative/
        # has both text and html email

      end
    end
  end
end