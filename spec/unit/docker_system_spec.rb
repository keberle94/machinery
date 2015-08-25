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

require_relative "spec_helper"

describe DockerSystem do
  describe "#check_host" do
    let(:docker_ps_output) { <<-EOF
CONTAINER ID        IMAGE                     COMMAND                CREATED             STATUS              PORTS               NAMES
c311f5336878        opensuse/mariadb:latest   "/bin/bash /scripts/   2 hours ago         Up 2 hours          3306/tcp            bla_db_1
EOF
}

    it "raises an error if container id does not exist" do
      expect(Cheetah).to receive(:run).with("docker", "ps", stdout: :capture).
        and_return(docker_ps_output)

      expect { DockerSystem.new("bla") }.to raise_error(Machinery::Errors::InspectionFailed)
    end

    it "does not raise an error if container id is valid" do
      expect(Cheetah).to receive(:run).with("docker", "ps", stdout: :capture).
        and_return(docker_ps_output)

      expect { DockerSystem.new("c311f5336878") }.not_to raise_error
    end
  end
end
