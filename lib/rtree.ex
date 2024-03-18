defmodule RBoundingBox do
  @type min_x :: integer
  @type min_y :: integer
  @type max_x :: integer
  @type max_y :: integer
  @type area :: integer
  defstruct min_x: 0, min_y: 0, max_x: 0, max_y: 0, area: 0

  @spec create(%{x: integer, y: integer}, %{x: integer, y: integer}) :: %RBoundingBox{}
  def create(%{x: x1, y: y1}, %{x: x2, y: y2}) do
    min_x = min(x1, x2)
    min_y = min(y1, y2)
    max_x = max(x1, x2)
    max_y = max(y1, y2)
    area = (max_x - min_x) * (max_y - min_y)

    %__MODULE__{
      min_x: min_x,
      min_y: min_y,
      max_x: max_x,
      max_y: max_y,
      area: area
    }
  end

  @spec update(nil, %{x: integer, y: integer}) :: %__MODULE__{}
  def update(nil, %{x: x, y: y}) do
    %__MODULE__{min_x: x, min_y: y, max_x: x, max_y: y, area: 0}
  end

  def update(box = %__MODULE__{}, %{x: x, y: y}) do
    new_min_x = min(box.min_x, x)
    new_min_y = min(box.min_y, y)
    new_max_x = max(box.max_x, x)
    new_max_y = max(box.max_y, y)
    area = (new_max_x - new_min_x) * (new_max_y - new_min_y)

    %__MODULE__{
      min_x: new_min_x,
      min_y: new_min_y,
      max_x: new_max_x,
      max_y: new_max_y,
      area: area
    }
  end

  def increases(object, box1 = %__MODULE__{}, box2 = %__MODULE__{}) do
    increase1 = update(box1, object).area - box1.area
    increase2 = update(box2, object).area - box2.area

    {increase1, increase2}
  end

  def contains?(box = %__MODULE__{}, %{x: x, y: y}) do
    x >= box.min_x and x <= box.max_x and y >= box.min_y and y <= box.max_y
  end

  def contains?(%{bounding: %__MODULE__{} = bounding}, %{x: x, y: y}) do
    contains?(bounding, %{x: x, y: y})
  end
end

defmodule RObject do
  defstruct [:x, :y, :data]
end

defmodule RNode do
  @type bounding :: %RBoundingBox{}
  @type objects :: list(%RObject{})
  @type children :: %{left: %RNode{}, right: %RNode{}}
  defstruct bounding: nil, children: nil, objects: []

  def create(%{objects: objects}) do
    box = Enum.reduce(objects, nil, fn object, acc -> RBoundingBox.update(acc, object) end)
    %__MODULE__{bounding: box, objects: objects}
  end
end

defmodule RTree do
  @m 2

  @spec search(%RNode{}, %{x: integer, y: integer}) :: {:ok, %RObject{}} | {:error, String.t()}
  def search(node = %RNode{children: nil}, %{x: x, y: y}) do
    case Enum.find(node.objects, fn object -> object.x == x and object.y == y end) do
      nil -> {:error, "Not found"}
      object -> {:ok, object}
    end
  end

  def search(node = %RNode{children: %{left: left, right: right}}, point) do
    if RBoundingBox.contains?(node, point) do
      if RBoundingBox.contains?(left, point) do
        search(left, point)
      else
        search(right, point)
      end
    else
      {:error, "Not found"}
    end
  end

  @spec insert(%RNode{}, %RObject{}) :: %RNode{}
  def insert(node = %RNode{children: nil}, object = %RObject{}) do
    node = %RNode{
      node
      | bounding: RBoundingBox.update(node.bounding, object),
        objects: node.objects ++ [object]
    }

    if length(node.objects) > @m do
      %RNode{node | objects: [], children: split(node.objects)}
    else
      node
    end
  end

  @spec insert(%RNode{}, %RObject{}) :: %RNode{}
  def insert(node = %RNode{children: %{left: left, right: right}}, object = %RObject{}) do
    {increase1, increase2} =
      RBoundingBox.increases(object, left.bounding, right.bounding)

    if increase1 <= increase2 do
      %RNode{
        node
        | bounding: RBoundingBox.update(node.bounding, object),
          children: %{left: insert(left, object), right: right}
      }
    else
      %RNode{
        node
        | bounding: RBoundingBox.update(node.bounding, object),
          children: %{left: left, right: insert(right, object)}
      }
    end
  end

  defp split(objects) do
    {left, right} = Enum.min_max_by(objects, fn object -> object.x + object.y end)

    {left_leaf, right_leaf} =
      {RNode.create(%{objects: [left]}), RNode.create(%{objects: [right]})}

    (objects -- [left, right])
    |> distribute(left_leaf, right_leaf)
  end

  defp distribute([], leaf_left, leaf_right) do
    %{left: leaf_left, right: leaf_right}
  end

  defp distribute([object | rest], leaf_left, leaf_right) do
    {left_increase, right_increase} =
      RBoundingBox.increases(object, leaf_left.bounding, leaf_right.bounding)

    if left_increase <= right_increase do
      distribute(rest, insert(leaf_left, object), leaf_right)
    else
      distribute(rest, leaf_left, insert(leaf_right, object))
    end
  end
end

defmodule Main do
  def main do
    %RNode{}
    |> RTree.insert(%RObject{x: 1, y: 2, data: "data"})
    |> RTree.insert(%RObject{x: 20, y: 30, data: "data"})
    |> RTree.insert(%RObject{x: 15, y: 18, data: "data"})
    |> RTree.insert(%RObject{x: 30, y: 10, data: "data"})
    |> RTree.insert(%RObject{x: 1, y: 10, data: "data"})
    |> RTree.insert(%RObject{x: 40, y: 7, data: "data"})
    |> RTree.insert(%RObject{x: 19, y: 25, data: "data"})
    |> IO.inspect()
  end
end

Main.main()
