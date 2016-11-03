require 'rack/mime'
require 'open-uri'
require 'fileutils'
require 'active_support/core_ext/hash/indifferent_access'

module MiddlemanHeadless
  class Interface
    attr_reader :options
    attr_accessor :builder

    def initialize(options, extension)
      @options = options
      @extension = extension
      @cache = {}

      @client = OAuth2::Client.new(
        @options.app_key,
        @options.app_secret,
        site: @options.address,
        token_url: '/auth/token',
        ssl: {
          verify: @options.verify
        }
      )

      @access_token = @client.client_credentials.get_token scope: ''
    end

    def space
      @space ||= Space.new(get("space/#{@options.space}").with_indifferent_access, self)
    end

    def entries(content_type)
      content_type = content_type[:slug] if content_type.is_a?(Hash)
      path = "entries/#{@options.space}/#{content_type}"
      @cache[content_type.to_sym] ||= get(path).map do |item|
        Entry.new(item.with_indifferent_access, self)
      end
    end

    def entry(content_type, id)
      entries(content_type).find do |item|
        item.id == id
      end
    end

    def token
      @access_token.token
    end

    def app
      @extension.app
    end

    def link_asset(id, urlopts)
      urlopts[:access_token] = token
      image_url = "#{options.address}/content/file/#{@options.space}/#{id}?#{urlopts.to_query}"

      return image_url

      # return image_url unless app.build?
      #
      # absolute_dir = File.join(app.root, app.config[:build_dir], app.config[:images_dir])
      # FileUtils.mkdir_p absolute_dir
      #
      # file_name = id
      #
      # open(image_url) do |f|
      #   file_name += Rack::Mime::MIME_TYPES.invert[f.content_type]
      #   file = File.join(absolute_dir, file_name)
      #
      #   File.open(file, 'wb') do |ff|
      #     ff.puts f.read
      #   end
      #
      #   puts "  downloaded  build/images/#{file_name}"
      # end
      #
      # # prevent file from being deleted by middleman
      # @builder.instance_variable_get(:@to_clean).reject! do |item|
      #   item.to_s == "build/images/#{file_name}"
      # end
      #
      # puts @builder.instance_variable_get(:@to_clean).inspect
      #
      # file_name
    end

    def method_missing(key)
      entries(key.to_s)
    end

    protected

    def get(path)
      path = "/content/#{path.to_s}"
      path = "#{path}?preview=enabled" if @options.preview
      JSON.parse(@access_token.get(path).body)
    end
  end

  class Item
    def initialize(data, interface)
      @data = data
      @interface = interface
    end

    def method_missing(key)
      @data[key]
    end
  end

  class Space < Item
    def content_types
      @data[:content_types].map do |item|
        Item.new(item, @interface)
      end
    end

    def languages
      @data[:languages].map do |item|
        Item.new(item, @interface)
      end
    end
  end

  class Entry
    def initialize(data, interface)
      @data = data
      @interface = interface
    end

    def id
      @data[:id]
    end

    def name
      @data[:name]
    end

    def version(key)
      Version.new(@data[:versions][key], @interface)
    end

    def field(key)
      version(I18n.locale).field(key)
    end

    def asset(key)
      Asset.new(field(key), @interface)
    end

    def assets(key)
      field(key).map do |value|
        Asset.new(value, @interface)
      end
    end

    def reference(key, type=nil)
      type = key if type.nil?
      Reference.new(type, field(key), @interface)
    end

    def references(key, type=nil)
      type = key if type.nil?
      field(key).map do |value|
        Reference.new(type, value, @interface)
      end
    end

    def method_missing(key)
      field(key)
    end
  end

  class Version
    def initialize(data, interface)
      @data = data
      @interface = interface
    end

    def field(key)
      @data[:fields][key]
    end

    def updated_at
      @data[:updated_at]
    end

    def published_at
      @data[:published_at]
    end

    def method_missing(key)
      field(key)
    end
  end

  class Asset
    def initialize(id, interface)
      @id = id
      @interface = interface
    end

    def url(options={})
      return @interface.link_asset(@id, options)
    end
  end

  class Reference
    def initialize(type, id, interface)
      @type = type
      @id = id
      @interface = interface
    end

    def entry
      @interface.entry(@type, @id)
    end

    def method_missing(*args)
      entry.send(*args)
    end
  end
end
