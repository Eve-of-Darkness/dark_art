defmodule DarkArt.World.Data do
  alias DarkArt.{Entity, World.Data}

  import Entity, only: [is_id?: 1]

  defstruct data: nil

  @type data :: :etc.tid()
  @type data_row :: {Entity.id(), Entity.t()}
  @type t :: %Data{data: data}

  @doc """
  Create new world data

  ## Examples

    iex> Data.new()
    #DarkArt.World.Data<size: 0>

  """
  @spec new() :: t
  def new do
    %Data{data: init_storage()}
  end

  @doc """
  Add entity to world; fails if entity already exists

  ## Examples

    iex> world = Data.new()
    iex> {:ok, world} = Data.add_entity(world, Entity.new([]))
    iex> world
    #DarkArt.World.Data<size: 1>

    iex> world = Data.new()
    iex> entity = Entity.new([])
    iex> {:ok, world} = Data.add_entity(world, entity)
    iex> Data.add_entity(world, entity)
    {:error, :already_exists}

  """
  @spec add_entity(t, Entity.t()) :: {:ok, t} | {:error, term}
  def add_entity(world = %Data{}, entity = %Entity{id: id}) when is_id?(id) do
    if insert_data(world.data, entity_to_row(entity)) do
      {:ok, world}
    else
      {:error, :already_exists}
    end
  end

  @doc """
  Get a single entity by id

  ## Examples

    iex> world = Data.new()
    iex> entity = Entity.new([])
    iex> Data.get_entity(world, entity.id)
    {:error, :not_found}

    iex> world = Data.new()
    iex> entity = Entity.new([])
    iex> {:ok, world} = Data.add_entity(world, entity)
    iex> {:ok, found} = Data.get_entity(world, entity.id)
    iex> found
    #DarkArt.Entity<[]>

  """
  @spec get_entity(t, Entity.id()) :: {:ok, Entity.t()} | {:error, term}
  def get_entity(world = %Data{}, id) when is_id?(id) do
    fetch_entity(world.data, id)
  end

  @doc """
  Update Entity in Data

  This can roughly be thought of as an upsert; as it blindly places
  it into the world overwriting the entity if it was already there.

  ## Examples

    iex> world = Data.new()
    iex> entity = Entity.new([])
    iex> {:ok, _} = Data.add_entity(world, entity)
    iex> Data.update_entity(world, Entity.add(entity, Nameable))
    iex> {:ok, updated} = Data.get_entity(world, entity.id)
    iex> updated
    #DarkArt.Entity<[Nameable]>

  """
  @spec update_entity(t, Entity.t()) :: t
  def update_entity(world, entity = %Entity{id: id}) when is_id?(id) do
    update_data(world.data, entity_to_row(entity))
    world
  end

  @doc """
  Get number of entities for world

  ## Examples

    iex> Data.new() |> Data.count()
    0

    iex> {:ok, world} = Data.new() |> Data.add_entity(Entity.new([]))
    iex> Data.count(world)
    1

  """
  @spec count(t) :: pos_integer
  def count(%Data{data: data}), do: row_count(data)

  ## Handy Implementations

  defimpl Inspect do
    def inspect(world, _opts) do
      import Inspect.Algebra

      concat([
        "#DarkArt.World.Data<size: #{Data.count(world)}>"
      ])
    end
  end

  ## Private Functions

  @spec row_count(data) :: pos_integer
  defp row_count(data) do
    data |> :ets.info() |> Keyword.get(:size, 0)
  end

  @spec entity_to_row(Entity.t()) :: data_row
  defp entity_to_row(entity = %Entity{id: id}) do
    {id, entity}
  end

  @spec insert_data(data, data_row) :: boolean
  defp insert_data(data, row) do
    :ets.insert_new(data, row)
  end

  @spec fetch_entity(data, Entity.id()) :: {:ok, Entity.t()} | {:error, term}
  defp fetch_entity(data, id) do
    {:ok, :ets.lookup_element(data, id, 2)}
  rescue
    ArgumentError -> {:error, :not_found}
  end

  @spec update_data(data, data_row) :: boolean
  defp update_data(data, row) do
    :ets.insert(data, row)
  end

  @spec init_storage() :: data
  defp init_storage do
    :ets.new(
      Data,
      [
        :set,
        :public,
        {:read_concurrency, true},
        {:write_concurrency, true}
      ]
    )
  end
end
