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

class PackagesRenderer < Renderer
  def do_render
    return unless @system_description.packages

    list do
      @system_description.packages.each do |p|
        item "#{p.name}-#{p.version}-#{p.release}.#{p.arch} (#{p.vendor})"
      end
    end
  end

  def do_render_comparison(description1, description2, description_common)
    @changed_packages = if description1.packages && description2.packages
      description1.packages.map(&:name) & description2.packages.map(&:name)
    else
      []
    end

    if description1.packages &&
      !description1.packages.reject { |package| @changed_packages.include?(package.name) }.empty?
      render_comparison_only_in(description1)
    end
    if description2.packages &&
      !description2.packages.reject { |package| @changed_packages.include?(package.name) }.empty?
      render_comparison_only_in(description2)
    end
    render_comparison_changed(description1, description2)
    render_comparison_common(description_common) if @options[:show_all]
  end

  # In the comparison case we only want to show the package name, not all details like version,
  # architecture etc.
  def do_render_comparison_only_in
    packages = @system_description.packages.reject { |package| @changed_packages.include?(package.name) }

    list do
      packages.each do |p|
        item "#{p.name}"
      end
    end
  end

  def render_comparison_changed(description1, description2)
    return if @changed_packages.empty?

    packages = description1.packages.select { |package| @changed_packages.include?(package.name) }

    puts "In both with different attributes ('#{description1.name}' <> '#{description2.name}'):"
    indent do
      list do
        packages.each do |package|
          other_package = description2.packages.find { |p| package.name == p.name}

          changes = []
          ["version", "vendor"].each do |attribute|
            if package[attribute] != other_package[attribute]
              changes << "#{attribute}: #{package[attribute]} <> #{other_package[attribute]}"
            end
          end

          item "#{package.name} (#{changes.join(", ")})"
        end
      end
    end
  end

  def display_name
    "Packages"
  end
end
