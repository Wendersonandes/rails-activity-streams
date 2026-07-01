class LocationsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_after_action :verify_authorized

  def states
    country = params[:country] || "BR"
    states = CS.states(country.to_sym)
    options = states.map { |code, name| "<option value=\"#{code}\">#{name}</option>" }.join
    render html: "<option value=''>Selecione</option>#{options}".html_safe
  end

  def cities
    country = params[:country] || "BR"
    state = params[:state]
    if state.present?
      states = CS.states(country.to_sym)
      code = states.key(state) || states.key(state.to_sym) || state
      cities = CS.cities(code.to_sym, country.to_sym) || []
    else
      cities = []
    end
    options = cities.map { |c| "<option value=\"#{c}\">#{c}</option>" }.join
    render html: "<option value=''>Selecione</option>#{options}".html_safe
  end
end
