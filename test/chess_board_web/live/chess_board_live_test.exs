defmodule ChessBoardWeb.ChessBoardLiveTest do
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint ChessBoardWeb.ChessBoardLive
  @test_game1 "[Event \"testing en passant\"]\n[Site \"test site\"]\n[Date \"2024.02.03\"]\n[Round \"1\"]\n[White \"Cristianus\"]\n[Black \"Loraine\"]\n[Result \"1-0\"]\n\n1. d4 c6 2. d5 e5 3. dxe6 d5 1-0"
  @test_game1_base64 "W0V2ZW50ICJ0ZXN0aW5nIGVuIHBhc3NhbnQiXQpbU2l0ZSAidGVzdCBzaXRlIl0KW0RhdGUgIjIwMjQuMDIuMDMiXQpbUm91bmQgIjEiXQpbV2hpdGUgIkNyaXN0aWFudXMiXQpbQmxhY2sgIkxvcmFpbmUiXQpbUmVzdWx0ICIxLTAiXQoKMS4gZDQgYzYgMi4gZDUgZTUgMy4gZHhlNiBkNSAxLTA%3D"
  @game_enter_textarea "<textarea name=\"game\" rows=\"4\" placeholder=\"Enter game here!\"></textarea>"
  @wc "white_cell"
  @bc "black_cell"

  use ChessBoardWeb.ConnCase

  test "disconnected and connected mount", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "We can&#39;t find the internet"

    {:ok, _view, html} = live(conn)
    assert html =~ @game_enter_textarea
  end

  test "when submitting a game, we get a chess board", %{conn: conn} do
    conn = get(conn, "/")
    {:ok, view, html} = live(conn)
    assert html =~ @game_enter_textarea

    result = view
          |> element("form")
          |> render_submit(%{game: @test_game1})
    refute result =~ @game_enter_textarea
    assert result =~ "&quot;testing en passant&quot;"
    assert result =~ "&quot;test site&quot;"
    assert result =~ "&quot;2024.02.03&quot;"
    assert result =~ "<!-- a8 --><img class=\"piece\" src=\"/images/Chess_rdt45.svg\"/>"
  end

  test "en passant capture", %{conn: conn} do
    conn = get(conn, "/?game=#{@test_game1_base64}")
    {:ok, view, html} = live(conn)
    refute html =~ @game_enter_textarea

    asserts = [
      [get_cell("d4", "plt"), get_cell("d2", "")],
      [get_cell("c6", "pdt"), get_cell("c7", "")],
      [get_cell("d5", "plt"), get_cell("d4", "")],
      [get_cell("e5", "pdt"), get_cell("e7", "")],
      [get_cell("e6", "plt"), get_cell("e5", ""), get_cell("d5", ""), "<div class=\"captures\"><div><img src=\"/images/Chess_pdt45.svg\"/></div></div>"]
    ]

    asserts
    |> Enum.each(fn toassert ->
      result = view
                |> element("button#btn_next")
                |> render_click()
      toassert
      |> Enum.each(fn text ->
          assert result =~ text
        end)
    end)
  end

  defp get_cell(position, piece) do
    color = ChessBoardWeb.ChessBoardLive.black_or_white(String.at(position, 1), String.at(position, 0))
    content = if piece != "", do: "<img class=\"piece\" src=\"/images/Chess_#{piece}45.svg\"/>", else: ""
    "<div class=\"cell_content #{color}\"><!-- #{position} -->#{content}</div>"
  end
end
