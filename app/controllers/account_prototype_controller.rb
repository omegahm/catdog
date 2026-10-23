class AccountPrototypeController < ApplicationController
  VARIANTS = { "A" => "Header menu", "B" => "One account page", "C" => "Home is the hub" }.freeze
  PAGES = { "home" => "Home", "game" => "Game page", "account" => "Account", "signup" => "Sign up" }.freeze

  Game = Data.define(:opponent, :state, :your_turn, :ago)
  Passkey = Data.define(:name, :last_used, :created)

  def show
    @variants = VARIANTS
    @variant = VARIANTS.key?(params[:variant]) ? params[:variant] : "A"
    @page = PAGES.key?(params[:page]) ? params[:page] : "home"
    @signed_in = params[:as] != "guest"
    @no_passkeys = params[:nopasskeys].present?
    @name = "Mads"
    @games = params[:nogames] ? [] : [
      Game.new("Mette", "playing", true, "2 hours ago"),
      Game.new("Guest", "playing", false, "yesterday"),
      Game.new(nil, "lobby", false, "3 days ago")
    ]
    @passkeys = [
      Passkey.new("iCloud Keychain", "today", "1 Oct 2026"),
      Passkey.new("YubiKey 5C", "3 weeks ago", "2 Oct 2026")
    ]
    @stats = { played: 27, won: 14, drawn: 3, lost: 10 }
  end
end
