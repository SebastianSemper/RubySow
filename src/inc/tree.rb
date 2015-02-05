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

def genFileTree(path,pattern,subTree)
    subTree[:node] = path
    Dir.chdir(path)
    Dir.foreach("."){|x|
        next if x == "." || x == ".."
        if (File.directory?(x))
            subTree[:childs].insert(-1, genFileTree(x,pattern,Tree.new(x,[])))
            Dir.chdir("..")
        else
            subTree[:childs].insert(-1,x)
        end
    }
    return subTree
end

def searchFileTree(pattern,subTree)
    out = Tree.new(subTree[:node],[])
    subTree[:childs].each{|c|
        if (c.is_a?(String))
            if (c = c[/.*#{pattern}/])
                out[:childs].insert(-1,c)
            end
        elsif (c.is_a?(Tree))
            out[:childs].insert(-1,searchFileTree(pattern,c))
        end
    }
    return out
end

def renameFileTree(pre,post,subTree)
    out = Tree.new(subTree[:node],[])
    subTree[:childs].each{|c|
        if (c.is_a?(String))
            if (c = c[/.*#{pre}/])
                out[:childs].insert(-1,c.gsub(pre,post))
            end
        elsif (c.is_a?(Tree))
            out[:childs].insert(-1,renameFileTree(pre,post,c))
        end
    }
    return out
end

def absoluteFileTree(subTree)
    out = Tree.new(Dir.getwd() +"/" + subTree[:node],[])
    subDir = out[:node]
    if !Dir.exist?(subTree[:node])
        Dir.mkdir(subTree[:node])
    end
    Dir.chdir(subTree[:node])
    subTree[:childs].each{|c|
        if (c.is_a?(String))
            out[:childs].insert(-1,Dir.getwd().to_s + "/" + c)
        elsif (c.is_a?(Tree))
            out[:childs].insert(-1,absoluteFileTree(c))
            Dir.chdir("..")
        end
    }
    return out
end

def applyToTree(fun,trees)
    treeCount = trees.size()-1
    childCount = trees[0][:childs].size()-1
    childArray = []
    for i in 0..childCount
        childArray.clear()
        for j in 0..treeCount
            childArray.insert(-1,trees[j][:childs][i])
        end
        if (trees[0][:childs][i].is_a?(Tree))
            applyToTree(fun,childArray)
        else
            fun.call(childArray)
        end
    end
end

Tree = Struct.new(:node,:childs)
FileTree = Tree.new("",[])
