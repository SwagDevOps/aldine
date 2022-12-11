# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
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

settings = Aldine::Settings.instance

# tasks ----------------------------------------------------------------------

task default: [:'tex:build']

desc 'Docker build'
task :'docker:build' do
  Aldine::Local::Docker.build
  Aldine::Local::Docker.install
end

desc 'Shell'
task shell: %w[docker:build] do
  Aldine::Local::Docker.run
end

desc 'Irb'
task irb: %w[docker:build] do
  Aldine::Local::Docker.rake(:shell, path: settings.get('directories.src'))
end

desc 'TeX sync'
task 'tex:sync': %w[docker:build] do
  Aldine::Local::Docker.rake(:sync, path: settings.get('directories.src'))
end

desc 'TeX build'
task 'tex:build': %w[vendorer:install tex:sync] do
  Aldine::Local::Docker.rake(:all, path: settings.get('directories.tmp'))
end

desc 'TeX log'
task 'tex:log': %w[docker:build] do
  Aldine::Local::Docker.rake(:log, path: settings.get('directories.src'))
end

desc 'Vendorer install'
task 'vendorer:install': %w[docker:build] do
  Aldine::Local::Docker.rake(:'vendorer:install', path: settings.get('directories.tmp'))
end
