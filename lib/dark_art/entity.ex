defmodule DarkArt.Entity do
  alias DarkArt.Entity

  @moduledoc """
  DarkArt.Entity is the container for any number of specific components.  Some
  ECS frameworks require a more specific component type; however, for this
  a component is simply a struct.

  *One caveat of this is you may only have one of each component for an entity*

  The decision behind this is to have faster component lookups that do not
  rely on lists to hold them.  If you need this functionality and can think of
  a performant way to handle it open a PR or Issues and let's talk about it.
  """

  @doc """
  Simple guard to check if the id of an entity is an id without needing to
  expose the actual underlying type of the id.  The id may change in the future
  and if so we want to keep it contained as much as possible.
  """
  defguard is_id?(id) when is_reference(id)

  defstruct id: nil,
            components: %{}

  @type id :: reference
  @type components :: %{module => struct}
  @type component :: struct | module
  @type t :: %Entity{
          id: id,
          components: components
        }
  @type update_result :: {:ok, struct} | :ignore | :remove | {:error, term}

  @doc """
  Creates an entity with a provided list of components, in this case the
  components may either be an actual struct or the module of the struct.
  If the module of the struct is given it will be expanded to the default
  state of that struct.

  ## Examples

    iex> Entity.new([Nameable])
    #DarkArt.Entity<[Nameable]>

    iex> some_name = %Nameable{name: "fred"}
    iex> Entity.new([some_name])
    #DarkArt.Entity<[Nameable]>

    iex> time = DateTime.utc_now()
    iex> name = %Nameable{name: "tim"}
    iex> Entity.new([time, name])
    #DarkArt.Entity<[DateTime, Nameable]>

    iex> Entity.new([])
    #DarkArt.Entity<[]>

  """
  @spec new([component]) :: t
  def new(components) do
    %Entity{
      id: make_ref(),
      components: Map.new(components, &struct_or_module_to_pair/1)
    }
  end

  @doc """
  Retrieves the component if found with `{:ok, component}` or `:error` if not

  ## Examples

    iex> entity = Entity.new([])
    iex> Entity.get(entity, Nameable)
    :error

    iex> entity = Entity.new([Nameable])
    iex> Entity.get(entity, Nameable)
    {:ok, %Nameable{name: ""}}

  """
  @spec get(t, module) :: {:ok, struct} | :error
  def get(%Entity{components: components}, component) do
    Map.fetch(components, component)
  end

  @doc """
  Adds one or any number of components to the entity.  This works similar
  to new where the components may be structs or just the module names for
  the structs.

  *No checking is done to determine if component already exists and will
  be overwritten*

  ## Examples

    iex> entity = Entity.new([Nameable])
    iex> Entity.add(entity, DateTime.utc_now())
    #DarkArt.Entity<[DateTime, Nameable]>

    iex> entity = Entity.new([Nameable])
    iex> Entity.add(entity, [Living, Moveable])
    #DarkArt.Entity<[Living, Moveable, Nameable]>

    iex> entity = Entity.new([%Nameable{name: "ben"}])
    iex> entity = Entity.add(entity, %Nameable{name: "ben of ft wayne"})
    iex> Entity.get(entity, Nameable)
    {:ok, %Nameable{name: "ben of ft wayne"}}

  """
  @spec add(t, component | [component]) :: t
  def add(entity = %Entity{}, components) when is_list(components) do
    Enum.reduce(components, entity, &add(&2, &1))
  end

  def add(entity = %Entity{components: components}, struct_or_module) do
    {module, data} = struct_or_module_to_pair(struct_or_module)
    %{entity | components: Map.put(components, module, data)}
  end

  @doc """
  Remove any number of components from entity

  If your entity has a short term component that is dynamically
  added at some point and then must be removed; this is the function
  to do so.  Unlike add, remove only works with struct modules.

  Either a single or list of components can be given to remove. If
  any of the provided components are not found they are simply ignored.

  ## Examples

    iex> entity = Entity.new([Nameable, Living, DateTime.utc_now()])
    iex> Entity.remove(entity, DateTime)
    #DarkArt.Entity<[Living, Nameable]>

    iex> entity = Entity.new([Nameable, Living, Moveable])
    iex> Entity.remove(entity, [Living, Moveable, DateTime])
    #DarkArt.Entity<[Nameable]>

  """
  @spec remove(t, module | [module]) :: t
  def remove(entity = %Entity{}, modules) when is_list(modules) do
    removed = Map.drop(entity.components, modules)
    %{entity | components: removed}
  end

  def remove(entity = %Entity{}, module) do
    removed = Map.delete(entity.components, module)
    %{entity | components: removed}
  end

  @doc ~S"""
  Update entity component with a given function

  This is meant as a way to cut down on the amount of boilerplate code
  you would end up writing to update components for an entity.  You
  provide the entity, the module of the component you want to udpate
  and either a single or double arity function.

  The provided function retrieves either just the component if it's a
  single arity function or the component and entire entity respectively
  if it's a double arity function.

  The provided function must return `{:ok, struct}` for an update.  It
  may also optionally return `:ignore`, in which case the entity is
  returned without any update.  If the result of the update is that the
  component should be removed the function can return `:remove`.

  ## Examples

    iex> kill = &{:ok, %{&1 | alive: false, current: 0}}
    iex> entity = Entity.new([Living])
    iex> {:ok, entity} = Entity.update(entity, Living, kill)
    iex> Entity.get(entity, Living)
    {:ok, %Living{max: 100, current: 0, alive: false}}

    iex> living_status = fn nameable, entity ->
    ...>   {:ok, %Living{alive: alive}} = Entity.get(entity, Living)
    ...>   status = if alive, do: "alive", else: "dead"
    ...>   {:ok, %{nameable | name: "#{nameable.name} - (#{status})"}}
    ...> end
    iex> entity = Entity.new([Living, %Nameable{name: "Ben"}])
    iex> {:ok, entity} = Entity.update(entity, Nameable, living_status)
    iex> Entity.get(entity, Nameable)
    {:ok, %Nameable{name: "Ben - (alive)"}}

    iex> imortal = fn _living, entity ->
    ...>   {:ok, %Nameable{name: name}} = Entity.get(entity, Nameable)
    ...>   if name == "ben", do: :remove, else: :ignore
    ...> end
    iex> entity = Entity.new([%Nameable{name: "ben"}, Living])
    iex> {:ok, updated} = Entity.update(entity, Living, imortal)
    iex> updated
    #DarkArt.Entity<[Nameable]>

  """
  @spec update(
          Entity.t(),
          module,
          (struct -> update_result)
          | (struct, Entity.t() -> update_result)
        ) ::
          {:ok, Entity.t()} | :error | {:error, term}
  def update(entity, component, fun) when is_function(fun) do
    with {:ok, data} <- get(entity, component) do
      case do_component_update(fun, data, entity) do
        {:ok, updated} ->
          {:ok, add(entity, updated)}

        :ignore ->
          {:ok, entity}

        :remove ->
          {:ok, remove(entity, component)}
      end
    end
  end

  @doc """
  Determine if entity holds a combination of components

  This is usefull if you need to check a set of entities for an
  edge case of some other components they may contain for further
  processing.

  ## Examples

    iex> entity = Entity.new([Nameable, Moveable])
    iex> Entity.has_components?(entity, [Nameable, Moveable])
    true
    iex> Entity.has_components?(entity, [Nameable])
    true
    iex> Entity.has_components?(entity, [])
    true
    iex> Entity.has_components?(entity, [Nameable, Living])
    false

    iex> entity = Entity.new([])
    iex> Entity.has_components?(entity, [])
    true
    iex> Entity.has_components?(entity, [Nameable])
    false

  """
  @spec has_components?(Entity.t(), [module] | %{module => []}) :: boolean
  def has_components?(entity = %Entity{}, comp) when is_list(comp) do
    has_components?(entity, Map.new(comp, &{&1, []}))
  end

  def has_components?(%Entity{components: entity}, map) when is_map(map) do
    map_size(entity) >= map_size(map) and all_in?(map, entity)
  end

  ## Handy Implementations

  defimpl Inspect do
    def inspect(%{components: components}, opts) do
      import Inspect.Algebra

      concat([
        "#DarkArt.Entity<",
        to_doc(Map.keys(components), opts),
        ">"
      ])
    end
  end

  ## Private Functions

  defp struct_or_module_to_pair(data = %struct{}), do: {struct, data}
  defp struct_or_module_to_pair(module), do: {module, struct(module)}

  defp do_component_update(fun, data, _) when is_function(fun, 1), do: fun.(data)
  defp do_component_update(fun, data, entity) when is_function(fun, 2), do: fun.(data, entity)

  # Directly lifted from MapSet because I don't want to bring in
  # everything from MapSet just to do this subset check
  defp all_in?(:none, _), do: true

  defp all_in?({key, _val, iter}, map2) do
    :erlang.is_map_key(key, map2) and all_in?(:maps.next(iter), map2)
  end

  defp all_in?(map1, map2) when is_map(map1) and is_map(map2) do
    map1
    |> :maps.iterator()
    |> :maps.next()
    |> all_in?(map2)
  end
end
