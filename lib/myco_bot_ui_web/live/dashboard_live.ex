defmodule MycoBotUiWeb.DashboardLive do
  require Logger
  use MycoBotUiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket),
      do: Phoenix.PubSub.subscribe(MycoBotUi.PubSub, "mycobot-live", link: true)

    {:ok,
     assign(socket,
       page_title: "Grow Tent 1",
       temp: 0,
       humidity: 0,
       lights: "ON",
       error: nil,
       refreshing_devices: false,
       devices: []
     )}
  end

  @impl true
  def handle_info(%{event: [:myco_bot, resource, :error]} = payload, socket) do
    {:noreply, assign(socket, error: "#{resource} error: #{payload.meta.error}")}
  end

  @impl true
  def handle_info(%{event: [:myco_bot, :ht_sensor, :read_temp]} = payload, socket) do
    {:noreply, assign(socket, temp: payload.measurements.temp)}
  end

  @impl true
  def handle_info(%{event: [:myco_bot, :ht_sensor, :read_rh]} = payload, socket) do
    {:noreply, assign(socket, humidity: payload.measurements.rh)}
  end

  @impl true
  def handle_info(%{event: [:myco_bot, :gpio, :sync]} = payload, socket) do
    {:noreply, assign(socket, %{devices: payload.meta.devices, refreshing_devices: false})}
  end

  @impl true
  def handle_info({:device_changed, device}, socket) do
    devices = socket.assigns.devices
    index = Enum.find_index(devices, fn d -> d.pin_number == device.pin_number end)
    devices = List.replace_at(devices, index, device)

    {:noreply, assign(socket, :devices, devices)}
  end

  @impl true
  def handle_info(payload, socket) do
    Logger.debug("[MYCOBOTUI] DashboardLive received update: #{inspect(payload)}")

    {:noreply, assign(socket, :results, payload)}
  end

  @impl true
  def handle_event("refresh_devices", _params, socket) do
    :telemetry.execute([:myco_bot_ui, :device, :refresh], %{}, %{})

    {:noreply, assign(socket, :refreshing_devices, true)}
  end

  @impl true
  def handle_event(event, params, socket) do
    Logger.warn("No event handler for: #{event}")
    Logger.debug("#{inspect(params)}")
    {:noreply, socket}
  end
end
