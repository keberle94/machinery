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

class ContainerizeTask
  def containerize(description, dir)
    output_path = File.join(dir, description.name)

    mapper = WorkloadMapper.new
    workloads = mapper.identify_workloads(description)

    if workloads.empty?
      Machinery::Ui.puts "No workloads detected."
    else
      FileUtils.mkdir_p(output_path)
      mapper.save(workloads, output_path)
      mapper.extract(description, workloads, output_path)
      write_readme_file(output_path)

      workloads.each do |workload|
        Machinery::Ui.puts "Detected workload '#{workload[0]}'."
      end
      Machinery::Ui.puts "\nWrote to #{output_path}."
    end
  end

  def write_readme_file(dir)
    FileUtils.cp(
      File.join(Machinery::ROOT, "export_helpers", "containerize_readme.md"),
      File.join(dir, "README.md")
    )
  end
end
