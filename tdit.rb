require "timex_datalink_client"
require "json"
require "time"
require "optparse"

# Function to parse the JSON data
def parse_json_data(file_path)
  return {} unless file_path && File.exist?(file_path)

  file = File.read(file_path)
  JSON.parse(file)
rescue JSON::ParserError
  {}
end

# Function to parse command line options
def parse_options
  options = {
    serial_device: "/dev/ttyACM0",
    verbose: false,
  }

  OptionParser.new do |opts|
    opts.banner = "Usage: timex.rb [options] [JSON_FILE]"

    opts.on("--serial-device DEVICE", "Specify a serial device (default: /dev/ttyACM0)") do |device|
      options[:serial_device] = device
    end

    opts.on("--verbose", "Enable verbose mode") do
      options[:verbose] = true
    end
  end.parse!

  options[:json_file] = ARGV[0] # The remaining argument should be the JSON file, if provided

  options
end

options = parse_options

# Read data from JSON file or use empty data if file is not provided
data = parse_json_data(options[:json_file])

# Create alarms
alarms = []
if data["alarms"]
  alarms = data["alarms"].map do |alarm|
    TimexDatalinkClient::Protocol9::Alarm.new(
      number: alarm["number"],
      audible: alarm["audible"],
      time: Time.new(0, 1, 1, alarm["hour"], alarm["minute"]),
      message: alarm["message"],
      month: alarm["month"],
      day: alarm["day"]
    )
  end
end

# Create phone numbers
phone_numbers = []
if data["phone_numbers"]
  phone_numbers = data["phone_numbers"].map do |phone_number|
    TimexDatalinkClient::Protocol9::Eeprom::PhoneNumber.new(
      name: phone_number["name"],
      number: phone_number["number"],
      type: phone_number["type"]
    )
  end
end

# Create timers
timers = []
if data["timers"]
  timers = data["timers"].map do |timer|
    TimexDatalinkClient::Protocol9::Timer.new(
      number: timer["number"],
      label: timer["label"],
      time: Time.new(0, 1, 1, timer["hour"], timer["minute"], timer["second"]),
      action_at_end: timer["action_at_end"].to_sym
    )
  end
end

# Create chrono
chrono = nil
if data["chrono"]
  chrono = TimexDatalinkClient::Protocol9::Eeprom::Chrono.new(
    label: data["chrono"]["label"],
    laps: data["chrono"]["laps"]
  )
end

# Create time models
time1 = Time.now
time2 = time1.dup.utc

time_models = [
  TimexDatalinkClient::Protocol9::Time.new(
    zone: 1,
    time: time1,
    is_24h: false
  ),
  TimexDatalinkClient::Protocol9::TimeName.new(
    zone: 1,
    name: "LAX"
  ),
  TimexDatalinkClient::Protocol9::Time.new(
    zone: 2,
    time: time2,
    is_24h: true
  ),
  TimexDatalinkClient::Protocol9::TimeName.new(
    zone: 2,
    name: "UTC"
  )
]

# Sound options
sound_options_data = data["sound_options"] || {}
sound_options = if sound_options_data.empty?
                   nil
                 else
                   TimexDatalinkClient::Protocol9::SoundOptions.new(
                     hourly_chime: sound_options_data.fetch("hourly_chime", false),
                     button_beep: sound_options_data.fetch("button_beep", false)
                   )
                 end

# Create models array
models = [
  TimexDatalinkClient::Protocol9::Sync.new,
  TimexDatalinkClient::Protocol9::Start.new
] + time_models + alarms + timers

if chrono || !phone_numbers.empty?
  models << TimexDatalinkClient::Protocol9::Eeprom.new(
    chrono: chrono,
    phone_numbers: phone_numbers
  )
end

models << sound_options if sound_options
models << TimexDatalinkClient::Protocol9::End.new

timex_datalink_client = TimexDatalinkClient.new(
  serial_device: options[:serial_device],
  models: models,
  verbose: options[:verbose]
)

timex_datalink_client.write
