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

def decList(argv)
    listName = argv[0]
    listContent = argv[1..(argv.size()-1)]
    ListNames.insert(-1,listName)
    ListContents.insert(-1,listContent)
    return ""
end

def getList(argv)
    listName = argv[0]
    index = ListNames.find_index(listName)
    if index == nil
        puts("List #{listName} was not declared.")
        return ""
    else
        out = ""
        ListContents[index].each{|e|
            out = out + "," + e
        }
        return ListContents[index]
    end
end

def sowToFile(argv)
    inName = argv[0]
    outName = argv[1]
    outFile = File.open(outName,'w')
    outFile.write(parseFile(inName))
    outFile.close()
    return " "
end

def dropImages(argv)
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

def patchIn(argv)
    name = argv[0]
    puts("Including #{name}.")
    return(parseFile(name))
end

def fetchCSS(argv)
        out = ""
        argv.each{|p|
            out = out + "<link rel=\"stylesheet\" type=\"text/css\" href=\"#{p}\">\n"
        }
        return(out)
end

def fetchJS(argv)
        out = ""
        argv.each{|p|
            out = out + "<script src=\"#{p}\" type=\"text/javascript\"></script>\n"
        }
        return(out)
end

CmdNames = [
    'setVariable',
    'decList',
    'getList',

    'sowToFile',
    'dropImages',
    'patchIn',
    'fetchCSS',
    'fetchJS'
]
CmdMethods = [
    method(:setVariable),
    method(:decList),
    method(:getList),

    method(:sowToFile),
    method(:dropImages),
    method(:patchIn),
    method(:fetchCSS),
    method(:fetchJS)
]
CmdArgc = [
    2,
    -1,
    1,

    2,
    -1,
    1,
    -1,
    -1
]
