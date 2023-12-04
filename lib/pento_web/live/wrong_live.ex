defmodule PentoWeb.WrongLive do
  use PentoWeb, :live_view

  alias Pento.Accounts
  def mount(_params, session, socket) do
    user = Accounts.get_user_by_session_token(session["user_token"])
    {
      :ok,
      assign(
        socket, score: 0,
        correction: get_target(),
        result: "0",
        message: "make a guess:",
        session_id: session["live_socket_id"], # for session
        current_user: user                     # for session
        )
      }
  end

  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <h1 class="mb-4 text-4xl font-extrabold">Your score: <%= @score %></h1>
    <h2>
      <%= @message %>
      <%= if @result == "1" do %>
        <.button class="bg-blue-500 hover:bg-blue-700
          text-white font-bold py-2 px-4 border border-blue-700 rounded m-1"
          phx-click="new_game">
            YES
        </.button>
      <% end %>
      <br/>
    </h2>
    <br/>
    <h2>
      <%= for n <- 1..10 do %>
        <.link class="bg-blue-500 hover:bg-blue-700
        text-white font-bold py-2 px-4 border border-blue-700 rounded m-1"
        phx-click="guess" phx-value-number= {n} >
          <%= n %>
        </.link>
      <% end %>
    </h2>
    <br/>
    <h2>한글한글</h2>
    <pre>
      <%= @current_user.email%>
      <%= @session_id %>
    </pre>
    """
  end

  def handle_event("new_game", _params, socket) do
    {
      :noreply,
      assign(socket, score: 0, correction: get_target(), result: False, message: "make a guess:")
    }
  end

  def handle_event("guess", %{"number" => guess}, socket) do
    correction = socket.assigns.correction

    case guess do
      ^correction -> is_correct(guess, socket)
      _ -> is_wrong(guess, socket)
    end
  end

  def get_target() do
    :rand.uniform(10)
    |> to_string()
  end

  def is_correct(guess, socket) do
    message = "Your guess: #{guess}. Correct!!. Play Again?"
    score = socket.assigns.score
    {
      :noreply,
      assign(socket, message: message, score: score, result: "1")
    }
  end

  def is_wrong(guess, socket) do
    message = "Your guess: #{guess}. Wrong. Guess again. "
    score = socket.assigns.score - 1
    {
      :noreply,
      assign(socket, message: message, score: score, result: "0")
    }
  end
end
