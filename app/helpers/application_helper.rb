module ApplicationHelper
  def svg(name, options = {})
    file_path = "#{Rails.root}/app/assets/images/svg_icons/#{name}.svg"

    if File.exist? file_path
      file = File.read(file_path)
      doc = Nokogiri::HTML::DocumentFragment.parse file
      svg = doc.at_css "svg"
      svg["class"] = options[:class] if options[:class].present?
    else
      doc = "<!-- SVG #{name} not found -->"
    end

    raw doc
  end
end
