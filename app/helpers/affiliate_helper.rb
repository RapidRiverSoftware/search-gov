module AffiliateHelper
  def affiliate_center_breadcrumbs(crumbs)
    aff_breadcrumbs =
      [link_to("Admin Center", sites_path), crumbs]
    breadcrumbs(aff_breadcrumbs.flatten)
  end

  def site_wizard_header(current_step)
    steps = {:basic_settings => 0, :content_sources => 1, :get_the_code => 2}
    step_contents = ["Step 1. Basic Settings", "Step 2. Set up site", "Step 3. Get the code"]
    image_tag("legacy/site_wizard_step_#{steps[current_step] + 1}.png", :alt => "#{step_contents[steps[current_step]]}")
  end

  def render_help_link(help_link)
    link_to(image_tag('legacy/help_icon.png', alt: 'Help?'), help_link.help_page_url, target: '_blank') if help_link
  end

  def render_last_crawl_status_dialog(dialog_id, url, last_crawl_status)
    content = ''
    content << link_to('Error', '#', :class => 'dialog-link', :dialog_id => dialog_id)
    content << link_to(content_tag(:span, nil, :class => 'ui-icon ui-icon-newwin'), '#', :class => 'dialog-link', :dialog_id => dialog_id)
    error_message_text = h(url)
    error_message_text << tag(:br)
    error_message_text << h(last_crawl_status)
    content << content_tag(:div, error_message_text.html_safe, :class => 'url-error-message hide', :id => dialog_id)
    content.html_safe
  end

  def javascript_full_path_tag(request, source)
    javascript_include_tag "//#{request.host_with_port}#{source}"
  end

  def render_affiliate_header(affiliate)
    if affiliate.uses_managed_header_footer?
      html = render_managed_header(affiliate)
      if affiliate.managed_header_links.present?
        html << content_tag(:div, render_managed_links(affiliate.managed_header_links).html_safe, :class => 'managed-header-footer-links-wrapper')
      end
      content_tag(:div, html.html_safe, :id => 'header', :class => 'managed') unless html.blank?
    elsif !affiliate.uses_managed_header_footer? and affiliate.header.present?
      content_tag(:div, affiliate.header.html_safe, :id => 'header', :class => 'header-footer')
    end
  end

  def render_managed_header(affiliate)
    content = ''
    if affiliate.header_image_file_name.present?
      begin
        image_style = 'display: inline-block;'
        content << link_to_unless(affiliate.website.blank?, image_tag(affiliate.header_image.url, :alt => 'logo', :style => "#{image_style}"), affiliate.website)
      rescue Exception
        nil
      end
    else
      style = 'font-family: Georgia, serif; font-size: 50px; display: inline-block; margin: 0;'
      content << link_to_unless(affiliate.website.blank?, content_tag(:div, affiliate.display_name, style: style), affiliate.website)
    end
    content.blank? ? content : content_tag(:div, content.html_safe, id: 'managed_header').html_safe
  end

  def render_managed_links(links)
    content = ''
    links.each_with_index do |link, index|
      options = {:class => 'first'} if index == 0
      content << content_tag(:li, link_to(link[:title], link[:url], options).html_safe) << "\n"
    end
    content_tag(:ul, content.html_safe, :class => 'managed-header-footer-links')
  end

  def render_affiliate_footer(affiliate)
    if affiliate.uses_managed_header_footer? and affiliate.managed_footer_links.present?
      html = content_tag(:div, render_managed_links(affiliate.managed_footer_links).html_safe, :class => 'managed-header-footer-links-wrapper')
      content_tag(:div, html.html_safe, id: 'usasearch_footer', class: 'managed')
    elsif !affiliate.uses_managed_header_footer? and affiliate.footer.present?
      content_tag(:div, affiliate.footer.html_safe, id: 'usasearch_footer', class: 'header-footer')
    end
  end

  def render_affiliate_body_class(affiliate)
    classes = "one-serp default #{I18n.locale}"
    classes << ' with-content-border' if affiliate.show_content_border?
    classes << ' with-content-box-shadow' if affiliate.show_content_box_shadow?
    classes
  end

  def render_affiliate_body_style(affiliate)
    style = ''
    background_color = render_affiliate_css_property_value(affiliate.css_property_hash, :page_background_color)
    background_image_url = affiliate.page_background_image.url rescue nil if affiliate.page_background_image_file_name.present?
    if background_image_url.present?
      background_repeat = render_affiliate_css_property_value(affiliate.css_property_hash, :page_background_image_repeat)
      style << "background: #{background_color} url(#{background_image_url}) #{background_repeat} center top"
    else
      style << "background-color: #{background_color}"
    end
    style
  end

  def render_staged_color_text_field_tag(affiliate, field_name_symbol)
    staged_css_property_hash = affiliate.staged_theme == 'custom' ? affiliate.staged_css_property_hash : Affiliate::THEMES[affiliate.staged_theme.to_sym]
    disabled = affiliate.staged_theme != 'custom'
    staged_css_property_hash = {} if staged_css_property_hash.nil?
    text_field_tag "affiliate[staged_css_property_hash][#{field_name_symbol}]",
                   render_affiliate_css_property_value(staged_css_property_hash, field_name_symbol),
                   {:disabled => disabled, :class => 'color { hash:true, adjust:false }'}
  end

  def render_embed_code_javascript(affiliate)
    embed_code = <<-JS
      var usasearch_config = { siteHandle:"#{affiliate.name}" };

      var script = document.createElement("script");
      script.type = "text/javascript";
      script.src = "//#{request.host_with_port}/javascripts/remote.loader.js";
      document.getElementsByTagName("head")[0].appendChild(script);
    JS
    javascript_tag embed_code
  end
end
