module DockerRailsProxy
  class DataBags < AwsCli
    class Push < self

      after_initialize do
        if File.exist?(options[:summary_path])
          self.local_summary = File.read(options[:summary_path])
        end
      end

      validates do
        unless local_summary == bucket_summary
          %{
            It seems that someone else pushed something to #{options[:bucket_path]}.
            Use `bin/#{APP_NAME} data-bags pull` to sync the data-bags.

            P.S. Your changes will be discarded.
          }
        end
      end

      def process
        if system <<-EOS
          aws s3 sync '#{options[:folder]}' '#{options[:bucket_path]}' \
            --delete \
            --exact-timestamps \
            #{exclude_args} \
            --profile '#{options[:profile]}' \
            --sse aws:kms
        EOS

          puts "Data bags pushed from #{options[:folder]} to #{options[:bucket_path]}"
        end
      end
    end
  end
end
