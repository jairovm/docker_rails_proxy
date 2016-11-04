module DockerRailsProxy
  class Stack < AwsCli
    class Destroy < self
      attr_accessor :stacks

      before_process do
        jq_command = <<-EOS
          .Stacks
          | map(
            select(
              .StackStatus | inside("CREATE_COMPLETE UPDATE_COMPLETE")
            )
          | .StackName
          )
          | sort[]
        EOS

        self.stacks = %x(
          aws cloudformation describe-stacks --profile '#{options[:profile]}' \
          | jq '#{jq_command}' | xargs
        ).strip.split(' ')

        if stacks.empty?
          $stderr.puts 'There are no stacks running'
          exit 1
        end
      end

      def process
        begin
          print_options(stacks, 'Choose the stack number and press [ENTER]')
          stack_name = get_option(stacks)
        end while stack_name.blank?

        puts "You're about to destroy this stack: #{stack_name}, are you sure? [yes]:"
        exit unless $stdin.gets.chomp == 'yes'

        puts "Destroying #{stack_name} stack"

        system <<-EOS
          aws cloudformation delete-stack \
            --stack-name '#{stack_name}' \
            --profile '#{options[:profile]}'
        EOS
      end
    end
  end
end
