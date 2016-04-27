require 'will_paginate/array'


class EnhanceInstructionController < ApplicationController
  include Filterbar
  include Pagination

  before_action :set_index_props, only: [:index]

  def index
    respond_to do |format|
      format.html
      format.json { render json: @props }
    end
  end

  private

  def find_instructions
    queryset = build_search_queryset_for_model ContentGuide

    queryset.where_subject(subject_params)
            .where_grade(grade_params)
            .paginate(pagination_params.slice(:page, :per_page))
  end

  def find_videos
    queryset = build_search_queryset_for_model Resource

    queryset.media
            .where_subject(subject_params)
            .where_grade(grade_params)
            .paginate(pagination_params.slice(:page, :per_page))
  end

  def build_search_queryset_for_model(model)
    queryset = model.where(nil)

    unless search_term.blank?
      search_ids = model.search(search_term, limit: 100).results.map {|r| r.model_id.to_i }
      queryset = queryset.where(id: search_ids).order_as_specified(id: search_ids)
    end

    queryset
  end

  def set_index_props
    @instructions = find_instructions
    @props = serialize_with_pagination(@instructions,
      pagination: pagination_params,
      each_serializer: InstructionSerializer
    )
    videos = serialize_with_pagination(find_videos,
      pagination: pagination_params,
      each_serializer: VideoInstructionSerializer
    )[:results]
    @props.merge!(filterbar_props)
    @props.merge!(videos: videos)
  end

end
