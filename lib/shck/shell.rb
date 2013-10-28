# -*- coding: utf-8 -*-

module Shck
  # shell related operation
  class Shell
    def self.cmd(config, host, ctx: :tmux)
      hosts = host_list config, host
      cmds = hosts.map do |h|
        "#{h['ssh']} #{h['dst']}"
      end
      cmds.unshift "tmux new-window -n '#{host}'" if ctx == :tmux
      cmds.shift + ' ' + nest_cmd(cmds)
    end

    private

    def self.escape_num(n)
      return 0 if n ==  0
      return 1 if n == 1
      escape_num(n - 1) * 2 + 1
    end

    def self.escaped_dquote(level)
      '\\' * escape_num(level) + '"'
    end

    def self.nest_cmd(list)
      cmd = ''
      list.reverse.each_with_index do |e, idx|
        depth = list.size - idx - 1
        q = escaped_dquote(depth)
        cmd = "#{q}#{e} #{cmd}#{q}"
      end
      cmd
    end

    def self.host_list(config, host)
      list = [host_def(config, host)]
      fail "invalid config for #{host}" unless list.first
      while list.first['from'] != 'localhost'
        list.unshift(host_def(config, list.first['from']))
      end
      list
    end

    def self.host_def(config, host)
      config.definition host
    end
  end
end
