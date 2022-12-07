# frozen_string_literal: true

module EppoClient
  # The main client singleton
  class Client
    include Singleton
    attr_accessor :config_requestor, :assignment_logger, :poller

    def instance
      Client.instance
    end

    def shutdown
      @poller.stop
    end
  end
end
