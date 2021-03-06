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

class LoggedCheetah
  class << self
    def run(*args)
      run_overloaded(*args, {})
    end

    def run_with_c(*args)
      run_overloaded(*args, with_c_locale: true)
    end

    private

    def run_overloaded(*args, options)
      command = args.select { |e| e.is_a?(String) }.join(" ")
      Machinery.logger.info("Running '#{command}'")

      if options[:with_c_locale]
        with_c_locale do
          Cheetah.run(*args)
        end
      else
        with_utf8_locale do
          Cheetah.run(*args)
        end
      end
    end
  end
end
