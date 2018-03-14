# frozen_string_literal: true

class Settings < ActiveRecord::Base
  class << self
    def method_missing(name, *args, &block)
      if name == :[]
        settings.data[args.first.to_s]
      elsif name == :[]=
        data = settings.data
        data[args.first.to_s] = args.second
        settings.update data: data
      else
        super
      end
    end

    private

    def respond_to_missing?(name, include_private = false)
      (name.to_s =~ /^\[\]=?$/) || super
    end

    def settings
      last || create!(data: { editing_enabled: true })
    end
  end
end
