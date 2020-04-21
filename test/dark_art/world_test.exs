defmodule DarkArt.WorldTest do
  use ExUnit.Case, async: true
  alias DarkArt.{Entity, World}
  doctest World

  setup do
    {:ok, world: World.new()}
  end

  describe "add_entity/2" do
    test "you can add an entity", %{world: world} do
      entity = Entity.new([])
      assert {:ok, _} = World.add_entity(world, entity)
    end

    test "fails to add existing entity", %{world: world} do
      entity = Entity.new([])
      assert {:ok, _} = World.add_entity(world, entity)
      assert {:error, :already_exists} = World.add_entity(world, entity)
    end
  end
end
