# frozen_string_literal: true

module PagesHelper
  def standardsinstitutes_link
    @standardsinstitutes_link ||= link_to('Learn More',
      'http://www.standardsinstitutes.org/institute/winter-2017-standards-institute',
      class: 'o-btn o-btn--register u-margin-bottom--zero', target: '_blank')
  end
end
