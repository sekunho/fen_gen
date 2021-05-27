defmodule FenGenWeb.PageLive do
  use Surface.LiveView
  alias FenGenWeb.Router.Helpers, as: Routes

  data uploaded_files, :list, default: []

  @impl true
  def mount(_params, _session, socket) do
    {:ok, allow_upload(socket, :board, accept: ~w(.jpg .jpeg), max_entries: 4)}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :board, fn %{path: path}, _entry ->
        dest = Path.join([:code.priv_dir(:fen_gen), "static", "uploads", Path.basename(path)])
        IO.inspect(dest)
        File.mkdir(dest) |> IO.inspect()
        File.cp!(path, dest)
        Routes.static_path(socket, "/uploads/#{Path.basename(dest)}")
      end)

    {:noreply, update(socket, :uploaded_files, &(&1 ++ uploaded_files))}
  end
end
