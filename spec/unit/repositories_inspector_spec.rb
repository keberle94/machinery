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

describe RepositoriesInspector do
  let(:description) {
    SystemDescription.new("systemname", {}, SystemDescriptionStore.new)
  }

  describe ".inspect" do
    let(:zypper_output_xml) {
      <<-EOF
        <?xml version='1.0'?>
        <stream>
        <repo-list>
        <repo alias="repo-update" name="openSUSE-Update" type="rpm-md" enabled="0" autorefresh="0" gpgcheck="0">
        <url>http://download.opensuse.org/update/13.1/</url>
        </repo>
        <repo alias="repo-oss" name="openSUSE-Oss" type="yast2" enabled="1" autorefresh="1" gpgcheck="1" priority="22">
        <url>http://download.opensuse.org/distribution/13.1/repo/oss/</url>
        </repo>
        <repo alias="nu_novell_com:SLES11-SP3-Pool" name="SLES11-SP3-Pool" type="rpm-md" enabled="1" autorefresh="1" gpgcheck="1">
        <url>https://nu.novell.com/repo/$RCE/SLES11-SP3-Pool/sle-11-i586?credentials=NCCcredentials</url>
        </repo>
        </repo-list>
        </stream>
      EOF
    }
    let(:zypper_output_detail) {
      <<-EOF
Weird zypper warning message which shouldn't mess up the repository parsing.
#  | Alias               | Name                        | Enabled | Refresh | Priority | Type   | URI                                                                     | Service
---+---------------------+-----------------------------+---------+---------+----------+--------+-------------------------------------------------------------------------+--------
 8 | repo-oss            | openSUSE-Oss                | Yes     | Yes     |   23     | yast2  | http://download.opensuse.org/distribution/13.1/repo/oss/                |
10 | repo-update         | openSUSE-Update             | Yes     | Yes     |   47     | rpm-md | http://download.opensuse.org/update/13.1/                               |
15 | nu_novell_com:SLES11-SP3-Pool                    | SLES11-SP3-Pool                                  | Yes     | Yes     |   99     | rpm-md | https://nu.novell.com/repo/$RCE/SLES11-SP3-Pool/sle-11-i586?credentials=NCCcredentials             | nu_novell_com
      EOF
    }
    let(:yum_output) {
<<-EOF
Not loading "blacklist" plugin, as it is disabled
Loading "langpacks" plugin
Loading "refresh-packagekit" plugin
Not loading "whiteout" plugin, as it is disabled
Adding en_US to language list
Config time: 0.014
Yum version: 3.4.3
Setting up Package Sacks
pkgsack time: 0.013
Repo-id      : fedora/20/x86_64
Repo-name    : Fedora 20 - x86_64
Repo-status  : enabled
Repo-revision: 1386924430
Repo-tags    : binary-x86_64
Repo-distro-tags: [cpe:/o:fedoraproject:fedora:20]: Null
Repo-updated : Fri Dec 13 09:55:41 2013
Repo-pkgs    : 38,597
Repo-size    : 38 G
Repo-metalink: https://mirrors.fedoraproject.org/metalink?repo=fedora-20&arch=x86_64
  Updated    : Fri Dec 13 09:55:41 2013
Repo-baseurl : http://mirror2.hs-esslingen.de/fedora/linux/releases/20/Everything/x86_64/os/ (94 more)
Repo-expire  : 604,800 second(s) (last: Mon Oct 20 16:46:16 2014)
Repo-filename: ///etc/yum.repos.d/fedora.repo

Repo-id      : fedora-debuginfo/20/x86_64
Repo-name    : Fedora 20 - x86_64 - Debug
Repo-status  : disabled
Repo-metalink: https://mirrors.fedoraproject.org/metalink?repo=fedora-debug-20&arch=x86_64
Repo-expire  : 21,600 second(s) (last: Unknown)
Repo-filename: ///etc/yum.repos.d/fedora.repo

Repo-id      : fedora-source/20/x86_64
Repo-name    : Fedora 20 - Source
Repo-status  : disabled
Repo-metalink: https://mirrors.fedoraproject.org/metalink?repo=fedora-source-20&arch=x86_64
Repo-expire  : 21,600 second(s) (last: Unknown)
Repo-filename: ///etc/yum.repos.d/fedora.repo

repolist: 58,567
      EOF
    }
    let(:expected_repo_list) {
      RepositoriesScope.new([
        Repository.new(
          alias: "nu_novell_com:SLES11-SP3-Pool",
          name: "SLES11-SP3-Pool",
          type: "rpm-md",
          enabled: true,
          autorefresh: true,
          gpgcheck: true,
          priority: 99,
          url: "https://nu.novell.com/repo/$RCE/SLES11-SP3-Pool/sle-11-i586?credentials=NCCcredentials",
          username: "d4c0246d79334fa59a9ffe625fffef1d",
          password: "0a0918c876ef4a1d9c352e5c47421235"
        ),
          Repository.new(
          alias: "repo-oss",
          name: "openSUSE-Oss",
          type: "yast2",
          enabled: true,
          autorefresh: true,
          gpgcheck: true,
          priority: 22,
          url: "http://download.opensuse.org/distribution/13.1/repo/oss/"
        ),
          Repository.new(
          alias: "repo-update",
          name: "openSUSE-Update",
          type: "rpm-md",
          enabled: false,
          autorefresh: false,
          gpgcheck: false,
          priority: 47,
          url: "http://download.opensuse.org/update/13.1/"
        )
      ])
    }
    let(:expected_yum_repo_list) {
     RepositoriesScope.new([
        Repository.new(
          alias: "fedora/20/x86_64",
          name: "Fedora 20 - x86_64",
          type: nil,
          url: "https://mirrors.fedoraproject.org/metalink?repo=fedora-20&arch=x86_64",
          enabled: true,
          autorefresh: false,
          gpgcheck: false,
          priority: 1
        ),
        Repository.new(
          alias: "fedora-debuginfo/20/x86_64",
          name: "Fedora 20 - x86_64 - Debug",
          type: nil,
          url: "https://mirrors.fedoraproject.org/metalink?repo=fedora-debug-20&arch=x86_64",
          enabled: false,
          autorefresh: false,
          gpgcheck: false,
          priority: 1
        ),
        Repository.new(
          alias: "fedora-source/20/x86_64",
          name: "Fedora 20 - Source",
          type: nil,
          url: "https://mirrors.fedoraproject.org/metalink?repo=fedora-source-20&arch=x86_64",
          enabled: false,
          autorefresh: false,
          gpgcheck: false,
          priority: 1
        )
      ])
    }

    let(:credentials_directories) { "NCCcredentials\n" }
    let(:ncc_credentials) {
      <<-EOF
username=d4c0246d79334fa59a9ffe625fffef1d
password=0a0918c876ef4a1d9c352e5c47421235
      EOF
    }
    let(:credential_dir) { "/etc/zypp/credentials.d/" }


    it "returns data about repositories when requirements are fulfilled" do
      system = double

      expect(system).to receive(:package_manager).and_return("zypper")

      expect(system).to receive(:check_requirement).with(
        "zypper", "--version"
      )
      expect(system).to receive(:run_command).with(
        "zypper",
        "--non-interactive",
        "--xmlout",
        "repos",
        "--details",
        :stdout => :capture
      ).and_return(zypper_output_xml)

      expect(system).to receive(:run_command).with(
        "zypper",
        "--non-interactive",
        "repos",
        "--details",
        :stdout => :capture
      ).and_return(zypper_output_detail)

      expect(system).to receive(:run_command).with(
        "bash", "-c",
        "test -d '#{credential_dir}' && ls -1 '#{credential_dir}' || echo ''",
        :stdout => :capture
      ).and_return(credentials_directories)

      expect(system).to receive(:run_command).with(
        "cat",
        "/etc/zypp/credentials.d/NCCcredentials",
        :stdout => :capture
      ).and_return(ncc_credentials)

      inspector = RepositoriesInspector.new
      summary = inspector.inspect(system, description)
      expect(description.repositories).to eq(expected_repo_list)
      expect(summary).to include("Found 3 repositories")
    end

    it "returns an empty array if there are no repositories" do
      system = double
      zypper_empty_output_xml = <<-EOF
        <?xml version='1.0'?>
        <stream>
        <repo-list>
        </repo-list>
        </stream>
      EOF
      zypper_empty_output_detail = "No repositories defined. Use the " \
        "'zypper addrepo' command to add one or more repositories."

      expect(system).to receive(:package_manager).and_return("zypper")

      expect(system).to receive(:check_requirement).with(
        "zypper", "--version"
      )
      expect(system).to receive(:run_command).with(
        "zypper",
        "--non-interactive",
        "--xmlout",
        "repos",
        "--details",
        :stdout => :capture
      ).and_return(zypper_empty_output_xml)

      expect(system).to receive(:run_command).with(
        "zypper",
        "--non-interactive",
        "repos",
        "--details",
        :stdout => :capture
      ).and_return(zypper_empty_output_detail)

      inspector = RepositoriesInspector.new
      summary = inspector.inspect(system, description)
      expect(description.repositories).to eq(RepositoriesScope.new([]))
      expect(summary).to include("Found 0 repositories")
    end


    it "raise an error when requirements are not fulfilled" do
      system = double

      expect(system).to receive(:package_manager).and_return("zypper")

      expect(system).to receive(:check_requirement).with(
        "zypper", "--version"
      ).and_raise(Machinery::Errors::MissingRequirement)

      inspector = RepositoriesInspector.new
      expect{inspector.inspect(system, description)}.to raise_error(
        Machinery::Errors::MissingRequirement)
    end

    it "returns sorted data" do
      system = double
      expect(system).to receive(:package_manager).and_return("zypper")
      expect(system).to receive(:check_requirement) { true }
      expect(system).to receive(:run_command) { zypper_output_xml }
      expect(system).to receive(:run_command) { zypper_output_detail }
      expect(system).to receive(:run_command) { credentials_directories }
      expect(system).to receive(:run_command) { ncc_credentials }

      inspector = RepositoriesInspector.new

      inspector.inspect(system, description)
      names = description.repositories.map(&:name)

      expect(names).to eq(names.sort)
    end

    it "returns repositories on a redhat system" do
      system = double
      expect(system).to receive(:package_manager).and_return("yum")
      expect(system).to receive(:check_requirement) { true }
      expect(system).to receive(:run_command).with(
        "yum", "repolist", "-v", "all", :stdout => :capture
      ).and_return(yum_output)

      inspector = RepositoriesInspector.new
      summary = inspector.inspect(system, description)
      expect(description.repositories).to eq(expected_yum_repo_list)
      expect(summary).to include("Found 3 repositories")
    end
  end
end
