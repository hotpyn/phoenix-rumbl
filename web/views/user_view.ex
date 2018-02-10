defmodule Hello.UserView do
  use Hello.Web, :view

  alias Hello.User

  def first_name(%User{name: name}) do
	name
	|> String.split(" ")
	|> Enum.at(0)
  end
end
