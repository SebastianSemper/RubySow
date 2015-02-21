#Copyright (C) 2015  Sebastian Semper

#This program is free software: you can redistribute it and/or modify it under
#the terms of the GNU General Public License as published by the Free Software
#Foundation, either version 3 of the License, or (at your option) any later
#version.

#This program is distributed in the hope that it will be useful, but WITHOUT ANY
#WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#PARTICULAR PURPOSE.  See the GNU General Public License for more details.

#You should have received a copy of the GNU General Public License along with
#this program.  If not, see <http://www.gnu.org/licenses/>

Page = Struct.new(
	#list of posts - sorted
	:posts,
	#link to page
	:link,
	#previous page - if it exists
	:pred,
	#successing page
	:succ,
	#final plaintext
	:final
	)

Post = Struct.new(
	#post name
	:name,
	#date as string
	:date,
	#date for sorting
	:date_s,
	#tags of post
	:tags,
	#link to page for single post
	:link,
	#text only
	:text,
	#final output
	:final,
	:page
	)

Blog = Struct.new(
	:root_p,
	#path to config file
	:config_p,
	#path to page skeleton
	:pageSkel_p,
	#path to post skeleton
	:postSkel_p,
	#path to the content folder
	:content_p,

	#page array
	:pages,
	#post array 
	:posts,
	#page size (posts per page)
	:pageSize,
	#should posts get an own page
	:extraPage,
	:archive,

	#store the dates in a tree - posts are leaves
	:dateTree,
	:tagTree,

	#links to drop below posts
	:backLink,
	:pastLink,
	:nextLink
	)

def parseConfig(blog,config)
	fileHandle = File.open(config,'r')
	blog[:root_p] = File.dirname(File.absolute_path(config))
	blog[:config_p] = File.absolute_path(config)
	fileHandle.each_line{ |line| 
		#allow comments and empty lines
		next if line.strip()[0] == "#"
		next if line == ""
		
		if ( line.partition("$page_skel:")[1] != "")
			blog[:pageSkel_p] = blog[:root_p] + "/" + line.partition("$page_skel:")[2].strip!
		elsif ( line.partition("$post_skel:")[1] != "")
			blog[:postSkel_p] = blog[:root_p] + "/" + line.partition("$post_skel:")[2].strip!
		elsif ( line.partition("$content_p:")[1] != "")
			blog[:content_p] = blog[:root_p] + "/" + line.partition("$content_p:")[2].strip!
		elsif ( line.partition("$nextLink:")[1] != "")
			blog[:nextLink] = line.partition("$nextLink:")[2].strip!
		elsif ( line.partition("$backLink:")[1] != "")
			blog[:backLink] = line.partition("$backLink:")[2].strip!
		elsif ( line.partition("$pastLink:")[1] != "")
			blog[:pastLink] = line.partition("$pastLink:")[2].strip!
		elsif ( line.partition("$posts_per_page:")[1] != "")
			blog[:pageSize] = line.partition("$posts_per_page:")[2].to_i
		elsif ( line.partition("$extra_page:")[1] != "")
			blog[:extraPage] = line.partition("$extra_page:")[2].to_i
		elsif ( line.partition("$archive:")[1] != "")
			blog[:archive] = line.partition("$archive:")[2].to_i
		end
	}
	return 1
end

def checkPageSkel(file)
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
	if (File.directory?(p))
		return Dir.entries(p).select{|c| c[/.*\.post/]}
	else
		puts("The folder #{p} does not exist. Doing nothing.")
		return 0
	end
end

def plainToPost(po,skel,blog,k)
	post = Post.new()
	post[:text]  = ""
	if File.exist?(skel)
		fileHandle = File.open(po,'r')
		fileHandle.each_line{ |line|
			if ( line.partition("$name:")[1] != "")
				post[:name] = line.partition("$name:")[2].strip!
			elsif ( line.partition("$date:")[1] != "")
				post[:date] = line.partition("$date:")[2].strip!
			elsif ( line.partition("$tags:")[1] != "")
				post[:tags] = line.partition("$tags:")[2].strip!.split(",")
			else
				post[:text] += line
			end
		}
		fileHandle.close()
		post[:link] = "#{processDate(post[:date]).join("_")}_#{processName(post[:name])}".downcase()[/[0-9\_a-z]*/]
		post[:final]  = ""
		post[:date_s] = processDate(post[:date])
		
		dateInTree(post[:date_s],blog[:dateTree],post)
		post[:tags].each{|t|
			tagInTree(t,blog[:tagTree],post)
		}
		
		fileHandle = File.open(skel,'r')
		fileHandle.each_line{ |line|
			if blog[:extraPage]==1
				line = line.sub("$link",post[:link]+".html")
			end
			post[:final] += line.sub("$name",post[:name] ).sub("$date",post[:date]).sub("$text",post[:text] ).sub("$tags",post[:tags].join(','))
		}
		return post
	else
		puts("No skeleton for post found at #{skel}. Doing nothing.")
		return Post.new()
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

def processDate(d)
	out = d.split('.').reverse()
	out[1] = out[1].rjust(2, '0')
	out[2] = out[2].rjust(2, '0')
	return out
end

def processName(n)
	return n.strip.gsub(" ","_")
end

def dateInTree(d,t,p)
	t[:children].each{|y|
		if d[0] == y[:node]
			y[:children].each{|m|
				if d[1] == m[:node]

					m[:children].insert(-1,p)
					return
				end
			}
			y[:children].insert(-1,Tree.new(d[1],[p]))
			return
		end
	}
	t[:children].insert(-1,Tree.new(d[0],[Tree.new(d[1],[p])]))
	return
end

def tagInTree(tag,tree,p)
	tree[:children].each{|c|
		if tag == c[:node]
			c[:children].insert(-1,p)
			return
		end
	}
	tree[:children].insert(-1,Tree.new(tag.strip,[p]))
end

def generateBlog(config)
	if (File.exist?(config))
		blog = Blog.new()
		puts("Generating blog from #{config}.")
		#populate blogValues
		return if parseConfig(blog,config) == 0
		puts(blog)
		#check page skeleton for $insertBlog
		if  (checkPageSkel(blog[:pageSkel_p])  == 0)
			return
		end

		postsPlain = getPosts(blog[:content_p])

		return if postsPlain == 0
		if postsPlain.size() == 0
			puts("No posts in directory. Doing nothing.")
			return 
		end
		puts(blog)
		
		blog[:posts] = []
		k = 1
		blog[:pages] = [Page.new([],"page#{k}.html",nil,nil,"")]
		blog[:dateTree] = Tree.new("dateTree",[])
		blog[:tagTree] = Tree.new("tagTree",[])

		postsPlain.each_with_index{|post,i|
			path = blog[:content_p] + "/" + post
			puts("Processing post from #{path}.")
			blog[:posts].insert(-1,plainToPost(path,blog[:postSkel_p],blog,k))
			blog[:pages][-1][:posts].insert(-1,blog[:posts][-1])
			blog[:posts][-1][:page] = blog[:pages][-1]
			if blog[:pageSize] > 0
				if ((i+1) % blog[:pageSize] == 0)
					k += 1
					blog[:pages].insert(-1,Page.new([],"page#{k}.html",nil,nil,""))				
				end
			end
			if blog[:extraPage]==1
				outFile = File.open("#{blog[:content_p]}/#{blog[:posts][-1][:link]}.rhtml",'w')
				inFile = File.open(blog[:pageSkel_p],'r')
				inFile.each_line{|line|
					line = line.sub("$pastLink"," ").sub("$nextLink"," ")
					outFile.write(line.sub("$insertBlog",blog[:posts][-1][:final].sub("$link"," ").sub("$backLink",blog[:backLink].sub("%",blog[:posts][-1][:page][:link]))))
				}
				outFile.close()
				inFile.close()
				blog[:posts][-1][:final] = blog[:posts][-1][:final].sub("$link","#{blog[:posts][-1][:link]}.html").sub("$backLink"," ")
			end	
		}

		
		blog[:pages].each_with_index{|page,i|
			outFile = File.open("#{blog[:content_p]}/page#{i+1}.rhtml",'w')
			inFile = File.open(blog[:pageSkel_p],'r')
			if i > 0
				page[:pred] = blog[:pages][i-1]
			end
			if i < (blog[:pages].size()-1)
				page[:succ] = blog[:pages][i+1]
			end
			text = ""
			page[:posts].each{|post|
				text += post[:final]
			}
			inFile.each_line{|line|
				toWrite = line.sub("$insertBlog",text)
				if blog[:pageSize] > 0
					if i > 0
						toWrite = toWrite.sub("$pastLink",blog[:pastLink].sub("%",page[:pred][:link]))
					else
						toWrite = toWrite.sub("$pastLink"," ")	
					end
					if i < (blog[:pages].size()-1)
						toWrite = toWrite.sub("$nextLink",blog[:nextLink].sub("%",page[:succ][:link]))
					else
						toWrite = toWrite.sub("$nextLink"," ")
					end
				else
					toWrite = toWrite.sub("$nextLink"," ").sub("$pastLink"," ")
				end
				page[:final] += toWrite
			}
			outFile.write(page[:final])
			outFile.close()
			inFile.close()
		}

		if blog[:archive] == 1
			outFile = File.open("#{blog[:content_p]}/archive.rhtml",'w')
			inFile = File.open(blog[:pageSkel_p].sub(".","_archive."),'r')
			tags = "<ul>"
			blog[:tagTree][:children].each{|t|
				tags += "<li>#{t[:node]}</li><ul>"
				t[:children].each{|c|
					tags += "<li><a href=\"#{c[:link]}.html\">#{c[:name]} - #{c[:date]}</a></li>"
				}
				tags += "</ul>"

			}
			tags += "</ul>"

			dates = "<ul>"
			blog[:dateTree][:children].each{|y|
				dates += "<li>#{y[:node]}</li><ul>"
				y[:children].each{|m|
					dates += "<li>#{m[:node]}</li><ul>"
					m[:children].each{|p|
						puts(p)
						dates += "<li><a href=\"#{p[:link]}.html\">#{p[:name]}</a></li>"
					}
					dates += "</ul>"
				}
				dates += "</ul>"
			}
			dates += "</ul>"
			inFile.each_line{|line|
				outFile.write(line.sub("$insertTags",tags).sub("$insertDates",dates))
			}
			outFile.close()
			inFile.close()
		end
		
	else
		puts("Config file #{config} not found! Doing nothing.")
		return
	end
end
