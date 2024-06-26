defmodule DocTest do
  use ExUnit.Case
  import ChessBoard.PortableGameNotationReader
  import ChessBoardWeb.ChessBoardLive

  doctest ChessBoard.PortableGameNotationReader
  doctest ChessBoardWeb.ChessBoardLive
end
