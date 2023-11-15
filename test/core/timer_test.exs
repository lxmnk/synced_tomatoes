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
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4
      } = :sys.get_state(context.pid)
    end

    test "sets :interval_type to :work", context do
      assert %{interval_type: :work} = Timer.get_status(context.pid)
    end

    test "inits :current_work_interval", context do
      assert %{current_work_interval: 1} = Timer.get_status(context.pid)
    end

    test "starts elixir timer with :work_min", context do
      %{time_left_ms: time_left_ms} = Timer.get_status(context.pid)

      assert_in_delta :timer.minutes(25), time_left_ms, 100
    end
  end

  describe "pause before short break" do
    setup do
      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: false
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)

      send(pid, :work_finished)

      %{pid: pid}
    end

    test "sets :interval_type to :short_break", context do
      assert %{interval_type: :short_break} = Timer.get_status(context.pid)
    end

    test "elixir timer is nil", context do
      time_left_ms = :timer.minutes(5)

      %{time_left_ms: ^time_left_ms} = Timer.get_status(context.pid)
    end
  end

  describe "starts short break" do
    setup do
      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)

      send(pid, :work_finished)

      %{pid: pid}
    end

    test "sets :interval_type to :short_break", context do
      assert %{interval_type: :short_break} = Timer.get_status(context.pid)
    end

    test "starts elixir timer with :short_break_min", context do
      %{time_left_ms: time_left_ms} = Timer.get_status(context.pid)

      assert_in_delta :timer.minutes(5), time_left_ms, 100
    end
  end

  describe "pause before long break" do
    setup do
      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: false
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)
      :sys.replace_state(pid, fn state ->
        Map.put(state, :current_work_interval, 4)
      end)

      send(pid, :work_finished)

      %{pid: pid}
    end

    test "sets :interval_type to :long_break", context do
      assert %{interval_type: :long_break} = Timer.get_status(context.pid)
    end

    test "elixir timer is nil", context do
      time_left_ms = :timer.minutes(15)

      %{time_left_ms: ^time_left_ms} = Timer.get_status(context.pid)
    end
  end

  describe "starts long break" do
    setup do
      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)
      :sys.replace_state(pid, fn state ->
        Map.put(state, :current_work_interval, 4)
      end)

      send(pid, :work_finished)

      %{pid: pid}
    end

    test "sets :interval_type to :long_break", context do
      assert %{interval_type: :long_break} = Timer.get_status(context.pid)
    end

    test "starts elixir timer with :long_break_min", context do
      %{time_left_ms: time_left_ms} = Timer.get_status(context.pid)

      assert_in_delta :timer.minutes(15), time_left_ms, 100
    end
  end

  describe "pause after short break" do
    setup do
      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: false
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)
      :sys.replace_state(pid, fn state ->
        Map.put(state, :interval_type, :short_break)
      end)

      send(pid, :short_break_finished)

      %{pid: pid}
    end

    test "sets :interval_type to :work", context do
      assert %{interval_type: :work} = Timer.get_status(context.pid)
    end

    test "elixir timer is nil", context do
      time_left_ms = :timer.minutes(25)

      %{time_left_ms: ^time_left_ms} = Timer.get_status(context.pid)
    end
  end

  describe "start work after short break" do
    setup do
      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)
      :sys.replace_state(pid, fn state ->
        Map.put(state, :interval_type, :short_break)
      end)

      send(pid, :short_break_finished)

      %{pid: pid}
    end

    test "sets :interval_type to :work", context do
      assert %{interval_type: :work} = Timer.get_status(context.pid)
    end

    test "increments :current_work_interval", context do
      assert %{current_work_interval: 2} = Timer.get_status(context.pid)
    end

    test "starts elixir timer with :work_min", context do
      %{time_left_ms: time_left_ms} = Timer.get_status(context.pid)

      assert_in_delta :timer.minutes(25), time_left_ms, 100
    end
  end

  describe "pause after long break" do
    setup do
      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: false
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)
      :sys.replace_state(pid, fn state ->
        Map.put(state, :interval_type, :long_break)
      end)

      send(pid, :long_break_finished)

      %{pid: pid}
    end

    test "sets :interval_type to :work", context do
      assert %{interval_type: :work} = Timer.get_status(context.pid)
    end

    test "elixir timer is nil", context do
      time_left_ms = :timer.minutes(25)

      %{time_left_ms: ^time_left_ms} = Timer.get_status(context.pid)
    end
  end

  describe "start work after long break" do
    setup do
      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)
      :sys.replace_state(pid, fn state ->
        Map.put(state, :interval_type, :long_break)
      end)

      send(pid, :long_break_finished)

      %{pid: pid}
    end

    test "sets :interval_type to :work", context do
      assert %{interval_type: :work} = Timer.get_status(context.pid)
    end

    test "resets :current_work_interval", context do
      assert %{current_work_interval: 1} = Timer.get_status(context.pid)
    end

    test "starts elixir timer with :work_min", context do
      %{time_left_ms: time_left_ms} = Timer.get_status(context.pid)

      assert_in_delta :timer.minutes(25), time_left_ms, 100
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
      %{ticking?: false} = Timer.get_status(context.pid)
    end

    test "saves elixir timer value", context do
      %{time_left_ms: time_left_ms} = Timer.get_status(context.pid)

      assert_in_delta :timer.minutes(25), time_left_ms, 100
    end

    test "cancels elixir timer", context do
      %{timer_ref: nil} = :sys.get_state(context.pid)
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
      :sys.replace_state(pid, fn state ->
        state
        |> Map.put(:ticking?, false)
      end)

      Timer.pause(pid)

      %{pid: pid}
    end

    test "does nothing", context do
      %{ticking?: false} = Timer.get_status(context.pid)
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
      :sys.replace_state(pid, fn state ->
        state
        |> Map.put(:ticking?, false)
        |> Map.put(:saved_timer_value, :timer.minutes(10))
      end)

      Timer.continue(pid)

      %{pid: pid}
    end

    test "makes timer ticking", context do
      %{ticking?: true} = Timer.get_status(context.pid)
    end

    test "starts elixir timer with :saved_timer_value", context do
      %{time_left_ms: time_left_ms} = Timer.get_status(context.pid)

      assert_in_delta :timer.minutes(10), time_left_ms, 100
    end
  end

  describe "continue already running timer" do
    setup do
      opts = [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ]

      {:ok, pid} = GenServer.start_link(Timer, opts)

      Timer.continue(pid)

      %{pid: pid}
    end

    test "does nothing", context do
      %{ticking?: true} = Timer.get_status(context.pid)
    end
  end
end
