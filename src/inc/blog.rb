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

#TODO: *check metadata of posts;
# => *make archive modular;
# => *tags are clickable;
# => *generate an rss-feed;

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
	#should an archive be created
	:archive,

	#store the dates in a tree - posts are leaves
	:dateTree,
	#store the tags in a tree - posts are leaves
	:tagTree,

	#links to drop below posts
	:backLink,
	#links on pages of posts
	:pastLink,
	:nextLink
	)

#parses a config file and populates the blog struct
def parseConfig(blog,config)
	fileHandle = File.open(config,'r')

	#blog root is the folder of the config file
	blog[:root_p] = File.dirname(File.absolute_path(config))

	blog[:config_p] = File.absolute_path(config)

	#parse all lines
	fileHandle.each_line{ |line| 
		#allow comments and empty lines
		next if line.strip()[0] == "#"
		next if line == ""
		
		#make some paths absolute with the root directory
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

#validates the skeleton of the pake skeleton
def checkPageSkel(file)
	if (File.exist?(file))
		fileHandle = File.open(file,'r')
		fileHandle.each_line{ |line|
			part = line.partition("$insertBlog")
			if ( part[1] != "")
				#as soon as we find $insertBlog we return true
				return 1
			end
		}
		puts("Don't know where to insert blog in #{file}. Doing nothing.")
		return 0
	else
		puts("Skeleton file for page not found!")
		return 0
	end
end

#parse a folder for *.post
def getPosts(p)
	if (File.directory?(p))
		return Dir.entries(p).select{|c| c[/.*\.post/]}
	else
		puts("The folder #{p} does not exist. Doing nothing.")
		return 0
	end
end

#convert the plaintext into a post-struct
def plainToPost(po,blog,k)
	post = Post.new()
	post[:text]  = ""
	if File.exist?(blog[:postSkel_p])
		fileHandle = File.open(po,'r')

		#parse the file for the metadata
		fileHandle.each_line{ |line|
			if ( line.partition("$name:")[1] != "")
				post[:name] = line.partition("$name:")[2].strip!
			elsif ( line.partition("$date:")[1] != "")
				post[:date] = line.partition("$date:")[2].strip!
			elsif ( line.partition("$tags:")[1] != "")
				post[:tags] = line.partition("$tags:")[2].strip!.split(",")
			else
				#if no command is present the line must be the actual content
				post[:text] += line
			end
		}
		fileHandle.close()

		#generate link from date and simplified version of the title
		post[:link] = "#{processDate(post[:date]).join("_")}_#{processName(post[:name])}".downcase()[/[0-9\_a-z]*/]
		post[:final]  = ""

		#reorder and fill up date with zeros
		post[:date_s] = processDate(post[:date])

		#sort post into tagTree
		post[:tags].each{|t|
			tagInTree(t,blog[:tagTree],post)
		}
		
		#generate the final output of the post by patching it into the skeleton
		fileHandle = File.open(blog[:postSkel_p],'r')
		fileHandle.each_line{ |line|
			#if each post has a link to its own page - insert the link
			if blog[:extraPage]==1
				line = line.sub("$link",post[:link]+".html")
			end
			#substitute metadata where neccesary
			post[:final] += line.sub("$name",post[:name] ).sub("$date",post[:date]).sub("$text",post[:text] ).sub("$tags",post[:tags].join(','))
		}
		return post
	else
		puts("No skeleton for post found at #{blog[:postSkel_p]}. Doing nothing.")
		return Post.new()
	end
end

#reverses and fills up date
def processDate(d)
	out = d.split('.').reverse()
	out[1] = out[1].rjust(2, '0')
	out[2] = out[2].rjust(2, '0')
	return out
end

#fills up the spaces and removes leading and trailing spaces
def processName(n)
	return n.strip.gsub(" ","_")
end

#sort date into the dateTree
def dateInTree(d,t,p)
	t[:children].each{|y|
		#check if year is already present
		if d[0] == y[:node]
			#check if month is present
			y[:children].each{|m|
				if d[1] == m[:node]
					#if yes we insert the post
					m[:children].insert(-1,p)
					return
				end
			}
			#if month is not present, we need a new subtree for this very month with the post
			#as the first node
			y[:children].insert(-1,Tree.new(d[1],[p]))
			return
		end
	}
	#if the years is not present yet, we need a whole path down to the leaf with post
	t[:children].insert(-1,Tree.new(d[0],[Tree.new(d[1],[p])]))
	return
end

#sorts the post into the tag tree
def tagInTree(tag,tree,p)
	tree[:children].each{|c|
		#check if tag is already present
		if tag == c[:node]
			#f yes just insert the post
			c[:children].insert(-1,p)
			return
		end
	}
	#f no, we generate a subtree for the tag
	tree[:children].insert(-1,Tree.new(tag.strip,[p]))
end

#main routine for generating the blog
def generateBlog(config)
	if (File.exist?(config))

		#make new blog instance
		blog = Blog.new()
		puts("Generating blog from #{config}.")

		#populate blogValues
		return if parseConfig(blog,config) == 0

		#check page skeleton for $insertBlog
		if  (checkPageSkel(blog[:pageSkel_p])  == 0)
			return
		end

		#delete old *.rhtml
		Dir.entries(blog[:content_p]).select{|c| c[/.*\.rhtml/]}.each{|r|
			File.delete("#{blog[:content_p]}/#{r}")
		}

		#import blog posts from the folder
		postsPlain = getPosts(blog[:content_p])

		#check for errors
		return if postsPlain == 0
		if postsPlain.size() == 0
			puts("No posts in directory. Doing nothing.")
			return 
		end

		#array for the final posts
		blog[:posts] = []
		
		#counter for the pages
		pgCnt = 1
		
		#always make a page 1 - this link will be the "index"
		blog[:pages] = [Page.new([],"page#{pgCnt}.html",nil,nil,"")]

		#initialize the trees
		blog[:dateTree] = Tree.new("dateTree",[])
		blog[:tagTree] = Tree.new("tagTree",[])

		#go through all posts !PLAINFILES!
		postsPlain.each_with_index{|post,i|

			#calc absolute path
			path = blog[:content_p] + "/" + post
			puts("Processing post from #{path}.")

			#generate a new post struct
			blog[:posts].insert(-1,plainToPost(path,blog,pgCnt))
		}
		
		#sort the posts by date
		blog[:posts].sort_by!{|p|
			-p[:date_s].join("").to_i
		}
		

		blog[:posts].each_with_index{|post,i|
			#sort the post into the dateTree
			dateInTree(post[:date_s],blog[:dateTree],post)

			#insert post into trailing page
			blog[:pages][-1][:posts].insert(-1,post)

			#store in post on which page it is
			post[:page] = blog[:pages][-1]

			#check if we want to split blog into pages
			if blog[:pageSize] > 0
				#generate new page if one is needed make sur eno empty page is generated
				if ((i+1) % blog[:pageSize] == 0)&&(i+1 < blog[:posts].size())
					pgCnt += 1
					blog[:pages].insert(-1,Page.new([],"page#{pgCnt}.html",nil,nil,""))				
				end
			end

			#check if each post gets an own page
			if blog[:extraPage]==1

				#generate a *.rhtml which will be found later by the fileTree and will get sowed together with the rest of the files
				outFile = File.open("#{blog[:content_p]}/#{post[:link]}.rhtml",'w')

				#use regular page skeleton
				inFile = File.open(blog[:pageSkel_p],'r')

				#just cops the lines
				inFile.each_line{|line|
					#just delete the links inbetween pages
					line = line.sub("$pastLink"," ").sub("$nextLink"," ")
					#insert post where normally the blog is and insert the backLink to its own page
					outFile.write(line.sub("$insertBlog",post[:final].sub("$link"," ").sub("$backLink",blog[:backLink].sub("%",post[:page][:link]))))
				}
				outFile.close()
				inFile.close()

				#insert the correct link and delte the backlink, because now the post will be put into the blog page
				post[:final] = post[:final].sub("$link","#{post[:link]}.html").sub("$backLink"," ")
			end	
		}

		#work through all generated pages
		blog[:pages].each_with_index{|page,i|

			#generate a *.rhtml that will also be sowed later
			outFile = File.open("#{blog[:content_p]}/page#{i+1}.rhtml",'w')
			inFile = File.open(blog[:pageSkel_p],'r')

			#first page does not have a predecessor
			if i > 0
				page[:pred] = blog[:pages][i-1]
			end

			#last page has no successor
			if i < (blog[:pages].size()-1)
				page[:succ] = blog[:pages][i+1]
			end

			#text that will be put as blog
			text = ""
			page[:posts].each{|post|
				text += post[:final]
			}

			#go through lines in skeleton
			inFile.each_line{|line|
				#substitute blog text to the right position
				toWrite = line.sub("$insertBlog",text)

				#check if we want several pages
				if blog[:pageSize] > 0
					#first page does get no backlink
					if i > 0
						toWrite = toWrite.sub("$pastLink",blog[:pastLink].sub("%",page[:pred][:link]))
					else
						toWrite = toWrite.sub("$pastLink"," ")	
					end
					#last page has no successor
					if i < (blog[:pages].size()-1)
						puts(blog[:nextLink])
						toWrite = toWrite.sub("$nextLink",blog[:nextLink].sub("%",page[:succ][:link]))
					else
						toWrite = toWrite.sub("$nextLink"," ")
					end
				else
					#if all is just one page, we don't need the links
					toWrite = toWrite.sub("$nextLink"," ").sub("$pastLink"," ")
				end
				page[:final] += toWrite
			}

			#write the line as is
			outFile.write(page[:final])
			outFile.close()
			inFile.close()
		}

		#check if we want an archive
		if blog[:archive] == 1
			outFile = File.open("#{blog[:content_p]}/archive.rhtml",'w')

			#alternate skeleton must be present
			inFile = File.open(blog[:pageSkel_p].sub(".","_archive."),'r')

			#drop tagTree
			tags = "<ul>"
			blog[:tagTree][:children].each{|t|
				tags += "<li>#{t[:node]}</li><ul>"
				t[:children].each{|c|
					tags += "<li><a href=\"#{c[:link]}.html\">#{c[:name]} - #{c[:date]}</a></li>"
				}
				tags += "</ul>"

			}
			tags += "</ul>"

			#drop dateTree
			dates = "<ul>"
			blog[:dateTree][:children].each{|y|
				dates += "<li>#{y[:node]}</li><ul>"
				y[:children].each{|m|
					dates += "<li>#{m[:node]}</li><ul>"
					m[:children].each{|p|
						dates += "<li><a href=\"#{p[:link]}.html\">#{p[:name]}</a></li>"
					}
					dates += "</ul>"
				}
				dates += "</ul>"
			}
			dates += "</ul>"

			#substitute everything in the skeleton
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
