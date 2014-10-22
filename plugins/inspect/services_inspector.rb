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

class ServicesInspector < Inspector
  def inspect(system, description, options = {})
    if has_systemd(system)
      result = ServicesScope.new(
        init_system: "systemd",
        services:    inspect_systemd_services(system)
      )
    elsif has_redhat_chkconfig(system)
      result = ServicesScope.new(
        init_system: "sysvinit",
        services:    inspect_sysvinit_redhat_services(system)
      )
    else
      result = ServicesScope.new(
        init_system: "sysvinit",
        services:    inspect_sysvinit_services(system)
      )
    end

    description.services = result
    @summary
  end

  private

  def has_systemd(system)
    system.run_command("systemctl", "--version")
    true
  rescue Cheetah::ExecutionFailed
    false
  end

  def has_redhat_chkconfig(system)
    system.run_command("chkconfig", "--version")
    true
  rescue Cheetah::ExecutionFailed
    false
  end

  def inspect_systemd_services(system)
    output = system.run_command(
      "systemctl",
      "list-unit-files",
      "--type=service,socket",
      :stdout => :capture
    )

    # The first line contains a table header. The last two lines contain a
    # separator and a summary (e.g. "197 unit files listed"). We also filter
    # templates.
    lines = output.lines[1..-3].reject { |l| l =~ /@/ }

    @summary = "Found #{lines.size} services."

    services = lines.map do |line|
      name, state = line.split(/\s+/)

      Service.new(name: name, state: state)
    end

    ServiceList.new(services.sort_by(&:name))
  end

  def inspect_sysvinit_services(system)
    system.check_requirement("chkconfig", "--help")

    output = system.run_command(
      "chkconfig",
      "--allservices",
      :stdout => :capture
    )

    @summary = "Found #{output.lines.size} services."

    services = output.lines.map do |line|
      name, state = line.split(/\s+/)

      Service.new(name: name, state: state)
    end

    ServiceList.new(services.sort_by(&:name))
  end

  def inspect_sysvinit_redhat_services(system)
    system.check_requirement("chkconfig", "--version")
    system.check_requirement("runlevel")

    output = system.run_command(
      "chkconfig", "--list",
      :stdout => :capture
    )

    previouslevel,runlevel = system.run_command(
      "runlevel",
      :stdout => :capture
    ).split(" ")


    @summary = "Found #{output.lines.size} services."

    services = output.lines.map do |line|
      state=[]
      name, state[0], state[1], state[2], state[3], state[4], state[5], state[6] = line.split(/\s+/)
      Service.new(name: name, state: state[runlevel.to_i].split(":")[1])
    end

    ServiceList.new(services.sort_by(&:name))
  end

end
