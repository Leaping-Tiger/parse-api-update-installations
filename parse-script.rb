# Script to update Installation channel names through parse.com api

# notes:
# - This is not officially supported by the api, nor is it described in the documentation
# - I hacked this together by analysing requests made in their web app on the core console.
# - I wrote this script to change our channel names of installations from user.username to user.id to facilitate changing usernames, 
#   and so that is the example I've included here. However you should be able to update any part of an installation by customising this script


# GET THESE BY ANALYSING A REQUEST MADE IN THE WEB APP CORE CONSOLE ON PARSE.COM
_ApplicationId = "" 
_MasterKey = "" 
_InstallationId = 

results_json = nil
skip = 0
while skip == 0 || (results_json.present? && results_json['results'].count > 0)

  uri = URI.parse(URI.encode("https://api.parse.com/1/classes/_Installation/"))
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Get.new(uri.request_uri)
  query = {"limit" => 101, "skip" => skip }
  request.form_data = query
  request.basic_auth( _ApplicationId , _MasterKey)
  response = http.request(request)
  results_json = JSON.parse(response.body)  

  old_skip = skip
  skip = skip+results_json['results'].count-1

  if skip != old_skip
    puts "\n\n! ------- NEW GET REQUEST: #{query} --------!"
    puts "FIRST RESULT #{  results_json['results'].first['channels'] }\n\n"
  else
    results_json = nil 
    puts "\n\n\n! ----------- ALL DONE! ----------- !"
  end

  if results_json.present?
    results_json['results'].each do |installation_json|

      if installation_json.present? && installation_json["channels"].present? && installation_json["channels"].count == 1


        # find relevant record based on current channels
        channel = installation_json["channels"].first
        user = User.find_by_username channel 

        if user.blank?
          puts " ? ------------ NO USER FOUND FOR #{channel} -------- ?"
        else
          
          # note channel names cannot start with a number and so I prefix them with 'user_'
          new_channel_name = "user_#{user.id}"

          uri = URI.parse(URI.encode("https://api.parse.com/1/classes/_Installation/#{installation_json["objectId"]}"))
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          request = Net::HTTP::Post.new(uri.request_uri)
          request.basic_auth( _ApplicationId , _MasterKey)
          request.body = { "channels" => [new_channel_name], "_method" => "PUT", "_InstallationId" => _InstallationId, "_ClientVersion" => "browser" }.to_json
          response = http.request(request)
          res = JSON.parse(response.body)
          puts "\n\nPROCESSED USER: #{user.id} #{user.username}, RESULT: #{res}\n\n"
        end # if user was identified

      end #if channels present

    end # foreach installation_json
  end # if results_json.present?

end #while

