module CoppereggAgents

  class Utils

    def self.log(str)
      str.split("\n").each do |line|
        puts "#{Time.now.strftime('%Y/%m/%d %H:%M:%S')}: #{line}"
      end
      $stdout.flush
    end

  end
end
