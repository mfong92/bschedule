class CoursesController < ApplicationController

  def home
  	params[:dept]
  end

  def results
    require 'nokogiri'
    require 'open-uri'
    require 'builder'
    @course = params[:dept] + params[:course_num]
  	@title, @info = live_data(params[:dept], params[:course_num])
  end
end
