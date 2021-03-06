class Estimate < ActiveRecord::Base
  belongs_to :consolidated_tax
  belongs_to :customer
  has_many :slips
  
  validates_presence_of :date
  
  before_save do
    self.number = self.customer.user.options.where(:name => 'NEXT_ESTIMATE_NUMBER').first.value.to_i
  end
    
  after_save do
    opt = self.customer.user.options.where(:name => 'NEXT_ESTIMATE_NUMBER').first
    opt.value = opt.value.to_i + 1
    opt.save!
  end
  
  # Get the sum of the slips' rates
  def rate
    sum = 0
    self.slips.each { |slip| sum += slip.rate }
    sum
  end
  
  # Applies consolidated taxes to the slip rate
  def total
    sum = self.rate
    compounds = []
    self.consolidated_tax.taxes.each do |tax|
      partial = sum * tax.rate / 100
      if tax.compound
        compounds << partial
      else
        compounds.each { |compound| sum += compound }
        sum += partial
      end
    end
    
     compounds.each { |compound| sum += compound }
    sum
  end
end
