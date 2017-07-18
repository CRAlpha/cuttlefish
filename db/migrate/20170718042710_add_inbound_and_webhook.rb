class AddInboundAndWebhook < ActiveRecord::Migration
  def change
    add_column :apps, :event_webhook, :string
    add_column :apps, :inbound_webhook, :string
  end
end
