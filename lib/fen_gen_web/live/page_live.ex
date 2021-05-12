defmodule FenGenWeb.PageLive do
  use Surface.LiveView

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
