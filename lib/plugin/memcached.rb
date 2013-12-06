module CoppereggAgents

  class Plugin::Memcached < Plugin

    def monitor(server)
      p server
      {:requests => 12}
    end
  end
end
