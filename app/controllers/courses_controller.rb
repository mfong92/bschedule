class CoursesController < ApplicationController

  def home
  end

  def results
    if (params[:dept_num])
      params[:course_num] = params[:dept_num].split.last
      params[:dept] = params[:dept_num].split[0..-2].join(" ")
    end
    @course = params[:dept].strip + " " + params[:course_num].strip
  	@title, @info, @url = live_data(params[:dept].strip, params[:course_num].strip)
  end
end
