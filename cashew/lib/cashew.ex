defmodule Cashew do
  alias Pixels

  @doc """
  Dump images data into a bin file.
  """
  def dump_images!(images, name \\ "data.bin") when is_list(images) and is_binary(name) do
    [%{height: rows, width: cols} | _] = images
    count = length(images)

    img_bins =
      Enum.map(images, fn img ->
        img.data
      end)
      |> :binary.list_to_bin()

    bin = <<count::32, rows::32, cols::32, img_bins::binary>>

    File.write(name, bin)
  end
end
