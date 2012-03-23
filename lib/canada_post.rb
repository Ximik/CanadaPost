# :main: README.rdoc

require 'net/http'
require 'rexml/document'
require 'builder'
 
class CanadaPost

  def initialize # :nodoc:
    @items = []
  end

  #
  # This method sets the merchant information
  #     
  def setMerchant(merchant)
    @merchantInfo = merchant;
  end  
  
  #
  # This method sets the customer information
  #  
  def setCustomer(customer)
    @customerInfo = customer;
  end
  
  #
  # This method allows you to add items to be shipped
  #  
  def addItem(item)
    @items << item;
  end    
  
  #
  # The main method. Makes request and parse the response
  #
  def getRates
    url = URI.parse 'http://sellonline.canadapost.ca:30000/'
    request = Net::HTTP::Post.new(url.path)
    request.content_type = 'application/x-www-form-urlencoded'
    request.body = prepareXML
    response = Net::HTTP.start(url.host, url.port) {|http| http.request(request)}
    xml = REXML::Document.new(response.body).root
    if error = xml.elements['error']
      error = error.elements['statusMessage'].text
      raise StandardError.new(error)
    end
    xml = xml.elements['ratesAndServicesResponse']
    result = {}
    result[:products] = []
    xml.elements.each('product') do |p|
      product = {}
      p.elements.each do |t|
        product[t.name.to_sym] = t.text
      end
      result[:products] << product
    end
    result[:options] = {}
    xml.elements['shippingOptions'].elements.each do |t|
      result[:options][t.name.to_sym] = t.text
    end
    return result
  end
  
  private 
  
  
  #
  # This method prepares the XML to be send to Canada Posts's Server.
  #
  def prepareXML
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.eparcel do
      xml.language 'en'
      xml.ratesAndServicesRequest do
        buildTags(xml, [:merchantCPCID, :fromPostalCode, :turnAroundTime, :itemsPrice], @merchantInfo)
        xml.lineItems do
          @items.each do |item|
            xml.item do
              buildTags(xml, [:quantity, :weight, :length, :width, :height, :description], item)
            end
            xml.readyToShip if item[:readyToShip]
          end
        end
        buildTags(xml, [:city, :provOrState, :country, :postalCode], @customerInfo)
      end
    end
    return xml.target!
  end
  
  #
  # This method just build tags in right order.
  #
  def buildTags(xml, tags, hash)
    tags.each do |t|
      text = hash[t]
      xml.method_missing t, text if text
    end
  end
        
end
