defmodule FenGenWeb.BoardLive do
  use Surface.LiveView
  alias FenGen.FEN
  alias FenGenWeb.Components.Tile

  @default_board Stream.repeatedly(fn -> "*" end) |> Enum.take(64)

  data fen, :string, default: ""
  data board_state, :map, default: @default_board

  @impl true
  def mount(_params, _session, socket) do
    {:ok, allow_upload(socket, :board, accept: ~w(.jpeg), max_entries: 1)}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :board, fn %{path: path}, _entry ->
        file_name = Path.basename(path)
        dest = Application.fetch_env!(:fen_gen, :upload_path)

        File.mkdir_p(dest)
        File.cp!(path, "#{dest}/#{file_name}.jpeg")

        "#{dest}/#{file_name}.jpeg"
      end)

    Enum.map(uploaded_files, &Process.send(self(), {:predict, &1}, [:noconnect]))

    {:noreply, socket}
  end

  @timeout 60_000
  @impl true
  def handle_info({:predict, img_path}, socket) do
    :poolboy.transaction(
      :worker,
      fn pid -> GenServer.call(pid, {:predict, self(), img_path}) end,
      @timeout
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:data, img_path, prediction}, socket) do
    board_state = String.graphemes(prediction)
    fen = FEN.parse_prediction(prediction)
    File.rm(img_path)

    {:noreply, assign(socket, fen: fen, board_state: board_state)}
  end

  defp get_tile_state(board_state, row, col) do
    index = row + col

    Enum.at(board_state, index)
  end
end
