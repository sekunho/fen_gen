defmodule LivebookWeb.HomeLiveTest do
  use LivebookWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Livebook.{SessionSupervisor, Session}

  test "disconnected and connected render", %{conn: conn} do
    {:ok, view, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Running sessions"
    assert render(view) =~ "Running sessions"
  end

  test "redirects to session upon creation", %{conn: conn} do
    {:ok, view, _} = live(conn, "/")

    assert {:error, {:live_redirect, %{to: to}}} =
             view
             |> element("button", "New notebook")
             |> render_click()

    assert to =~ "/sessions/"
  end

  describe "file selection" do
    test "updates the list of files as the input changes", %{conn: conn} do
      {:ok, view, _} = live(conn, "/")

      path = Path.expand("../../../lib", __DIR__) <> "/"

      assert view
             |> element("form")
             |> render_change(%{path: path}) =~ "livebook_web"
    end

    test "allows importing when a notebook file is selected", %{conn: conn} do
      {:ok, view, _} = live(conn, "/")

      path = test_notebook_path("basic")

      view
      |> element("form")
      |> render_change(%{path: path})

      assert assert {:error, {:live_redirect, %{to: to}}} =
                      view
                      |> element(~s{button[phx-click="fork"]}, "Fork")
                      |> render_click()

      assert to =~ "/sessions/"
    end

    test "disables import when a directory is selected", %{conn: conn} do
      {:ok, view, _} = live(conn, "/")

      path = File.cwd!()

      view
      |> element("form")
      |> render_change(%{path: path})

      assert view
             |> element(~s{button[phx-click="fork"][disabled]}, "Fork")
             |> has_element?()
    end

    test "disables import when a nonexistent file is selected", %{conn: conn} do
      {:ok, view, _} = live(conn, "/")

      path = File.cwd!() |> Path.join("nonexistent.livemd")

      view
      |> element("form")
      |> render_change(%{path: path})

      assert view
             |> element(~s{button[phx-click="fork"][disabled]}, "Fork")
             |> has_element?()
    end

    @tag :tmp_dir
    test "disables open when a write-protected notebook is selected",
         %{conn: conn, tmp_dir: tmp_dir} do
      {:ok, view, _} = live(conn, "/")

      path = Path.join(tmp_dir, "write_protected.livemd")
      File.touch!(path)
      File.chmod!(path, 0o444)

      view
      |> element("form")
      |> render_change(%{path: path})

      assert view
             |> element(~s{button[phx-click="open"][disabled]}, "Open")
             |> has_element?()

      assert view
             |> element(~s{[aria-label="This file is write-protected, please fork instead"]})
             |> has_element?()
    end
  end

  describe "sessions list" do
    test "lists running sessions", %{conn: conn} do
      {:ok, id1} = SessionSupervisor.create_session()
      {:ok, id2} = SessionSupervisor.create_session()

      {:ok, view, _} = live(conn, "/")

      assert render(view) =~ id1
      assert render(view) =~ id2
    end

    test "updates UI whenever a session is added or deleted", %{conn: conn} do
      {:ok, view, _} = live(conn, "/")

      {:ok, id} = SessionSupervisor.create_session()
      assert render(view) =~ id

      SessionSupervisor.close_session(id)
      refute render(view) =~ id
    end

    test "allows forking existing session", %{conn: conn} do
      {:ok, id} = SessionSupervisor.create_session()
      Session.set_notebook_name(id, "My notebook")

      {:ok, view, _} = live(conn, "/")

      assert {:error, {:live_redirect, %{to: to}}} =
               view
               |> element(~s{[data-test-session-id="#{id}"] button}, "Fork")
               |> render_click()

      assert to =~ "/sessions/"

      {:ok, view, _} = live(conn, to)
      assert render(view) =~ "My notebook - fork"
    end

    test "allows closing session after confirmation", %{conn: conn} do
      {:ok, id} = SessionSupervisor.create_session()

      {:ok, view, _} = live(conn, "/")

      assert render(view) =~ id

      view
      |> element(~s{[data-test-session-id="#{id}"] a}, "Close")
      |> render_click()

      view
      |> element(~s{button}, "Close session")
      |> render_click()

      refute render(view) =~ id
    end
  end

  test "link to introductory notebook correctly creates a new session", %{conn: conn} do
    {:ok, view, _} = live(conn, "/")

    assert {:error, {:live_redirect, %{to: to}}} =
             view
             |> element(~s{[aria-label="Introduction"] button})
             |> render_click()

    assert to =~ "/sessions/"

    {:ok, view, _} = live(conn, to)
    assert render(view) =~ "Welcome to Livebook"
  end

  describe "notebook import" do
    test "allows importing notebook directly from content", %{conn: conn} do
      Phoenix.PubSub.subscribe(Livebook.PubSub, "sessions")

      {:ok, view, _} = live(conn, "/home/import/content")

      notebook_content = """
      # My notebook
      """

      view
      |> element("form", "Import")
      |> render_submit(%{data: %{content: notebook_content}})

      assert_receive {:session_created, id}

      {:ok, view, _} = live(conn, "/sessions/#{id}")
      assert render(view) =~ "My notebook"
    end
  end

  # Helpers

  defp test_notebook_path(name) do
    path =
      ["../../support/notebooks", name <> ".livemd"]
      |> Path.join()
      |> Path.expand(__DIR__)

    unless File.exists?(path) do
      raise "Cannot find test notebook with the name: #{name}"
    end

    path
  end
end
