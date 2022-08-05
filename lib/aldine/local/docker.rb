# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../local'

# Local to docker communication methods.
module Aldine::Local::Docker
  autoload(:Pathname, 'pathname')

  class << self
    # Get workdir used inside docker container.
    #
    # @return [Pathname
    def workdir
      '/workdir'.then { |path| Pathname.new(path) }
    end

    def user
      shell.user
    end

    def image
      "u#{user.uid}/texlive-#{tex.project_name}"
    end

    def directories
      # tex directories
      %w[out src tmp].sort.freeze
    end

    def build
      shell.sh('/usr/bin/env', 'docker', 'build', '-t', image, './docker')
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength

    # Executes given command in a container.
    #
    # @param [Array<String>] command
    # @param [String] path
    # @param [Struct] user
    #
    # @return [Process::Status]
    def run(command = [], path: nil, user: nil)
      user ||= self.user

      [
        '/usr/bin/env', 'docker', 'run', '--rm',
        shell.tty? ? '-it' : nil,
        '-u', [user.uid, user.gid].join(':'),
        '-e', "TERM=#{ENV.fetch('TERM', 'xterm')}",
        '-e', "OUTPUT_NAME=#{tex.output_name}",
        '-e', "TMPDIR=/tmp/u#{user.uid}",
        '-v', "#{shell.pwd.join('gems.rb').realpath}:#{workdir.join('gems.rb')}:ro",
        '-v', "#{shell.pwd.join('gems.locked').realpath}:#{workdir.join('gems.locked')}:ro",
        '-v', "#{shell.pwd.join('vendor').realpath}:#{workdir.join('vendor')}",
        '-v', "#{shell.pwd.join('.bundle').realpath}:#{workdir.join('.bundle')}",
        '-v', "#{shell.pwd.join('src').realpath}:#{workdir.join('src')}:ro",
        '-v', "#{shell.pwd.join('out').realpath}:#{workdir.join('out')}",
        '-v', "#{shell.pwd.join('tmp').realpath}:#{workdir.join('tmp')}",
        '-v', "#{shell.pwd.join('.tmp').realpath}:/tmp/u#{user.uid}",
        '-w', "/workdir/#{path}",
        image
      ]
        .compact
        .concat(command)
        .then { |params| shell.sh(*params) }
    end

    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def install
      run(%w[bundle install --standalone])
    end

    def rake(task, path: nil)
      run(%w[bundle exec rake].concat([task.to_s]), path: path)
    end

    protected

    def fs
      shell.fs
    end

    def shell
      ::Aldine::Local::Shell
    end

    def tex
      ::Aldine::Local::Tex
    end
  end
end
