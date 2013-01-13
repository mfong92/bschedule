module CoursesHelper

	def schedule(ccn, section_info)
		numbers = []
		nums = []

		codes = {'FL' => '12D2', 'SP' => '13B4', 'SU' => '13C1'}
		doc = open('https://telebears.berkeley.edu/enrollment-osoc/osc?_InField1=RESTRIC&_InField2=' + ccn + '&_InField3=' + codes[params[:semester]])
		doc.each_line do |line|
			if line.include?('limit')
				a = line.scan(Regexp.new(/([0-9]+)/))
				nums += a[0] + a[1]
			end
		end

		nums += ['0']*4
		enrolled, limit, wait_list, wait_limit = nums.collect {|x| x.strip}
		section_info[:enrolled] = enrolled + '/' + limit
		section_info[:waitlist] = wait_list + '/' + wait_limit
		section_info[:open] = Integer(enrolled) < Integer(limit)
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

			args = params[:course].split
			if args.length > 1 and args.last =~ /\d/
				dept = args[0...-1].join(' ')
				num = args.last
			end
    		dept = dept.strip.upcase
   			num = num.strip.upcase
   			course = (dept + " " + num).strip
     		dept.gsub! /\s/, '+'
          	class_url = 'https://osoc.berkeley.edu/OSOC/osoc?y=0&p_term=' + params[:semester] + '&p_deptname=--+Choose+a+Department+Name+--&p_classif=--+Choose+a+Course+Classification+--&p_presuf=--+Choose+a+Course+Prefix%2fSuffix+--&p_course=' + num + '&p_dept=' + dept + '&x=0'
    	else
    		dept = params[:dept].strip.upcase
    		num = params[:course_num].strip.upcase
    	    course = (dept + " " + num).strip
    		params[:dept].gsub! /\s/, '+'
    		class_url = 'http://osoc.berkeley.edu/OSOC/osoc?y=0&p_ccn=' + params[:ccn].strip + '&p_units=' + params[:units].strip + '&p_term=' + params[:semester] + '&p_bldg=' + params[:building].strip + '&p_exam=' + params[:final].strip + '&p_deptname=--+Choose+a+Department+Name+--&p_hour=' + params[:hours].strip + '&p_classif=--+Choose+a+Course+Classification+--&p_restr=' + params[:restrictions].strip + '&p_info=' + params[:additional].strip + '&p_presuf=--+Choose+a+Course+Prefix%2fSuffix+--&p_course=' + params[:course_num].strip + '&p_title=' + params[:course_title].strip + '&p_updt=' + params[:status].strip + '&p_day=' + params[:days].strip + '&p_instr=' + params[:instructor].strip + '&p_dept='  + params[:dept].strip + '&x=0'
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
		ccn_regex = Regexp.new(/name="_InField2" value="([0-9]*)"/)
		sem_regex = Regexp.new(/name="_InField3" value="([0-9A-Z]*)/)
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
			if sec[:ccn].include?('SEE NOTE') or sec[:ccn].strip == '' or sec[:ccn].include?('SEE DEPT')
				sec[:ccn] = "%05d" % lookup_ccn
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

		# group by lecture
		lectures = []
		lec = []
		last_lec = ''
		lec_was_last = false
		sections.reverse.each do |name|
			if name.include?(' S ')
				if lec_was_last
					lectures << lec
					lec = []
				end
				lec.unshift(name)
				lec_was_last = false
				next
			end
			title = name.split[0...-3].join(' ')
			if not lec_was_last
				lec.unshift(name)
				lec_was_last = true
				last_lec = title
				next
			end
			if title == last_lec and lec.length > 1
				lec.unshift(name)
			else
				lectures << lec
				lec = [name]
			end
			lec_was_last = true
			last_lec = title
		end
		if lec.length > 0
			lectures << lec
		end
		lectures.reverse!
		
		return lectures, info, class_url, course, params[:semester]
	end
	
end
