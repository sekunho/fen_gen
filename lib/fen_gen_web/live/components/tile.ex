defmodule FenGenWeb.Components.Tile do
  use Surface.Component
  alias FenGenWeb.Router.Helpers, as: Routes

  @state ["*", "r", "n", "b", "q", "k", "p", "R", "N", "B", "Q", "K", "P",]

  prop current_state, :string, values: @state, default: "*"

end
