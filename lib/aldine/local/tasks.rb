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
  ::Aldine.dotenv { require 'rake' }
end

autoload(:Bundler, 'bundler')
autoload(:FileUtils, 'fileutils')
autoload(:Pathname, 'pathname')

# environment ----------------------------------------------------------------

caller_locations.fetch(0).to_s.then do |fp|
  ENV['TEX_PROJECT_NAME'] ||= Pathname.new(fp).dirname.basename.to_s.freeze
end

# config ---------------------------------------------------------------------

config = Aldine::Local::Config

# tasks ----------------------------------------------------------------------

task default: [:'tex:build']

unless Rake::Task.task_defined?(:setup)
  desc 'Setup'
  task :setup do
    # @todo do something with the bin directory of gem?
    # Bundler.locked_gems.specs.keep_if { |v| v.name == 'aldine' }.fetch(0).full_gem_path
  end
end

desc 'Docker build'
task :'docker:build' do
  Aldine::Local::Docker.build
  Aldine::Local::Docker.install
end

desc 'Shell'
task shell: %w[docker:build setup] do
  Aldine::Local::Docker.run
end

desc 'Irb'
task irb: %w[docker:build setup] do
  Aldine::Local::Docker.rake(:shell, path: config[:src_dir])
end

desc 'TeX sync'
task 'tex:sync': %w[docker:build setup] do
  Aldine::Local::Docker.rake(:sync, path: config[:src_dir])
end

desc 'TeX build'
task 'tex:build': %w[tex:sync] do
  Aldine::Local::Docker.rake(:all, path: config[:tex_dir])
end

desc 'TeX log'
task 'tex:log': %w[docker:build setup] do
  Aldine::Local::Docker.rake(:log, path: config[:src_dir])
end

desc 'Vendorer setup'
task 'vendorer:setup': %w[docker:build setup] do
  Aldine::Local::Docker.rake(:'vendorer:setup', path: config[:tmp_dir])
end
