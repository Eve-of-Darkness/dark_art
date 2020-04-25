defmodule DarkArt.World.DataTest do
  use ExUnit.Case, async: true
  alias DarkArt.{Entity, World.Data}
  doctest Data

  setup do
    {:ok, world: Data.new()}
  end

  describe "add_entity/2" do
    test "you can add an entity", %{world: world} do
      entity = Entity.new([])
      assert {:ok, _} = Data.add_entity(world, entity)
    end

    test "fails to add existing entity", %{world: world} do
      entity = Entity.new([])
      assert {:ok, _} = Data.add_entity(world, entity)
      assert {:error, :already_exists} = Data.add_entity(world, entity)
    end
  end
end
