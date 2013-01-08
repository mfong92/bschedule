class CoursesController < ApplicationController

  def home
  end

  def results
    if (params[:course])
      dept = (params[:course])[/^[^0-9]+/]
      num = (params[:course])[/\d+\w*/]
    else
      dept = params[:dept]
      num = params[:course_num]
    end

    if dept.nil?
      dept = ''
    end
    if num.nil?
      num = ''
    end
    dept = dept.strip.upcase
    num = num.strip.upcase

    @course = (dept + " " + num).strip
    @title, @info, @url = live_data(dept, num)

  end
end
