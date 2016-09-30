module DockerRailsProxy
  module Callbacks
    INHERITABLE_CALLBACKS = %w(
      _before_initialize
      _after_initialize
      _validates
      _before_process
      _after_process
    ).freeze

    UNINHERITABLE_CALLBACKS = %w(
      _builds
    ).freeze

    def self.included(base)
      base.extend(ClassMethods)

      INHERITABLE_CALLBACKS.each do |callback|
        base.inheritable_attributes callback.to_sym
        base.send "#{callback}=", []
      end

      UNINHERITABLE_CALLBACKS.each do |callback|
        base.uninheritable_attributes callback.to_sym
      end
    end

    module ClassMethods
    private

      INHERITABLE_CALLBACKS.each do |type|
        define_method(type.sub('_', '').to_sym) do |*callbacks, &block|
          _add_callbacks type: type, callbacks: callbacks, &block
        end
      end

      UNINHERITABLE_CALLBACKS.each do |type|
        define_method(type.sub('_', '').to_sym) do |*callbacks, &block|
          send("#{type}=", []) if send(type).nil?
          _add_callbacks type: type, callbacks: callbacks, &block
        end
      end

      def _add_callbacks(type:, callbacks:, &block)
        callbacks.each { |c| send(type) << _make_lambda(callback: c) }
        send(type) << _make_lambda(callback: block) if block_given?
        send type
      end

      def _make_lambda(callback:)
        case callback
        when Symbol
          -> (resource, *rest) { resource.send(callback, *rest) }
        when ::Proc
          if callback.arity <= 0
            -> (resource) { resource.instance_exec(&callback) }
          else
            -> (resource, *rest) do
              if rest.empty?
                resource.instance_exec(resource, &callback)
              else
                resource.instance_exec(*rest, &callback)
              end
            end
          end
        else
          -> (*) {}
        end
      end

      def _run_before_initialize_callbacks
        Array(_before_initialize).each do |callback|
          if (result = callback.call(self)).is_a? String
            $stderr.puts %(
              #{result}
            )
            exit 1
          end
        end
      end

      def _run_after_initialize_callbacks(resource:)
        Array(_after_initialize).each { |c| c.call(resource) }
      end

      def _run_validation_callbacks(resource:)
        Array(_validates).each do |callback|
          if (result = callback.call(resource)).is_a? String
            $stderr.puts %(
              #{result}
            )
            exit 1
          end
        end
      end

      def _run_before_process_callbacks(resource:)
        Array(_before_process).each { |c| c.call(resource) }
      end

      def _run_after_process_callbacks(resource:)
        Array(_after_process).each { |c| c.call(resource) }
      end

      def _run_build_callbacks(params:)
        Array(_builds).each do |callback|
          result = callback.call(self, params: params)
          return result if result.is_a?(Class)
        end

        self
      end
    end
  end
end
