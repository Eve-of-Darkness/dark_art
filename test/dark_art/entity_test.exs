defmodule DarkArt.EntityTest do
  use ExUnit.Case, async: true
  alias DarkArt.Entity
  doctest Entity

  describe "#new/1" do
    test "works with just the module" do
      entity = Entity.new([Nameable])
      assert %Entity{} = entity
      assert is_reference(entity.id)
      assert entity.components[Nameable] == %Nameable{}
    end

    test "works with a struct" do
      nameable = %Nameable{name: "ben"}
      entity = Entity.new([nameable])
      assert %Entity{} = entity
      assert is_reference(entity.id)
      assert entity.components[Nameable] == nameable
    end

    test "works with struct and a module" do
      nameable = %Nameable{name: "ben"}
      entity = Entity.new([nameable, Living])
      assert entity.components[Nameable] == nameable
      assert entity.components[Living] == %Living{}
    end
  end

  describe "#get/2" do
    setup do
      {:ok, entity: Entity.new([Living])}
    end

    test "retrieves a component if it is part of the entity", context do
      assert {:ok, living} = Entity.get(context.entity, Living)
      assert living == %Living{}
    end

    test "retruns :error if component isn't found in entity", context do
      assert :error = Entity.get(context.entity, Nameable)
    end
  end

  describe "#add/2" do
    setup do
      {:ok, entity: Entity.new([Living])}
    end

    test "adds a new component by module", context do
      entity = Entity.add(context.entity, Nameable)
      assert entity.components[Nameable] == %Nameable{}
      assert entity.components[Living] == %Living{}
    end

    test "adds a new component by struct", context do
      nameable = %Nameable{name: "ben"}
      entity = Entity.add(context.entity, nameable)
      assert entity.components[Living] == %Living{}
      assert entity.components[Nameable] == nameable
    end

    test "adds multiple components at once", context do
      nameable = %Nameable{name: "ben"}
      entity = Entity.add(context.entity, [nameable, Moveable])
      assert entity.components[Living] == %Living{}
      assert entity.components[Nameable] == nameable
      assert entity.components[Moveable] == %Moveable{}
    end
  end

  describe "#update/3" do
    setup do
      {:ok, entity: Entity.new([Living])}
    end

    test "it errors for a component the entity does not have", %{entity: entity} do
      assert :error == Entity.update(entity, Nameable, &{:ok, %{&1 | name: "gg"}})
    end

    test "it will update an entity with a found component", %{entity: entity} do
      assert {:ok, updated} =
               Entity.update(entity, Living, &{:ok, %{&1 | current: 0, alive: false}})

      assert updated.components[Living].current == 0
      refute updated.components[Living].alive
    end

    test "does nothing if update returns :ignore", %{entity: entity} do
      assert {:ok, not_updated} =
               Entity.update(entity, Living, fn living = %{current: current, max: max} ->
                 cond do
                   current == max -> :ignore
                   current > max -> {:ok, %{living | current: current - 1}}
                   current < max -> {:ok, %{living | current: current + 1}}
                 end
               end)

      assert entity == not_updated
    end

    test "given a function with an arity of two", %{entity: entity} do
      {:ok, updated} =
        entity
        |> Entity.add(%Nameable{name: "ben"})
        |> Entity.update(Nameable, fn nameable, entity ->
          {:ok, living} = Entity.get(entity, Living)
          status = if living.alive, do: "alive", else: "dead"
          {:ok, %{nameable | name: "#{nameable.name} - (#{status})"}}
        end)

      assert updated.components[Nameable].name == "ben - (alive)"
    end
  end

  describe "remove/2" do
    setup do
      {:ok, entity: Entity.new([Living, Nameable, Moveable])}
    end

    test "removing a single component", %{entity: entity} do
      updated = Entity.remove(entity, Living)
      assert entity.components[Living]
      refute updated.components[Living]
    end

    test "removing several components", %{entity: entity} do
      updated = Entity.remove(entity, [Nameable, Moveable])
      assert [Living] == Map.keys(updated.components)
    end
  end
end
