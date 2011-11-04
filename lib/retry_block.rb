require "retry_block/version"

module Kernel
  def retry_block (opts={}, &block)
    opts = {
      :attempts => nil,        # Number of times to try block. Nil means to retry forever until success
      :sleep => 0,             # Seconds to sleep between attempts
      :catch => Exception,     # An exception or array of exceptions to listen for
      :fail_callback => nil    # Proc/lambda that gets executed between attempts
    }.merge(opts)

    opts[:catch] = [ opts[:catch] ].flatten
    attempts = 1

    if (not opts[:attempts].nil?) and (not opts[:attempts].is_a? Integer or opts[:attempts] <= 0)
      raise ArgumentError, "retry_block: :attempts must be an integer >= 0 or nil"
    end

    begin
      return yield attempts
    rescue *opts[:catch] => exception

      # If a callable object was given for :fail_callback then call it
      if opts[:fail_callback].respond_to? :call
        callback_opts = [attempts, exception].slice(0, opts[:fail_callback].arity)
        opts[:fail_callback].call *callback_opts
      end
      
      # If we've maxed out our attempts, raise the exception to the calling code
      raise if (not opts[:attempts].nil?) and (attempts += 1) > opts[:attempts]

      # Sleep before the next retry if the option was given
      sleep opts[:sleep] if opts[:sleep].is_a? Numeric and opts[:sleep] > 0
      
      retry
    end #rescue
  end # def
end # module
