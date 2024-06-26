defmodule ChessBoard.PortableGameNotationReader do
  alias ChessBoard.Models.Game

  def encode_to_base64(pgn_text) do
    Base.encode64(pgn_text)
  end

  @doc """
  Takes a base64 encoded PGN game and decodes it.
  """
  def decode_from_base64(pgn_base64) do
    Base.decode64!(pgn_base64)
  end

  def parse(pgn_base64) do
    tg = decode_from_base64(pgn_base64)
    [properties, game] = tg |> String.split("\n\n")
    propsMap = extract_properties(properties)
    %{moves: moves, result: result} = extract_moves(game)
    %Game{properties: propsMap, moves: moves, result: result}
  end

  defp extract_properties(properties) do
    properties
      |> String.split("\n")
      |> Enum.map(fn l -> l |> String.trim_leading("[") |> String.trim_trailing("]") end)
      |> Enum.map(fn l ->
        p = l |> String.split(" ")
        {hd(p), tl(p) |> Enum.join(" ")}
      end)
      |> Map.new()
  end

  defp extract_moves(game) do
    moves = Regex.split(~r/\d+\. ?/, game)
    |> Enum.map(fn m -> String.trim(m) |> String.split(" ") end)
    last = List.last(moves)
    new_last = [hd(last), hd(tl(last))]
    result = tl(tl(last)) |> Enum.join(" ")
    moves = List.delete(moves, last)
    moves = List.insert_at(moves, Enum.count(moves), new_last)
    %{moves: moves, result: result}
  end
end
