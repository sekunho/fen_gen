defmodule FenGenWeb.Components.Tile do
  use Surface.Component

  @state ["*", "r", "n", "b", "q", "k", "p", "R", "N", "B", "Q", "K", "P",]

  prop current_state, :string, values: @state, default: "*"

end
