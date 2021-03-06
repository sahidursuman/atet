module PaymentGateway
  # Assume payment gateway is up until we find it isn't. Because classes are
  # reloaded every request in development, it creates a race condition where
  # PaymentGateway.available? may be nil in the request. Because classes are
  # cached in test and also eager loaded in production this shouldn't be a problem
  # in those environments, but it's annoying in development
  @available = true
  MUTEX ||= Mutex.new
  logger = Rails.logger
  logger.info "Initialised PaymentGateway logger"

  TASK ||= PeriodicTask.new(every: 5.seconds, run_immediately: !Rails.env.test?) do
    begin
      result = HTTParty.get ENV.fetch('PAYMENT_GATEWAY_PING_ENDPOINT')
      MUTEX.synchronize do
        if result.success? != @available
          logger.info "PaymentGateway: State change from old #{@available} to #{result.success?}"
        end
        # leaving this outside of the 'if' because when changed the tests break
        @available = result.success?
      end
    rescue SystemCallError => e
      logger.error err_message(e)
      MUTEX.synchronize do
        @available = false
      end
    end
  end

  def available?
    MUTEX.synchronize { @available }
  end

  delegate :run, :stop, to: :TASK

  private

  def err_message(error)
    <<-EOS
      PaymentGateway: SystemCallError - #{error.class} #{error.message}
      #{error.backtrace.join("\n    ")}
      PaymentGateway: SystemCallError - gateway now unavailable (#{error.message})
    EOS
  end

  module_function :available?, :run, :stop, :err_message
end
