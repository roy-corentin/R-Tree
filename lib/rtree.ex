defmodule RBoundingBox do
  @type min_x :: integer
  @type min_y :: integer
  @type max_x :: integer
  @type max_y :: integer
  @type area :: integer
  defstruct min_x: 0, min_y: 0, max_x: 0, max_y: 0, area: 0

  @spec update(nil, %{x: integer, y: integer}) :: %RBoundingBox{}
  def update(nil, %{x: x, y: y}) do
    %RBoundingBox{min_x: x, min_y: y, max_x: x, max_y: y, area: 0}
  end

  def update(box = %RBoundingBox{}, %{x: x, y: y}) do
    new_min_x = min(box.min_x, x - 1)
    new_min_y = min(box.min_y, y - 1)
    new_max_x = max(box.max_x, x + 1)
    new_max_y = max(box.max_y, y + 1)
    area = (new_max_x - new_min_x) * (new_max_y - new_min_y)

    %RBoundingBox{
      min_x: new_min_x,
      min_y: new_min_y,
      max_x: new_max_x,
      max_y: new_max_y,
      area: area
    }
  end

  @spec contains(%RBoundingBox{}, %{x: integer, y: integer}) :: boolean
  def contains(box = %RBoundingBox{}, %{x: x, y: y}) do
    x >= box.min_x and x <= box.max_x and y >= box.min_y and y <= box.max_y
  end

  def increases(object, box1 = %RBoundingBox{}, box2 = %RBoundingBox{}) do
    increase1 = update(box1, object).area - box1.area
    increase2 = update(box2, object).area - box2.area
    [increase1, increase2]
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
          children: [insert(children[0], object), children[1]]
      }
    else
      %RNode{
        node
        | bounding: RBoundingBox.update(node.bounding, object),
          children: [children[0], insert(children[1], object)]
      }
    end
  end

  defp split_leaf([], leaf_left, leaf_right) do
    [leaf_left, leaf_right]
  end

  defp split_leaf([object | rest], nil, nil) do
    split_leaf(rest, insert(%RNode{}, object), nil)
  end

  defp split_leaf([object | rest], leaf_left, nil) do
    split_leaf(rest, leaf_left, insert(%RNode{}, object))
  end

  defp split_leaf([object | rest], leaf_left, leaf_right) do
    [increase1, increase2] =
      RBoundingBox.increases(object, leaf_left.bounding, leaf_right.bounding)

    if increase1 < increase2 do
      split_leaf(rest, insert(leaf_left, object), leaf_right)
    else
      split_leaf(rest, leaf_left, insert(leaf_right, object))
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
