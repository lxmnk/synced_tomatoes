defmodule Test.Core.TimerManagerTest do
  use Test.Cases.DBCase

  alias SyncedTomatoes.Core.{Timer, TimerManager}

  setup do
    %{
      timer_opts: [
        work_min: 25,
        short_break_min: 5,
        long_break_min: 15,
        work_intervals_count: 4,
        auto_next: true
      ],
      user_id: insert(:user).id
    }
  end

  test "starts timer", context do
    assert {:ok, _} = TimerManager.start_timer(context.user_id, context.timer_opts)

    assert timer_exists?(context.user_id)
  end

  describe "with started timer" do
    setup context do
      opts = Keyword.put(
        context.timer_opts,
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
      assert {:ok, _} = TimerManager.fetch_timer(context.user_id)
    end

    test "removes timer", context do
      TimerManager.stop_timer(context.user_id)

      refute timer_exists?(context.user_id)
    end
  end

  defp timer_exists?(user_id) do
    timer =
      TimerManager
      |> Supervisor.which_children()
      |> Enum.find(
        fn
          {{Timer, ^user_id}, _, _, _} -> true
          _ -> false
        end
      )

    case timer do
      nil -> false
      _ -> true
    end
  end
end
