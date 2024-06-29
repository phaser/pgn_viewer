defmodule ChessBoard.PortableGameNotationReaderTest do
  use ExUnit.Case
  alias ChessBoard.PortableGameNotationReader
  @test_game2_base64 "W0V2ZW50ICJ0ZXN0aW5nIGVuIHBhc3NhbnQiXQpbU2l0ZSAidGVzdCBzaXRlIl0KW0RhdGUgIjIwMjQuMDIuMDMiXQpbUm91bmQgIjEiXQpbV2hpdGUgIkNyaXN0aWFudXMiXQpbQmxhY2sgIkxvcmFpbmUiXQpbUmVzdWx0ICIxLTAiXQoKMS4gZDQgYzYgMi4gZDUgZTUgMy4gZHhlNiAxLTA="
  @test_game3_base64 "W0V2ZW50ICJPcGVuIE5PUi1jaCJdCltTaXRlICJPc2xvIE5PUiJdCltEYXRlICIyMDAxLjA0LjEzIl0KW1JvdW5kICI4Il0KW1doaXRlICJDYXJsc2VuLE0iXQpbQmxhY2sgIkpvaGFuc2VuLFNBIl0KW1Jlc3VsdCAiMS0wIl0KW1doaXRlRWxvICIyMDY0Il0KW0JsYWNrRWxvICIyMTU5Il0KW0VDTyAiQjAyIl0KCjEuZTQgTmY2IDIuTmMzIGQ1IDMuZTUgTmU0IDQuTmNlMiBkNCA1LmQzIE5jNSA2LmY0IE5jNiA3Lk5mMyBCZzQgOC5OZzMgZTYKOS5CZTIgQmU3IDEwLk8tTyBoNSAxMS5oMyBoNCAxMi5OaDEgQmY1IDEzLk5mMiBRZDcgMTQuYzQgZjYgMTUuYjMgYTUgMTYuYTMgYTQKMTcuYjQgTmIzIDE4LlJiMSBOeGMxIDE5LlJ4YzEgZnhlNSAyMC5iNSBOYTUgMjEuTnhlNSBRZDYgMjIuQmg1KyBnNiAyMy5OeGc2IE8tTy1PCjI0Lk54aDggUnhoOCAyNS5OZTQgUXhhMyAyNi5SYTEgUWIzIDI3LlJ4YTQgUnhoNSAyOC5ReGg1IFF4YTQgMjkuUWU4KyBCZDgKMzAuTmM1IFFhMyAzMS5RZDcrIEtiOCAzMi5ReGQ4KyBLYTcgMzMuUXhjNyAgMS0w"

  test "Parsing moves should take into account that last round may have only white moving" do
    game = PortableGameNotationReader.parse(@test_game2_base64)
    assert Enum.count(List.last(game.moves)) == 1
    game = PortableGameNotationReader.parse(@test_game3_base64)
    assert Enum.count(List.last(game.moves)) == 1
  end

  test "Test valid_move" do
    assert PortableGameNotationReader.valid_move("e4") == true
    assert PortableGameNotationReader.valid_move("O-O") == true
  end
end
