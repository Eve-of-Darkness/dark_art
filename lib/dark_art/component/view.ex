defmodule DarkArt.Component.View do
  alias DarkArt.{Component.View, Entity}

  @moduledoc """
  Provides a quick way to access and identify what entities have
  a certain component makeup.
  """

  defstruct id: nil, view: %{}

  @type t :: %View{
          id: atom,
          view: %{module => []}
        }

  @doc """
  Create a new view

  Given any number of components this will create a new view
  that will determine if an entity has the provided composition.

  ## Examples

    iex> View.new([Moveable])
    #DarkArt.Component.View<[Moveable]>

  """
  @spec new([module]) :: t
  def new(components) when is_list(components) do
    %View{
      id: :"#{components |> Enum.sort() |> Enum.join(".")}",
      view: Map.new(components, &{&1, []})
    }
  end

  @doc """
  Determine if entity has components of view

  This delegates to `Entity.has_components?/2` with an already
  optimized map-key comparison structure that otherwise needs to
  be build up dynamically when calling that function directly with
  a list of component modules.

  ## Examples

    iex> view = View.new([Moveable])
    iex> entity = Entity.new([Moveable, Living])
    iex> View.has_components?(view, entity)
    true

    iex> view = View.new([Moveable, Living])
    iex> entity = Entity.new([Nameable])
    iex> View.has_components?(view, entity)
    false

  """
  @spec has_components?(t, Entity.t()) :: boolean
  def has_components?(%View{view: view}, entity = %Entity{}) do
    Entity.has_components?(entity, view)
  end

  ## Handy Implementations

  defimpl Inspect do
    def inspect(%{view: view}, opts) do
      import Inspect.Algebra

      concat([
        "#DarkArt.Component.View<",
        to_doc(Map.keys(view), opts),
        ">"
      ])
    end
  end
end
