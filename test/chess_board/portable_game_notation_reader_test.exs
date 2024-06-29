defmodule ChessBoard.PortableGameNotationReaderTest do
  use ExUnit.Case
  alias ChessBoard.PortableGameNotationReader
  @test_game2_base64 "W0V2ZW50ICJ0ZXN0aW5nIGVuIHBhc3NhbnQiXQpbU2l0ZSAidGVzdCBzaXRlIl0KW0RhdGUgIjIwMjQuMDIuMDMiXQpbUm91bmQgIjEiXQpbV2hpdGUgIkNyaXN0aWFudXMiXQpbQmxhY2sgIkxvcmFpbmUiXQpbUmVzdWx0ICIxLTAiXQoKMS4gZDQgYzYgMi4gZDUgZTUgMy4gZHhlNiAxLTA="

  test "Parsing moves should take into account that last round may have only white moving" do
    game = PortableGameNotationReader.parse(@test_game2_base64)
    assert Enum.count(List.last(game.moves)) == 1
  end

  test "Test valid_move" do
    assert PortableGameNotationReader.valid_move("e4") == true
  end
end
