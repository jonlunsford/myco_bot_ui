defmodule MycoBotUiWeb.DashboardLive do
  require Logger
  use MycoBotUiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket),
      do: Phoenix.PubSub.subscribe(MycoBotUi.PubSub, "mycobot-live", link: true)

    {:ok,
     assign(socket,
       page_title: "Grow Room 1",
       temp: 70.0,
       humidity: 90.0,
       lights: "ON",
       devices: [
         %{
           pin_number: 16,
           pin_direction: :output,
           value: 1,
           setting: 90,
           status: "Online",
           type: "humidifier"
         }
       ]
     )}
  end

  @impl true
  def handle_info(%{event: [:myco_bot, :ht_sensor, :read_temp]} = payload, socket) do
    Logger.debug("[MYCOBOTUI] received update: #{inspect(payload)}")

    {:noreply, assign(socket, temp: payload.measurements.temp)}
  end

  @impl true
  def handle_info(%{event: [:myco_bot, :ht_sensor, :read_rh]} = payload, socket) do
    Logger.debug("[MYCOBOTUI] received update: #{inspect(payload)}")

    {:noreply, assign(socket, humidity: payload.measurements.rh)}
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

    {:noreply, assign(socket, results: payload)}
  end

  @impl true
  def handle_event(event, params, socket) do
    Logger.warn("No event handler for: #{event}")
    Logger.debug("#{inspect(params)}")
    {:noreply, socket}
  end
end
