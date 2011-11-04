require 'test/unit'
require 'lib/retry_block'

class TestRetryBlock < Test::Unit::TestCase
  def setup
    @fail_count = 0
    @run_count = 0
    @fail_callback = lambda do
      @fail_count += 1
    end
  end

  def test_runs_block_once
    assert_nothing_raised do
      retry_block(:fail_callback => @fail_callback) do
        @run_count += 1
      end
    end
    assert_equal 1, @run_count
    assert_equal 0, @fail_count
  end

  def test_runs_block_twice
    assert_nothing_raised do
      retry_block(:attempts => 2, :fail_callback => @fail_callback) do
        @run_count += 1
        raise TestException if @run_count == 1
      end
    end
    assert_equal 2, @run_count
    assert_equal 1, @fail_count
  end

  def test_runs_block_twice_and_fails
    assert_raises(TestException) do
      retry_block(:attempts => 2, :fail_callback => @fail_callback) do
        @run_count += 1
        raise TestException
      end
    end
    assert_equal 2, @run_count
    assert_equal 2, @fail_count
  end

  def test_raises_unexpected_exception1
    assert_raises(RuntimeError) do
      retry_block(:attempts => 2, :catch => TestException, :fail_callback => @fail_callback) do
        @run_count += 1
        raise RuntimeError
      end
    end
    assert_equal 1, @run_count
    assert_equal 0, @fail_count
  end

  def test_raises_unexpected_exception2
    assert_raises(RuntimeError) do
      retry_block(:attempts => 2, :catch => [TestException], :fail_callback => @fail_callback) do
        @run_count += 1
        raise RuntimeError
      end
    end
    assert_equal 1, @run_count
    assert_equal 0, @fail_count
  end

  def test_catches_exception1
    assert_nothing_raised do
      retry_block(:attempts => 2, :catch => TestException, :fail_callback => @fail_callback) do
        @run_count += 1
        raise TestException unless @run_count == 2
      end
    end
    assert_equal 2, @run_count
    assert_equal 1, @fail_count
  end

  def test_catches_multiple_exception
    assert_nothing_raised do
      retry_block(:attempts => 3, :catch => [TestException, RuntimeError], :fail_callback => @fail_callback) do
        @run_count += 1
        raise TestException if @run_count == 1
        raise RuntimeError if @run_count == 2
      end
    end
    assert_equal 3, @run_count
    assert_equal 2, @fail_count
  end

  def test_doesnt_catch_unexpected_exception_from_list
    assert_raises(Exception) do
      retry_block(:attempts => 4, :catch => [TestException, RuntimeError], :fail_callback => @fail_callback) do
        @run_count += 1
        raise TestException if @run_count == 1
        raise RuntimeError if @run_count == 2
        raise Exception if @run_count == 3
      end
    end
    assert_equal 3, @run_count
    assert_equal 2, @fail_count
  end

  def test_fails_on_bad_argument1
    assert_raises(ArgumentError) do
      retry_block(:attempts => -1, :fail_callback => @fail_callback) do
        @run_count += 1
      end
    end
    assert_equal 0, @run_count
    assert_equal 0, @fail_count
  end

  def test_fails_on_bad_argument2
    assert_raises(ArgumentError) do
      retry_block(:attempts => 0.4, :fail_callback => @fail_callback) do
        @run_count += 1
      end
    end
    assert_equal 0, @run_count
    assert_equal 0, @fail_count
  end

  def test_sleeps
    sleep_time = 0.1     # Sleep for 1/10 of a second
    attempts = 3
    # Doesn't sleep after last failure
    total_sleep_time = (attempts-1) * sleep_time
    begin_time = Time.new
    assert_raises(TestException) do
      retry_block(:attempts => attempts, :fail_callback => @fail_callback, :sleep => sleep_time) do
        @run_count += 1
        raise TestException
      end
    end
    end_time = Time.new
    time_elapsed = end_time - begin_time
    assert_equal attempts, @run_count
    assert_equal attempts, @fail_count
    # Things are never exact.  Expect that time_elapsed in seconds to be
    # equal to total_sleep_time plus or minus 5%
    assert_in_delta total_sleep_time, time_elapsed, total_sleep_time*0.05
  end

  def test_doesnt_sleep
    begin_time = Time.new
    assert_raises(TestException) do
      retry_block(:attempts => 1, :fail_callback => @fail_callback, :sleep => 0.1) do
        @run_count += 1
        raise TestException
      end
    end
    end_time = Time.new
    time_elapsed = end_time - begin_time
    assert_equal 1, @run_count
    assert_equal 1, @fail_count
    # plus or minus 1/100 of a second ;)
    assert_in_delta 0.0, time_elapsed, 0.01
  end

  def test_runs_forever
    assert_raises(RuntimeError) do
      retry_block(:attempts => nil, :catch => TestException, :fail_callback => @fail_callback) do
        @run_count += 1
        raise TestException unless @run_count == 100
        raise RuntimeError
      end
    end
    assert_equal 100, @run_count
    assert_equal 99, @fail_count
  end
end

class TestException < Exception
end
