defmodule FenGen.Worker do
  use GenServer

  @impl true
  def init(:ok) do
    scripts_path = Application.fetch_env!(:fen_gen, :scripts_path)

    port =
      Port.open(
        {:spawn, "python #{scripts_path}/predict.py"},
        [:binary]
      )

    {:ok, %{port: port, requests: %{}}}
  end

  @impl true
  def handle_call({:predict, pid, img_path}, _from, state) do
    Port.command(state.port, [img_path, "\n"])
    state = put_in(state, [:requests, img_path], pid)

    {:reply, img_path, state}
  end

  @impl true
  def handle_info({_port, {:data, data}}, state) do
    [img_path, prediction] = String.split(data, ",")
    {from_pid, state} = pop_in(state, [:requests, img_path])
    send(from_pid, {:data, img_path, prediction})

    {:noreply, state}
  end

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def predict(pid, img_path) do
    GenServer.call(__MODULE__, {:predict, pid, img_path})
  end
end
