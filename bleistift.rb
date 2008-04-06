#!/usr/bin/env ruby
require 'rubygems'
require 'camping'
require 'camping/session'
require 'RedCloth'

Camping.goes :Bleistift

module Bleistift
  include Camping::Session
end

module Bleistift::Models
  class Thing<Base
    has_many :ratings
  end
  class Rating<Base
    belongs_to :thing
  end
  class CreateDing < V 0.1
    def self.up
      create_table :bleistift_things, :force => true do |t|
        t.text :body
        t.timestamps
      end
      create_table :bleistift_ratings, :force => true do |t|
        t.integer :thing_id
        t.string :username
        t.text :reason
        t.timestamps
      end
    end
    def self.down
      drop_table :bleistift_things
      drop_table :bleistift_ratings
    end
  end
  class DingHasUsername < V 0.2
    def self.up
      add_column :bleistift_things, :username, :string
    end
    def self.down
      remove_column :bleistift_things, :username
    end
  end
  class RatingHasRatingDoh < V 0.3
    def self.up
      add_column :bleistift_ratings, :value, :integer
    end
    def self.down
      remove_column :bleistift_ratings, :value
    end
  end
end

module Bleistift::Controllers
  class Index < R('/')
    def get
      @things = Thing.find(:all)
      render :list
    end
  end

  class New < R '/new'
    def get
      @thing = Thing.new
      render :new
    end
    def post
      @thing = Thing.new(@input.thing)
      if @thing.save
        redirect Index
      else
        render :new
      end
    end
  end
    
  class Rate < R('/rate/(\d)')
    def post(id)
      thing = Thing.find(id)
      value = case @input.rating
      when 'Diesseits'
        1
      when 'Jenseits'
        -1
      else
        0
      end      
      thing.ratings.create(:value => value, :username => 'not implemented')
      redirect Index
    end
  end
  class Static < R '/static/(.+)'
    MIME_TYPES = {'.css' => 'text/css', '.js' => 'text/javascript', '.jpg' => 'image/jpeg', '.png' => 'image/png', '.gif' => 'image/gif'}
    PATH = File.expand_path(File.dirname(__FILE__))
    def get(path)
      @headers['Content-Type'] = MIME_TYPES[path[/\.\w+$/, 0]] || "text/plain"
      unless path.include? ".." # prevent directory traversal attacks
        @headers['X-Sendfile'] = "#{PATH}/static/#{path}"
      else
        @status = "403"
        "403 - Invalid path"
      end
    end
  end
end

module Bleistift::Views
  def layout
    html do
      head do
        title((@title ? @title : "" ) + " - jenseits des bleitstiftstummels")
        link :rel => "stylesheet", 
              :href => R(Static, 'stylesheets/style.css'), 
              :type => "text/css", 
              :media => 'screen'
        script :src => R(Static, "javascripts/prototype.js"), 
                :type => 'text/javascript'
        script :src => R(Static, "javascripts/scriptaculous.js"), 
                :type => 'text/javascript'          
        script :src => R(Static, "javascripts/application.js"), 
                :type => 'text/javascript'          
      end
      body do
        div.header! do
          h1 do
            a "jenseitsdesbleistiftstummels", :href => R(Index)
          end
          p "für jäger und sammler"
          img :src => R(Static, 'images/spinner.gif'), 
              :id => 'spinner', 
              :style => 'display:none'
        end
        div.content! do
          self << yield
        end
        div.footer! do
          "&copy; 2008 jan krutisch - camping ftw!"
        end
      end
    end
  end
  
  def list
    p do
      a "Neues Ding bauen", :href => R(New)
    end
    
    ul do
      @things.each do |thing|
        li do
          self << textilize(thing.body)
          p do
            self << "Rating: #{thing.ratings.average(:value)}"
          end
          p do
            form :action => R(Rate, thing.id), :method => 'POST' do
              input :type => 'submit', :value => 'Jenseits', :name => 'rating'
              input :type => 'submit', :value => 'Diesseits', :name => 'rating'
            end
          end
        end
      end
    end
    
  end

  def new
    h2 "Neues Bleistift-Ding"
    errors_for(@thing)
    form :action => R(New), :method => 'POST' do
      _form
      p do
        input :type => "submit", :value => "Create"
        self << " or "
        a "Cancel", :href => R(Index) 
      end
    end
  end
  
  def _form
    p do
      textarea @thing.body, :name => 'thing[body]', 
            :rows => 5,
            :cols => 80,
            :id => 'thing_body'
    end
  end
  
end
module Bleistift::Helpers
  def textilize(text)
    RedCloth.new(text).to_html
  end
end


def Bleistift.create
  Camping::Models::Session.create_schema
  Bleistift::Models.create_schema
end
