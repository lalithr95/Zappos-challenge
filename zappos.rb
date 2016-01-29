#!/usr/bin/ruby
=begin
When giving gifts, consumers usually keep in mind two variables - cost and quantity. In order to facilitate better gift-giving on the Zappos website, our Software Engineering team would like you to create an application (or a web application) that does the following: 

- Take two inputs: N (desired # of products) and X (desired dollar amount) 
- Use the attachments that show screen shots of our API documentation (start with the API-home doc) with directions & information to create a list of Zappos products whose combined values match as closely as possible to X dollars. For example, if a user entered 3 (# of products) and $150, the application should print combinations of 3 product items whose total value is closest to $150. 
- You should output at least 3-5 unique combinations. 

For each combination: 

- It has to be unique (e.g. [3, 4, 5] is the same as [4,3,5]) 
- You shouldn't re-use a product; it should consist of unique products. (e.g. [4,4,5] is not allowed) 
- You should also download/save image associated with each product. 

- Extra credit: Sort the combinations by how close they are to the target total price. 
=end

require "json"
require "httparty"
require "open-uri"

class Zappos
  def initialize
    puts "Enter Desired product count"
    @desired_products = gets.chomp.to_f
    puts "Enter Desired amount $ "
    @desired_amount = gets.chomp.to_f
    @apiKey = "12c3302e49b9b40ab8a222d7cf79a69ad11ffd78"
  end
  
  def getProducts()
    #Fetches only required products and sorts on basis of price
    searchTerm = ""
    @itemLimit = 100
    if ( @desired_amount / @desired_products ).round(2) <= 10.00
      priceSort = '"price":"asc"'
      url = URI.escape("http://api.zappos.com/Search?term=#{searchTerm}&sort={#{priceSort}}&limit=#{@itemLimit}&key=#{@apiKey}")
    elsif (@desired_amount/@desired_products).round(2) >= 1500.00
      priceSort = '"price":"desc"'
      url = URI.escape("http://api.zappos.com/Search?term=#{searchTerm}&sort={#{priceSort}}&limit=#{@itemLimit}&key=#{@apiKey}")
    else 
      url = URI.escape("http://api.zappos.com/Search?term=#{searchTerm}&limit=#{@itemLimit}&key=#{@apiKey}")
    end
    response = HTTParty.get(url)
    response = JSON.parse(response.body)
    return filterProducts(response)
  end
  
  def api_error()
    puts "Problem with API error"
    exit 0
  end
  
  def filterProducts(response)
    # Filter products which have amount less than desired_amount. High price products are filtered in this phace
    result = {}
    result['model'] = []
    response['results'].each do |record|
      if record['price'].gsub('$','').to_f < @desired_amount
        result['model'] << record
      end
    end
    result
  end
  
  def getCombination(data)
    # Generates combination of products
    # A caching system can be implemented on combination obtained. Whenever user uses the program again combination need
    # not be computed.
    product = {}
    data['model'].each do |record|
      image_data = Hash.new
      image_data[:url], image_data[:format] = getProductImage(data, record['productId'], record['styleId'].to_s)
      product[record['productId']] = [record['price'], record['productName'], image_data]
    end
    data = product
    products = product.keys.combination(@desired_products).to_a
    return products, data
  end

  def getProductImage(data, productId, styleId)
    # Fetches product image of product
    url = "http://api.zappos.com/Image?productId=#{productId}&key=#{@apiKey}"
    response = HTTParty.get(url)
    response = JSON.parse(response.body)
    return response['images'][styleId][0]['filename'], response['images'][styleId][0]['format']
  end
  
  def arrageProducts(comb, data)
    # comb contains key as list and value as price and we sort on basis of value
    # Extra credit: Sort the combinations by how close they are to the target total price.
    result = {}
    comb.each do |a|
      result[a] = calculatePrice(a, data) if calculatePrice(a, data) < @desired_amount
    end
    result = result.sort {|x,y| y[1] <=> x[1]}
    printResult(result, data)
  end
  
  def calculatePrice(a, data)
    # Calculates total price of each combination
    price = 0.0
    a.each do |i|
      price += data[i][0].gsub("$","").to_f
    end
    price
  end
  
  def printResult(result, data)
    # Prints result to User and also downloads the image respected to the product to user
    # Image download can be pushed as a background job
    i = 0
    uniqueKeys = []
    result.each do |key, value|
      if i == 4
        break
      else
        flag = true
        key.each do |k|
          if uniqueKeys.include? k
            flag = false
            break
          end
        end
        if flag
          if value < @desired_amount
            printStyle(key, value, data)
            i += 1
          end
          key.each do |k|
            uniqueKeys << k
            open(data[k][2][:url]) do |f|
               File.open("#{k}.#{data[k][2][:format]}","wb") do |file|
                 file.puts f.read
               end
            end
          end
        end
      end
    end
  end

  def printStyle key, value, data
    # Print with little Style ;)
    5.times { print "="}
    puts "Product Combination Value " + value.to_s
    5.times { print "="}
    puts key.to_s
    key.each do |k|
      puts "Name : " + data[k][1]
      puts "Price: " + data[k][0]
    end
  end
end

# Object creation and method invocation
z = Zappos.new
products = z.getProducts()
combination, data = z.getCombination(products)
z.arrageProducts(combination, data)
