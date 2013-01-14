class CoursesController < ApplicationController

  def home
  end

  def advanced
  	@semester = params[:semester]
  end

  def search
    @lectures, @info, @url, @course, @semester = live_data(params)
  end

  def about
  end
  
end
