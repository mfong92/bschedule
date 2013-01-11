module CoursesHelper

	def schedule(ccn, section_info)
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
		section_info[:enrolled] = (enrolled + '/' + limit)
		section_info[:waitlist] = (wait_list + '/' + wait_limit)
	end


	def live_data(params)
		require 'thread/pool'
		require 'open-uri'

		# parse arguments 
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

    	# fetch html for page
		doc = open(class_url).read
		
		# split html lines into sections
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
		
		# parse each section for relevant information
		sections = []
		info = {}
		ccn_regex = Regexp.new(/input type="hidden" name="_InField2" value="([0-9]*)"/)
		html_sections.each do |section_lines|
			d = []
			lookup_ccn = -1
			section_lines.each do |line|
				if line.include?(':&#160;')
					raw = line.scan(Regexp.new(/>([^<]+)/))
					d << (raw[1][0] + ' ').split('&#')[0].split('&nbsp')[0].split.join(' ')
				end
				match = line.match(ccn_regex)
				if match
					lookup_ccn = match.captures[0]
				end
			end
			if lookup_ccn == -1
				next
			end
			sec = Hash.new
			name = d[0]
			sec = { course: name, title: d[1], location: d[2], 
					instructor: d[3], status: d[4], ccn: d[5], units: d[6], 
					final: d[7], restrictions:d[8], note: d[9], 
					enrollment: d[10], lookup_ccn: lookup_ccn }
			if sec[:location].include? 'UNSCHED'
				time = 'UNSCHED'
				place = sec[:location].split('UNSCHED')[1].strip
			else
				time_place = sec[:location].split(',')*2
				time = time_place[0]
				place = time_place[1]
			end
			sec[:time] = time
			sec[:place] = place
			info[name] = sec
			sections << name
		end

		# fetch live data for each section
		pool = Thread::Pool.new(30)
		stats = Hash.new
		sections.each do |section|
			lookup_ccn = info[section][:lookup_ccn]
			pool.process {
				schedule(lookup_ccn, info[section])
			}
		end
		pool.shutdown

		lectures = []
		lec = []
		sections.each do |name|
			if not name.include?(' S ')
				if lec.length > 0
					lectures << lec
				end
				lec = [name]
			else 
				lec << name
			end
		end
		if lec.length > 0
			lectures << lec
		end
		
		return lectures, info, class_url, course
	end
	
end
