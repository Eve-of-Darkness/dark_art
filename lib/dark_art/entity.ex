defmodule DarkArt.Entity do
  alias DarkArt.Entity

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

  @spec new([component]) :: t
  def new(components) do
    %Entity{
      id: make_ref(),
      components: Map.new(components, &struct_or_module_to_pair/1)
    }
  end

  @spec get(t, module) :: {:ok, struct} | :error
  def get(%Entity{components: components}, component) do
    Map.fetch(components, component)
  end

  @spec add(t, component | [component]) :: t
  def add(entity = %Entity{}, components) when is_list(components) do
    Enum.reduce(components, entity, &add(&2, &1))
  end

  def add(entity = %Entity{components: components}, struct_or_module) do
    {module, data} = struct_or_module_to_pair(struct_or_module)
    %{entity | components: Map.put(components, module, data)}
  end

  ## Private Functions

  defp struct_or_module_to_pair(data = %struct{}), do: {struct, data}
  defp struct_or_module_to_pair(module), do: {module, struct(module)}
end
