class RatingsController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:close, :update, :follow, :unfollow]

  def index
    params = unsafe_params_hash.select{|k, v| v.present? }

    filter_params = {}

    m_selected_category = Maybe(@current_community.categories.find_by_url_or_id(params[:category]))
    filter_params[:categories] = m_selected_category.own_and_subcategory_ids.or_nil
    selected_category = m_selected_category.or_nil
    relevant_filters = select_relevant_filters(m_selected_category.own_and_subcategory_ids.or_nil)
    relevant_search_fields = parse_relevant_search_fields(params, relevant_filters)

    @categories = @current_community.categories.includes(:children)
    @main_categories = @categories.select { |c| c.parent_id == nil }

    @show_categories = @categories.size > 1
    @category_menu_enabled = @show_categories || @show_custom_fields

    @persons = Array.new()
    Category::persons_by_listings_in_category(selected_category).flatten.uniq.each do |target_user|
      @persons.push({
        person: target_user,
        testimonials_count: TestimonialViewUtils.received_testimonials_in_community(target_user, @current_community).count,
        ptc: TestimonialViewUtils.received_positive_testimonials_in_community(target_user, @current_community).count,
        ntc: TestimonialViewUtils.received_negative_testimonials_in_community(target_user, @current_community).count,
        feedback_positive_percentage: target_user.feedback_positive_percentage_in_community(@current_community)
      })
    end

    @persons.sort! {|a1,a2| a2[:feedback_positive_percentage] <=> a1[:feedback_positive_percentage]}

    limit = params[:per_page].to_i
    render :locals => {
        :persons => @persons,
        :limit => limit,
        :selected_category => selected_category,
        :search_params => CustomFieldSearchParams.remove_irrelevant_search_params(params, relevant_search_fields),
    }
  end

  private

  def filter_unnecessary(search_params, numeric_fields)
    search_params.reject do |search_param|
      numeric_field = numeric_fields.find(search_param[:id])
      search_param.slice(:id, :value) == { id: numeric_field.id, value: (numeric_field.min..numeric_field.max) }
    end
  end

  def parse_relevant_search_fields(params, relevant_filters)
    search_filters = SearchPageHelper.parse_filters_from_params(params)
    checkboxes = search_filters[:checkboxes]
    dropdowns = search_filters[:dropdowns]
    numbers = filter_unnecessary(search_filters[:numeric], @current_community.custom_numeric_fields)
    search_fields = checkboxes.concat(dropdowns).concat(numbers)

    SearchPageHelper.remove_irrelevant_search_fields(search_fields, relevant_filters)
  end

  def select_relevant_filters(category_ids)
    relevant_filters =
        if category_ids.present?
          @current_community
              .custom_fields
              .joins(:category_custom_fields)
              .where("category_custom_fields.category_id": category_ids, search_filter: true)
              .distinct
        else
          @current_community
              .custom_fields.where(search_filter: true)
        end

    relevant_filters.sort
  end

  def unsafe_params_hash
    params.to_unsafe_hash
  end
end
