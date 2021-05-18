defmodule Cashew do
  alias Pixels

  def boards_to_tiles(dir, opts \\ []) when is_binary(dir) and is_list(opts) do
    if File.dir?(dir) do
      source = IO.iodata_to_binary([dir, "/*.jpeg"])
      dest = Keyword.get(opts, :to, IO.iodata_to_binary([dir, "_tiles"]))
      max_concurrency = Keyword.get(opts, :max_concurrency, System.schedulers_online())

      File.mkdir(dest)

      source
      |> Path.wildcard()
      |> maybe_take_random_subset(opts)
      |> Task.async_stream(&resize_and_split(&1, dest),
        max_concurrency: max_concurrency,
        timeout: :infinity
      )
      |> Enum.to_list()
    else
      raise File.Error
    end
  end

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
  def dump_images(images, name \\ "tiles.gz", %{count: count, rows: rows, cols: cols})
      when is_list(images) and is_binary(name) do
    data =
      images
      |> Enum.map(fn img ->
        img.data
      end)
      |> :binary.list_to_bin()

    bin = <<count::32, rows::32, cols::32, data::binary>>

    File.write(name, bin)
  end

  @doc """
  Dump labels into a bin file.
  """
  @spec dump_tile_labels([binary], binary) :: :ok | {:error, atom}
  def dump_tile_labels(labels, name \\ "labels.bin") do
    count = length(labels)
    data = :binary.list_to_bin(labels)
    bin = <<count::32, data::binary>>

    File.write(name, bin)
  end

  ### LAZY VERSIONS

  @doc """
  Lazy version of `read_all/1`.
  """
  def stream_read_all(path) do
    [path, "/*.png"]
    |> IO.iodata_to_binary()
    |> Path.wildcard()
    |> Stream.map(fn path ->
      {:ok, image} = Pixels.read_file(path)

      image
    end)
  end

  @doc """
  Lazily dumps tile data into a bin file.

  Note: This will overwrite any existing bin of the same name.
  """
  def stream_dump_images(lazy_enum, name \\ "tiles.bin", %{count: count, rows: rows, cols: cols})
      when is_struct(lazy_enum) and is_binary(name) do
    lazy_bin_list = Stream.map(lazy_enum, &Map.fetch!(&1, :data))
    bin_metadata = <<count::32, rows::32, cols::32>>

    File.rm(name)
    File.write!(name, bin_metadata)

    file = File.open!(name, [:append, :binary])

    lazy_bin_list
    |> Stream.map(&IO.binwrite(file, &1))
    |> Stream.run()

    File.close(file)
  end

  defp resize_and_split(img_path, dest) when is_binary(img_path) and is_binary(dest) do
    fen = Path.basename(img_path, ".jpeg")
    img_folder = IO.iodata_to_binary([dest, "/", fen])

    File.mkdir(img_folder)

    """
    convert '#{img_path}' \
      -crop 8x8@ +repage +adjoin \
      -quality 100 \
      -set filename:index "%[fx:t]" \
      '#{img_folder}/tile-%[filename:index].png' \
    """
    |> String.to_charlist()
    |> :os.cmd()

    fen
  end

  defp maybe_take_random_subset(img_paths, opts) do
    subset = Keyword.get(opts, :subset, 0)

    if subset > 0 do
      Enum.take_random(img_paths, subset)
    else
      img_paths
    end
  end
end
