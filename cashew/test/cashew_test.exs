defmodule CashewTest do
  use ExUnit.Case
  # doctest Cashew

  @base_path "#{File.cwd!()}/test"
  @bin_dir "#{@base_path}/data"
  @tiles_path "#{@bin_dir}/tiles.bin"
  @labels_path "#{@bin_dir}/labels.bin"
  @board_path "#{@base_path}/data/boards"
  test "dump boards to bin" do
    count = 2*64
    rows = 50
    cols = 50
    labels = "nK*b*q*R*******k*****Pb*n**p***********r****B******q*****n***N**rrK**R********n********B******N******P************k******B***Qb*"

    File.rm_rf("#{@board_path}_tiles/")

    Cashew.stream_boards_to_bin(@board_path, @bin_dir, cleanup: false)
    img_bin_result = File.read(@tiles_path)
    label_bin_result = File.read(@labels_path)

    File.rm(@tiles_path)
    File.rm(@labels_path)

    assert {:ok, img_bin} = img_bin_result
    assert <<^count::32, ^rows::32, ^cols::32, _images::binary>> = img_bin

    assert {:ok, label_bin} = label_bin_result
    assert <<^count::32, ^labels::binary>> = label_bin
  end
end
