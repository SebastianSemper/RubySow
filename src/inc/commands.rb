# provide name and value
def setVariable(argv)
    varName = argv[0]
    varValue = argv[1]

    index= VarNames.find_index(varName)
    if index == nil
        puts("Setting #{varName} is not possible. Does not exist.")
    else
        VarValues[index] = varValue
        puts("Setting #{varName} to #{varValue}.")
    end
    return ""
end

# provide name
def getVariable(argv)
    varName = argv[0]
    index= VarNames.find_index(varName)
    if index == nil
        puts("Returning #{varName} is not possible. Does not exist.")
        return ""
    else
        return VarValues[index]
    end
end


def decVariable(argv)
    varName = argv[0]
    varValue = argv[1]
    VarNames.insert(-1,varName)
    VarValues.insert(-1,varValue)
    puts("Setting #{varName} to #{varValue}.")
    return ""
end

#get name an initial values
def decList(argv)
    listName = argv[0]
    listContent = argv[1..(argv.size()-1)]
    ListNames.insert(-1,listName)
    ListContents.insert(-1,listContent)
    return ""
end

def genList(argv)
    listName = argv[0]
    #open dir, pull out rexeg matches, join them
    listContent = Dir.entries(argv[1]).select{|c| c[/#{argv[2]}/]}
    ListNames.insert(-1,listName)
    ListContents.insert(-1,listContent)
    return ""
end

#return comma sep. list as string
def getList(argv)
    listName = argv[0]
    index = ListNames.find_index(listName)
    if index == nil
        puts("List #{listName} was not declared.")
        return ""
    else
        return ListContents[index].join(",")
    end
end

#return a lists size
def getListSize(argv)
    listName = argv[0]
    index = ListNames.find_index(listName)
    if index == nil
        puts("List #{listName} was not declared.")
        return ""
    else
        return ListContents[index].size().to_s()
    end
end

#apply a function to every element of a list
#returns a list of return values
def applyToList(argv)
        funName = argv[0]
        funArgs = argv[1..-1]
        out = ""
        funArgs.each{|a|
            if (a == funArgs.first())
                out = execCommand(funName,[a])
            else
                out += "," + execCommand(funName,[a])
            end
        }
        return out
end

#apply a function with several parameters to lists
#lists provide values for a paramater each
#count of lists must be provided
def applyToLists(argv)
        funName = argv[0]
        funArgs = argv[2..-1]
        listCount = argv[1].to_i()
        listSize = funArgs.size()/listCount
        out = ""
        for i in 0..(listSize-1)
            args = []
            for j in 0..(listCount-1)
                args.insert(-1,funArgs[j*listSize+i])
            end
            args = args[0..(listSize-2)]
            if i == 0
                out = execCommand(funName,args)
            else
                out += "," + execCommand(funName,args)
            end
        end
        return out
end

def readTree(argv)
    path = argv[0]
    match = argv[1]
    out = Dir.glob(path+"**/*.rhtml")
    puts(out)
    return ""
end

#parses a file and saves as an other file
def sowToFile(argv)
    inName = argv[0]
    outName = argv[1]
    puts("Sowing #{outName}.")
    outDir_p =  p_getVal("outDir")
    outFile = File.open(outName,'w')
    outFile.write(parseFile(inName))
    outFile.close()
    return outName
end

#drops some text that can be wrapped around a lists elements
def dropList(argv)
    container = argv[0]
    imgList = argv[1..-1]

    #split the container
    contStart = container.scan(/.*\%/)[0].gsub(/\%/,'')
    contEnd = container.scan(/\%.*/)[0].gsub(/\%/,'')
    out = ""
    imgList.each{|i|
        out = out + contStart + i + contEnd + "\n"
    }
    return out
end

#drops some text that has places where to add values
#each list provides values for one place
def dropLists(argv)
    container = argv[0]
    lists = argv[1..-1]
    listCount = container.count("%")
    listSize = lists.size()/listCount.to_i()
    out = ""
    for i in 0..(listSize-1)
        part = container
        for j in 0..(listCount-1)
            ins = part.partition("%")[0]
            part = part.partition("%")[2]
            out += ins + lists[j*listSize + i]
        end
        out += part + "\n"
    end
    return out
end

#Sows in another files content, that gets parsed as well an the output is
#writen directly to the target
def patchIn(argv)
    name = argv[0]
    puts("Including #{name}.")
    return(parseFile(name))
end

#loads some css files provided in a list
def fetchCSS(argv)
        out = ""
        argv.each{|p|
            out = out + "<link rel=\"stylesheet\" type=\"text/css\" href=\"#{p}\">\n"
        }
        return(out)
end

#loads some JS scripts provided in a list
def fetchJS(argv)
        out = ""
        argv.each{|p|
            out = out + "<script src=\"#{p}\" type=\"text/javascript\"></script>\n"
        }
        return(out)
end



CmdNames = [
    'setVariable',
    'getVariable',
    'decVariable',
    'decList',
    'genList',
    'getList',
    'getListSize',
    'applyToList',
    'applyToLists',

    'readTree',
    'sowToFile',
    'dropList',
    'dropLists',
    'patchIn',
    'fetchCSS',
    'fetchJS'
]
CmdMethods = [
    method(:setVariable),
    method(:getVariable),
    method(:decVariable),
    method(:decList),
    method(:genList),
    method(:getList),
    method(:getListSize),
    method(:applyToList),
    method(:applyToLists),

    method(:readTree),
    method(:sowToFile),
    method(:dropList),
    method(:dropLists),
    method(:patchIn),
    method(:fetchCSS),
    method(:fetchJS)
]
CmdArgc = [
    2,
    1,
    2,
    -1,
    -1,
    1,
    1,
    2,
    -1,

    2,
    2,
    -1,
    -1,
    1,
    -1,
    -1
]
