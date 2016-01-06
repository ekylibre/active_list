
require 'csv'
require 'action_dispatch'
require 'rails'
require 'code_string'
require 'i18n-complements'

module ActiveList
  # Build and returns a short UID
  def self.new_uid
    @@last_uid ||= 0
    uid = @@last_uid.to_s(36).to_sym
    @@last_uid += 1
    uid
  end

  autoload :VERSION,    'active_list/version'
  autoload :Helpers,    'active_list/helpers'
  autoload :Definition, 'active_list/definition'
  autoload :Renderers,  'active_list/renderers'
  autoload :Exporters,  'active_list/exporters'
  autoload :Generator,  'active_list/generator'

  # Set the temporary directory
  # Pathname or callable are acceptable
  def self.temporary_directory=(dir)
    if dir.respond_to?(:call) || dir.is_a?(Pathname)
      @@temporary_directory = dir
    else
      @@temporary_directory = Pathname(dir)
    end
  end

  # Returns the temporary directory
  def self.temporary_directory
    if @@temporary_directory.respond_to? :call
      @@temporary_directory.call
    else
      @@temporary_directory
    end
  end

  mattr_reader :renderers
  @@renderers = {}

  def self.register_renderer(name, renderer)
    unless renderer < ActiveList::Renderers::AbstractRenderer
      fail ArgumentError, 'A renderer must be ActiveList::Renderers::Renderer'
    end
    @@renderers[name] = renderer
  end

  mattr_reader :exporters
  @@exporters = {}

  def self.register_exporter(name, exporter)
    unless exporter < ActiveList::Exporters::AbstractExporter
      fail ArgumentError, "ActiveList::Exporters::AbstractExporter expected (got #{exporter.name}/#{exporter.ancestors.inspect})"
    end
    @@exporters[name] = exporter
  end
end

ActiveList.temporary_directory = Pathname(Dir.tmpdir)

ActiveList.register_renderer(:simple_renderer, ActiveList::Renderers::SimpleRenderer)

ActiveList.register_exporter(:ods,  ActiveList::Exporters::OpenDocumentSpreadsheetExporter)
ActiveList.register_exporter(:csv,  ActiveList::Exporters::CsvExporter)
ActiveList.register_exporter(:xcsv, ActiveList::Exporters::ExcelCsvExporter)

unless 'string'.respond_to? :dig
  class ::String
    def dig(depth = 1)
      strip.gsub(/^/, '  ' * depth) + "\n"
    end
  end
end

require 'active_list/rails'
