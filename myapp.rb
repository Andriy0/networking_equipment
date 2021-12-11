require 'mysql2'

require 'sinatra/base'
require 'sinatra/reloader'

require 'haml'

require 'dotenv'
Dotenv.load

class NetEq < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  
  set :root, File.dirname(__FILE__)
  
  client = Mysql2::Client.new(:host => ENV['HOST'],
                              :username => ENV['USERNAME'],
                              :password => ENV['PASSWORD'],
                              :database => ENV['DBNAME'])

  use Rack::Session::Cookie,
      :key => 'rack.session',
      :path => '/',
      :secret => ENV['SESSION_SECRET']

  get '/change_lang' do

    if session[:lang] == "en"
      session[:lang] = "ua"
    else
      session[:lang] = "en"
    end

    redirect to params['rout']
    
  end
  
  get '/' do

    if !session[:lang]
      session[:lang] = "us"
    end
    
    @products = client.query("
SELECT 
  a.id, a.name, 
  a.rating, a.price 
FROM adapter a;
")

    @headers = @products.fields

    haml :index
    
  end

  get '/details' do
    
    @result = client.query("
SELECT 
  a.id, a.name, a.rating, a.weight,
  a.price, a.hardware_interface,
  a.data_link_protocol, a.item_dimensions,
  a.data_transfer_rate,
  v.name AS 'brand', 
  t.name AS 'type',
  ct.name AS 'connection_type'
FROM vendor v
  INNER JOIN adapter a ON 
    v.id = a.vendor_id
  INNER JOIN type t ON 
    t.id = a.type_id
  INNER JOIN connection_type ct ON 
    ct.id = a.connection_type_id
WHERE a.id = #{params['id']};
")

    @result.each do |row|
      @product = row
    end
    
    haml :details
    
  end

  get '/edit_product' do

    @result = client.query("
SELECT 
  a.id, a.name, a.rating, a.weight,
  a.price, a.hardware_interface,
  a.data_link_protocol, a.item_dimensions,
  a.data_transfer_rate,
  v.name AS 'brand', a.vendor_id AS 'brand_id',
  t.name AS 'type', a.type_id,
  ct.name AS 'connection_type', a.connection_type_id
FROM vendor v
  INNER JOIN adapter a ON 
    v.id = a.vendor_id
  INNER JOIN type t ON 
    t.id = a.type_id
  INNER JOIN connection_type ct ON 
    ct.id = a.connection_type_id
WHERE a.id = #{params['id']};
")

    @result.each do |row|
      @product = row
    end

    @brands = client.query("
SELECT *
FROM vendor;
")
    
    @types = client.query("
SELECT *
FROM type;
")
    
    @connection_types = client.query("
SELECT *
FROM connection_type;
")
    
    haml :edit_product
    
  end

  get '/add_product' do

    @brands = client.query("
SELECT *
FROM vendor;
")
    
    @types = client.query("
SELECT *
FROM type;
")
    
    @connection_types = client.query("
SELECT *
FROM connection_type;
")
    
    haml :add_product
    
  end

  post '/add_product' do

    client.query("
INSERT INTO 
       adapter 
       (name, rating, price, vendor_id, type_id, 
        connection_type_id, item_dimensions,
        data_link_protocol, hardware_interface, 
        data_transfer_rate, weight)
VALUES 
       (\"#{params['product_name']}\",
        \"#{params['product_rating']}\",
        \"#{params['product_price']}\",
        \"#{params['product_brand']}\",
        \"#{params['product_type']}\",
        \"#{params['product_connection_type']}\",
        \"#{params['product_dimensions']}\",
        \"#{params['product_data_link_protocol']}\",
        \"#{params['product_hardware_interface']}\",
        \"#{params['product_data_transfer_rate']}\",
        \"#{params['product_weight']}\");
")
    
    redirect to('/')
    
  end

  post '/edit_product' do

    client.query("
UPDATE adapter SET
  name = \"#{params['product_name']}\",
  rating = \"#{params['product_rating']}\",
  price = \"#{params['product_price']}\",
  vendor_id = \"#{params['product_brand']}\",
  type_id = \"#{params['product_type']}\",
  connection_type_id = \"#{params['product_connection_type']}\",
  item_dimensions = \"#{params['product_dimensions']}\",
  data_link_protocol = \"#{params['product_data_link_protocol']}\",
  hardware_interface = \"#{params['product_hardware_interface']}\",
  data_transfer_rate = \"#{params['product_data_transfer_rate']}\",
  weight = \"#{params['product_weight']}\"
WHERE id = #{params['id']};
")

    redirect to('/details?id=' + params['id'])

  end

  get '/delete_product' do

    client.query("
DELETE FROM adapter
WHERE id = #{params['id']};
")
    
    redirect to('/')
    
  end

  get '/structure' do
    haml :structure
  end

  get '/brands' do
    
    @brands = client.query("
SELECT *
FROM vendor;
")

    @brand_headers = @brands.fields
    
    haml :brands
  end

  post '/add_brand' do
    
    client.query("
INSERT INTO vendor (name)
VALUES (\"#{params['brand_name']}\");
")

    redirect to('/brands')

  end

  get '/edit_brand' do

    result = client.query("
SELECT *
FROM vendor
WHERE id = #{params['id']};
")
    result.each do |row|
      @brand = row
    end

    haml :edit_brand
    
  end

  post '/edit_brand' do

    client.query("
UPDATE vendor SET
name = \"#{params['brand_name']}\"
WHERE id = #{params['id']};
")

    redirect to('/brands')

  end
  
  get '/delete_brand' do

    client.query("
DELETE FROM vendor
WHERE id = #{params['id']};
")

    redirect to('/brands')

  end   

  get '/search' do

    haml :search
    
  end

  post '/search' do

    @products = client.query("
SELECT 
  a.id, a.name, 
  a.rating, a.price 
FROM 
  vendor v
  INNER JOIN adapter a ON 
    v.id = a.vendor_id
  INNER JOIN type t ON 
    t.id = a.type_id
  INNER JOIN connection_type ct ON 
    ct.id = a.connection_type_id
WHERE
  a.name LIKE \"%#{params['keyword']}%\"
  OR t.name LIKE \"%#{params['keyword']}%\"
  OR ct.name LIKE \"%#{params['keyword']}%\";
")
     
    haml :search

  end
  
end
