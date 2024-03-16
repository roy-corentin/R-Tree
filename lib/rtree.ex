defmodule RBoundingBox do
  defstruct min_x: 0, min_y: 0, max_x: 0, max_y: 0

  def update(_box = nil, _point = %{x: x, y: y}) do
    %RBoundingBox{min_x: x - 1, min_y: y - 1, max_x: x + 1, max_y: y + 1}
  end

  def update(box = %RBoundingBox{}, _point = %{x: x, y: y}) do
    %RBoundingBox{
      min_x: min(box.min_x, x - 1),
      min_y: min(box.min_y, y - 1),
      max_x: max(box.max_x, x + 1),
      max_y: max(box.max_y, y + 1)
    }
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
  def insert(node = %RNode{}, object = %RObject{}) do
    %RNode{
      node
      | bounding: RBoundingBox.update(node.bounding, object),
        objects: node.objects ++ [object]
    }
  end
end

defmodule Main do
  def main do
    %RNode{}
    |> RTree.insert(%RObject{x: 1, y: 2, data: "data"})
    |> RTree.insert(%RObject{x: 2, y: 3, data: "data"})
    |> IO.inspect()
  end
end

Main.main()
