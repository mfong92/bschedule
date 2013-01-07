class CoursesController < ApplicationController

  def home
  	params[:dept]
  end

  def results
    @course = params[:dept] + " " + params[:course_num]
  	@title, @info, @url = live_data(params[:dept], params[:course_num])
  end
end
