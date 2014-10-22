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

require_relative "spec_helper"

describe ServicesInspector do
  describe "#inspect" do
    subject(:inspector) { ServicesInspector.new }

    let(:description) {
      SystemDescription.new("systemname", {}, SystemDescriptionStore.new)
    }

    let(:systemctl_list_unit_files_output) {
      <<-EOF
UNIT FILE         STATE
alsasound.service static
autofs.service    disabled
getty@.service    enabled
syslog.socket     enabled

4 unit files listed.
EOF
    }

    let(:chkconfig_output) {
      <<-EOF
boot.isapnp               on
alsasound                 on
autofs                    off
EOF
    }

    let(:chkconfig_redhat_output) {
      <<-EOF
crond           0:off   1:off   2:on    3:on    4:on    5:on    6:off
dnsmasq         0:off   1:off   2:off   3:off   4:off   5:off   6:off
EOF
    }


    it "returns data about systemd services when systemd is present" do
      system = double
      expect(system).to receive(:run_command).
        with("systemctl", "--version")
      expect(system).to receive(:run_command).
        with(
          "systemctl",
          "list-unit-files",
          "--type=service,socket",
          :stdout => :capture
        ).
        and_return(systemctl_list_unit_files_output)

      summary = inspector.inspect(system, description)

      expect(description.services).to eq(ServicesScope.new(
        init_system: "systemd",
        services:    ServiceList.new([
          Service.new(name: "alsasound.service", state: "static"),
          Service.new(name: "autofs.service",    state: "disabled"),
          Service.new(name: "syslog.socket",     state: "enabled")
        ])
      ))
      expect(summary).to eq("Found 3 services.")
    end

    it "returns data about SysVinit services when no systemd is present" do
      system = double
      expect(system).to receive(:run_command).
        with("systemctl", "--version").
        and_raise(Cheetah::ExecutionFailed.new(nil, nil, nil, nil))
      expect(system).to receive(:run_command).
        with("chkconfig", "--version").
        and_raise(Cheetah::ExecutionFailed.new(nil, nil, nil, nil))
      expect(system).to receive(:check_requirement).
        with("chkconfig", "--help")
      expect(system).to receive(:run_command).
        with("chkconfig", "--allservices", :stdout => :capture).
        and_return(chkconfig_output)

      summary = inspector.inspect(system, description)


      expect(description.services).to eq(ServicesScope.new(
        init_system: "sysvinit",
        services:    ServiceList.new([
          Service.new(name: "alsasound",   state: "on"),
          Service.new(name: "autofs",      state: "off"),
          Service.new(name: "boot.isapnp", state: "on"),
        ])
      ))
      expect(summary).to eq("Found 3 services.")
    end

    it "raises an exception when requirements are not fulfilled" do
      system = double
      expect(system).to receive(:run_command).
        with("systemctl", "--version").
        and_raise(Cheetah::ExecutionFailed.new(nil, nil, nil, nil))
      expect(system).to receive(:run_command).
        with("chkconfig", "--version").
        and_raise(Cheetah::ExecutionFailed.new(nil, nil, nil, nil))
      expect(system).to receive(:check_requirement).
        with("chkconfig", "--help").
        and_raise(Machinery::Errors::MissingRequirement)

      expect {
        inspector.inspect(system, description)
      }.to raise_error(Machinery::Errors::MissingRequirement)
    end

    it "returns data about SysVinit services on a redhat system" do
      system = double
      expect(system).to receive(:run_command).
        with("systemctl", "--version").
        and_raise(Cheetah::ExecutionFailed.new(nil, nil, nil, nil))
      expect(system).to receive(:run_command).
        with("chkconfig", "--version").
        and_return("chkconfig version 1.3.49.3")
      expect(system).to receive(:check_requirement).
        with("chkconfig", "--version")
      expect(system).to receive(:check_requirement).
        with("runlevel")
      expect(system).to receive(:run_command).
        with("runlevel", :stdout => :capture).
        and_return("N 5")
      expect(system).to receive(:run_command).
        with("chkconfig", "--list", :stdout => :capture).
        and_return(chkconfig_redhat_output)
      summary = inspector.inspect(system, description)

      expect(description.services).to eq(ServicesScope.new(
        init_system: "sysvinit",
        services:    ServiceList.new([
          Service.new(name: "crond", state: "on"),
          Service.new(name: "dnsmasq", state: "off"),
        ])
      ))
      expect(summary).to eq("Found 2 services.")
    end
  end
end
