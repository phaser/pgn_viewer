defmodule ChessBoard.Repo do
  use Ecto.Repo,
    otp_app: :chess_board,
    adapter: Ecto.Adapters.SQLite3
end
