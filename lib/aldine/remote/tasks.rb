# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative('../remote').then do
  ::Aldine.dotenv { require 'rake' }
end

autoload(:IRB, 'irb')
autoload(:FileUtils, 'fileutils')

# variables -----------------------------------------------------------

path = Aldine::Remote::Path
settings = Aldine::Settings.instance
fs = FileUtils::Verbose
pdf = lambda do |type|
  Aldine::Remote::PdfBuilder.new(type).call.tap { |file| fs.mv(file, path.call('out')) }
end

# constants -----------------------------------------------------------

PDF_TYPES = lambda do
  Dir.chdir(path.call(:src).to_path) do
    Dir.glob("#{settings.get('latex_name')}*.tex").map do |fname|
      fname.gsub(/^#{settings.get('latex_name')}\./, '').gsub(/\.tex/, '').to_sym
    end.sort
  end
end.call

# tasks ---------------------------------------------------------------
task default: [:all]

Signal.trap('INT') { warn('Interrupt') } # Handle interrupt (without error)

PDF_TYPES.tap do |types|
  desc 'Build all pdf'
  # rubocop:disable Style/SymbolProc
  task all: types.map { |type| "pdf:#{type}" } do |task|
    task.reenable
  end
  # rubocop:enable Style/SymbolProc

  types.each do |type|
    desc "Build PDF with format: #{type}"
    task "pdf:#{type}" do |task|
      pdf.call(type)
      task.reenable
    end
  end

  desc 'Tail log files allowing to see new log entries as they are written'
  task :log do |task|
    # rubocop:disable Layout/BlockAlignment
    types
      .map { |type| path.call(:tmp).join([settings.get(:output_name), type, 'log'].join('.')) }
      .map { |fp| fs.touch(fp) }.tap do |res|
      Aldine::Shell::Command.new(%w[tail --retry -F].concat(res.flatten)).call
    rescue Aldine::Shell::CommandError => e
      raise unless e.status.to_s.match(/\(signal\s+2\)$/)
    end
    # rubocop:enable Layout/BlockAlignment
    task.reenable
  end
end

desc 'Shell (irb)'
task :shell do
  ARGV.clear
  -> { IRB.start }.tap do
    {
      SAVE_HISTORY: 1000,
      HISTORY_FILE: "#{ENV.fetch('TMPDIR', '/tmp')}/.irb_history",
    }.map { |k, v| IRB.conf[k] = v }
  end.call
end

desc 'Watch'
task :watch do
  exclude_matcher = /%r{#{settings.get('watch_exclude', '^.*/(\..+)$')}}/

  Aldine::Remote::InotifyWait.new(path.call('src').to_s).call do |fpath, events|
    Aldine::Shell::Chalk.warn({ fpath => events }, fg: :yellow)
    unless fpath.match(exclude_matcher)
      [:reenable, :invoke].each { |m| Rake::Task[:sync].public_send(m) }
      begin
        PDF_TYPES.each { |type| pdf.call(type) }
      rescue Aldine::Shell::CommandError => e
        ["#{e.class} [#{e.command.first}]:", e.backtrace[-3..-1].to_a.join("\n")].join("\n").tap do |message|
          Shell::Chalk.warn(message, fg: :black, bg: :red)
        end
      end
    end
  end
end

desc 'Synchronize build directory from sources'
task :sync do
  [
    Aldine::Remote::Synchro.new(path.call('src'), path.call('tmp')),
    Aldine::Remote::BundleSetup.new(path.call('tmp')),
  ].each(&:call)
end

desc 'Vendorer install'
task :'vendorer:install' do
  settings.get('container.workdir').then do |workdir|
    Dir.chdir(workdir) do
      ::Aldine::Remote::Vendorer.new.then { |vendorer| vendorer.file ? vendorer.call : [] }.then do |errors|
        raise errors.first unless errors.empty?
      end
    end
  end
end
