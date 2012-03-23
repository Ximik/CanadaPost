# :main: README.rdoc

require 'net/http'
require 'rexml/document'
require 'builder'
 
class CanadaPost

  def initialize :nodoc:
    @items = []
  end

  #
  # This method sets the Merchant information
  #     
  def setMerchant(merchantInfo)
    @merchantInfo = merchantInfo;
  end  
  
  #
  # This method sets the Customer Info
  #  
  def setCustomer(customerInfo)
    @customerInfo = customerInfo;
  end
  
  #
  # This method allows you to Add items to be shipped
  #  
  def addItem(itemInfo)
    @items << itemInfo;
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
        xml.merchantCPCID 'CPC_DEMO_XML'
        [:fromPostalCode, :turnAroundTime, :itemsPrice].each { |k| xml.method_missing k, @merchantInfo[k] }
        xml.lineItems do
          @items.each do |item|
            xml.item do
              [:quantity, :weight, :length, :width, :height, :description].each { |k| xml.method_missing k, item[k] }
            end
            xml.readyToShip if item[:readyToShip]
          end
        end
        [:city, :provOrState, :country, :postalCode].each { |k| xml.method_missing k, @customerInfo[k] }
      end
    end
    return xml.target!
  end
        
end