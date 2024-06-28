defmodule ChessBoardWeb.ChessBoardLiveTest do
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint ChessBoardWeb.ChessBoardLive
  @test_game1 "[Event \"testing en passant\"]\n[Site \"test site\"]\n[Date \"2024.02.03\"]\n[Round \"1\"]\n[White \"Cristianus\"]\n[Black \"Loraine\"]\n[Result \"1-0\"]\n\n1. d4 c6 2. d5 e5 3. dxe6 d5 1-0"
  @test_game1_base64 "W0V2ZW50ICJ0ZXN0aW5nIGVuIHBhc3NhbnQiXQpbU2l0ZSAidGVzdCBzaXRlIl0KW0RhdGUgIjIwMjQuMDIuMDMiXQpbUm91bmQgIjEiXQpbV2hpdGUgIkNyaXN0aWFudXMiXQpbQmxhY2sgIkxvcmFpbmUiXQpbUmVzdWx0ICIxLTAiXQoKMS4gZDQgYzYgMi4gZDUgZTUgMy4gZHhlNiBkNSAxLTA%3D"
  @game_enter_textarea "<textarea name=\"game\" rows=\"4\" placeholder=\"Enter game here!\"></textarea>"
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
      ["<div class=\"cell_content black_cell\"><!-- d4 --><img class=\"piece\" src=\"/images/Chess_plt45.svg\"/></div>", "<div class=\"cell_content black_cell\"><!-- d2 --></div>"],
      ["<div class=\"cell_content white_cell\"><!-- c6 --><img class=\"piece\" src=\"/images/Chess_pdt45.svg\"/></div>", "<div class=\"cell_content black_cell\"><!-- c7 --></div>"],
      ["<div class=\"cell_content white_cell\"><!-- d5 --><img class=\"piece\" src=\"/images/Chess_plt45.svg\"/></div>", "<div class=\"cell_content black_cell\"><!-- d4 --></div>"],
      ["<div class=\"cell_content black_cell\"><!-- e5 --><img class=\"piece\" src=\"/images/Chess_pdt45.svg\"/></div>", "<div class=\"cell_content black_cell\"><!-- e7 --></div>"],
      [
        "<div class=\"cell_content white_cell\"><!-- e6 --><img class=\"piece\" src=\"/images/Chess_plt45.svg\"/></div>",
        "<div class=\"cell_content black_cell\"><!-- e5 --></div>",
        "<div class=\"cell_content white_cell\"><!-- d5 --></div>",
        "<div class=\"captures\"><div><img src=\"/images/Chess_pdt45.svg\"/></div></div>"
      ]
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
end
