class ApplicationController < ActionController::Base

  before_perform :print_all_headers
  def print_all_headers
    #p request.env.to_hash.select{ |key,val| ! key.starts_with?("rack") && ! key.starts_with?("action_")}
    p request.env.to_hash 
  end
    
end
