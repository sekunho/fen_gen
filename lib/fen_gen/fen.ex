defmodule FenGen.FEN do
  @spec parse_prediction(binary) :: binary
  def parse_prediction(prediction) when is_binary(prediction) do
    prediction
    |> String.trim()
    |> String.graphemes()
    |> Enum.chunk_every(8)
    |> Enum.map(fn chunks ->
      {fen, prev_blanks} =
        Enum.reduce(chunks, {"", 0}, fn char, {fen, prev_blanks} ->
          cond do
            char == "*" ->
              {fen, prev_blanks + 1}

            char != "*" && prev_blanks > 0 ->
              {IO.iodata_to_binary([fen, Integer.to_string(prev_blanks), char]), 0}

            true ->
              {IO.iodata_to_binary([fen, char]), 0}
          end
        end)

      fen =
        if prev_blanks > 0 do
          IO.iodata_to_binary([fen, Integer.to_string(prev_blanks)])
        else
          fen
        end

      IO.iodata_to_binary([fen, "/"])
    end)
    |> IO.iodata_to_binary()
  end
end
