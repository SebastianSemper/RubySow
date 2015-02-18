$blogParams = [
	"page_skel",
	"post_skel",
	"post_folder",
	"extra_page",
	"posts_per_page"
]

$blogValues = [
]

def parseConfig(config)
	$blogValues = Array.new($blogParams.size(),nil)
	fileHandle = File.open(config,'r')
	lineNum = 1
	fileHandle.each_line{ |line| 
		#allow comments and empty lines
		next if line.strip()[0] == "#"
		next if line == ""
		part = line.partition("=")
		
		if (part.find_index("=")==nil)
			puts("Syntax error in line #{lineNum}")
		else
			index = $blogParams.find_index(part[0])
			if (index != nil)
				$blogValues[index] = part[2]
			end
		end
		lineNum += 1
	}
	if $blogValues.find_index(nil) == nil
		puts("Config file #{config} was sane!")
		return 1
	else
		puts("Config file #{config} was not sane! Values are missing.")
		return 0
	end
end

def checkPageSkel(file)
	file = file.strip!
	if (File.exist?(file))
		fileHandle = File.open(file,'r')
		lineNum = 1
		fileHandle.each_line{ |line|
			part = line.partition("$insertBlog")
			if ( part[1] != "")
				return lineNum
			end
			lineNum += 1
		}
		puts("Don't know where to insert blog in #{file}. Doing nothing.")
		return 0
	else
		puts("Skeleton file for page not found!")
		return 0
	end
end

def getPosts(p)
	p = p.strip!
	if (File.directory?(p))
		return Dir.entries(p).select{|c| c[/.*\.post/]}
	else
		puts("The folder #{p} does not exist. Doing nothing.")
		return 0
	end
end

def postToPart(post,skel)
	name = ""
	date = ""
	tags = []
	text = ""
	if File.exist?(skel)
		fileHandle = File.open(post,'r')
		fileHandle.each_line{ |line|
			if ( line.partition("$name:")[1] != "")
				name = line.partition("$name:")[2].strip!
			elsif ( line.partition("$date:")[1] != "")
				date = line.partition("$date:")[2].strip!
			elsif ( line.partition("$tags:")[1] != "")
				tags = line.partition("$tags:")[2].strip!.split(",")
			else
				text += line
			end
		}
		fileHandle.close()
		out = ""
		fileHandle = File.open(skel,'r')
		fileHandle.each_line{ |line|
			out += line.sub("$name",name).sub("$date",date).sub("$text",text).sub("$tags",tags.join(','))
		}
		return out
	else
		puts("No skeleton for post found at #{skel}. Doing nothing.")
		return ""
	end
end

def partsToSkel(parts,skel)
	out = ""
	if File.exist?(skel)
		fileHandle = File.open(skel,'r')
		fileHandle.each_line{ |line|
			out += line.sub("$insertBlog",parts)
		}
		return out
	else
		puts("No skeleton for post found at #{skel}. Doing nothing.")
		return ""
	end
end


def generateBlog(config)
	if (File.exist?(config))
		puts("Generating blog from #{config}.")
		#populate blogValues
		return if parseConfig(config) == 0

		#check page skeleton for $insertBlog
		blogLine = checkPageSkel(
			File.dirname(File.absolute_path(config))+
			"/"+$blogValues[$blogParams.find_index("page_skel")]
			) 
		return if blogLine == 0

		posts = getPosts(
			File.dirname(File.absolute_path(config))+
			"/"+$blogValues[$blogParams.find_index("post_folder")]
			)
		return if posts == 0
		if (posts.size() == 0)
			puts("No posts in directory. Doing nothing.")
			return 
		end

		parts = []
		skel = File.dirname(File.absolute_path(config))+ "/"+$blogValues[$blogParams.find_index("post_skel")].strip
		posts.each{|post|
			path = File.dirname(File.absolute_path(config)) + "/" + $blogValues[$blogParams.find_index("post_folder")].strip + "/" + post
			puts("Processing post from #{path}.")
			parts.insert(-1,postToPart(path,skel))
		}
		postsPerPage = $blogValues[$blogParams.find_index("posts_per_page")].to_i
		pageParts = [""]
		postCount = 1
		pageName = File.dirname(File.absolute_path(config))+
					"/"+$blogValues[$blogParams.find_index("post_folder")].strip + 
					"/" + "page#{pageParts.size()}.rhtml"
		pageFile = File.open(pageName,'w')
		pageSkel = File.dirname(File.absolute_path(config)) +"/" +$blogValues[$blogParams.find_index("page_skel")].strip
		parts.each{|part|
			pageParts[-1] += part
			if  postCount == postsPerPage 
				pageFile.write(partsToSkel(pageParts[-1],pageSkel))
				pageFile.close()
				pageParts.insert(-1,"")
				pageName = File.dirname(File.absolute_path(config))+
					"/"+$blogValues[$blogParams.find_index("post_folder")].strip + 
					"/" + "page#{pageParts.size()}.rhtml"
				pageFile = File.open(pageName,'w')
				postCount = 0
			end
			postCount += 1
		}
		puts($blogValues)
		puts(pageFile)
		pageFile.write(partsToSkel(pageParts[-1],pageSkel))
		pageFile.close()
	else
		puts("Config file #{config} not found! Doing nothing.")
		return
	end
end
