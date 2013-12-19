require 'rubygems'
require 'sinatra'
# require 'pry'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17

helpers do
    def cal_total(cards)
        arr = cards.map { |e| e[1] }

    total = 0
    arr.each do |a|
      if a == 'A'
       total += 11
      elsif a.to_i == 0
        total += 10
      else
        total += a.to_i
      end
    end

    arr.select { |e| e == "A"}.count.times do
      if total <= BLACKJACK_AMOUNT
        break
      else 
        total -= 10
        end
      end

    total
  end

    def card_images(card) #['H','4']
      suit = case card[0]
        when 'H' then 'hearts'
        when 'D' then 'diamonds'
        when 'C' then 'clubs'
        when 'S' then 'spades'
      end

        value = card[1]
        if ['J', 'Q', 'K', 'A'].include?(value)
            value = case card[1]
                when 'J' then 'jack'
                when 'Q' then 'queen'
                when 'K' then 'king'
                when 'A' then 'ace'
            end
        end

    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
    end

    def winner(msg)
      @success = "<strong>#{session[:player_name]} wins</strong> #{msg}"
      @show_hit_or_stay_buttons = false
      @play_again = true
    end

    def loser(msg)
      @error = "Player <strong>#{session[:player_name]} loses #{msg}</strong>"
      @show_hit_or_stay_buttons = false
      @play_again = true
    end

    def tie(msg)
      @success = "<strong>It's a tie #{msg}"
      @show_hit_or_stay_buttons = false
      @play_again = true
    end
end

before do
    @show_hit_or_stay_buttons = true
end

get '/' do
    if session[:player_name]
        redirect '/game'
    else
        redirect '/new_player'
    end
end

get '/new_player' do
    erb :new_player
end

post '/new_player' do
    name_check = params[:player_name]
    if name_check.empty?
      @error = "Name is required"
      halt erb(:new_player)
    end

    if name_check != name_check[/[a-zA-Z]+/]
      @error = "Your name can only consist of letters"
      halt erb(:new_player)
    end

    session[:player_name] = params[:player_name].capitalize
    #progress to the game
    redirect '/game'
end 

get '/game' do
  session[:turn] = session[:player_name]

  #Create deck
  suits = ['S', 'H', 'D', 'C']
  cards = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(cards).shuffle!
  #setup hands
  session[:dealer_cards] = []
  session[:player_cards] = []
  #deal cards
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  erb :game
end

post '/game/player/hit' do
    session[:player_cards] << session[:deck].pop

    player_total = cal_total(session[:player_cards])
    if player_total == BLACKJACK_AMOUNT
      winner("#{session[:player_name]} hit blackjack")
    elsif player_total > BLACKJACK_AMOUNT
      loser("because they busted")
    end

    erb :game
end

post '/game/player/stay' do
    @success = "#{session[:player_name]} selected to stay"
    @show_hit_or_stay_buttons = false
    redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = "dealer"
    @show_hit_or_stay_buttons = false
    dealer_total = cal_total(session[:dealer_cards])

    if dealer_total == BLACKJACK_AMOUNT
        loser(",dealer hit Blackjack")
    elsif dealer_total > BLACKJACK_AMOUNT
        winner("Dealer busted at #{session[:dealer_total]}")
    elsif dealer_total >= DEALER_MIN_HIT 
        redirect '/game/compare'
    else
        @show_dealer_hit_button = true
    end

    erb :game
end

post '/game/dealer/hit' do
    session[:dealer_cards] << session[:deck].pop
    redirect '/game/dealer'
end

get '/game/compare' do
    @show_hit_or_stay_buttons = false
    player_total = cal_total(session[:player_cards])
    dealer_total = cal_total(session[:dealer_cards])

    if player_total < dealer_total
        @error = "#{session[:player_name]} lost the game because the dealers total was higher"
        loser("#{session[:player_name]} stayed at #{player_total} and the dealer had a total of #{dealer_total}")
    elsif player_total > dealer_total
        @success = "Congratz. #{session[:player_name]} you beat the dealers total and won the game"
        winner("#{session[:player_name]} stayed at #{player_total} and the dealer had a total of #{dealer_total}")
    else
        @error = "#{session[:player_name]} you lost because you and the dealer had the same total"
        tie("#{session[:player_name]} and the dealer stayed at #{dealer_total}")
    end

    erb :game
end

get '/game_over' do
  erb :game_over
end