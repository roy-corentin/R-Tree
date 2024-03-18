defmodule RTreeTest do
  use ExUnit.Case
  doctest RTree

  describe "RTree" do
    test "#insert basic" do
      node = %RNode{}
      object = %RObject{x: 1, y: 1, data: "data"}

      assert RTree.insert(node, object) == %RNode{
               bounding: %RBoundingBox{min_x: 1, min_y: 1, max_x: 1, max_y: 1, area: 0},
               children: nil,
               objects: [%RObject{x: 1, y: 1, data: "data"}]
             }
    end

    test "#insert insert more than @m objects" do
      node = %RNode{}
      objects = for i <- 1..3, do: %RObject{x: i, y: i, data: "data"}
      node = Enum.reduce(objects, node, fn object, acc -> RTree.insert(acc, object) end)

      assert RTree.insert(node, %RObject{x: 4, y: 4, data: "data"}) == %RNode{
               bounding: %RBoundingBox{min_x: 1, min_y: 1, max_x: 4, max_y: 4, area: 9},
               children: %{
                 left: %RNode{
                   bounding: %RBoundingBox{min_x: 1, min_y: 1, max_x: 2, max_y: 2, area: 1},
                   children: nil,
                   objects: [
                     %RObject{x: 1, y: 1, data: "data"},
                     %RObject{x: 2, y: 2, data: "data"}
                   ]
                 },
                 right: %RNode{
                   bounding: %RBoundingBox{min_x: 3, min_y: 3, max_x: 4, max_y: 4, area: 1},
                   children: nil,
                   objects: [
                     %RObject{x: 3, y: 3, data: "data"},
                     %RObject{x: 4, y: 4, data: "data"}
                   ]
                 }
               },
               objects: []
             }
    end

    test "#insert insert two time more than @m objects" do
      node = %RNode{}
      objects = for i <- 1..5, do: %RObject{x: i, y: i, data: "data"}
      node = Enum.reduce(objects, node, fn object, acc -> RTree.insert(acc, object) end)

      assert RTree.insert(node, %RObject{x: 6, y: 6, data: "data"}) == %RNode{
               bounding: %RBoundingBox{area: 25, max_x: 6, max_y: 6, min_x: 1, min_y: 1},
               children: %{
                 left: %RNode{
                   bounding: %RBoundingBox{min_x: 1, min_y: 1, max_x: 2, max_y: 2, area: 1},
                   children: nil,
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
                       objects: [
                         %RObject{x: 3, y: 3, data: "data"},
                         %RObject{x: 4, y: 4, data: "data"}
                       ]
                     },
                     right: %RNode{
                       bounding: %RBoundingBox{min_x: 5, min_y: 5, max_x: 6, max_y: 6, area: 1},
                       children: nil,
                       objects: [
                         %RObject{x: 5, y: 5, data: "data"},
                         %RObject{x: 6, y: 6, data: "data"}
                       ]
                     }
                   },
                   objects: []
                 }
               }
             }
    end

    test "#search should find node if exist" do
      node = %RNode{}
      objects = for i <- 1..5, do: %RObject{x: i, y: i, data: "data"}
      node = Enum.reduce(objects, node, fn object, acc -> RTree.insert(acc, object) end)

      assert RTree.search(node, %{x: 3, y: 3}) == {:ok, %RObject{x: 3, y: 3, data: "data"}}
    end

    test "#search when not exist return not found" do
      node = %RNode{}
      objects = for i <- 1..5, do: %RObject{x: i, y: i, data: "data"}
      node = Enum.reduce(objects, node, fn object, acc -> RTree.insert(acc, object) end)

      assert RTree.search(node, %{x: 6, y: 6}) == {:error, "Not found"}
    end
  end
end
