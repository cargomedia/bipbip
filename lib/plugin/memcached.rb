module CoppereggAgents

  class Plugin::Memcached < Plugin

    def monitor(server)
      raise 'foo'
      p server
      {:requests => 12}
    end
  end
end
