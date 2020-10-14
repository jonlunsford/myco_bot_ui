defmodule MycoBotUiWeb.DashboardLive do
  require Logger
  use MycoBotUiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket),
      do: Phoenix.PubSub.subscribe(MycoBotUi.PubSub, "mycobot-live", link: true)

    {:ok,
     assign(socket,
       page_title: "Grow Tent",
       temp: 0.0,
       rh: 0.0,
       lights: "ON",
       error: nil,
       refreshing_devices: false,
       devices: []
     )}
  end

  @impl true
  def handle_info(%{event: [:myco_bot, :state, :broadcast]} = payload, socket) do
    Logger.debug("[MYCOBOTUI] #{inspect(payload)}")

    assigns = Map.merge(socket.assigns, payload.meta)

    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_info(%{event: [:myco_bot, resource, :error]} = payload, socket) do
    Logger.debug("[MYCOBOTUI] #{inspect(payload)}")

    {:noreply, assign(socket, :error, "#{resource} error: #{payload.meta.error}")}
  end

  @impl true
  def handle_info(%{event: [:myco_bot, :ht_sensor, :read_temp]} = payload, socket) do
    Logger.debug("[MYCOBOTUI] #{inspect(payload)}")

    {:noreply, assign(socket, :temp, payload.measurements.temp)}
  end

  @impl true
  def handle_info(%{event: [:myco_bot, :ht_sensor, :read_rh]} = payload, socket) do
    Logger.debug("[MYCOBOTUI] #{inspect(payload)}")

    {:noreply, assign(socket, :rh, payload.measurements.rh)}
  end

  @impl true
  def handle_info(%{event: [:myco_bot, :gpio, :sync]} = payload, socket) do
    Logger.debug("[MYCOBOTUI] #{inspect(payload)}")

    {:noreply, assign(socket, %{devices: payload.meta.devices, refreshing_devices: false})}
  end

  @impl true
  def handle_info(%{event: [:myco_bot, :gpio, :up]} = payload, socket) do
    Logger.debug("[MYCOBOTUI] #{inspect(payload)}")

    device = payload.meta

    {:noreply, assign(socket, :devices, update_devices(device, socket))}
  end

  @impl true
  def handle_info(%{event: [:myco_bot, :gpio, :down]} = payload, socket) do
    Logger.debug("[MYCOBOTUI] #{inspect(payload)}")

    device = payload.meta

    {:noreply, assign(socket, :devices, update_devices(device, socket))}
  end

  @impl true
  def handle_info({:device_changed, device}, socket) do
    :telemetry.execute(
      [:myco_bot_ui, :device, :change],
      %{},
      Map.take(device, [:pin_number, :pin_direction, :value, :type, :status])
    )

    {:noreply, assign(socket, :devices, update_devices(device, socket))}
  end

  @impl true
  def handle_info(payload, socket) do
    Logger.debug("[MYCOBOTUI] unhandled info: #{inspect(payload)}")

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

  defp update_devices(device, socket) do
    devices = socket.assigns.devices
    index = Enum.find_index(devices, fn d -> d.pin_number == device.pin_number end)
    List.replace_at(devices, index, device)
  end
end
