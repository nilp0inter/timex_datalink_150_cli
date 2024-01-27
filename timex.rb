require "timex_datalink_client"
require "json"
require "time"
require "optparse"

# Function to parse the JSON data
def parse_json_data(file_path)
  file = File.read(file_path)
  JSON.parse(file)
end

# Function to parse command line options
def parse_options
  options = {
    sound_theme: nil,
    wrist_app: nil,
    serial_device: "/dev/ttyACM0",
    verbose: false
  }

  OptionParser.new do |opts|
    opts.banner = "Usage: timex.rb [options] JSON_FILE"

    opts.on("--sound-theme SPC_FILE", "Specify a sound theme SPC file") do |spc_file|
      options[:sound_theme] = spc_file
    end

    opts.on("--wrist-app ZAP_FILE", "Specify a wrist app ZAP file") do |zap_file|
      options[:wrist_app] = zap_file
    end

    opts.on("--serial-device DEVICE", "Specify a serial device (default: /dev/ttyACM0)") do |device|
      options[:serial_device] = device
    end

    opts.on("--verbose", "Enable verbose mode") do
      options[:verbose] = true
    end
  end.parse!

  options[:json_file] = ARGV[0] # The remaining argument should be the JSON file

  if options[:json_file].nil?
    raise "JSON file path must be provided. Use 'timex.rb --help' for more information."
  end

  options
end

options = parse_options

# Read data from JSON file
data = parse_json_data(options[:json_file])

# Create appointments
appointments = data["appointments"].map do |appointment|
  TimexDatalinkClient::Protocol3::Eeprom::Appointment.new(
    time: Time.parse(appointment["time"]),
    message: appointment["message"]
  )
end

# Create anniversaries
anniversaries = data["anniversaries"].map do |anniversary|
  TimexDatalinkClient::Protocol3::Eeprom::Anniversary.new(
    time: Time.parse(anniversary["time"]),
    anniversary: anniversary["anniversary"]
  )
end

# Create phone numbers
phone_numbers = data["phone_numbers"].map do |phone_number|
  TimexDatalinkClient::Protocol3::Eeprom::PhoneNumber.new(
    name: phone_number["name"],
    number: phone_number["number"],
    type: phone_number["type"]
  )
end

# Create lists
lists = data["lists"].map do |list|
  TimexDatalinkClient::Protocol3::Eeprom::List.new(
    list_entry: list["list_entry"],
    priority: list["priority"]
  )
end
time1 = Time.now
time2 = time1.dup.utc

time_models = [
  TimexDatalinkClient::Protocol3::Time.new(
    zone: 1,
    time: time1,
    is_24h: true,
    date_format: "%_d-%m-%y"
  ),
  TimexDatalinkClient::Protocol3::Time.new(
    zone: 2,
    time: time2,
    is_24h: true,
    date_format: "%y-%m-%d"
  ),
]

alarms = data["alarms"].map do |alarm|
  TimexDatalinkClient::Protocol3::Alarm.new(
    number: alarm["number"],
    audible: alarm["audible"],
    time: Time.new(0, 1, 1, alarm["hour"], alarm["minute"]),
    message: alarm["message"]
  )
end

# Read SoundOptions and appointment_notification_minutes from JSON
sound_options_data = data["sound_options"]
sound_options = TimexDatalinkClient::Protocol3::SoundOptions.new(
  hourly_chime: sound_options_data["hourly_chime"],
  button_beep: sound_options_data["button_beep"]
)
appointment_notification_minutes = data["appointment_notification_minutes"]

# Rest of your code to create appointments, anniversaries, etc.

models = [
  TimexDatalinkClient::Protocol3::Sync.new,
  TimexDatalinkClient::Protocol3::Start.new
] + time_models + alarms + [
  TimexDatalinkClient::Protocol3::Eeprom.new(
    appointments: appointments,
    anniversaries: anniversaries,
    lists: lists,
    phone_numbers: phone_numbers,
    appointment_notification_minutes: appointment_notification_minutes
  )
]

# Optional Sound Theme
if options[:sound_theme]
  models << TimexDatalinkClient::Protocol3::SoundTheme.new(spc_file: options[:sound_theme])
end

# Optional Wrist Apps
if options[:wrist_app]
  models << TimexDatalinkClient::Protocol3::WristApp.new(zap_file: options[:wrist_app])
end

models << sound_options
models << TimexDatalinkClient::Protocol3::End.new

timex_datalink_client = TimexDatalinkClient.new(
  serial_device: options[:serial_device],
  models: models,
  verbose: options[:verbose]
)

timex_datalink_client.write
