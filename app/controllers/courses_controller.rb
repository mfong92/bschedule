class CoursesController < ApplicationController

  def home
  end

  def advanced
  end

  def results
    @lectures, @lec_titles, @sec_titles, @url, @course = live_data(params)
  end
end
