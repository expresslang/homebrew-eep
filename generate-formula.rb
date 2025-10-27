#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'erb'
require 'digest'
require 'fileutils'
require 'net/http'
require 'uri'

begin
  require 'octokit'
rescue LoadError
  puts "Error: octokit gem is required. Install it with: gem install octokit"
  exit 1
end

class FormulaGenerator
  RESOURCES_AND_TEMPLATES = {
    "expresslang/eep-releases" => {
      "mac-x86-64" => {
        "type" => "release-artifact",
        "pattern" => "eep-macos-*-x64",
      },
      "lnx-x86-64" => {
        "type" => "release-artifact",
        "pattern" => "eep-linux-x64",
      }
    }
  }

  def initialize(metadata_file = 'formula-metadata.json')
    @metadata_file = metadata_file
    @metadata = load_metadata
    @dry_run = false
    @client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
  end

  def generate(version:, dry_run: false)
    @dry_run = dry_run

    raise "Version must be specified (e.g. v1.4.45)" unless version
    raise "Version must match pattern 'vX.Y.Z'" unless version.match?(/^v\d+\.\d+\.\d+/)

    puts "Fetching SHA256 hashes for #{version}..."
    results = update_sha256_hashes(version)

    puts "Generating formula..."
    generate_formula('eep', 'templates/eep.rb.erb', 'Formula/eep.rb')

    puts "Saving metadata..."
    save_metadata(results)

    puts "\nFormula generated successfully!"
  end

  private

  def load_metadata
    unless File.exist?(@metadata_file)
      puts "Metadata file #{@metadata_file} not found, creating new one..."
      return {}
    end

    JSON.parse(File.read(@metadata_file))
  end

  def save_metadata(metadata)
    if @dry_run
      puts "\n--- #{@metadata_file} (DRY RUN) ---"
      puts '```json'
      puts JSON.pretty_generate(metadata)
      puts '```'
      puts "--- END #{@metadata_file} ---\n"
      return
    end

    File.write(@metadata_file, JSON.pretty_generate(metadata))
  end

  def update_sha256_hashes(version)
    result = {
      "version" => version.sub(/^v/, '')
    }

    # Process each resource group
    RESOURCES_AND_TEMPLATES.each do |resource_repo, resources|
      puts "Processing #{resource_repo}..."

      release = @client.release_for_tag(resource_repo, version)
      raise "Release not found for #{resource_repo} at tag #{version}" unless release

      result[resource_repo.to_s] = {}
      resources.each do |resource_name, resource_info|
        puts "  Processing resource: #{resource_name}"

        pattern = resource_info['pattern']
        # Convert wildcard pattern to regex (e.g., "eep-macos-*-x64" -> /eep-macos-.*-x64/)
        regex_pattern = pattern.gsub('*', '.*')
        asset = release.assets.find { |a| a.name.match?(/^#{regex_pattern}$/) }
        raise "Asset matching '#{pattern}' not found in release #{version}" unless asset

        url = asset.browser_download_url
        raise "No download URL found for asset in release #{version}" unless url

        puts "    Downloading from #{url}"
        content = download_http(url)
        hash = Digest::SHA256.hexdigest(content)
        puts "    SHA256: #{hash}"

        result[resource_repo.to_s][resource_name] = {
          "url" => url,
          "sha256" => hash
        }
      end
    end

    result
  end

  def download_http(url)
    uri = URI(url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new(uri)
      request['User-Agent'] = 'Homebrew Formula Generator'
      response = http.request(request)

      case response
      when Net::HTTPSuccess
        response.body
      when Net::HTTPRedirection
        location = response['location']
        raise "Redirect without location" unless location
        location = URI.join(url, location).to_s if location.start_with?('/')
        download_http(location)
      else
        raise "HTTP #{response.code}: #{response.message}"
      end
    end
  end

  def generate_formula(name, template_path, output_path)
    unless File.exist?(template_path)
      raise "Template file #{template_path} not found"
    end

    template = ERB.new(File.read(template_path), trim_mode: '-')
    content = template.result(binding)

    if @dry_run
      puts "\n--- #{output_path} (DRY RUN) ---"
      puts content
      puts "--- END #{output_path} ---\n"
      return
    end

    FileUtils.mkdir_p(File.dirname(output_path))
    File.write(output_path, content)
    puts "  Generated: #{output_path}"
  end

  def metadata
    @metadata
  end
end

# CLI interface
if __FILE__ == $0
  require 'optparse'

  options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options]"

    opts.on('-v', '--version VERSION', 'Set version number (e.g., v1.4.45)') do |v|
      options[:version] = v
    end

    opts.on('-d', '--dry-run', 'Show what would be generated without writing files') do
      options[:dry_run] = true
    end

    opts.on('-h', '--help', 'Show this help') do
      puts opts
      exit
    end
  end.parse!

  begin
    generator = FormulaGenerator.new
    generator.generate(
      version: options[:version],
      dry_run: options[:dry_run]
    )
  rescue => e
    puts "Error: #{e.message}"
    puts e.backtrace if ENV['DEBUG']
    exit 1
  end
end
