module Locomotive
  module Dragonfly

    def self.resize_url(source, resize_string, url_host = nil)
      if file = self.fetch_file(source)
        # FIXME: dragonfly allows to override the asset_host set in its initializer file.
        # https://github.com/markevans/dragonfly/blob/b681ce2e44139aa7632c5331dc5601530b23d82f/lib/dragonfly/server.rb#L82
        # https://github.com/markevans/dragonfly/blob/master/lib/dragonfly/job.rb#L175
        options = url_host.blank? ? {} : { host: url_host }

        file.thumb(resize_string).url(options)
      else
        Locomotive.log :error, "Unable to resize on the fly: #{source.inspect}"
        return
      end
    end

    def self.thumbnail_pdf(source, resize_string)
      if file = self.fetch_file(source)
        file.thumb(resize_string, format: 'png', frame: 0).encode('png').url
      else
        Locomotive.log :error, "Unable to convert the pdf: #{source.inspect}"
        return
      end
    end

    def self.fetch_file(source)
      file = nil

      if source.is_a?(String) || source.is_a?(Hash) # simple string or theme asset
        source = source['url'] if source.is_a?(Hash)

        clean_source!(source)

        if source =~ /^http/
          file = self.app.fetch_url(source)
        else
          file = self.app.fetch_file(File.join('public', source))
        end

      elsif source.respond_to?(:url) # carrierwave uploader
        if source.file.respond_to?(:url)
          file = self.app.fetch_url(source.url) # amazon s3, cloud files, ...etc
        else
          file = self.app.fetch_file(source.path)
        end

      end

      file
    end

    def self.app
      ::Dragonfly.app
    end

    protected

    def self.clean_source!(source)
      # remove the leading / trailing whitespaces
      source.strip!

      # remove the query part (usually, timestamp) if local file
      source.sub!(/(\?.*)$/, '') unless source =~ /^http/
    end

  end
end
