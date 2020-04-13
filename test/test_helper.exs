defmodule Nameable do
  defstruct name: ""
end

defmodule Living do
  defstruct max: 100, current: 100, alive: true
end

defmodule Moveable do
  defstruct cord: {0, 0, 0}, vector: {0, 0, 0}, velocity: 0
end

ExUnit.start()
