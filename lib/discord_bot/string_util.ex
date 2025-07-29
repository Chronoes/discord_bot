defmodule DiscordBot.StringUtil do
  @spec left_padding_fn([binary()]) :: (binary() -> binary())
  def left_padding_fn(list) do
    max_len = max_length(list)

    fn name -> String.pad_leading(name, max_len) end
  end

  @spec right_padding_fn([binary()]) :: (binary() -> binary())
  def right_padding_fn(list) do
    max_len = max_length(list)

    fn name -> String.pad_trailing(name, max_len) end
  end

  @spec max_length([binary()]) :: non_neg_integer()
  def max_length(list) do
    list |> Enum.map(&String.length/1) |> Enum.max()
  end
end
