defmodule DarkArt.Component.ViewTest do
  use ExUnit.Case, async: true
  alias DarkArt.{Component.View, Entity}
  doctest View

  describe "new/1" do
    test "works with an empty list" do
      view = View.new([])
      assert view.id == :""
      assert view.view == %{}
    end

    test "the id is predictable" do
      assert View.new([Nameable, Moveable]).id ==
               Moveable.Elixir.Nameable

      assert View.new([Moveable, Nameable, Living]).id ==
               Living.Elixir.Moveable.Elixir.Nameable
    end
  end
end
