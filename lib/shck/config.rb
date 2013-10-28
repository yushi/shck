# -*- coding: utf-8 -*-
require 'yaml'

module Shck
  # config file loader
  class ConfigLoader
    def initialize(path = nil)
      @yml = {}
      load(path) if path
    end

    def load(path)
      @yml = YAML.load_file(path)
    end

    def hosts
      @yml['host'].sort
    end

    def groups
      @yml['group']
    end

    def group_hosts
    end

    def definitions
      @yml['def'].map do |d|
        d['from'] ||= 'localhost'
        d['ssh'] ||= 'ssh -t'
        d
      end
    end

    def definition(host = nil)
      definitions.each do |host_def|
        next unless host.match(host_def['regex'])
        d = host_def.clone
        d['dst'] = host
        d.delete 'regex'
        return d
      end
      nil
    end

    def include?(host)
      hosts.include?(host)
    end
  end
end
