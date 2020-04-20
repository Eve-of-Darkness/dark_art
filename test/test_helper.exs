defmodule Nameable do
  defstruct name: ""
end

defmodule Living do
  defstruct max: 100, current: 100, alive: true

  def kill(living) do
    if living.alive do
      {:ok, %{living | current: 0, alive: false}}
    else
      :ignore
    end
  end
end

defmodule Moveable do
  defstruct cord: {0, 0, 0}, vector: {0, 0, 0}, velocity: 0
end

ExUnit.start()
