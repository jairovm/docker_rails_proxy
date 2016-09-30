module DockerRailsProxy
  module InheritableAttributes
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def inheritable_attributes(*args)
        @inheritable_attributes ||= [:inheritable_attributes]
        @inheritable_attributes += args
        args.each do |arg|
          class_eval %(class << self; attr_accessor :#{arg} end)
        end
        @inheritable_attributes
      end

      def uninheritable_attributes(*args)
        @uninheritable_attributes ||= [:uninheritable_attributes]
        @uninheritable_attributes += args
        args.each do |arg|
          class_eval %(class << self; attr_accessor :#{arg} end)
        end
        @uninheritable_attributes
      end

      def inherited(subclass)
        @inheritable_attributes.each do |inheritable_attribute|
          instance_name  = "@#{inheritable_attribute}"
          instance_value = instance_variable_get(instance_name).dup
          subclass.instance_variable_set(instance_name, instance_value)
        end

        @uninheritable_attributes.each do |uninheritable_attribute|
          instance_name = "@#{uninheritable_attribute}"

          if instance_name == '@uninheritable_attributes'
            instance_value = instance_variable_get(instance_name).dup
            subclass.instance_variable_set(instance_name, instance_value)
          else
            subclass.instance_variable_set(instance_name, nil)
          end
        end
      end
    end
  end
end
