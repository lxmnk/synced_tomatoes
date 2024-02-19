defmodule Test.Core.TimerTest do
  use ExUnit.Case

  alias SyncedTomatoes.Core.Timer

  describe "start new timer" do
    setup do
      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)

      %{pid: pid}
    end

    test "saves init opts", context do
      assert %{
        interval_min: %{
          work: 25,
          short_break: 5,
          long_break: 15
        },
        work_intervals_count: 4
      } = :sys.get_state(context.pid)
    end

    test "inits timer", context do
      assert %{
        interval_type: :work,
        current_work_interval: 1,
        timer_ref: timer_ref
      } = :sys.get_state(context.pid)

      assert_in_delta :timer.minutes(25), Process.read_timer(timer_ref), 100
    end
  end

  describe "start new timer with overriden interval " do
    setup do
      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true,
        interval_type: :long_break,
        current_work_interval: 2,
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)

      %{pid: pid}
    end

    test "inits timer", context do
      assert %{
        interval_type: :long_break,
        current_work_interval: 2,
        timer_ref: timer_ref
      } = :sys.get_state(context.pid)

      assert_in_delta :timer.minutes(15), Process.read_timer(timer_ref), 100
    end
  end

  describe "start new timer with overriden time left" do
    setup do
      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true,
        time_left_ms: :timer.minutes(5)
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)

      %{pid: pid}
    end

    test "inits timer", context do
      assert %{
        interval_type: :work,
        current_work_interval: 1,
        timer_ref: timer_ref
      } = :sys.get_state(context.pid)

      assert_in_delta :timer.minutes(5), Process.read_timer(timer_ref), 100
    end
  end

  describe "starts short break" do
    setup do
      test_pid = self()

      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: false,
        notify_fun: fn message -> send(test_pid, message) end
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)

      send(pid, :work_finished)

      %{pid: pid}
    end

    test "updates timer", context do
      time_left_ms = :timer.minutes(5)

      assert %{
        interval_type: :short_break,
        current_work_interval: 1,
        saved_timer_value: ^time_left_ms
      } = :sys.get_state(context.pid)
    end

    test "notifies passed pid" do
      assert_receive :work_finished
    end
  end

  describe "starts short break with auto_next" do
    setup do
      test_pid = self()

      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true,
        notify_fun: fn message -> send(test_pid, message) end
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)

      send(pid, :work_finished)

      %{pid: pid}
    end

    test "updates timer", context do
      assert %{
        interval_type: :short_break,
        current_work_interval: 1,
        timer_ref: timer_ref
      } = :sys.get_state(context.pid)

      assert_in_delta :timer.minutes(5), Process.read_timer(timer_ref), 100
    end

    test "notifies passed pid" do
      assert_receive :work_finished
    end
  end

  describe "starts long break" do
    setup do
      test_pid = self()

      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: false,
        notify_fun: fn message -> send(test_pid, message) end
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)
      :sys.replace_state(pid, fn state ->
        Map.put(state, :current_work_interval, 4)
      end)

      send(pid, :work_finished)

      %{pid: pid}
    end

    test "updates timer", context do
      time_left_ms = :timer.minutes(15)

      assert %{
        interval_type: :long_break,
        current_work_interval: 4,
        saved_timer_value: ^time_left_ms
      } = :sys.get_state(context.pid)
    end

    test "notifies passed pid" do
      assert_receive :work_finished
    end
  end

  describe "starts long break with auto_next" do
    setup do
      test_pid = self()

      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true,
        notify_fun: fn message -> send(test_pid, message) end
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)
      :sys.replace_state(pid, fn state ->
        Map.put(state, :current_work_interval, 4)
      end)

      send(pid, :work_finished)

      %{pid: pid}
    end

    test "updates timer", context do
      assert %{
        interval_type: :long_break,
        current_work_interval: 4,
        timer_ref: timer_ref
      } = :sys.get_state(context.pid)

      assert_in_delta :timer.minutes(15), Process.read_timer(timer_ref), 100
    end

    test "notifies passed pid" do
      assert_receive :work_finished
    end
  end

  describe "starts work after short break" do
    setup do
      test_pid = self()

      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: false,
        notify_fun: fn message -> send(test_pid, message) end
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)
      :sys.replace_state(pid, fn state ->
        Map.put(state, :interval_type, :short_break)
      end)

      send(pid, :short_break_finished)

      %{pid: pid}
    end

    test "updates timer", context do
      time_left_ms = :timer.minutes(25)

      assert %{
        interval_type: :work,
        current_work_interval: 2,
        saved_timer_value: ^time_left_ms
      } = :sys.get_state(context.pid)
    end

    test "notifies passed pid" do
      assert_receive :short_break_finished
    end
  end

  describe "start work after short break with auto_next" do
    setup do
      test_pid = self()

      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true,
        notify_fun: fn message -> send(test_pid, message) end
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)
      :sys.replace_state(pid, fn state ->
        Map.put(state, :interval_type, :short_break)
      end)

      send(pid, :short_break_finished)

      %{pid: pid}
    end

    test "updates timer", context do
      assert %{
        interval_type: :work,
        current_work_interval: 2,
        timer_ref: timer_ref
      } = :sys.get_state(context.pid)

      assert_in_delta :timer.minutes(25), Process.read_timer(timer_ref), 100
    end

    test "notifies passed pid" do
      assert_receive :short_break_finished
    end
  end

  describe "starts work after long break" do
    setup do
      test_pid = self()

      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: false,
        notify_fun: fn message -> send(test_pid, message) end
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)
      :sys.replace_state(pid, fn state ->
        Map.put(state, :interval_type, :long_break)
      end)

      send(pid, :long_break_finished)

      %{pid: pid}
    end

    test "updates timer", context do
      time_left_ms = :timer.minutes(25)

      assert %{
        interval_type: :work,
        current_work_interval: 1,
        saved_timer_value: ^time_left_ms
      } = :sys.get_state(context.pid)
    end

    test "notifies passed pid" do
      assert_receive :long_break_finished
    end
  end

  describe "start work after long break with auto_next" do
    setup do
      test_pid = self()

      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true,
        notify_fun: fn message -> send(test_pid, message) end
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)
      :sys.replace_state(pid, fn state ->
        Map.put(state, :interval_type, :long_break)
      end)

      send(pid, :long_break_finished)

      %{pid: pid}
    end

    test "updates timer", context do
      assert %{
        interval_type: :work,
        current_work_interval: 1,
        timer_ref: timer_ref
      } = :sys.get_state(context.pid)

      assert_in_delta :timer.minutes(25), Process.read_timer(timer_ref), 100
    end

    test "notifies passed pid" do
      assert_receive :long_break_finished
    end
  end

  describe "pause timer" do
    setup do
      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)

      Timer.pause(pid)

      %{pid: pid}
    end

    test "makes timer paused", context do
      %{
        ticking?: false,
        timer_ref: nil,
        saved_timer_value: saved_timer_value
      } = :sys.get_state(context.pid)

      assert_in_delta :timer.minutes(25), saved_timer_value, 100
    end
  end

  describe "pause already paused timer" do
    setup do
      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)
      pause_timer(pid)

      result = Timer.pause(pid)

      %{result: result, pid: pid}
    end

    test "returns error", context do
      assert {:error, :already_paused} = context.result
    end

    test "does nothing", context do
      assert %{ticking?: false} = :sys.get_state(context.pid)
    end
  end

  describe "continue timer" do
    setup do
      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)
      pause_timer(pid)

      Timer.continue(pid)

      %{pid: pid}
    end

    test "continues timer", context do
      assert %{
        ticking?: true,
        interval_type: :work,
        timer_ref: timer_ref
      } = :sys.get_state(context.pid)

      assert_in_delta :timer.minutes(25), Process.read_timer(timer_ref), 100
    end
  end

  describe "continue timer in short break" do
    setup do
      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        interval_type: :short_break,
        auto_next: true
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)
      pause_timer(pid)

      Timer.continue(pid)

      %{pid: pid}
    end

    test "continues timer", context do
      assert %{
        ticking?: true,
        interval_type: :short_break,
        timer_ref: timer_ref
      } = :sys.get_state(context.pid)

      assert_in_delta :timer.minutes(5), Process.read_timer(timer_ref), 100
    end
  end

  describe "continue already ticking timer" do
    setup do
      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)

      result = Timer.continue(pid)

      %{result: result, pid: pid}
    end

    test "returns error", context do
      assert {:error, :already_ticking} = context.result
    end

    test "does nothing", context do
      assert %{ticking?: true} = :sys.get_state(context.pid)
    end
  end

  describe "ticking timer status" do
    setup do
      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)

      %{pid: pid}
    end

    test "returns status", context do
      assert %{
        ticking?: true,
        interval_type: :work,
        time_left_ms: time_left_ms,
        current_work_interval: 1,
      } = Timer.get_status(context.pid)

      assert_in_delta :timer.minutes(25), time_left_ms, 100
    end
  end

  describe "paused timer status" do
    setup do
      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)
      pause_timer(pid)

      %{pid: pid}
    end

    test "returns status", context do
      assert %{
        ticking?: false,
        interval_type: :work,
        time_left_ms: time_left_ms,
        current_work_interval: 1,
      } = Timer.get_status(context.pid)

      assert_in_delta :timer.minutes(25), time_left_ms, 100
    end
  end

  describe "sync timer" do
    setup do
      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)
      pause_timer(pid)

      sync_data = %{
        interval_type: :short_break,
        current_work_interval: 2,
        time_left_ms: 1
      }
      Timer.sync(pid, sync_data)

      %{pid: pid}
    end

    test "updates timer", context do
      assert %{
        ticking?: false,
        interval_type: :short_break,
        current_work_interval: 2,
        saved_timer_value: 1
      } = :sys.get_state(context.pid)
    end
  end

  describe "sync ticking timer" do
    setup do
      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)

      sync_data = %{
        interval_type: :short_break,
        current_work_interval: 2,
        time_left_ms: 1
      }
      result = Timer.sync(pid, sync_data)

      %{result: result}
    end

    test "return error", context do
      assert {:error, :timer_ticking} = context.result
    end
  end

  defp pause_timer(pid) do
    :sys.replace_state(pid, fn %{timer_ref: timer_ref} = state ->
      saved_timer_value = Process.cancel_timer(timer_ref)

      state
      |> Map.put(:ticking?, false)
      |> Map.put(:timer_ref, nil)
      |> Map.put(:saved_timer_value, saved_timer_value)
    end)
  end
end
