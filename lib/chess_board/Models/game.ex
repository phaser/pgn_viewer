defmodule ChessBoard.Models.Game do
  defstruct properties: %{}, moves: [], step: 0, captures: [], result: "", status: "not started"
end
