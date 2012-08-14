module ComponentHelper

  # Goals: 
  # 1. Remove all newlines
  # 2. Remove all spaces
  # N.B. Given that incoming data from EAD guides cannot be trusted for legibility
  # all strings exported from this data, especially for ExportIviewXml module,
  # have to be stripped of their newlines and extraneous spaces
  #
  # 3. Remove all commas.  Iview/MS Expression Media does not do well with commas in 
  # <SetName> values.  Since the contents of the title do not matter for export and
  # are only of consequence for student worker legibility, they can be removed.
  def format_component_strings(string)
    begin
      return string.strip.gsub(/\n/, ' ').gsub(/  +/, ' ').gsub(/,/, '').gsub(/;/, '').truncate(100)
    rescue Exception => e
      return nil
    end
  end

end
