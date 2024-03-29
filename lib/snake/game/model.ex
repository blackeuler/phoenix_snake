defmodule Snake.Game.Model do
  defstruct [:snakes, :food, width: 3800, height: 3800]

  alias Snake.Game.{Food, Snake}

  def new() do
    %__MODULE__{snakes: [], food: []}
  end

  def add_snake(%__MODULE__{} = m, snake) do
    if snake in m.snakes do
      m
    else
      %{m | snakes: [snake | m.snakes]}
    end
  end

  def add_food(%__MODULE__{width: width, height: height} = m) do
    %{m | food: [Food.new(width, height) | m.food]}
  end

  def generate_food(%__MODULE__{width: w, height: h, food: food} = m, num_food) do
    Enum.reduce(1..num_food, m, fn _, acc ->
      add_food(acc)
    end)
  end

  def snake_of_length(n, user_name) do
    Enum.reduce(1..n, Snake.new({:rand.uniform(3000), :rand.uniform(3000)}, user_name), fn _, acc ->
      Snake.grow(acc)
    end)
  end

  def update(%__MODULE__{} = m, delta_t) do
    m
    |> handle_collisions()
    |> move_snakes(delta_t)
  end

  def move_snakes(%__MODULE__{snakes: snakes} = m, delta_t) do
    %{m | snakes: Enum.map(snakes, fn s -> Snake.move(s, delta_t) end)}
  end

  def handle_collisions(%__MODULE__{height: height, width: width, snakes: snakes, food: food} = m) do
    {eaten_food, remaining_food} =
      Enum.split_with(food, fn f ->
        Enum.any?(snakes, fn s -> collides(s, f) end)
      end)

    new_snakes =
      Enum.map(snakes, fn snake ->
        if Enum.any?(eaten_food, fn f -> collides(snake, f) end) do
          Snake.grow(snake)
        else
          snake
        end
      end)

    {dead_snakes, alive_snakes} =
      Enum.split_with(new_snakes, fn s ->
        Enum.any?(new_snakes, fn other ->
          (s != other &&
             collides(s, other)) || s.head.x > width || s.head.y > height
        end)
      end)

    dead_snakes_food = List.flatten(Enum.map(dead_snakes, fn s -> Food.from_snake(s) end))
    new_food = remaining_food ++ dead_snakes_food

    %{m | snakes: alive_snakes, food: new_food}
  end

  defp collides(%Snake{head: head}, %Snake{head: other_head, body: other_body}) do
    distance(head, other_head) < head.r + other_head.r ||
      Enum.any?(other_body, fn seg -> distance(head, seg) < head.r + seg.r end)
  end

  defp collides(%Snake{head: head}, %Food{} = food) do
    distance(head, food) < head.r + food.r
  end

  def update_all_snakes(%__MODULE__{snakes: snakes} = m) do
    %{m | snakes: Enum.map(snakes, &Snake.move/1)}
  end

  def update_snake_angle(%__MODULE__{snakes: snakes} = m, current_player, {x, y}) do
    %{
      m
      | snakes:
          Enum.map(snakes, fn snake ->
            if snake.id == current_player.id do
              dx = x - snake.head.x
              dy = y - snake.head.y
              angle = :math.atan2(dy, dx)
              Snake.change_direction(snake, angle)
            else
              snake
            end
          end)
    }
  end

  def distance(p1, p2) do
    dx = p2.x - p1.x
    dy = p2.y - p1.y
    :math.sqrt(dx * dx + dy * dy)
  end

  def to_svg_box(%__MODULE__{width: w, height: h, snakes: snakes}, snake, _width, _height) do
    snake = Enum.find(snakes, &(&1.id == snake.id))
    # Define a zoom level (in this case, 2x)
    zoom = 200

    # Calculate the x and y offsets based on the player's position and the desired zoom level
    x_offset = snake.head.x - w / 2
    y_offset = snake.head.y - h / 2
    "#{x_offset} #{y_offset} #{w - zoom} #{h - zoom}"
  end

  # def to_svg_box(
  #       %__MODULE__{width: w, height: h, snakes: snakes},
  #       snake,
  #       window_width,
  #       window_height
  #     ) do
  #   snake = Enum.find(snakes, &(&1.id == snake.id))

  #   # Define the zoom factor; increase this value to zoom in more
  #   zoom_factor = 7

  #   # Calculate the zoom level based on the browser window dimensions and game dimensions
  #   zoom_x = window_width / w * zoom_factor
  #   zoom_y = window_height / h * zoom_factor
  #   zoom = min(zoom_x, zoom_y)

  #   # Calculate the x and y offsets based on the player's position and the desired zoom level
  #   x_offset = max(snake.head.x * zoom - window_width / 2, 0)
  #   y_offset = max(snake.head.y * zoom - window_height / 2, 0)
  #   # Clamp the x and y offsets to keep the game area within the screen
  #   x_offset = min(max(x_offset, 0), w * zoom - window_width)
  #   y_offset = min(max(y_offset, 0), h * zoom - window_height)
  #   #"#{x_offset} #{y_offset} #{window_width} #{window_height}"
  #   # "#{x_offset} #{y_offset} #{w} #{h}"
  #   "#{snake.head.x - w/2} #{snake.head.y - h/2} #{w} #{h}"
  # end
end
