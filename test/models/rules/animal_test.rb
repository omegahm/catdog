require "test_helper"

module Rules
  class AnimalTest < ActiveSupport::TestCase
    include RulesHelper

    test "a head meeting a tail directly is legal and makes a complete animal of length 2" do
      start = board([ 3, 3 ] => "dog head e")

      assert start.legal?("dog tail w", "front", 0, [ 3, 4 ])
      animal = start.place([ 3, 4 ], "dog tail w", "front", 0).animals.sole
      assert animal.complete?
      assert_equal 2, animal.length
      assert_equal "dog", animal.species
    end

    test "an animal may not get 2 heads" do
      assert_not board([ 3, 3 ] => "dog head e").legal?("dog head w", "front", 0, [ 3, 4 ])
      assert_not board([ 3, 3 ] => "dog head e", [ 3, 4 ] => "dog straight w e").legal?("dog head w", "front", 0, [ 3, 5 ])
    end

    test "an animal may not get 2 tails" do
      assert_not board([ 3, 3 ] => "cat tail e").legal?("cat tail w", "front", 0, [ 3, 4 ])
      assert_not board([ 3, 3 ] => "cat tail e", [ 3, 4 ] => "cat turn w s").legal?("cat tail n", "front", 0, [ 4, 4 ])
    end

    test "an animal may not close into a loop with no head and no tail" do
      start = board([ 3, 3 ] => "dog turn e s", [ 3, 4 ] => "dog turn w s", [ 4, 3 ] => "dog turn n e")

      assert_not start.legal?("dog turn n w", "front", 0, [ 4, 4 ])
      assert_equal [ 3 ], start.animals.map(&:length)
    end

    test "an animal is complete with exactly 1 head and 1 tail and counts every part" do
      start = board([ 3, 2 ] => "cat tail e", [ 3, 3 ] => "cat straight w e", [ 3, 4 ] => "cat turn w s")
      open = start.animals.sole

      assert_not open.complete?
      assert_equal 3, open.length

      complete = start.place([ 4, 4 ], "cat head n", "front", 0).animals.sole
      assert complete.complete?
      assert_equal 4, complete.length
    end

    test "crossing parts do not connect" do
      animals = board([ 3, 3 ] => "dog straight w e + dog straight n s").animals

      assert_equal [ 1, 1 ], animals.map(&:length)
    end

    test "an animal that passes through a tile twice counts both parts" do
      start = board(
        [ 3, 2 ] => "dog tail e",
        [ 3, 3 ] => "dog straight w e + dog straight n s",
        [ 3, 4 ] => "dog turn w n",
        [ 2, 4 ] => "dog turn s w",
        [ 2, 3 ] => "dog turn e s"
      )

      assert start.legal?("dog head n", "front", 0, [ 4, 3 ])
      animal = start.place([ 4, 3 ], "dog head n", "front", 0).animals.sole
      assert animal.complete?
      assert_equal 7, animal.length
      assert_equal 6, animal.cells.size
    end

    test "a crossing can carry both species" do
      animals = board([ 3, 2 ] => "cat tail e", [ 3, 3 ] => "cat straight w e + dog straight n s", [ 2, 3 ] => "dog head s").animals

      assert_equal({ "cat" => [ 2 ], "dog" => [ 2 ] }, animals.group_by(&:species).transform_values { it.map(&:length) })
      assert animals.none?(&:complete?)
    end

    test "animals at a cell lists each animal once" do
      looped = board(
        [ 3, 2 ] => "dog tail e",
        [ 3, 3 ] => "dog straight w e + dog straight n s",
        [ 3, 4 ] => "dog turn w n",
        [ 2, 4 ] => "dog turn s w",
        [ 2, 3 ] => "dog turn e s"
      )

      assert_equal 1, looped.animals_at([ 3, 3 ]).size
    end
  end
end
