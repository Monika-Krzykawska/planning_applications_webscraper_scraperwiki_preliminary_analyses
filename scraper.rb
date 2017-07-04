# This is a template for a Ruby scraper on morph.io (https://morph.io)
# including some code snippets below that you should find helpful

# require 'scraperwiki'
# require 'mechanize'
#
# agent = Mechanize.new
#
# # Read in a page
# page = agent.get("http://foo.com")
#
# # Find somehing on the page using css selectors
# p page.at('div.content')
#
# # Write out to the sqlite database using scraperwiki library
# ScraperWiki.save_sqlite(["name"], {"name" => "susan", "occupation" => "software developer"})
#
# # An arbitrary query against the database
# ScraperWiki.select("* from data where 'name'='peter'")

# You don't have to do things with the Mechanize or ScraperWiki libraries.
# You can use whatever gems you want: https://morph.io/documentation/ruby
# All that matters is that your final data is written to an SQLite database
# called "data.sqlite" in the current working directory which has at least a table
# called "data".
#!/usr/bin/env ruby

require 'scraperwiki'

# Saving data:
# unique_keys = [ 'id' ]
# data = { 'id'=>12, 'name'=>'violet', 'age'=> 7 }
# ScraperWiki.save_sqlite(unique_keys, data)

require 'nokogiri'
require 'json'
require 'rubygems'
require 'mechanize'
require 'csv'
require 'net/http'

# THE CODE IN THIS SCRAPER IS TO GET DETAILS OF THE FIELDS WHICH USUALLY DIFFER BETWEEN LOCAL PLANNING AUTHORITIES.
# THESE FIELDS ARE:
# 1. OPTIONS AVAILABLE UNDER "APPLICATION TYPE",
# 2. OPTIONS AVAILABLE UNDER "DEVELOPMENT TYPE",
# 3. HEADINGS OF THE TABLE SHOWING DATA ON THE INDIVIDUAL APPLICATION
# 4. HEADINGS OF THE TABLE SHOWING DATA ON THE INDIVIDUAL APPEAL

# FIRSTLY, IN ORDER TO SEARCH THE FORM SPECIFY YOUR VARIBLES HERE:
url = 'https://publicaccess.westoxon.gov.uk/online-applications/search.do?action=advanced' #link to the advanced search page on the local authority website
url_beginning = "https://publicaccess.westoxon.gov.uk" #the first bit of the url (ending with "gov.uk")http://planning.stockport.gov.uk/PlanningData-live/search.do?action=advanced&searchType=Appeal
url_appeal = 'https://publicaccess.westoxon.gov.uk/online-applications/search.do?action=advanced&searchType=Appeal' #link to appeals search
council = "West_Oxfordshire" #specify the council name
startDate = "01/03/2017" #specify decision date start
endDate = "03/03/2017" #specify decision date end
startAppealDate = "01/03/2017" #specify appeal start date
endAppealDate = "15/03/2017" #specify appeal end date

# this is to instantiate a new mechanize object
agent = Mechanize.new

# this is to fetch the webpage
page = agent.get(url)

# this is to fetch the form
search_form = page.form('searchCriteriaForm')

# PART 1:
# this is to check what options are available on the form
# under the 'application type' field
app_types = search_form.field_with(:name => 'searchCriteria.caseType').options
app_types_counter = app_types.count
pp app_types_counter
pp app_types

# this is to convert application types to strings
app_types.map! do |app|
    app.to_s
end

# this is to create reference numbers for the final array

reference_array = []

app_types.each do |app|
    reference_array.push("app#{council}#{app}")
end
# pp reference_array

# this is to create one more array with council name
councilapp_array = Array.new(app_types_counter,council)

table = [reference_array, app_types, councilapp_array].transpose
pp table

# this is to save the data in sqlite table
# i = 0

# while i < app_types_counter

# data = { "reference"=>reference_array[i], "app_type"=>app_types[i], "council" =>councilapp_array[i] }
# unique_keys = [ "reference" ]
# ScraperWiki::save_sqlite(unique_keys, data, table_name = "application_type", verbose=2)

# i = i + 1
# end

# PART 2:
# this is to check what options are available on the form
# under the 'development type' field
dev_types = search_form.field_with(:name => 'searchCriteria.developmentType').options
dev_types_counter = dev_types.count
pp dev_types_counter
pp dev_types

# this is to create reference numbers for the final array

reference_array = []

dev_types.each do |dev|
    reference_array.push("dev#{council}#{dev}")
    end
# pp reference_array

# this is to create one more array with council name
councildev_array = Array.new(dev_types_counter,council)

# this is to convert development types to strings
dev_types.map! do |dev|
    dev.to_s
end

table2 = [reference_array, dev_types, councildev_array].transpose
pp table2

# this is to save the data in sqlite table
# i = 0

# while i < dev_types_counter

# data = { "reference"=>reference_array[i], "dev_type"=>dev_types[i], "council" =>councildev_array[i] }
# unique_keys = [ "reference" ]
# ScraperWiki::save_sqlite(unique_keys, data, table_name = "development_type",verbose=2)

# i = i + 1
# end

# PART 3:
# The below code is to select and click on an example application and then to
# check how many rows there are in the table and what the table's headings are

# this is to instantiate a new mechanize object
agent = Mechanize.new

# this is to fetch the webpage
page = agent.get(url)

# this is to fetch the form
search_form = page.form('searchCriteriaForm')

# this is to set the values of two fields of the form
search_form['date(applicationDecisionStart)'] = startDate
search_form['date(applicationDecisionEnd)'] = endDate

# this is to submit the form
page = agent.submit(search_form)

# this is to create an empty array to store the links (results)
links_array = []

# the following loop is to find all links on the page which include
# the "applicationDetails" wording and store them in the links_array.
# There should be 10 links per page.

page.links.each do |link|
	if link.href.include?"applicationDetails"
	links_array.push(link.href)
	end
end

# this is to convert the links to strings,
# then, to suplement urls with the missing text:
# "http://planning.xxxxxxxx.gov.uk"

links_array.map! do |item|
	item.to_s
	item = "#{url_beginning}#{item}"
end

# This is to select the first link from the array
application = links_array[0]

# this is to instantiate a new mechanize object
agent = Mechanize.new

# this is to fetch the webpage and parse HTML using Nokogiri
sub_page = ScraperWiki::scrape(application)
parse_sub_page = Nokogiri::HTML(sub_page)

# *****
# this is to parse the data, remove spaces and push the data
# to the heading_array.

row_counter = parse_sub_page.css('#simpleDetailsTable').css('th').count
	
#pp row_counter
	
heading_array = []
	
i = 0
    
while i < row_counter
    
    heading = parse_sub_page.css('#simpleDetailsTable').css('th')[i].text
    heading_tidied = heading.strip
    heading_tidied = heading_tidied.downcase
    heading_array.push(heading_tidied)
	
	i = i + 1
	
end

# this is to check how many headings there are
head_counter = heading_array.count

pp head_counter
pp heading_array

# this is to create reference numbers for the final table

reference_array = []

heading_array.each do |heading|
    reference_array.push("heading#{council}#{heading}")
end
# pp reference_array

# this is to create one more array with council names
councilhead_array = Array.new(head_counter,council)

table3 = [reference_array, heading_array, councilhead_array].transpose
pp table3

# this is to save the data in sqlite table
# i = 0

# while i < head_counter

# data = { "reference"=>reference_array[i], "table_heading"=>heading_array[i], "council" =>councilhead_array[i] }
# unique_keys = [ "reference" ]
# ScraperWiki::save_sqlite(unique_keys, data, table_name = "headings",verbose=2)

# i = i + 1
# end

# PART 4:
# The below code is to select and click on an example appeal and then to
# check how many rows there are in the table and what the table's headings are

# this is to instantiate a new mechanize object
agent = Mechanize.new

# this is to fetch the webpage
page = agent.get(url_appeal)

# this is to fetch the form
search_form = page.form('searchCriteriaForm')

# this is to set the values of two fields of the form
search_form['date(appealLodgedStart)'] = startAppealDate
search_form['date(appealLodgedEnd)'] = endAppealDate

# this is to submit the form
page = agent.submit(search_form)

# this is to create an empty array to store the links (results)
appeallinks_array = []

# the following loop is to find all links on the page which include
# the "appealDetails" wording and store them in the appeallinks_array.
# There should be 10 links per page.

page.links.each do |link|
	if link.href.include?"appealDetails"
	appeallinks_array.push(link.href)
	end
end

# this is to convert the links to strings,
# then, to suplement urls with the missing text:
# "http://planning.xxxxxxxx.gov.uk"

appeallinks_array.map! do |item|
	item.to_s
	item = "#{url_beginning}#{item}"
end

# This is to select the first link from the array
appeal = appeallinks_array[0]

# this is to instantiate a new mechanize object
agent = Mechanize.new

# this is to fetch the webpage and parse HTML using Nokogiri
sub_page = ScraperWiki::scrape(appeal)
parse_sub_page = Nokogiri::HTML(sub_page)

# *****
# this is to parse the data, remove spaces and push the data
# to the appealheading_array.

row_counter = parse_sub_page.css('#appealDetails').css('th').count
	
#pp row_counter
	
appealheading_array = []
	
i = 0
    
while i < row_counter
    
    appealheading = parse_sub_page.css('#appealDetails').css('th')[i].text
    appealheading_tidied = appealheading.strip
    appealheading_tidied = appealheading_tidied.downcase
    appealheading_array.push(appealheading_tidied)
	
	i = i + 1
	
end

# this is to check how many appeal headings there are
appealhead_counter = appealheading_array.count

pp appealhead_counter
pp appealheading_array

# this is to create reference numbers for the final table

reference_array = []

appealheading_array.each do |appealheading|
    reference_array.push("appealheading#{council}#{appealheading}")
end
# pp reference_array

# this is to create one more array with council name
councilappealhead_array = Array.new(appealhead_counter,council)

table4 = [reference_array, appealheading_array, councilappealhead_array].transpose
pp table4

# this is to save the results in sqlite table
# i = 0

# while i < appealhead_counter

# data = { "reference"=>reference_array[i], "appeal_heading"=>appealheading_array[i], "council" =>councilappealhead_array[i] }
# unique_keys = [ "reference" ]
# ScraperWiki::save_sqlite(unique_keys, data, table_name = "appeal_headings",verbose=2)

# i = i + 1
# end

# ADDITIONAL CHECKS (OPTIONAL)

# checking whether url exists:

# url = URI.parse("http://planning.basildon.gov.uk/online-applications/search.do?action=advanced")
# req = Net::HTTP.new(url.host, url.port)
## req.use_ssl = true (piece of the code to include in the https addresses)
# res = req.request_head(url.path)

# pp res
