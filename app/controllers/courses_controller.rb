class CoursesController < ApplicationController

  def home
  end

  def advanced
  end

  def results
    @lectures, @info, @url, @course = live_data(params)
  end
end
