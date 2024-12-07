#!/usr/bin/env ruby

# Usage
# =====
#
# Deploy TRELLIS API Docker container as Serverless on RunPod,
# then set the Endpoint ID and API Key.
#
# ```
# $ export RUNPOD_ENDPOINT_ID=... RUNPOD_API_KEY=...
# ```
#
# Then run script. With `--wait` option, it waits for the response,
# or check current status with `--job`.
# 
# ```
# $ ruby runpod_client.rb -i PATH_TO_IMAGE -w -o OUTPUT_GLB_PATH
# ```

require 'optparse'
require 'base64'
require 'net/http'
require 'uri'
require 'json'

ENDPOINT_ID = ENV['RUNPOD_ENDPOINT_ID']
API_KEY = ENV['RUNPOD_API_KEY']

def post_run(image)
  url = URI.parse("https://api.runpod.ai/v2/#{ENDPOINT_ID}/run")

  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(url.path, {
    'Authorization' => "Bearer #{API_KEY}",
    'Content-Type' => 'application/json'
  })

  image_base64 = Base64.encode64(image).gsub(/\n/, '')
  request.body = {
    'input': {
      'image': image_base64
    }
  }.to_json

  response = http.request(request)

  response_json = JSON.parse(response.body)

  if error = response_json['error']
    raise error
  end

  return response_json['id']
end

def get_status(job_id)
  url = URI.parse("https://api.runpod.ai/v2/#{ENDPOINT_ID}/status/#{job_id}")

  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true

  request = Net::HTTP::Get.new(url.path, {
    'Authorization' => "Bearer #{API_KEY}",
    'Content-Type' => 'application/json'
  })

  response = http.request(request)

  response_json = JSON.parse(response.body)

  if error = response_json['error']
    raise error
  end

  return response_json['status'], response_json['output']
end

options = {}
OptionParser.new do |opts|
  opts.on('-w', '--[no-]-wait', 'Wait response') do |wait|
    options[:wait] = wait
  end

  opts.on('-i', '--image PATH', 'Path to image') do |image|
    options[:image_path] = image
  end

  opts.on('-j', '--job JOB_ID', 'Existing Job ID') do |job_id|
    options[:job_id] = job_id
  end

  opts.on('-o', '--output PATH', 'Path to output') do |output|
    options[:output_path] = output
  end
end.parse!

if image_path = options[:image_path]
  image_binary = File.read(image_path)
  job_id = post_run(image_binary)

  puts job_id

  unless options[:wait]
    return
  end
else
  job_id = options[:job_id]
end

status, output = get_status(job_id)

puts status

if options[:wait]
  loop do
    case status
    when 'IN_QUEUE', 'IN_PROGRESS'
      sleep 1
    else
      break
    end

    last_status = status
    status, output = get_status(job_id)
    if status != last_status
      puts status
    end
  end
end

case status
when 'COMPLETED'
  if output_path = options[:output_path]
    File.open(output_path, 'wb') do |f|
      f.write(Base64.decode64(output['glb']))
    end
  end
end