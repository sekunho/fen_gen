defmodule Cashew.Tile do
  alias Cashew.Label
  alias Pixels

  @type t :: %__MODULE__{
          id: non_neg_integer,
          fen: binary,
          width: integer,
          height: integer,
          data: binary,
          label: Label.t()
        }

  @type attrs :: %{
          id: non_neg_integer,
          fen: binary,
          label: Label.t() | nil
        }

  @enforce_keys [:id, :fen, :data, :height, :width]
  defstruct id: nil, fen: nil, data: nil, height: 0, width: 0, label: nil

  @doc """
  Converts a `Pixels` to a `Tile`.
  """
  @spec from_pixels(Pixels.t(), attrs) :: t()
  def from_pixels(%Pixels{data: d, height: h, width: w}, attrs) when is_map(attrs) do
    %__MODULE__{id: attrs.id, fen: attrs.fen, data: d, height: h, width: w, label: attrs.label}
  end

  def parse_attrs(path) do
    [tile_name, fen] =
      path
      |> String.split("/")
      |> Enum.reverse()
      |> Enum.take(2)

    id =
      tile_name
      |> Path.basename(".png")
      |> String.replace("tile-", "")
      |> String.to_integer()

    %{
      id: id,
      fen: fen,
      label: nil
    }
  end

  def sort_paths(paths) do
    paths
    |> Enum.group_by(fn path ->
      path
      |> String.split("/")
      |> Enum.reverse()
      |> Enum.take(2)
      |> Enum.at(1)
    end)
    |> Enum.flat_map(fn {_group, tiles} ->
      Enum.sort_by(tiles, &sort_mapper/1, :asc)
    end)
  end

  def sort_mapper(path) do
    path
    |> Path.basename(".png")
    |> String.replace("tile-", "")
    |> String.to_integer()
  end
end
