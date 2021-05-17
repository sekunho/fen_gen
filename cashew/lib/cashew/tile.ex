defmodule Cashew.Tile do
  alias Cashew.Label
  alias Pixels

  defstruct data: nil, height: 0, width: 0, label: "*"

  @type t :: %__MODULE__{width: integer, height: integer, data: binary, label: Label.t()}

  @doc """
  Converts a `Pixel` to a `Tile`.
  """
  @spec from_pixels(Pixels.t(), binary) :: Cashew.Tile.t()
  def from_pixels(%Pixels{data: d, height: h, width: w}, label) when is_binary(label) do
    %__MODULE__{data: d, height: h, width: w, label: label}
  end
end
