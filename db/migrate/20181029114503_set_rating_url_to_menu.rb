class SetRatingUrlToMenu < ActiveRecord::Migration[5.1]
  def self.up

    menu_link = MenuLink.create :community_id => 1, :sort_priority => 0
    MenuLinkTranslation.create :menu_link_id => menu_link.id, :locale => 'en', :url => "http://#{APP_CONFIG.domain}/en/ratings", :title => 'Ratings'

  end
end
