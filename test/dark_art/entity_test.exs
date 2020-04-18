defmodule DarkArt.EntityTest do
  use ExUnit.Case, async: true
  alias DarkArt.Entity

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

  describe "#component_tags/1" do
    test "returns an empty list for a blank entity" do
      assert [] == Entity.component_tags(Entity.new([]))
    end

    test "returns a list with the correct component modules" do
      nameable = %Nameable{name: "ben"}
      datetime = DateTime.utc_now()
      entity = Entity.new([nameable, datetime])

      assert [DateTime, Nameable] = Entity.component_tags(entity)
    end
  end
end
