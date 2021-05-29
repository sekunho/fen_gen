defmodule FenGenWeb.BoardLiveTest do
  use FenGenWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "FENGEN"
    assert render(live) =~ "FENGEN"
  end
end
