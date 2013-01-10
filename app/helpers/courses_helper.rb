module CoursesHelper

	def schedule(ccn, stats)
		numbers = []
		nums = []

		doc = open('https://telebears.berkeley.edu/enrollment-osoc/osc?_InField1=RESTRIC&_InField2=' + ccn + '&_InField3=13B4')
		doc.each_line do |line|
			if line.include?('limit')
				a = line.scan(Regexp.new(/([0-9]+)/))
				nums += a[0] + a[1]
			end
		end

		nums += ['0']*4
		enrolled, limit, wait_list, wait_limit = nums
		stats[ccn] = (enrolled + '/' + limit), (wait_list + '/' + wait_limit)
	end


	def live_data(params)
		require 'thread/pool'
		require 'open-uri'

		course = ""

		if params[:course]
     		dept = (params[:course])[/^[^0-9]+/]
          	num = (params[:course])[/\d+\w*/]
          	if dept.nil?
     			dept = ''
    		end
    		if num.nil?
      			num = ''
    		end
    		dept = dept.strip.upcase
   			num = num.strip.upcase
   			course = (dept + " " + num).strip

     		dept.gsub! /\s/, '+'
          	class_url = 'https://osoc.berkeley.edu/OSOC/osoc?y=0&p_term=SP&p_deptname=--+Choose+a+Department+Name+--&p_classif=--+Choose+a+Course+Classification+--&p_presuf=--+Choose+a+Course+Prefix%2fSuffix+--&p_course=' + num + '&p_dept=' + dept + '&x=0'


    	else
    		dept = params[:dept].strip.upcase
    		num = params[:course_num].strip.upcase
    	    course = (dept + " " + num).strip

    		params[:dept].gsub! /\s/, '+'
    		class_url = 'http://osoc.berkeley.edu/OSOC/osoc?y=0&p_ccn=' + params[:ccn] + '&p_units=' + params[:units] + '&p_term=SP&p_bldg=' + params[:building] + '&p_exam=' + params[:final] + '&p_deptname=--+Choose+a+Department+Name+--&p_hour=' + params[:hours] + '&p_classif=--+Choose+a+Course+Classification+--&p_restr=' + params[:restrictions] + '&p_info=' + params[:additional] + '&p_presuf=--+Choose+a+Course+Prefix%2fSuffix+--&p_course=' + params[:course_num] + '&p_title=' + params[:course_title] +'&p_updt=' + params[:status] +'&p_day=' + params[:days] + '&p_instr=' + params[:instructor] + '&p_dept='  + params[:dept] + '&x=0'

    	end

    	if dept == '' and num == ''
    		course = 'RESULTS'
    	end

		doc = open(class_url).read
		
		html_sections = []
		temp_lines = []
		doc.each_line do |line|
			if line.include?('<TABLE BORDER=0 CELLSPACING=2 CELLPADDING=0>')
				if not temp_lines.empty?
					html_sections << temp_lines
					temp_lines = []
				end
				temp_lines << line
			else
				if not temp_lines.empty?
					temp_lines << line
				end
			end
		end
		html_sections << temp_lines
		
		sections = []
		ccn_regex = Regexp.new(/input type="hidden" name="_InField2" value="([0-9]*)"/)
		html_sections.each do |section_lines|
			data = []
			lookup_ccn = -1
			section_lines.each do |line|
				if line.include?(':&#160;')
					raw = line.scan(Regexp.new(/>([^<]+)/))
					data << (raw[1][0].split.join(' ') + ' ').split('&nbsp')[0].split('&#')[0]
				end
				match = line.match(ccn_regex)
				if match
					lookup_ccn = match.captures[0]
				end
			end
			if lookup_ccn != -1
				data << lookup_ccn
				sections << data
			end
		end

		pool = Thread::Pool.new(30)
		stats = Hash.new
		sections.each do |section|
			lookup_ccn = section.last
			pool.process {
				schedule(lookup_ccn, stats)
			}
		end
		pool.shutdown

		sections.each do |section|
			lookup_ccn = section.pop
			enrolled, waitlist = stats[lookup_ccn]
			section << enrolled << waitlist
		end

		lectures = []
		lec = []
		secs = []
		sections.each do |section|
			name = section[0]
			if not name.include?('DIS') and not name.include?('LAB')
				if not lec.empty?
					lec << secs
					lectures << lec
				end
				secs = []
				lec = section
			else 
				secs << section
			end
		end
		lec << secs
		lectures << lec
		
		lec_titles = ['Course', 'Title', 'Location', 'Instructor', 'Status', 'CCN', 'Units', 'Final', 'Restrictions', 'Note', 'Current', 'Enrolled', 'Waitlist']
		section_titles = lec_titles.dup

		lec_indices = [10, 9, 8, 4]
		sec_indices = [10, 9, 8, 7, 6, 4, 3, 1]
		lectures.each do |lec|
			lec_indices.each do |i|
				lec.delete_at(i)
			end
			sections = lec.last
			sections.each do |section|
				sec_indices.each do |j|
					section.delete_at(j)
				end
				section[0] = section[0].split(' ')[-2,2].join(' ')
			end
		end

		lec_indices.each do |i|
			lec_titles.delete_at(i)
		end
		sec_indices.each do |j|
			section_titles.delete_at(j)
		end

		return lectures, lec_titles, section_titles, class_url, course
	end
	
end
