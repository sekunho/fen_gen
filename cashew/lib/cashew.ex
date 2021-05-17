defmodule Cashew do
  alias Cashew.{Tile, Label}
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
  Dump labels into a bin file.
  """
  @spec dump_tile_labels([binary], binary) :: :ok | {:error, atom}
  def dump_tile_labels(labels, bin_path \\ "labels.bin") do
    count = length(labels)
    data = :binary.list_to_bin(labels)
    bin = <<count::32, data::binary>>

    File.write(bin_path, bin)
  end

  ### LAZY VERSIONS

  @doc """
  Packages the chessboard images in a directory into an
  bin with all the images, and another for labels.

  iex> stream_boards_to_bin("path/to/board_images", "path/to/bin/folder")
  {"path/to/bin/folder/tiles.bin", "path/to/bin/folder/labels.bin"}
  """
  def stream_boards_to_bin(boards_dir, bin_path, opts \\ []) do
    if File.dir?(boards_dir) do
      tiles_dir = IO.iodata_to_binary([boards_dir, "_tiles"])
      tile_dirs_wildcard = IO.iodata_to_binary([tiles_dir, "/**"])
      cleanup = Keyword.get(opts, :cleanup, true)

      fen_list =
        boards_dir
        |> Cashew.boards_to_tiles(opts)
        |> Enum.map(&elem(&1, 1))

      fens_length = length(fen_list)
      tiles = Cashew.stream_read_all(tile_dirs_wildcard)

      ## Dump tiles to image bin
      tiles
      |> Cashew.stream_dump_images("#{bin_path}/tiles.bin", %{
        count: fens_length * 64,
        rows: 50,
        cols: 50
      })

      ## Dump labels to bin
      tiles
      |> Enum.uniq_by(&Map.fetch!(&1, :fen))
      |> Enum.flat_map(&Label.from_fen/1)
      |> Cashew.dump_tile_labels("#{bin_path}/labels.bin")

      if cleanup do
        File.rm_rf!(tiles_dir)
      end

      {"#{bin_path}/tiles.bin", "#{bin_path}/labels.bin"}
    else
      raise File.Error
    end
  end

  @doc """
  Lazy version of `read_all/1`.
  """
  def stream_read_all(path) do
    [path, "/*.png"]
    |> IO.iodata_to_binary()
    |> Path.wildcard()
    |> Tile.sort_paths()
    |> Stream.map(fn path ->
      {:ok, image} = Pixels.read_file(path)
      attrs = Tile.parse_attrs(path)

      Tile.from_pixels(image, attrs)
    end)
  end

  @doc """
  Lazily dumps tile data into a bin file.

  Note: This will overwrite any existing bin of the same name.
  """
  def stream_dump_images(lazy_tile_list, name \\ "tiles.bin", %{count: count, rows: rows, cols: cols})
      when is_struct(lazy_tile_list) and is_binary(name) do
    bin_metadata = <<count::32, rows::32, cols::32>>

    File.rm(name)
    File.write!(name, bin_metadata)

    file = File.open!(name, [:append])

    lazy_tile_list
    |> Stream.map(fn tile ->
      flat_bin = flatten_channels(tile.data)

      IO.binwrite(file, flat_bin)
    end)
    |> Stream.run()

    File.close(file)
  end

  defp flatten_channels(bin) do
    bin
    |> :binary.bin_to_list()
    |> Enum.chunk_every(4)
    |> Enum.map(fn
      [0, 0, 0, 255] -> 0
      [255, 255, 255, 255] -> 255
    end)
    |> :binary.list_to_bin()
  end

  defp resize_and_split(img_path, dest) when is_binary(img_path) and is_binary(dest) do
    fen = Path.basename(img_path, ".jpeg")
    img_folder = IO.iodata_to_binary([dest, "/", fen])

    File.mkdir(img_folder)

    """
    convert '#{img_path}' \
      -crop 8x8@ +repage +adjoin \
      -quality 100 \
      -monochrome \
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
