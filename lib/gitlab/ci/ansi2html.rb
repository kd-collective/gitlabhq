# frozen_string_literal: true

# ANSI color library
#
# Implementation per http://en.wikipedia.org/wiki/ANSI_escape_code
module Gitlab
  module Ci
    module Ansi2html
      # Timestamp line prefix format:
      # <timestamp> <stream number><stream type><full line type>
      # - timestamp: UTC RFC3339 timestamp
      # - stream number: 1 byte (2 hex chars) stream number
      # - stream type: E/O (Err or Out)
      # - full line type: `+` if line is continuation of previous line, ` ` otherwise
      TIMESTAMP_HEADER_REGEX = Gitlab::Ci::Trace::Stream::TIMESTAMP_HEADER_REGEX
      TIMESTAMP_HEADER_DATETIME_LENGTH = Gitlab::Ci::Trace::Stream::TIMESTAMP_HEADER_DATETIME_LENGTH
      TIMESTAMP_HEADER_LENGTH = Gitlab::Ci::Trace::Stream::TIMESTAMP_HEADER_LENGTH

      # keys represent the trailing digit in color changing command (30-37, 40-47, 90-97. 100-107)
      COLOR = {
        0 => 'black', # not that this is gray in the intense color table
        1 => 'red',
        2 => 'green',
        3 => 'yellow',
        4 => 'blue',
        5 => 'magenta',
        6 => 'cyan',
        7 => 'white' # not that this is gray in the dark (aka default) color table
      }.freeze

      STYLE_SWITCHES = {
        bold: 0x01,
        italic: 0x02,
        underline: 0x04,
        conceal: 0x08,
        cross: 0x10
      }.freeze

      def self.convert(ansi, state = nil)
        Converter.new.convert(ansi, state)
      end

      Result = Struct.new(:html, :state, :append, :truncated, :offset, :size, :total, keyword_init: true) # rubocop:disable Lint/StructNewOverride

      class Converter
        include EncodingHelper

        STATE_PARAMS = [:offset, :n_open_tags, :fg_color, :bg_color, :style_mask, :sections, :lineno_in_section].freeze

        def convert(stream, new_state)
          reset_state
          restore_state(new_state, stream) if new_state.present?

          append = false
          truncated = false

          cur_offset = stream.tell
          if cur_offset > @offset
            @offset = cur_offset
            truncated = true
          else
            stream.seek(@offset)
            append = @offset > 0
          end

          start_offset = @offset

          process_stream_with_lookahead(stream)

          Ansi2html::Result.new(
            html: @out.force_encoding(Encoding.default_external),
            state: state,
            append: append,
            truncated: truncated,
            offset: start_offset,
            size: stream.tell - start_offset,
            total: stream.size
          )
        end

        def section_to_class_name(section)
          section.to_s.downcase.gsub(/[^a-z0-9]/, '-')
        end

        private

        attr_accessor :offset, :n_open_tags, :fg_color, :bg_color, :style_mask, :sections, :lineno_in_section

        def process_stream_with_lookahead(stream)
          # We process lines with 1-line look-back, so that we can process line continuations
          previous_line = nil

          stream.each_line do |line|
            line = encode_utf8_no_detect(line)
            handle_line(previous_line, line)
            previous_line = line
          end

          handle_line(previous_line, nil) if previous_line

          close_open_tags
        end

        def handle_line(line, next_line)
          if line.nil?
            # First line, initialize check for timestamps
            @has_timestamps = next_line.match?(TIMESTAMP_HEADER_REGEX)
            return
          end

          is_continued = @has_timestamps && next_line&.at(TIMESTAMP_HEADER_LENGTH - 1) == '+'

          # Continued lines contain an ignored \n character at the end, so we can chop it off
          line.delete_suffix!("\n") if is_continued

          if @current_line_buffer.nil?
            @current_line_buffer = line
          else
            # Ignore timestamp from continued line
            @current_line_buffer << line[TIMESTAMP_HEADER_LENGTH..]
          end

          return if is_continued

          consume_line(@current_line_buffer)
          @current_line_buffer = nil
        end

        def consume_line(line)
          scanner = StringScanner.new(line)
          last_offset = nil
          line_start_offset = @offset

          # Consume tokens until end of string or no more progress
          until scanner.eos? || @offset == last_offset
            last_offset = @offset
            consume_token(scanner, @offset == line_start_offset)
          end
        end

        def consume_token(scanner, at_line_start)
          return if at_line_start && skip_timestamp(scanner) # Avoid regex on timestamps

          if scanner.scan(Gitlab::Regex.build_trace_section_regex)
            handle_section(scanner)
          elsif scanner.scan(/\e([@-_])(.*?)([@-~])/)
            handle_sequence(scanner)
          elsif scanner.scan(/\e(?:[@-_].*?)?$/)
            return
          elsif scanner.scan('<')
            write_in_tag '&lt;'
          elsif scanner.scan(/\r?\n/)
            handle_new_line
          else
            write_in_tag scanner.scan(/./m)
          end

          @offset += scanner.matched_size
        end

        def has_timestamp_prefix?(line)
          # Avoid regex on timestamps for performance
          return unless @has_timestamps && line && line.length >= TIMESTAMP_HEADER_LENGTH

          line[TIMESTAMP_HEADER_DATETIME_LENGTH - 1] == 'Z' &&
            line[4] == '-' && line[7] == '-' && line[10] == 'T' && line[13] == ':'
        end

        def skip_timestamp(scanner)
          return unless @has_timestamps

          line = scanner.peek(TIMESTAMP_HEADER_LENGTH + 1)
          return unless has_timestamp_prefix?(line)

          scanner.pos += TIMESTAMP_HEADER_LENGTH
          @offset += TIMESTAMP_HEADER_LENGTH
        end

        def handle_new_line
          write_in_tag %(<br/>)

          close_open_tags if @sections.any? && @lineno_in_section == 0
          @lineno_in_section += 1
        end

        def handle_section(scanner)
          action = scanner[1]
          timestamp = scanner[2]
          section = scanner[3]

          normalized_section = section_to_class_name(section)

          case action
          when 'start'
            handle_section_start(normalized_section, timestamp)
          when 'end'
            handle_section_end(normalized_section, timestamp)
          end
        end

        def handle_section_start(section, timestamp)
          return if @sections.include?(section)

          @sections << section
          write_raw %(<div class="section-start" data-timestamp="#{timestamp}" data-section="#{data_section_names}" role="button"></div>)
          @lineno_in_section = 0
        end

        def handle_section_end(section, timestamp)
          return unless @sections.include?(section)

          # close all sections up to section
          until @sections.empty?
            write_raw %(<div class="section-end" data-section="#{data_section_names}"></div>)

            last_section = @sections.pop
            break if section == last_section
          end
        end

        def data_section_names
          @sections.join(' ')
        end

        def handle_sequence(scanner)
          indicator = scanner[1]
          terminator = scanner[3]

          # We are only interested in color and text style changes - triggered by
          # sequences starting with '\e[' and ending with 'm'. Any other control
          # sequence gets stripped (including stuff like "delete last line")
          return unless indicator == '[' && terminator == 'm'

          close_open_tags

          commands = scanner[2].split ';'
          if commands.empty?
            reset
            return
          end

          evaluate_command_stack(commands)
        end

        def evaluate_command_stack(stack)
          return unless command = stack.shift

          if self.respond_to?("on_#{command}", true)
            self.__send__("on_#{command}", stack) # rubocop:disable GitlabSecurity/PublicSend
          end

          evaluate_command_stack(stack)
        end

        def write_in_tag(data)
          ensure_open_new_tag
          @out << data
        end

        def write_raw(data)
          close_open_tags
          @out << data
        end

        def ensure_open_new_tag
          open_new_tag if @n_open_tags == 0
        end

        def open_new_tag
          css_classes = []

          unless @fg_color.nil?
            fg_color = @fg_color
            # Most terminals show bold colored text in the light color variant
            # Let's mimic that here
            if @style_mask & STYLE_SWITCHES[:bold] != 0
              fg_color.sub!(/fg-([a-z]{2,}+)/, 'fg-l-\1')
            end

            css_classes << fg_color
          end

          css_classes << @bg_color unless @bg_color.nil?

          STYLE_SWITCHES.each do |css_class, flag|
            css_classes << "term-#{css_class}" if @style_mask & flag != 0
          end

          if @sections.any?
            css_classes << 'section'

            css_classes << if @lineno_in_section == 0
                             'section-header'
                           else
                             'line'
                           end

            css_classes += sections.map { |section| "js-s-#{section}" }
          end

          close_open_tags

          @out << if css_classes.any?
                    %(<span class="#{css_classes.join(' ')}">)
                  else
                    %(<span>)
                  end

          @n_open_tags += 1
        end

        def close_open_tags
          while @n_open_tags > 0
            @out << %(</span>)
            @n_open_tags -= 1
          end
        end

        def reset_state
          @offset = 0
          @n_open_tags = 0
          @out = +''
          @sections = []
          @lineno_in_section = 0
          @current_line_buffer = nil
          @has_timestamps = nil
          reset
        end

        def state
          state = STATE_PARAMS.index_with do |param|
            send(param) # rubocop:disable GitlabSecurity/PublicSend
          end
          Base64.urlsafe_encode64(state.to_json)
        end

        def restore_state(new_state, stream)
          state = Base64.urlsafe_decode64(new_state)
          state = Gitlab::Json.parse(state, symbolize_names: true)
          return if state[:offset].to_i > stream.size

          STATE_PARAMS.each do |param|
            send("#{param}=".to_sym, state[param]) # rubocop:disable GitlabSecurity/PublicSend
          end
        end

        def reset
          @fg_color = nil
          @bg_color = nil
          @style_mask = 0
        end

        def enable(flag)
          @style_mask |= flag
        end

        def disable(flag)
          @style_mask &= ~flag
        end

        def set_fg_color(color_index, prefix = nil)
          @fg_color = get_term_color_class(color_index, ["fg", prefix])
        end

        def set_bg_color(color_index, prefix = nil)
          @bg_color = get_term_color_class(color_index, ["bg", prefix])
        end

        def get_term_color_class(color_index, prefix)
          color_name = COLOR[color_index]
          return if color_name.nil?

          get_color_class(["term", prefix, color_name])
        end

        def set_fg_color_256(command_stack)
          css_class = get_xterm_color_class(command_stack, "fg")
          @fg_color = css_class unless css_class.nil?
        end

        def set_bg_color_256(command_stack)
          css_class = get_xterm_color_class(command_stack, "bg")
          @bg_color = css_class unless css_class.nil?
        end

        def get_xterm_color_class(command_stack, prefix)
          # the 38 and 48 commands have to be followed by "5" and the color index
          return unless command_stack.length >= 2
          return unless command_stack[0] == "5"

          command_stack.shift # ignore the "5" command
          color_index = command_stack.shift.to_i

          return unless color_index >= 0
          return unless color_index <= 255

          get_color_class(["xterm", prefix, color_index])
        end

        def get_color_class(segments)
          [segments].flatten.compact.join('-')
        end

        def on_0(_)
          reset
        end

        def on_1(_)
          enable(STYLE_SWITCHES[:bold])
        end

        def on_3(_)
          enable(STYLE_SWITCHES[:italic])
        end

        def on_4(_)
          enable(STYLE_SWITCHES[:underline])
        end

        def on_8(_)
          enable(STYLE_SWITCHES[:conceal])
        end

        def on_9(_)
          enable(STYLE_SWITCHES[:cross])
        end

        def on_21(_)
          disable(STYLE_SWITCHES[:bold])
        end

        def on_22(_)
          disable(STYLE_SWITCHES[:bold])
        end

        def on_23(_)
          disable(STYLE_SWITCHES[:italic])
        end

        def on_24(_)
          disable(STYLE_SWITCHES[:underline])
        end

        def on_28(_)
          disable(STYLE_SWITCHES[:conceal])
        end

        def on_29(_)
          disable(STYLE_SWITCHES[:cross])
        end

        def on_30(_)
          set_fg_color(0)
        end

        def on_31(_)
          set_fg_color(1)
        end

        def on_32(_)
          set_fg_color(2)
        end

        def on_33(_)
          set_fg_color(3)
        end

        def on_34(_)
          set_fg_color(4)
        end

        def on_35(_)
          set_fg_color(5)
        end

        def on_36(_)
          set_fg_color(6)
        end

        def on_37(_)
          set_fg_color(7)
        end

        def on_38(stack)
          set_fg_color_256(stack)
        end

        def on_39(_)
          set_fg_color(9)
        end

        def on_40(_)
          set_bg_color(0)
        end

        def on_41(_)
          set_bg_color(1)
        end

        def on_42(_)
          set_bg_color(2)
        end

        def on_43(_)
          set_bg_color(3)
        end

        def on_44(_)
          set_bg_color(4)
        end

        def on_45(_)
          set_bg_color(5)
        end

        def on_46(_)
          set_bg_color(6)
        end

        def on_47(_)
          set_bg_color(7)
        end

        def on_48(stack)
          set_bg_color_256(stack)
        end

        def on_49(_)
          set_bg_color(9)
        end

        def on_90(_)
          set_fg_color(0, 'l')
        end

        def on_91(_)
          set_fg_color(1, 'l')
        end

        def on_92(_)
          set_fg_color(2, 'l')
        end

        def on_93(_)
          set_fg_color(3, 'l')
        end

        def on_94(_)
          set_fg_color(4, 'l')
        end

        def on_95(_)
          set_fg_color(5, 'l')
        end

        def on_96(_)
          set_fg_color(6, 'l')
        end

        def on_97(_)
          set_fg_color(7, 'l')
        end

        def on_99(_)
          set_fg_color(9, 'l')
        end

        def on_100(_)
          set_bg_color(0, 'l')
        end

        def on_101(_)
          set_bg_color(1, 'l')
        end

        def on_102(_)
          set_bg_color(2, 'l')
        end

        def on_103(_)
          set_bg_color(3, 'l')
        end

        def on_104(_)
          set_bg_color(4, 'l')
        end

        def on_105(_)
          set_bg_color(5, 'l')
        end

        def on_106(_)
          set_bg_color(6, 'l')
        end

        def on_107(_)
          set_bg_color(7, 'l')
        end

        def on_109(_)
          set_bg_color(9, 'l')
        end
      end
    end
  end
end
