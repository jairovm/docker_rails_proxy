module DockerRailsProxy
  class DataBags < AwsCli
    class Pull < self
      def process
        if system <<-EOS.strip
          aws s3 sync '#{options[:bucket_path]}' '#{options[:folder]}' \
            --delete \
            --exact-timestamps \
            #{exclude_args} \
            --profile '#{options[:profile]}'
        EOS

          puts "Data bags pulled from #{options[:bucket_path]} to #{options[:folder]}"
        end
      end
    end
  end
end
