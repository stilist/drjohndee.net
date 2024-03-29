# frozen_string_literal: true

#--
# The life and times of Dr John Dee
# Copyright (C) 2023  Jordan Cole <feedback@drjohndee.net>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#++

module HistoricalDiary
  module JekyllLayer
    module Shared
      # Convenience methods for reading the <tt>Jekyll::Site</tt> config. It
      # can only be used in files that `include` both `Shared::Config` and
      # `Shared::Site`.
      module Config
        class ConfigIsMissingRequiredKeyError < ArgumentError; end

        DEFAULT_CONFIG = {
          calendar_system: 'Gregorian',
          lang: 'en',
        }.freeze
        private_constant :DEFAULT_CONFIG

        CONFIG_NAMESPACE = 'historical_diary'
        private_constant :CONFIG_NAMESPACE

        # Attempt to retrieve a plugin-specific config value. If the config
        # doesn't define `key`, this may return a default value.
        def config(key, scoped: false)
          config_without_fallback(key, scoped:) || DEFAULT_CONFIG[key.to_sym]
        end

        # The same as `#config`, but raises `ConfigIsMissingKeyError` if the
        # key is not set.
        def config!(key, scoped: false)
          value = config_without_fallback(key, scoped:)
          return value unless value.nil?

          message = "Site config does not define '#{key}'"
          message << " in the #{CONFIG_NAMESPACE} namespace" if scoped
          raise ConfigIsMissingRequiredKeyError, message
        end

        private

        # Attempt to retrieve a plugin-specific config value, which may not be
        # set in the config.
        def config_without_fallback(key, scoped:)
          if scoped
            site_object.config.dig CONFIG_NAMESPACE, key.to_s
          else
            site_object.config[key.to_s]
          end
        end
      end
    end
  end
end
