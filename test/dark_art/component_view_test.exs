defmodule DarkArt.ComponentViewTest do
  use ExUnit.Case, async: true
  alias DarkArt.{ComponentView, Entity}
  doctest ComponentView

  describe "new/1" do
    test "works with an empty list" do
      view = ComponentView.new([])
      assert view.id == :""
      assert view.view == %{}
    end

    test "the id is predictable" do
      assert ComponentView.new([Nameable, Moveable]).id ==
               Moveable.Elixir.Nameable

      assert ComponentView.new([Moveable, Nameable, Living]).id ==
               Living.Elixir.Moveable.Elixir.Nameable
    end
  end
end
