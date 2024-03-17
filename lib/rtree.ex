defmodule RBoundingBox do
  @type min_x :: integer
  @type min_y :: integer
  @type max_x :: integer
  @type max_y :: integer
  defstruct min_x: 0, min_y: 0, max_x: 0, max_y: 0

  @spec update(nil, %{x: integer, y: integer}) :: %RBoundingBox{}
  def update(nil, %{x: x, y: y}) do
    %RBoundingBox{min_x: x, min_y: y, max_x: x, max_y: y}
  end

  def update(box = %RBoundingBox{}, %{x: x, y: y}) do
    %RBoundingBox{
      min_x: min(box.min_x, x - 1),
      min_y: min(box.min_y, y - 1),
      max_x: max(box.max_x, x + 1),
      max_y: max(box.max_y, y + 1)
    }
  end

  @spec contains(%RBoundingBox{}, %{x: integer, y: integer}) :: boolean
  def contains(box = %RBoundingBox{}, %{x: x, y: y}) do
    x >= box.min_x and x <= box.max_x and y >= box.min_y and y <= box.max_y
  end

  @spec increases(%{x: integer, y: integer}, %RBoundingBox{}, %RBoundingBox{}) :: list(integer)
  def increases(%{x: x, y: y}, box1 = %RBoundingBox{}, box2 = %RBoundingBox{}) do
    [increase(box1, %{x: x, y: y}), increase(box2, %{x: x, y: y})]
  end

  @spec increase(%RBoundingBox{}, %{x: integer, y: integer}) :: integer
  def increase(box = %RBoundingBox{}, %{x: x, y: y}) do
    area(update(box, %{x: x, y: y})) - area(box)
  end

  @spec area(%RBoundingBox{}) :: integer
  def area(box = %RBoundingBox{}) do
    (box.max_x - box.min_x) * (box.max_y - box.min_y)
  end
end

defmodule RObject do
  defstruct [:x, :y, :data]
end

defmodule RNode do
  @type bounding :: %RBoundingBox{}
  @type objects :: list(%RObject{})
  defstruct bounding: nil, children: [], objects: []
end

defmodule RTree do
  @m 2

  @spec insert(%RNode{}, %RObject{}) :: %RNode{}
  def insert(node = %RNode{}, object = %RObject{}) do
    node = %RNode{
      node
      | bounding: RBoundingBox.update(node.bounding, object),
        objects: node.objects ++ [object]
    }

    if length(node.objects) > @m do
      %RNode{node | objects: [], children: split_leaf(node.objects, nil, nil)}
    else
      node
    end
  end

  @spec insert(%RNode{}, %RObject{}) :: %RNode{}
  def insert(node = %RNode{children: children}, object = %RObject{}) when length(children) == 2 do
    {increase1, increase2} =
      RBoundingBox.increases(object, children[0].bounding, children[1].bounding)

    if increase1 < increase2 do
      %RNode{
        node
        | bounding: RBoundingBox.update(node.bounding, object),
          children: [RTree.insert(children[0], object), children[1]]
      }
    else
      %RNode{
        node
        | bounding: RBoundingBox.update(node.bounding, object),
          children: [children[0], RTree.insert(children[1], object)]
      }
    end
  end

  defp split_leaf([], leaf_left, leaf_right) do
    [leaf_left, leaf_right]
  end

  defp split_leaf([object | rest], nil, nil) do
    split_leaf(rest, RTree.insert(%RNode{}, object), nil)
  end

  defp split_leaf([object | rest], leaf_left, nil) do
    split_leaf(rest, leaf_left, RTree.insert(%RNode{}, object))
  end

  defp split_leaf([object | rest], leaf_left, leaf_right) do
    [increase1, increase2] =
      RBoundingBox.increases(object, leaf_left.bounding, leaf_right.bounding)

    if increase1 < increase2 do
      split_leaf(rest, RTree.insert(leaf_left, object), leaf_right)
    else
      split_leaf(rest, leaf_left, RTree.insert(leaf_right, object))
    end
  end
end

defmodule Main do
  def main do
    %RNode{}
    |> RTree.insert(%RObject{x: 1, y: 2, data: "data"})
    |> RTree.insert(%RObject{x: 20, y: 30, data: "data"})
    |> RTree.insert(%RObject{x: 15, y: 4, data: "data"})
    |> IO.inspect()
  end
end

Main.main()
