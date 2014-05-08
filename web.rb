require './db/config'
require 'sinatra/base'
require 'sinatra/assetpack'
require 'grape'

Dir['./lib/validators/**/*.rb'].each { |f| require(f) }

configure do
  set :server, :puma
end

module Transitmix
  class Home < Sinatra::Base
    set :root, File.dirname(__FILE__)

    register Sinatra::AssetPack

    assets do
      js :app, [
        '/js/app.js',
        '/js/utils.js',
        '/js/data/*.js',
        '/js/models/*.js',
        '/js/collections/*.js',
        '/js/views/*.js',
        '/js/routers/*.js',
      ]

      css :app, [
        '/css/style.css'
       ]

      js_compression :uglify
      css_compression :simple
    end

    get '/' do
      erb :index
    end

    get '/*' do
      if params[:splat].first[0,3] == 'api'
        pass
      else
        erb :index
      end
    end

  end # Home

  class API < ::Grape::API
    version 'v1', using: :header, vendor: 'transitmix'
    format :json

    rescue_from Sequel::NoMatchingRow do
      Rack::Response.new({}, 404)
    end

    namespace :api do
      resource :lines do
        helpers do
          def line_params
            Line::PERMITTED.reduce({}) { |model_params, attr|
              model_params[attr] = params[attr] if params[attr]
              model_params
            }
          end
        end

        params do
          requires :id, type: String
        end

        get '/:id' do
          Line.first!(id: params[:id])
        end

        params do
          optional :page, type: Integer, default: 1
          optional :per, type: Integer, default: 10, max: 100
        end

        get do
          Line.dataset.paginate(params[:page], params[:per]).order(Sequel.desc(:created_at))
        end

        params do
          requires :name, type: String
          requires :description, type: String
          requires :coordinates, type: Array
          optional :start_time, type: String
          optional :end_time, type: String
          optional :frequency, type: Integer
          optional :speed, type: Integer
          optional :color, type: String
        end

        post do
          Line.create(line_params)
        end

        params do
          requires :id, type: String
        end

        put '/:id' do
          line = Line.where(id: params[:id]).first
          line.update(line_params)
          line
        end
      end # resource :lines

      resource :maps do
        helpers do
          def map_params
            Map::PERMITTED.reduce({}) { |model_params, attr|
              model_params[attr] = params[attr] if params[attr]
              model_params
            }
          end
        end

        params do
          requires :id, type: String
        end

        get '/:id' do
          Map.first!(id: params[:id])
        end

        params do
          optional :page, type: Integer, default: 1
          optional :per, type: Integer, default: 10, max: 100
        end

        get do
          Map.dataset.paginate(params[:page], params[:per]).order(Sequel.desc(:created_at))
        end

        params do
          requires :name, type: String
          optional :center, type: Array
          optional :zoom_level, type: String
        end

        post do
          Map.create(map_params)
        end

        params do
          requires :id, type: String
        end

        put '/:id' do
          map = Map.where(id: params[:id]).first
          map.update(map_params)
          map
        end
      end # resource :maps
    end # namespace :api

  end # API

  class StatusAPI < Grape::API
    format :json
    get('/.well-known/status') { Status.new }
  end # Status
end # Transitmix