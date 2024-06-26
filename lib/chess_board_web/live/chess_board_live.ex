defmodule ChessBoardWeb.ChessBoardLive do
  require Integer
  use ChessBoardWeb, :live_view
  alias ChessBoard.PortableGameNotationReader;
  alias ChessBoard.Models.Game

  @columns ["a", "b", "c", "d", "e", "f", "g", "h"]
  @rows ["1", "2", "3", "4", "5", "6", "7", "8"]

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket = assign(socket, board: generate_initial_board(), game: nil, previous_boards: [], previous_games: [])
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"game" => game_base64}, _uri, socket) do
    game = PortableGameNotationReader.parse(game_base64)
    {:noreply, assign(socket, board: generate_initial_board(), game: game, previous_boards: [], previous_games: [game])}
  end

  def handle_params(_, _, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
      <div id="main_content">
      <div :if={@game == nil}>
      <form class="game_form" phx-submit="view-game">
      <textarea name="game" rows="4" placeholder="Enter game here!"></textarea>
      <button type="submit">View game</button>
      </form>
      </div>
      <div :if={@game != nil} class="captures">
        <div :for={cp <- @game.captures}><img src={"/images/Chess_#{cp}45.svg"} /></div>
      </div>
      <div :if={@game != nil} class="board">
        <table>
          <th :for={l <- [""] ++ columns() ++ [""]}><%= l %></th>
          <tr :for={n <- Enum.reverse(rows())} class="chess_row">
            <th><%= n %></th>
            <td :for={l <- columns()} class="chess_cell" align="center" valign="center">
              <div class={"cell_content " <> black_or_white(l,n)}>
                <!-- <%= l %><%= n %> -->
                <img class="piece" :if={@board["#{l}#{n}"].piece != nil} src={"/images/Chess_#{@board["#{l}#{n}"].piece}45.svg"} />
              </div>
            </td>
            <th><%= n %></th>
          </tr>
          <th :for={l <- [""] ++ columns() ++ [""]}><%= l %></th>
        </table>
        <div id="game_info">
          <h3>Game Info</h3>
          <div :for={p <- @game.properties} class="property"><div><%= elem(p, 0) %></div><div><%= elem(p, 1) %></div>
          </div>
          <h4>Status - <%= @game.status %></h4>
          </div>
        </div>
        <div id="board_navigation" :if={@game != nil}>
            <button :if={@game.status == "not started"} disabled> &lt; </button>
            <button :if={@game.status != "not started"} phx-click="previous-move"> &lt; </button>
            <span class="w-xl m-8">move: <%= @game.step %> / round: <%= Integer.floor_div(@game.step + 1, 2) %> </span>
            <button :if={@game.status != "ended"} phx-click="next-move"> &gt; </button>
        </div>
      </div>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("previous-move", _params, socket) do
    IO.puts "prev move"
    if socket.assigns.previous_boards != [] do
      board = List.last(socket.assigns.previous_boards)
      game = List.last(socket.assigns.previous_games)
      {:noreply, assign(socket, board: board, game: game, previous_boards: List.delete(socket.assigns.previous_boards, board), previous_games: List.delete(socket.assigns.previous_games, game))}
    else
      {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("next-move", _params, socket) do
    step = socket.assigns.game.step + 1
    socket = assign(socket, previous_boards: socket.assigns.previous_boards ++ [ socket.assigns.board ], previous_games: socket.assigns.previous_games ++ [ socket.assigns.game ])
    move(step, socket)
  end

  def handle_event("view-game", params, socket) do
    game = params["game"]
    if game != "" do
      game = PortableGameNotationReader.encode_to_base64(game)
      {:noreply, push_patch(socket, to: ~p"/?game=#{game}")}
    else
      {:noreply, socket}
    end
  end

  def move(step, socket) do
    c = case rem(step, 2) do
      0 -> "dt"
      1 -> "lt"
    end
    pos = Integer.floor_div((step + if c == "dt", do: 0, else: 1), 2)
    if pos >= Enum.count(socket.assigns.game.moves) do
      {:noreply, assign(socket, game: %{socket.assigns.game | status: "ended"})}
    else
      move_pair =
        socket.assigns.game.moves
        |> Enum.drop(pos)
        |> Enum.take(1)
        |> List.flatten
      move = if Integer.is_odd(step), do: hd(move_pair), else: hd(tl(move_pair))
      socket = do_move(move_info(move, step), socket)
      {:noreply, assign(socket, game: %{socket.assigns.game | step: step, status: "in progress"})}
    end
  end

  def do_move(%{piece: "R", turn_color: c, ambiguity_file: af, row: row, col: col} = move_info, socket) do
    IO.puts "move rook #{inspect move_info}"
    board = socket.assigns.board
    piece = "#{String.downcase(move_info.piece)}#{c}"
    tomove = elem(hd(
      board
      |> Enum.filter(fn e -> elem(e, 1).piece == piece end)
      |> Enum.filter(fn e -> (if af != "", do: String.contains?(elem(e, 0), af), else: true) end)), 0)
    assign(socket,
      board: %{socket.assigns.board | "#{col}#{row}" => %{piece: piece}, tomove => %{piece: nil}},
      game: %Game{socket.assigns.game | captures: get_capture(%{row: row, col: col, piece: piece, socket: socket})})
  end

  def do_move(%{piece: "N", row: row, col: col, turn_color: c, ambiguity_file: af} = move_info, socket) do
    IO.puts "move knight #{inspect move_info}"
    piece = "#{String.downcase(move_info.piece)}#{c}"
    [colwi, rowwi] = [@columns |> Enum.with_index(), @rows |> Enum.with_index()]
    [a, b] = [elem(rowwi |> Enum.find(fn e -> elem(e, 0) == "#{row}" end), 1),
              elem(colwi |> Enum.find(fn e -> elem(e, 0) == "#{col}" end), 1)]
    possible_positions =
      [{a - 2, b - 1}, {a - 2, b + 1}, {a - 1, b - 2}, {a - 1, b + 2}, {a + 2, b - 1}, {a + 2, b + 1}, {a + 1, b - 2}, {a + 1, b + 2}]
      |> Enum.map(fn e ->
        c = elem(e, 1)
        r = elem(e, 0)
        if c < 0 || c > 7 || r < 0 || r > 7, do: "", else: "#{elem(Enum.at(colwi, c), 0)}#{elem(Enum.at(rowwi, r), 0)}"
      end)
      |> Enum.filter(fn e -> e != "" end)
      |> Enum.filter(fn e -> socket.assigns.board[e].piece != nil && socket.assigns.board[e].piece == piece end)
      |> Enum.filter(fn e -> (if af != "", do: String.contains?(e, af), else: true) end)
    tomove = hd(possible_positions)
    assign(socket,
      board: %{socket.assigns.board | "#{col}#{row}" => %{piece: piece}, tomove => %{piece: nil}},
      game: %Game{socket.assigns.game | captures: get_capture(%{row: row, col: col, piece: piece, socket: socket})})
  end

  def do_move(%{piece: "B", row: row, col: col, turn_color: c, color: color} = move_info, socket) do
    IO.puts "move bishop #{inspect move_info}"
    piece = "#{String.downcase(move_info.piece)}#{c}"
    tomove = hd(socket.assigns.board |> Enum.filter(fn kvp -> elem(kvp, 1).piece == piece && move_info(elem(kvp, 0), move_info.step).color == color end))
    assign(socket,
      board: %{socket.assigns.board | "#{col}#{row}" => %{piece: piece}, elem(tomove, 0) => %{piece: nil}},
      game: %Game{socket.assigns.game | captures: get_capture(%{row: row, col: col, piece: piece, socket: socket})})
  end

  def do_move(%{piece: "Q", row: row, col: col, turn_color: c} = move_info, socket) do
    IO.puts "move queen #{inspect move_info}"
    piece = "#{String.downcase(move_info.piece)}#{c}"
    tomove = hd(socket.assigns.board |> Enum.filter(fn kvp -> elem(kvp, 1).piece == piece end))
    assign(socket,
      board: %{socket.assigns.board | "#{col}#{row}" => %{piece: piece}, elem(tomove, 0) => %{piece: nil}},
      game: %Game{socket.assigns.game | captures: get_capture(%{row: row, col: col, piece: piece, socket: socket})})
  end

  def do_move(%{piece: "K", row: row, col: col, turn_color: c} = move_info, socket) do
    IO.puts "move king #{inspect move_info}"
    piece = "#{String.downcase(move_info.piece)}#{c}"
    tomove = hd(socket.assigns.board |> Enum.filter(fn kvp -> elem(kvp, 1).piece == piece end))
    assign(socket,
      board: %{socket.assigns.board | "#{col}#{row}" => %{piece: piece}, elem(tomove, 0) => %{piece: nil}},
      game: %Game{socket.assigns.game | captures: get_capture(%{row: row, col: col, piece: piece, socket: socket})})
  end

  def do_move(%{piece: "O", turn_color: c, castle: castle} = move_info, socket) do
    IO.puts "castle #{inspect move_info}"
    tomove = if castle == 2 do
      # castle queen side
      if c == "lt", do: {"a1", "c1", "b1", "e1"}, else: {"a8", "c8", "b8", "e8"}
    else
      # castle king side
      if c == "lt", do: {"h1", "f1", "g1", "e1"}, else: {"h8", "f8", "g8", "e8"}
    end
    assign(socket, board: %{
      socket.assigns.board |
        elem(tomove, 0) => %{piece: nil},
        elem(tomove, 1) => %{piece: "r#{c}"},
        elem(tomove, 2) => %{piece: "k#{c}"},
        elem(tomove, 3) => %{piece: nil}})
  end

  def do_move(%{piece: "P", row: row, col: col, turn_color: c} = move_info, socket) do
    IO.puts "move pawn #{inspect move_info} #{c}"
    board = socket.assigns.board
    piece = "#{String.downcase(move_info.piece)}#{c}"
    selected_key = if move_info.captures do
      source_column = String.at(move_info.move_string, 0);
      source_row = elem(Integer.parse(row), 0) + if c == "lt", do: -1, else: 1
      "#{source_column}#{source_row}"
    else
      pspots = (if c == "lt", do: [-1], else: [1]) # pawns for white move from bottom, while from black from top
        ++ (if (c == "lt" && row == "4"), do: [-2], else: []) # for row 4 for white we can move from back two squares
        ++ (if (c == "dt" && row == "5"), do: [2], else: []) # for row 5 for black we can move from back two squares
      possible_source_keys = pspots |> Enum.map(fn offset -> "#{col}#{elem(Integer.parse(row), 0) + offset}" end)
      hd(possible_source_keys |> Enum.filter(fn key -> Map.has_key?(board, key) && board[key].piece != nil end))
    end
    assign(socket,
      board: %{board | "#{col}#{row}" => %{piece: piece}, selected_key => %{piece: nil}},
      game: %Game{socket.assigns.game | captures: get_capture(%{row: row, col: col, piece: piece, socket: socket})})
  end

  defp get_capture(%{row: row, col: col, socket: socket}) do
    board = socket.assigns.board
    captures = socket.assigns.game.captures
    cell = board["#{col}#{row}"]
    IO.inspect(if cell.piece != nil, do: captures ++ [cell.piece], else: captures)
  end

  @doc """
  Extracts information from the move encoded as string like row, col and the color
  of the cell.

  ### Examples
      iex> move_info("Nf6", 0)
      %{check: false, color: "black_cell", row: "6", col: "f", piece: "N", captures: false, promotes: false, check_mate: false, promoted_piece: nil, ambiguity_file: "", castle: 0, move_string: "Nf6", step: 0, turn_color: "dt" }
      iex> move_info("Qe4+", 0)
      %{ check: true, color: "white_cell", row: "4", col: "e", piece: "Q", captures: false, promotes: false, check_mate: false, promoted_piece: nil, ambiguity_file: "", castle: 0, move_string: "Qe4+", step: 0, turn_color: "dt" }
      iex> move_info("Qxf4+", 0)
      %{ check: true, color: "black_cell", row: "4", col: "f", piece: "Q", captures: true, promotes: false, check_mate: false, promoted_piece: nil, ambiguity_file: "", castle: 0, move_string: "Qxf4+", step: 0, turn_color: "dt" }
      iex> move_info("b8=Q", 0)
      %{ check: false, color: "black_cell", row: "8", col: "b", piece: "P", captures: false, promotes: true, check_mate: false, promoted_piece: "Q", ambiguity_file: "", castle: 0, move_string: "b8=Q", step: 0, turn_color: "dt" }
      iex> move_info("Nge2", 0)
      %{ check: false, color: "white_cell", row: "2", col: "e", piece: "N", captures: false, promotes: false, check_mate: false, promoted_piece: nil, ambiguity_file: "g", castle: 0, move_string: "Nge2", step: 0, turn_color: "dt" }
  """
  def move_info(move, step) do
    c = case rem(step, 2) do
      0 -> "dt"
      1 -> "lt"
    end
    piece = piece(move)
    if piece == "O" do # castle?
      %{piece: piece, castle: (if String.contains?(move, "O-O-O"), do: 2, else: 1), turn_color: c, move_string: move, step: step}
    else
      move_info_without_castle(piece, move, c, step)
    end
  end

  defp move_info_without_castle(piece, move, c, step) do
    {cidx, ridx} = if String.at(move, 1) == "x" do
      {2, 3}
    else
      if piece != "P", do: {1, 2}, else: {0, 1}
    end
    row = String.at(move, ridx)
    [cidx, row, ambiguity_file] = if row in @rows, do: [cidx, row, ""], else: [ridx, String.at(move, ridx + 1), String.at(move, cidx)]
    col = String.at(move, cidx)
    color = black_or_white(col, row)
    promotes = String.contains?(move, "=");
    %{
      row: row,
      col: col,
      color: color,
      piece: piece,
      captures: String.contains?(move, "x"),
      promotes: promotes,
      check: String.contains?(move, "+"),
      check_mate: String.contains?(move, "#"),
      promoted_piece: (if promotes, do: String.at(move, String.length(move) - 1) |> then(fn lc -> (if lc == "+", do: String.length(move) - 2, else: lc) end), else: nil),
      ambiguity_file: ambiguity_file,
      castle: 0,
      turn_color: c,
      move_string: move,
      step: step
    }
  end

  defp piece(move) do
    piece = String.at(move, 0)
    if piece in ["Q", "K", "R", "N", "B", "O"], do: piece, else: "P"
  end

  @doc """
  This function determines if a cell should be black or white depending
  on it row 1-8 and column a-h. The cell on the bottom left corner must be black!

  ### Examples
      iex> black_or_white("1", "e")
      "black_cell"
  """
  def black_or_white(l, n) do
    ln = char_to_int l
    nn = char_to_int n
    case rem(ln + nn, 2) do
      1 -> "white_cell"
      0 -> "black_cell"
    end
  end

  defp columns(), do: @columns
  defp rows(), do: @rows

  defp char_to_int(c), do: %{"a" => 1, "b" => 2, "c" => 3, "d" => 4, "e" => 5, "f" => 6, "g" => 7, "h" => 8, "1" => 1, "2" => 2, "3" => 3, "4" => 4, "5" => 5, "6" => 6, "7" => 7, "8" => 8}["#{c}"]

  defp generate_initial_board() do
    board = for l <- @columns do
      for n <- @rows do
        {"#{l}#{n}", %{piece: nil}}
      end
    end
    |> List.flatten()
    |> Map.new

    # white
    # back row
    board = %{board | "a1" => %{piece: "rlt"}}
    board = %{board | "h1" => %{piece: "rlt"}}
    board = %{board | "b1" => %{piece: "nlt"}}
    board = %{board | "g1" => %{piece: "nlt"}}
    board = %{board | "c1" => %{piece: "blt"}}
    board = %{board | "f1" => %{piece: "blt"}}
    board = %{board | "d1" => %{piece: "qlt"}}
    board = %{board | "e1" => %{piece: "klt"}}
    # front row
    board = %{board | "a2" => %{piece: "plt"}}
    board = %{board | "h2" => %{piece: "plt"}}
    board = %{board | "b2" => %{piece: "plt"}}
    board = %{board | "g2" => %{piece: "plt"}}
    board = %{board | "c2" => %{piece: "plt"}}
    board = %{board | "f2" => %{piece: "plt"}}
    board = %{board | "d2" => %{piece: "plt"}}
    board = %{board | "e2" => %{piece: "plt"}}

    # black
    # back row
    board = %{board | "a8" => %{piece: "rdt"}}
    board = %{board | "h8" => %{piece: "rdt"}}
    board = %{board | "b8" => %{piece: "ndt"}}
    board = %{board | "g8" => %{piece: "ndt"}}
    board = %{board | "c8" => %{piece: "bdt"}}
    board = %{board | "f8" => %{piece: "bdt"}}
    board = %{board | "d8" => %{piece: "qdt"}}
    board = %{board | "e8" => %{piece: "kdt"}}
    # front row
    board = %{board | "a7" => %{piece: "pdt"}}
    board = %{board | "h7" => %{piece: "pdt"}}
    board = %{board | "b7" => %{piece: "pdt"}}
    board = %{board | "g7" => %{piece: "pdt"}}
    board = %{board | "c7" => %{piece: "pdt"}}
    board = %{board | "f7" => %{piece: "pdt"}}
    board = %{board | "d7" => %{piece: "pdt"}}
    board = %{board | "e7" => %{piece: "pdt"}}

    board
  end

end
