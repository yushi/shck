# -*- coding: utf-8 -*-
# -*- condig: utf-8 -*-
require 'curses'

module Shck
  # curses based cui class
  class CUI
    def initialize(config, mode: :tmux)
      @config = config
      @input = ''
      @pos = 0
      @mode = mode
      @selected = nil
    end

    def run
      init_draw
      main_loop
    end

    private

    def main_loop
      loop do
        draw
        process_input
      end
    end

    def init_draw
      Curses.init_screen
      Curses.start_color
      Curses.init_pair(1, Curses::COLOR_BLUE, Curses::COLOR_WHITE)
      Curses.init_pair(2, Curses::COLOR_RED, Curses::COLOR_WHITE)
      Curses.init_pair(3, Curses::COLOR_WHITE, Curses::COLOR_GREEN)
      Curses.init_pair(3, Curses::COLOR_WHITE, Curses::COLOR_BLACK)
      Curses.stdscr.keypad(true)
      Curses.ESCDELAY = 0

    end

    def draw
      Curses.clear
      Curses.use_default_colors
      draw_hosts
      draw_border
      draw_mode
      draw_input
      Curses.doupdate
    end

    def draw_hosts
      y = 2
      host_list = hosts(@input)
      @selected = nil unless host_list.include?(@selected)
      host_list.each do |host|
        if @selected == host and @mode == :shell
          draw_selected_host([y, 0], host)
        else
          draw_host([y, 0], host)
        end
        y += 1
      end
    end

    def draw_selected_host(pos, host)
      Curses.setpos(pos[0], pos[1])
      Curses.attron(Curses.color_pair(3) | Curses::A_NORMAL) do
        Curses.addstr(host)
      end
    end

    def draw_host(pos, host)
      Curses.setpos(pos[0], pos[1])
      m = host.match(@input)
      Curses.addstr(m.pre_match)
      Curses.attron(Curses.color_pair(2) | Curses::A_NORMAL) do
        Curses.addstr(m[0])
      end
      Curses.addstr(m.post_match)
    end

    def draw_border
      Curses.setpos(1, 0)
      Curses.addstr('-' * Curses.cols)
    end

    def draw_input
      Curses.setpos(0, 0)
      Curses.addstr(@input)
      @pos = @input.size  if @pos > @input.size
      @pos = 0 if @pos < 0
      pos = @pos
      Curses.setpos(0, pos)
    end

    def draw_mode
      c = Curses::COLOR_RED
      Curses.attron(Curses.color_pair(c) | Curses::A_NORMAL)
      Curses.setpos(Curses.lines - 1, 0)
      Curses.addstr(@mode.to_s)
      Curses.attroff(Curses.color_pair(c) | Curses::A_NORMAL)
    end

    def process_input
      i = Curses.getch
      case i
      when String then process_input_str i
      when Fixnum then process_input_fixnum i
      end
    end

    def process_input_str(i)
      @input.insert(@pos, i)
      @pos += 1
    end

    def process_input_fixnum(i)
      case i
      when Curses::KEY_CTRL_A then @pos = 0
      when Curses::KEY_CTRL_E then @pos = @input.size
      when Curses::KEY_CTRL_B then @pos -= 1
      when Curses::KEY_CTRL_F then @pos += 1
      when Curses::KEY_LEFT then @pos -= 1
      when Curses::KEY_RIGHT then @pos += 1
      when Curses::KEY_CTRL_D then @input.slice!(@pos)
      when Curses::KEY_CTRL_K then @input.slice!(@pos..-1)
      when Curses::KEY_DOWN then select_down
      when Curses::KEY_UP then select_up
      when Curses::KEY_CTRL_N then select_down
      when Curses::KEY_CTRL_P then select_up
      when Curses::KEY_CTRL_I then switch_mode # TAB
      when 27 then quit # ESC
      when KEY_CTRL_J then do_open # ENTER
      when 127, Curses::KEY_CTRL_H, KEY_BACKSPACE # BS
        @pos -= 1
        @input.slice!(@pos)
      end
    end

    def switch_mode
      case @mode
      when :shell
        @mode = :tmux
        @selected = nil
      when :tmux then @mode = :shell
      end
    end

    def select_up
      return unless @mode == :shell
      list = hosts(@input)
      return @selected = list[0] unless @selected
      list.each_with_index do |host, idx|
        next unless host == @selected
        @selected = list[idx - 1]
        return
      end
    end

    def select_down
      return unless @mode == :shell
      list = hosts(@input)
      return @selected = list[0] unless @selected
      list.each_with_index do |host, idx|
        next unless host == @selected
        @selected = list[idx + 1]
        return
      end
    end

    def quit
      Curses.close_screen
      exit
    end

    def hosts(q)
      @config.hosts.select do |host|
        host.match(q)
      end
    rescue RegexpError
      []
    end

    def do_open
      case @mode
      when :tmux
        do_open_tmux
      when :shell
        do_open_shell
      end
    end

    def do_open_tmux
      hosts(@input).each do |host|
        fork do
          exec Shell.cmd(@config, host, ctx: :tmux)
        end
      end
    end

    def do_open_shell
      host_list = [@selected]
      host_list = hosts(@input) unless @selected

      host_list.each do |host|
        pid = fork do
          Curses.close_screen
          `reset`
          exec Shell.cmd(@config, host, ctx: :shell)
        end
        Process.waitpid pid
      end
      exit
    end
  end
end
