# Copyright (c) 2013-2014 SUSE LLC
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

class Docker < Exporter
  attr_accessor :name

  def initialize(description)
    @name = "docker"
    @system_description = description
  end

  def write(output_dir)
    File.write(File.join(output_dir, "Dockerfile"), dockerfile_content)
  end

  def export_name
    "#{@system_description.name}-docker"
  end

  private

  def base_image
    case @system_description.os
    when OsOpenSuse13_1
      "opensuse:13.1"
    when OsOpenSuse13_2
      "opensuse:13.2"
    else
      raise Machinery::Errors::ExportFailed.new(
        "Export is not possible because the operating system " \
        "'#{@system_description.os.display_name}' is not supported."
      )
    end
  end

  def dockerfile_content
    <<EOF
FROM #{base_image}
EOF
  end
end
