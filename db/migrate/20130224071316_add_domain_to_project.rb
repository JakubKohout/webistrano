class AddDomainToProject < ActiveRecord::Migration
  def self.up
    add_column :projects, :domain, :string
  end

  def self.down
    remove_column :projects, :domain
  end
end
