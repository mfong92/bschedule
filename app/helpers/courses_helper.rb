



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
		ccn_regex = Regexp.new(/input type="hidden" name="_InField2" value="([0-9]*)"/)
		ccns = []
		doc.scan(ccn_regex).each do |ccn|
			ccns << ccn[0]
		end

		stats = Hash.new
		pool = Thread::Pool.new(15)
		ccns.each do |lookup_ccn|
			pool.process {
				schedule(lookup_ccn, stats)
			}
			#sleep 0.05
		end
		pool.shutdown

		data = []
		doc.each_line do |line|
			if line.include?(':&#160;')
				raw = line.scan(Regexp.new(/>([^<]+)/))
				data << raw[1][0].strip().split(':&#160;')[0]
			end
		end

		info = []
		titles = ['Name', 'CCN', 'Time', 'Enrolled', 'Waitlist']
		data.each_slice(11).zip(ccns) do |section, lookup_ccn|
			name = section[0].split(' ')[-2,2].join(' ')
			ccn = section[5]
			time_place = section[2].split(',')
			time = time_place[0].strip()
			enrolled, waitlist = stats[lookup_ccn]
			info << [name, ccn, time, enrolled, waitlist]
		end

		return titles, info, class_url, course
	end
	
end
