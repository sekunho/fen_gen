defmodule Cashew.Label do
  @typedoc """
  "*" | "r" | "n" | "b" | "k" | "q" | "p" | "R" | "N" | "B" | "K" | "Q" | "P"
  """
  @type t :: String.t()

  def from_fen(%Cashew.Tile{} = tile) do
    tile.fen
    |> String.replace("-", "")
    |> maybe_pad_fen()
  end

  defp maybe_pad_fen(fen) do
    fen
    |> String.graphemes()
    |> Enum.flat_map(fn s ->
      case s in ~w(1 2 3 4 5 6 7 8) do
        true ->
          n = String.to_integer(s)

          fn -> "*" end
          |> Stream.repeatedly()
          |> Enum.take(n)
          # |> IO.iodata_to_binary()

        false ->
          [s]
      end
    end)
  end
end
