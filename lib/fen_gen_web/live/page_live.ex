defmodule FenGenWeb.PageLive do
  use Surface.LiveView
  alias FenGenWeb.Router.Helpers, as: Routes

  data uploaded_files, :list, default: []
  data fen, :string, default: ""

  @impl true
  def mount(_params, _session, socket) do
    IO.puts "HEYYYY"
    {:ok, allow_upload(socket, :board, accept: ~w(.jpeg), max_entries: 4)}
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
        # Routes.static_path(socket, "/uploads/#{Path.basename(dest)}")

        "#{dest}/#{file_name}.jpeg"
      end)
      |> IO.inspect(label: "FILES")

    Enum.map(uploaded_files, &Process.send(self(), {:predict, &1}, [:noconnect]))

    {:noreply, update(socket, :uploaded_files, &(&1 ++ uploaded_files))}
  end

  @impl true
  def handle_info({:predict, img_path}, socket) do
    {:spawn, "python scripts/predict.py"}
    |> Port.open([:binary])
    |> Port.command([img_path, "\n"])

    {:noreply, socket}
  end

  @impl true
  def handle_info({_port, {:data, prediction}}, socket) do
    IO.inspect(prediction)
    fen =
      prediction
      |> String.trim()
      |> String.graphemes()
      |> Enum.chunk_every(8)
      |> Enum.map(fn chunks ->
        {fen, prev_blanks} =
          Enum.reduce(chunks, {"", 0}, fn char, {fen, prev_blanks} ->
            cond do
              char == "*" ->
                {fen, prev_blanks + 1}

              char != "*" && prev_blanks > 0 ->
                {IO.iodata_to_binary([fen, Integer.to_string(prev_blanks), char]), 0}

              true ->
                {IO.iodata_to_binary([fen, char]), 0}
            end
          end)

          fen =
            if prev_blanks > 0 do
              IO.iodata_to_binary([fen, Integer.to_string(prev_blanks)])
            else
              fen
            end

          IO.iodata_to_binary([fen, "\\"])
      end)
      |> IO.iodata_to_binary()

    {:noreply, assign(socket, fen: fen)}
  end
end
