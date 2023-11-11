defmodule Test.Core.TimerManagerTest do
  use ExUnit.Case

  alias SyncedTomatoes.Core.{Timer, TimerManager}

  setup do
    start_supervised!(TimerManager, restart: :temporary)

    %{
      timer_settings: [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4
      ],
      user_id: 1
    }
  end

  test "starts timer", context do
    assert :ok = TimerManager.start_timer(context.user_id, context.timer_settings)

    assert [_, _] = Supervisor.which_children(TimerManager)

    assert TimerManager.get_timer(context.user_id)
  end

  describe "with started timer" do
    setup context do
      opts = Keyword.put(
        context.timer_settings,
        :name,
        {:via, Registry, {:timer_registry, context.user_id}}
      )

      spec = %{
        id: {Timer, context.user_id},
        start: {Timer, :start_link, [opts]}
      }

      {:ok, _} = Supervisor.start_child(TimerManager, spec)

      :ok
    end

    test "gets timer", context do
      assert TimerManager.get_timer(context.user_id)
    end

    test "removes timer", context do
      TimerManager.stop_timer(context.user_id)

      assert [_] = Supervisor.which_children(TimerManager)
    end
  end
end
