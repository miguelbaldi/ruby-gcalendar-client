new_content = ""
count = 0
File.open('basic.ics','r') do |f|
    while line = f.gets
        idx = line =~ /SUMMARY/
        unless idx.nil?
            line =  "SUMMARY: Event test #{count}\n"
        end 
        idx = line =~ /DESCRIPTION/
        unless idx.nil?
            line = "DESCRIPTION: Description test #{count}\n"
        end
        idx = line =~ /LOCATION/
        unless idx.nil?
            if idx == 0
                line = "LOCATION: Location test #{count}\n"
            end
        end
        idx = line =~ /BEGIN:VEVENT/
        unless idx.nil?
            count = count + 1
        end
        new_content = new_content + line
    end
end
puts new_content
