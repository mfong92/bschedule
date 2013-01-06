module CoursesHelper

	def schedule(ccn)
		numbers = []
		doc = Nokogiri::HTML(open('https://telebears.berkeley.edu/enrollment-osoc/osc?_InField1=RESTRIC&_InField2=' + ccn + '&_InField3=13B4'))
		doc.search('blockquote').each do |line|
			if (line.content.scan(/[0-9]+/) != [])
				numbers = line.content.scan(/[0-9]+/)
			end
		end
		numbers += ['0', '0', '0', '0']
		enrolled, limit, wait_list, wait_limit = numbers
		return (enrolled + '/' + limit), (wait_list + '/' + wait_limit)
	end


	def results(dept, course_num)
		data = []
		ccns = []
		num = course_num
		class_url = 'https://osoc.berkeley.edu/OSOC/osoc?y=0&p_term=SP&p_deptname=--+Choose+a+Department+Name+--&p_classif=--+Choose+a+Course+Classification+--&p_presuf=--+Choose+a+Course+Prefix%2fSuffix+--&p_course=' + num + '&p_dept=' + dept + '&x=0'
		doc = open(class_url).read
		ccn_search = Regexp.new(/input type="hidden" name="_InField2" value="([0-9]*)"/)
		doc.scan(ccn_search).each do |ccn|
			ccns << ccn[0]
		end

		doc.each_line do |line|
			if line.include?(':&#160;')
				raw = line.scan(Regexp.new(/>([^<&]+)/))
				data << raw[1][0].strip
			end
		end

		sections = []
		data.each_slice(11) do |section|
			sections << section
		end
		# sections contains a list per section:
		# [course, coursetitle, location, instructor, status, ccn, units, 
		#  finalgroup, restrictions, note]

		puts ['Section', 'Enrolled', 'Waitlist'].map{|x| x.ljust(10)}.join('')
		sections.zip(ccns).each do |section, ccn|
			name = section[0].split(' ')[-2,2].join(' ')
			e, w = schedule(ccn)
			puts [name, e, w].map{|x| x.ljust(10)}.join('')
		end
	end
end
