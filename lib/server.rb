# Copyright (c) 2013-2015 SUSE LLC
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 3 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact SUSE LLC.
#
# To contact SUSE about this file by physical or electronic mail,
# you may find current contact information at www.suse.com

class Server < Sinatra::Base
  module Helpers
    def scope_help(scope)
      text = File.read(File.join(Machinery::ROOT, "plugins", "#{scope}/#{scope}.md"))
      Kramdown::Document.new(text).to_html
    end

    def diff_to_object(diff)
      diff = Machinery.scrub(diff)
      lines = diff.lines[2..-1]
      diff_object = {
        file: diff[/--- a(.*)/, 1],
        additions: lines.select { |l| l.start_with?("+") }.length,
        deletions: lines.select { |l| l.start_with?("-") }.length
      }

      original_line_number = 0
      new_line_number = 0
      diff_object[:lines] = lines.map do |line|
        line = ERB::Util.html_escape(line.chomp).
          gsub("\\", "&#92;").
          gsub("\t", "&nbsp;" * 8)
        case line
        when /^@.*/
          entry = {
            type: "header",
            content: line
          }
          original_line_number = line[/-(\d+)/, 1].to_i
          new_line_number = line[/\+(\d+)/, 1].to_i
        when /^ .*/, ""
          entry = {
            type: "common",
            new_line_number: new_line_number,
            original_line_number: original_line_number,
            content: line[1..-1]
          }
          new_line_number += 1
          original_line_number += 1
        when /^\+.*/
          entry = {
            type: "addition",
            new_line_number: new_line_number,
            content: line[1..-1]
          }
          new_line_number += 1
        when /^\-.*/
          entry = {
            type: "deletion",
            original_line_number: original_line_number,
            content: line[1..-1]
          }
          original_line_number += 1
        end

        entry
      end

      diff_object
    end
  end

  helpers Helpers

  get "/descriptions/:id.js" do
    description = SystemDescription.load(params[:id], settings.system_description_store)
    diffs_dir = description.scope_file_store("analyze/config_file_diffs").path
    if description.config_files && diffs_dir
      # Enrich description with the config file diffs
      description.config_files.files.each do |file|
        path = File.join(diffs_dir, file.name + ".diff")
        file.diff = diff_to_object(File.read(path)) if File.exists?(path)
      end
    end

    # Enrich file information with downloadable flag
    ["config_files", "changed_managed_files", "unmanaged_files"].each do |scope|
      next if !description[scope]

      description[scope].files.each do |file|
        file.downloadable = file.on_disk?
      end
    end

    description.to_hash.to_json
  end

  get "/descriptions/:id/files/:scope/*" do
    description = SystemDescription.load(params[:id], settings.system_description_store)
    filename = File.join("/", params["splat"].first)

    file = description[params[:scope]].files.find { |f| f.name == filename }

    if request.accept.first.to_s == "text/plain" && file.binary?
      status 406
      return "binary file"
    end

    content = file.content
    type = MimeMagic.by_path(filename) || MimeMagic.by_magic(content) || "text/plain"

    content_type type
    attachment File.basename(filename)

    content
  end

  get "/compare/:a/:b.json" do
    description_a = SystemDescription.load(params[:a], settings.system_description_store)
    description_b = SystemDescription.load(params[:b], settings.system_description_store)

    diff = {
      meta: {
        description_a: description_a.name,
        description_b: description_b.name,
      }
    }

    Inspector.all_scopes.each do |scope|
      if description_a[scope] && description_b[scope]
        comparison = Comparison.compare_scope(description_a, description_b, scope)
        diff[scope] = comparison.as_json
      else
        diff[:meta][:uninspected] ||= Hash.new

        if !description_a[scope] && description_b[scope]
          diff[:meta][:uninspected][description_a.name] ||= Array.new
          diff[:meta][:uninspected][description_a.name] << scope
        end
        if !description_b[scope] && description_a[scope]
          diff[:meta][:uninspected][description_b.name] ||= Array.new
          diff[:meta][:uninspected][description_b.name] << scope
        end
      end
    end

    diff.to_json
  end

  get "/compare/:a/:b" do
    haml File.read(File.join(Machinery::ROOT, "html/comparison.html.haml")),
      locals: { description_a: params[:a], description_b: params[:b] }
  end

  get "/compare/:a/:b/files/:scope/*" do
    description1 = SystemDescription.load(params[:a], settings.system_description_store)
    description2 = SystemDescription.load(params[:b], settings.system_description_store)
    filename = File.join("/", params["splat"].first)

    begin
      diff = FileDiff.diff(description1, description2, params[:scope], filename)
    rescue Machinery::Errors::BinaryDiffError
      status 406
      return "binary file"
    end

    diff.to_s(:html)
  end

  get "/:id" do
    haml File.read(File.join(Machinery::ROOT, "html/index.html.haml")),
      locals: { description_name: params[:id] }
  end
end
