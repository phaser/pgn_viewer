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
    %{moves: moves, result: result, meta_moves: meta_moves} = extract_moves(game)
    %Game{properties: propsMap, moves: moves, result: result, meta_moves: meta_moves}
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
    valid_moves = moves |> Enum.map(fn m -> m |> Enum.filter(&valid_move(&1)) end)
    meta_moves = moves |> Enum.map(fn m -> m |> Enum.filter(&invalid_move(&1)) end)
    %{moves: valid_moves, meta_moves: meta_moves, result: ""}
  end

  def valid_move(move) do
    if String.length(move) == 0 do
       false
    else
      valid_chars =
        Enum.to_list(?1..?8) ++
        Enum.to_list(?a..?h) ++ [?Q, ?K, ?B, ?N, ?R, ?O, ?-, ?x, ?+, ?#, ?=]
      String.graphemes(move) |> Enum.all?(fn c -> hd(String.to_charlist(c)) in valid_chars end)
    end
  end

  def invalid_move(move), do: !valid_move(move)
end
