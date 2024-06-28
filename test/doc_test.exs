defmodule DocTest do
  use ExUnit.Case
  import ChessBoardWeb.ChessBoardLive

  doctest ChessBoard.PortableGameNotationReader
  doctest ChessBoardWeb.ChessBoardLive
end
