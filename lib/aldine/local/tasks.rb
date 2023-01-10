# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

# Define local tasks runnable through rake.
#
# The default task is to generate TeX output files.
# Tasks strictly relating to LaTeX live in the ``tex`` namespace.

require_relative('../local').then do
  ::Aldine.dotenv

  {
    Rake: 'rake',
    Bundler: 'bundler',
    FileUtils: 'fileutils',
    Pathname: 'pathname',
  }.each { |k, v| autoload(k, v) }
end

# variables -----------------------------------------------------------------

docker = ::Aldine::Local::Docker
tex = ::Aldine::Local::Tex

# mixins ----------------------------------------------------------------------

[
  ::Aldine::Concerns::SettingsAware,
].each { |mixin| self.__send__(:include, mixin) }

# @note Mixins documentation only (IDE helper).
class Object
  # @!method settings()
  #   @return [Aldine::Settings]
end

# tasks ----------------------------------------------------------------------

task default: [:'tex:build']

desc 'Docker build'
task :'docker:build' do
  docker.build
  docker.install
end

desc 'Shell'
task shell: %w[docker:build] do
  docker.run
end

desc 'Irb'
task irb: %w[docker:build] do
  docker.rake(:shell, path: settings.get('directories.src'))
end

desc 'TeX sync'
task 'tex:sync': %w[docker:build] do
  docker.rake(:sync, path: settings.get('directories.src'))
end

desc 'TeX build'
task 'tex:build': %w[tex:install vendorer:install tex:sync] do
  docker.rake(:all, path: settings.get('directories.tmp'))
end

desc 'Install provided TeX packages'
task 'tex:install' do
  tex.installer.call.then do |packages|
    if packages.is_a?(Array) and !packages.empty?
      puts('installed packages: %s' % packages.join(', '))
    end
  end
end

desc 'TeX log'
task 'tex:log': %w[docker:build] do
  docker.rake(:log, path: settings.get('directories.src'))
end

desc 'Vendorer install'
task 'vendorer:install': %w[docker:build] do
  docker.rake(:'vendorer:install', path: settings.get('directories.src'))
end
