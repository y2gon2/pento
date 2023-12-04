defmodule PentoWeb.Router do
  use PentoWeb, :router

  import PentoWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PentoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PentoWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", PentoWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:pento, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PentoWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  #라우터에서 pipe_through 사용하기:
  # Phoenix에서는 pipe_through를 사용하여 라우트를 특정 플러그 파이프라인에 연결할 수 있다.
  # 이는 라우트가 처리되기 전에 특정 플러그들이 실행함.
  # 즉 일반적인 HTTP 요청에 대해서는, 이런 방식으로 인증과 같은 필수적인 절차를 거침.
  # 그러나 LiveView에서는 WebSocket을 통한 통신으로 인해 이러한 절차를 건너뛰게 됨.
  # 따라서, 라우터에서 일반 라우트뿐만 아니라, HTTP GET 요청으로 시작하는 live 라우트에 대해서도
  # pipe_through를 사용해야 함. 따라서, LiveView가 처음 로드될 때 필요한 보안 절차를 거치게 됨.
  #
  # Live 뷰 마운트 시 인증 및 권한 부여 로직 구현:
  # LiveView가 WebSocket을 통해 연결된 후, 페이지 간의 이동(라이브 리디렉션)은
  # WebSocket 세션 내에서 이루어지므로 추가적인 HTTP 요청이나 플러그 파이프라인을 거치지 않음.
  # 즉, 한 LiveView에서 다른 LiveView로 이동할 때, 기존에 설정된 보안 절차를 다시 거치지 않는다는 것을 의미.
  # 이것이 보안상의 허점이 될 수 있으므로, 이를 방지하기 위해, 각 LiveView가 마운트될 때
  # (즉, LiveView가 시작될 때) 인증 및 권한 부여 로직을 실행해야 함.
  # 따라서, LiveView 간의 이동이 발생해도 각 뷰에서 필요한 보안 검사를 수행할 수 있음.
  scope "/", PentoWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{PentoWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", PentoWeb do
    # pipe_through를 사용하여 라우트를 특정 플러그 파이프라인에 연결
    # 이는 router 가 처리되기 전에 특정 플러그(:require_authenticated_user)들이 실행되도록 함.
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      # root_layout: {PentoWeb.Layouts, :root}, # 해당 인자는 이미 default 라서 적용해도 동일함.
      # user_auth.ex
      on_mount: [{PentoWeb.UserAuth, :ensure_authenticated}] do
      # 어떤 browser HTTP request 에 대해서 authentication 이 필요하진 설정
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

      live "/guess", WrongLive

      live "/products", ProductLive.Index, :index
      live "/products/new", ProductLive.Index, :new # :new -> action argument (해당 view 를 실행할 때 socket 에 넣을 action??)
      live "/products/:id/edit", ProdcutLive.Index, :erl_distribution

      live "/products/:id", ProdctLive.Show, :show
      live "/products/:id/show/edit", ProductLive.Show, :edit
    end
  end

  scope "/", PentoWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{PentoWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
