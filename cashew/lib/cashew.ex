defmodule Cashew do
  alias Pixels

  @doc """
  Reads all the images under a FEN directory. It is
  assumed to be a PNG file, otherwise it won't be read.
  """
  def read_all(path) do
    [path, "/*.png"]
    |> IO.iodata_to_binary()
    |> Path.wildcard()
    |> Enum.map(fn path ->
      {:ok, image} = Pixels.read_file(path)

      image
    end)
  end

  @doc """
  Dump tile data into a bin file.
  """
  @spec dump_images([Pixels.t()], binary) :: :ok | {:error, atom}
  def dump_images(images, name \\ "tiles.gz")
      when is_list(images) and is_binary(name) do
    [%{height: rows, width: cols} | _] = images
    count = length(images)

    data =
      images
      |> Enum.map(fn img ->
        img.data
      end)
      |> :binary.list_to_bin()

    bin = <<count::32, rows::32, cols::32, data::binary>>

    compress_and_write(bin, name)
  end

  @doc """
  Dump labels into a bin file.
  """
  @spec dump_tile_labels([binary], binary) :: :ok | {:error, atom}
  def dump_tile_labels(labels, name \\ "labels.gz") do
    count = length(labels)
    data = :binary.list_to_bin(labels)
    bin = <<count::32, data::binary>>

    compress_and_write(bin, name)
  end

  defp compress_and_write(data, name) do
    bin = :zlib.gzip(data)

    File.write(name, bin)
  end
end
