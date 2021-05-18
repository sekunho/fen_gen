defmodule CashewTest do
  use ExUnit.Case
  doctest Cashew

  @base_path "#{File.cwd!()}/test"
  @data_path "#{@base_path}/data"
  @bin_path_a "#{@base_path}/tiles_a.bin"
  @bin_path_b "#{@base_path}/tiles_b.bin"
  test "if lazy and eager yield the same bins" do
    count = 64
    rows = 50
    cols = 50

    # Lazy version
    @data_path
    |> Cashew.stream_read_all()
    |> Cashew.stream_dump_images(@bin_path_a, %{count: count, rows: rows, cols: cols})

    bin_a = File.read!(@bin_path_a)
    File.rm(@bin_path_a)

    assert <<^count::32, ^rows::32, ^cols::32, images_a::binary>> = bin_a

    # Eager
    @data_path
    |> Cashew.read_all()
    |> Cashew.dump_images(@bin_path_b, %{count: count, rows: rows, cols: cols})

    bin_b = File.read!(@bin_path_b)
    File.rm(@bin_path_b)

    assert <<^count::32, ^rows::32, ^cols::32, images_b::binary>> = bin_b

    # Equality
    assert images_a == images_b
  end
end
