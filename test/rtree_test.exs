defmodule RTreeTest do
  use ExUnit.Case
  doctest RTree

  describe "RTree" do
    test "#insert basic" do
      node = %RNode{limit: 2}
      object = %RObject{x: 1, y: 1, data: "data"}

      assert RTree.insert(node, object) == %RNode{
               bounding: %RBoundingBox{min_x: 1, min_y: 1, max_x: 1, max_y: 1, area: 0},
               children: nil,
               limit: 2,
               objects: [%RObject{x: 1, y: 1, data: "data"}]
             }
    end

    test "#insert insert more than the limit" do
      node = %RNode{limit: 2}
      objects = for i <- 1..3, do: %RObject{x: i, y: i, data: "data"}
      node = Enum.reduce(objects, node, fn object, acc -> RTree.insert(acc, object) end)

      assert RTree.insert(node, %RObject{x: 4, y: 4, data: "data"}) == %RNode{
               bounding: %RBoundingBox{min_x: 1, min_y: 1, max_x: 4, max_y: 4, area: 9},
               children: %{
                 left: %RNode{
                   bounding: %RBoundingBox{min_x: 1, min_y: 1, max_x: 2, max_y: 2, area: 1},
                   children: nil,
                   limit: 2,
                   objects: [
                     %RObject{x: 1, y: 1, data: "data"},
                     %RObject{x: 2, y: 2, data: "data"}
                   ]
                 },
                 right: %RNode{
                   bounding: %RBoundingBox{min_x: 3, min_y: 3, max_x: 4, max_y: 4, area: 1},
                   children: nil,
                   limit: 2,
                   objects: [
                     %RObject{x: 3, y: 3, data: "data"},
                     %RObject{x: 4, y: 4, data: "data"}
                   ]
                 }
               },
               limit: 2,
               objects: []
             }
    end

    test "#insert with a limit at 4" do
      limit = 4
      node = %RNode{limit: limit}
      objects = for i <- 1..8, do: %RObject{x: i, y: i, data: "data"}
      node = Enum.reduce(objects, node, fn object, acc -> RTree.insert(acc, object) end)

      assert RTree.insert(node, %RObject{x: 9, y: 9, data: "data"}) == %RNode{
               bounding: %RBoundingBox{area: 64, max_x: 9, max_y: 9, min_x: 1, min_y: 1},
               children: %{
                 left: %RNode{
                   bounding: %RBoundingBox{area: 4, max_x: 3, max_y: 3, min_x: 1, min_y: 1},
                   children: nil,
                   limit: 4,
                   objects: [
                     %RObject{x: 1, y: 1, data: "data"},
                     %RObject{x: 2, y: 2, data: "data"},
                     %RObject{x: 3, y: 3, data: "data"}
                   ]
                 },
                 right: %RNode{
                   bounding: %RBoundingBox{area: 25, max_x: 9, max_y: 9, min_x: 4, min_y: 4},
                   children: %{
                     left: %RNode{
                       bounding: %RBoundingBox{area: 4, max_x: 6, max_y: 6, min_x: 4, min_y: 4},
                       children: nil,
                       limit: 4,
                       objects: [
                         %RObject{x: 4, y: 4, data: "data"},
                         %RObject{data: "data", x: 5, y: 5},
                         %RObject{data: "data", x: 6, y: 6}
                       ]
                     },
                     right: %RNode{
                       bounding: %RBoundingBox{area: 4, max_x: 9, max_y: 9, min_x: 7, min_y: 7},
                       children: nil,
                       limit: 4,
                       objects: [
                         %RObject{x: 8, y: 8, data: "data"},
                         %RObject{x: 7, y: 7, data: "data"},
                         %RObject{x: 9, y: 9, data: "data"}
                       ]
                     }
                   },
                   limit: 4,
                   objects: []
                 }
               },
               limit: 4,
               objects: []
             }
    end

    test "#insert insert two time more than the limit" do
      node = %RNode{limit: 2}
      objects = for i <- 1..5, do: %RObject{x: i, y: i, data: "data"}
      node = Enum.reduce(objects, node, fn object, acc -> RTree.insert(acc, object) end)

      assert RTree.insert(node, %RObject{x: 6, y: 6, data: "data"}) == %RNode{
               bounding: %RBoundingBox{area: 25, max_x: 6, max_y: 6, min_x: 1, min_y: 1},
               children: %{
                 left: %RNode{
                   bounding: %RBoundingBox{min_x: 1, min_y: 1, max_x: 2, max_y: 2, area: 1},
                   children: nil,
                   limit: 2,
                   objects: [
                     %RObject{x: 1, y: 1, data: "data"},
                     %RObject{x: 2, y: 2, data: "data"}
                   ]
                 },
                 right: %RNode{
                   bounding: %RBoundingBox{min_x: 3, min_y: 3, max_x: 6, max_y: 6, area: 9},
                   children: %{
                     left: %RNode{
                       bounding: %RBoundingBox{min_x: 3, min_y: 3, max_x: 4, max_y: 4, area: 1},
                       children: nil,
                       limit: 2,
                       objects: [
                         %RObject{x: 3, y: 3, data: "data"},
                         %RObject{x: 4, y: 4, data: "data"}
                       ]
                     },
                     right: %RNode{
                       bounding: %RBoundingBox{min_x: 5, min_y: 5, max_x: 6, max_y: 6, area: 1},
                       children: nil,
                       limit: 2,
                       objects: [
                         %RObject{x: 5, y: 5, data: "data"},
                         %RObject{x: 6, y: 6, data: "data"}
                       ]
                     }
                   },
                   limit: 2,
                   objects: []
                 }
               },
               limit: 2,
               objects: []
             }
    end

    test "#search should find node if exist" do
      node = %RNode{limit: 2}
      objects = for i <- 1..5, do: %RObject{x: i, y: i, data: "data"}
      node = Enum.reduce(objects, node, fn object, acc -> RTree.insert(acc, object) end)

      assert RTree.search(node, %{x: 3, y: 3}) == {:ok, %RObject{x: 3, y: 3, data: "data"}}
    end

    test "#search when not exist return not found" do
      node = %RNode{limit: 2}
      objects = for i <- 1..5, do: %RObject{x: i, y: i, data: "data"}
      node = Enum.reduce(objects, node, fn object, acc -> RTree.insert(acc, object) end)

      assert RTree.search(node, %{x: 6, y: 6}) == {:error, "Not found"}
    end

    test "#search when objects in boundary return them" do
      node = %RNode{limit: 2}
      objects = for i <- 1..5, do: %RObject{x: i, y: i, data: "data"}
      node = Enum.reduce(objects, node, fn object, acc -> RTree.insert(acc, object) end)

      assert RTree.search(node, %RBoundingBox{min_x: 2, min_y: 2, max_x: 5, max_y: 5, area: 9}) ==
               [
                 %RObject{x: 2, y: 2, data: "data"},
                 %RObject{x: 3, y: 3, data: "data"},
                 %RObject{x: 4, y: 4, data: "data"},
                 %RObject{x: 5, y: 5, data: "data"}
               ]
    end

    test "#search when objects not in boundary return empty list" do
      node = %RNode{limit: 2}
      objects = for i <- 1..5, do: %RObject{x: i, y: i, data: "data"}
      node = Enum.reduce(objects, node, fn object, acc -> RTree.insert(acc, object) end)

      assert RTree.search(node, %RBoundingBox{min_x: 6, min_y: 6, max_x: 7, max_y: 7, area: 1}) ==
               []
    end

    test "#overlaps? no overlaping box" do
      box1 = %RBoundingBox{min_x: 1, min_y: 1, max_x: 2, max_y: 2, area: 1}
      box2 = %RBoundingBox{min_x: 3, min_y: 3, max_x: 4, max_y: 4, area: 1}

      assert RBoundingBox.overlaps?(box1, box2) == false
    end

    test "#overlaps? overlaping box" do
      box1 = %RBoundingBox{min_x: 1, min_y: 1, max_x: 2, max_y: 2, area: 1}
      box2 = %RBoundingBox{min_x: 2, min_y: 2, max_x: 4, max_y: 4, area: 4}

      assert RBoundingBox.overlaps?(box1, box2) == true
    end

    test "#overlaps? overlaping boxes but with any corner inside the other" do
      box1 = %RBoundingBox{min_x: 1, min_y: 2, max_x: 5, max_y: 3, area: 1}
      box2 = %RBoundingBox{min_x: 2, min_y: 1, max_x: 4, max_y: 4, area: 4}

      assert RBoundingBox.overlaps?(box1, box2) == true
    end
  end
end
