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

  def contains(box = %RBoundingBox{}, %{x: x, y: y}) do
    x >= box.min_x and x <= box.max_x and y >= box.min_y and y <= box.max_y
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
      split_leaf(node.objects, nil, nil)
    else
      node
    end
  end

  def insert(node = %RNode{children: children}, object = %RObject{}) when length(children) > 0 do
    if RBoundingBox.contains(node.bounding, object) do
      %RNode{node | children: Enum.map(node.children, fn child -> insert(child, object) end)}
    else
      node
    end
  end

  defp split_leaf([], leaf_left, leaf_right) do
    %RNode{children: [leaf_left, leaf_right]}
  end

  defp split_leaf([object | rest], nil, nil) do
    split_leaf(rest, RTree.insert(%RNode{}, object), nil)
  end

  defp split_leaf([object | rest], leaf_left, nil) do
    split_leaf(rest, leaf_left, RTree.insert(%RNode{}, object))
  end

  defp split_leaf([object | rest], leaf_left, leaf_right) do
    if RBoundingBox.update(leaf_left.bounding, object) <
         RBoundingBox.update(leaf_right.bounding, object) do
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
    |> RTree.insert(%RObject{x: 2, y: 3, data: "data"})
    |> RTree.insert(%RObject{x: 3, y: 4, data: "data"})
    |> IO.inspect()
  end
end

Main.main()
