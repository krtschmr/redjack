RSpec.describe Redjack::Card do

	it "is an ace" do
		card = Redjack::Card.new("A", "hearts")
		expect(card).to be_ace
	end

	it "has correct points for face cards" do 
		{
			"A" => 11,
			"K" => 10,
			"Q" => 10,
			"J" => 10			
		}.each do |face, value|
			card = Redjack::Card.new(face, "hearts")
			expect(card.points).to eq(value)
		end
	end

	it "has correct points for number cards" do 
		2.upto(10).each do |number|
			card = Redjack::Card.new(number, "hearts")
			expect(card.points).to eq(number)
		end
	end
	
end