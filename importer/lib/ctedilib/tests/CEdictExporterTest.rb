require 'test/unit'

class CEdictExporterTest < Test::Unit::TestCase

  def test_export
    exporter = CEdictExporter.new
    exporter.export_staging_db_from_table("cards_staging", [ $options[:system_tags]['LWE_FAVORITES'], $options[:system_tags]['BAD_DATA'] ])
  end

end