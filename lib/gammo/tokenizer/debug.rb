module Gammo
  class Tokenizer
    module Debug
      def self.included(base)
        base.extend ClassMethods
      end

      def debug(msg)
        puts msg if @debug
      end

      module ClassMethods
        def method_added(method)
          name = method.to_s
          return if %w[debug _debugged ?].any?(&name.method(:end_with?))
          return unless name.start_with?('scan_')
          return if map[method]
          map[method] = true
          alias_method :"#{name}_debugged", method
          class_eval <<-EOS
            def #{method}
              debug "#{method}, \#{scanner.string[scanner.pos]}"
              #{method}_debugged
            end
          EOS
        end

        def map
          @map ||= {}
        end
      end
    end
  end
end
