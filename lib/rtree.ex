defmodule RBoundingBox do
  @type min_x :: float()
  @type min_y :: float()
  @type max_x :: float()
  @type max_y :: float()
  @type area :: float()

  defstruct min_x: 0, min_y: 0, max_x: 0, max_y: 0, area: 0

  @doc """
  Creates a new bounding box from two points.
  """
  @spec create(%{x: float(), y: float()}, %{x: float(), y: float()}) :: %RBoundingBox{}
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

  @doc """
  Updates the bounding box to include a new point.
  """
  @spec update(nil, %{x: float(), y: float()}) :: %__MODULE__{}
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

  @doc """
  Chooses the bounding box with the smallest area increase for adding a point.
  """
  def choose_smallest_increase(object, box1 = %__MODULE__{}, box2 = %__MODULE__{}) do
    increase1 = update(box1, object).area - box1.area
    increase2 = update(box2, object).area - box2.area

    if increase1 <= increase2 do
      {:left}
    else
      {:right}
    end
  end

  @doc """
  Checks if a point is contained within the bounding box.
  """
  @spec contains?(%__MODULE__{}, %{x: float(), y: float()}) :: boolean()
  def contains?(box = %__MODULE__{}, %{x: x, y: y}) do
    x >= box.min_x and x <= box.max_x and y >= box.min_y and y <= box.max_y
  end

  def contains?(%{bounding: %__MODULE__{} = bounding}, point) do
    contains?(bounding, point)
  end

  @doc """
  Checks if two bounding boxes overlap.
  """
  @spec overlaps?(%__MODULE__{}, %__MODULE__{}) :: boolean()
  def overlaps?(bounding = %__MODULE__{}, bounding2 = %__MODULE__{}) do
    !(bounding.min_x > bounding2.max_x or bounding2.min_x > bounding.max_x or
        bounding.max_y < bounding2.min_y or bounding2.max_y < bounding.min_y)
  end
end

defmodule RObject do
  defstruct [:x, :y, :data]
end

defmodule RNode do
  @type bounding :: %RBoundingBox{}
  @type children :: %{left: %RNode{}, right: %RNode{}}
  @type objects :: list(%RObject{})
  @type limit :: integer()

  defstruct bounding: nil, children: nil, objects: [], limit: nil

  @doc """
  Creates a new node with the given objects and limit.
  """
  @spec create(%{objects: list(%RObject{}), limit: integer()}) :: %__MODULE__{}
  def create(%{objects: objects, limit: limit}) do
    box = Enum.reduce(objects, nil, fn object, acc -> RBoundingBox.update(acc, object) end)
    %__MODULE__{bounding: box, objects: objects, limit: limit}
  end
end

defmodule RTree do
  @doc """
  Searches for a point in the R-tree.
  or
  Searches for objects within a bounding box in the R-tree.
  """
  @spec search(%RNode{children: nil}, %{x: float(), y: float()}) ::
          {:ok, %RObject{}} | {:error, String.t()}
  def search(node = %RNode{children: nil}, %{x: x, y: y}) do
    with object <- Enum.find(node.objects, fn object -> object.x == x and object.y == y end) do
      {:ok, object}
    else
      nil -> {:error, "Not found"}
    end
  end

  def search(
        %RNode{children: %{left: left, right: right}, bounding: bounding},
        point = %{x: _, y: _}
      ) do
    if bounding |> RBoundingBox.contains?(point) do
      if left |> RBoundingBox.contains?(point) do
        search(left, point)
      else
        search(right, point)
      end
    else
      {:error, "Not found"}
    end
  end

  @spec search(%RNode{children: nil}, %RBoundingBox{}) :: list(%RObject{})
  def search(node = %RNode{children: nil}, bounding = %RBoundingBox{}) do
    Enum.filter(node.objects, fn object -> RBoundingBox.contains?(bounding, object) end)
  end

  def search(
        %RNode{children: %{left: left, right: right}, bounding: node_bounding},
        bounding = %RBoundingBox{}
      ) do
    if node_bounding |> RBoundingBox.overlaps?(bounding) do
      search(left, bounding) ++ search(right, bounding)
    else
      []
    end
  end

  @doc """
  Inserts an object into the R-tree.
  """
  @spec insert(%RNode{}, %RObject{}) :: %RNode{}
  def insert(node = %RNode{children: nil}, object = %RObject{}) do
    node = %RNode{
      node
      | bounding: RBoundingBox.update(node.bounding, object),
        objects: node.objects ++ [object]
    }

    if length(node.objects) > node.limit do
      %RNode{node | objects: [], children: split(node)}
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

  defp split(%{objects: objects, limit: limit}) do
    {left, right} = Enum.min_max_by(objects, fn object -> object.x + object.y end)

    {left_leaf, right_leaf} =
      {RNode.create(%{objects: [left], limit: limit}),
       RNode.create(%{objects: [right], limit: limit})}

    (objects -- [left, right]) |> distribute(left_leaf, right_leaf)
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
