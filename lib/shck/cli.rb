# -*- coding: utf-8 -*-
require 'optparse'
require 'yaml'

module Shck
  # command line interface
  class CLI

    def initialize
      @options = {}
      @options[:cui_mode] = :tmux
    end

    def run(args = ARGV)
      parse_option
      yml = YAML.load_file(File.expand_path('~/.shck.yml'))
      config = ConfigLoader.new(yml)

      case @options[:mode]
      when 'h'
        num = ARGV.shift
        if num
          select_host config, num
        else
          list_hosts config
        end
      when 'g'
        num = ARGV.shift
        if num
          select_group config, num
        else
          list_groups config
        end
      when 'inspect' then inspect_host config, args.shift
      else
        cui = CUI.new(config, mode: @options[:cui_mode])
        cui.run
      end
    end

    private

    def list_hosts(config)
      config.hosts.each_with_index do |host, idx|
        puts "#{idx + 1} #{host}"
      end
    end

    def list_groups(config)
      config.groups.each_with_index do |group, idx|
        puts "#{idx + 1} #{group['name']}"
      end
    end

    def inspect_host(config, host)
      puts Shell.cmd(config, host)
    end

    def select_host(config, num)
      host = config.hosts[num.to_i - 1]
      fork do
        exec Shell.cmd(config, host)
      end
    end

    def select_group(config, num)
      group = config.groups[num.to_i - 1]
      hosts = config.hosts.select do |host|
        host.match(group['regex'])
      end

      hosts.each do |host|
        fork do
          exec Shell.cmd(config, host)
        end
      end
    end

    def parse_option
      opt = OptionParser.new
      opt.on('-t') { |v| @options[:cui_mode] = :tmux }
      opt.on('-s') { |v| @options[:cui_mode] = :shell }
      opt.parse!(ARGV)
      @options[:mode] =  ARGV.shift
    end
  end
end
