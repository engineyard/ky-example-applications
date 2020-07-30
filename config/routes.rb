Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get '/add-requests-in-queue', to: 'pages#add_requests_in_queue'

end


