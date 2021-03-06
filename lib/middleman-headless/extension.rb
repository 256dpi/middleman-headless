require 'middleman-core'

require 'middleman-headless/interface'

module MiddlemanHeadless
  class Extension < ::Middleman::Extension
    option :address, 'https://0.0.0.0:4000', 'The Headless address'
    option :app_key, nil, 'The applications key used for authentication'
    option :app_secret, nil, 'The applications secret used for authentication"'
    option :verify, true, 'Certificates are verified by default'
    option :space, nil, 'The space to be used'
    option :preview, false, 'Enable preview mode'
    option :cache, false, 'Enable caching. You need to restart the middleman to get updated content.'
    option :download_assets, false, 'Download assets and replace links during a build.'
    option :assets_dir, 'assets', 'The directory to place downloaded assets in.'
    option :process_exts, %w(.html .json), 'The extension of files to process for downloadable assets.'
    option :assets_hash_length, 8, 'The length of the appended hash key to the asset filenames.'

    expose_to_config :headless
    expose_to_template :headless

    def initialize(app, options_hash={}, &block)
      super
      require 'oauth2'

      app.before do
        extensions[:headless].clear unless app.build?
      end
    end

    def headless
      if options.app_key.blank? or options.app_secret.blank? or options.address.blank?
        raise 'missing app_key, app_secret or address'
      end

      @interface ||= Interface.new(options, app.build?)
    end

    def clear
      @interface = nil unless options.cache
    end

    def after_build(builder)
      download_assets(builder) if options[:download_assets] and app.build?
    end

    def download_assets(builder)
      downloads = {}
      builder.thor.say 'Downloading headless assets...'

      Middleman::Util.all_files_under(app.config[:build_dir]).each do |file|
        next unless options[:process_exts].include?(File.extname(file))

        content = File.binread(file.expand_path)

        content.gsub! /hldl:\/\/([A-z0-9=]+)\// do
          data = JSON.parse(Base64.urlsafe_decode64($1))
          hash = Digest::SHA1.hexdigest(data['addr'])[0..options[:assets_hash_length]]
          id = "#{data['name']}-#{hash}.#{data['ext']}"
          downloads[id] = data['addr']
          "/#{options[:assets_dir]}/#{id}"
        end

        File.open(file.expand_path, 'wb') { |f| f.write(content) }
        builder.thor.say_status :processed, file
      end

      downloads.each do |id, url|
        dest = Pathname(app.config[:build_dir]).join(options[:assets_dir], id)
        builder.thor.get url, dest, verbose: false
        builder.thor.say_status :downloaded, dest
      end
    end
  end
end
