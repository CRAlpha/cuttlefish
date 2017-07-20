class AddReportedToDelivery < ActiveRecord::Migration
  def change
    add_column :deliveries, :reported, :boolean, default: false
    Delivery.update_all(reported: true)
  end
end
