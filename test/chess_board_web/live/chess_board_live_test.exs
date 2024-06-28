defmodule ChessBoardWeb.ChessBoardLiveTest do
  import Plug.Conn
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint ChessBoardWeb.ChessBoardLive
  @test_game1 "[Event \"testing en passant\"]\n[Site \"test site\"]\n[Date \"2024.02.03\"]\n[Round \"1\"]\n[White \"Cristianus\"]\n[Black \"Loraine\"]\n[Result \"1-0\"]\n\n1. d4 c6 2. d5 e5 3. dxe6 d5 1-0"
  use ChessBoardWeb.ConnCase

  test "disconnected and connected mount", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "We can&#39;t find the internet"

    {:ok, view, html} = live(conn)
    assert html =~ "<textarea name=\"game\" rows=\"4\" placeholder=\"Enter game here!\"></textarea>"
  end

  test "when submitting a game, we get a chess board", %{conn: conn} do
    conn = get(conn, "/")
    {:ok, view, html} = live(conn)
    assert html =~ "<textarea name=\"game\" rows=\"4\" placeholder=\"Enter game here!\"></textarea>"

    result = view
          |> element("form")
          |> render_submit(%{game: @test_game1})
    assert result =~ "&quot;testing en passant&quot;"
    assert result =~ "&quot;test site&quot;"
    assert result =~ "&quot;2024.02.03&quot;"
    assert result =~ "<!-- a8 --><img class=\"piece\" src=\"/images/Chess_rdt45.svg\"/>"
  end
end
