module OpsWorks
  module User

    def load_existing_ssh_users
      #return {} unless node[:opsworks_gid]

      existing_ssh_users = {}
      (node[:passwd] || node[:etc][:passwd]).each do |username, entry|
        if entry[:gid] == node[:opsworks_gid]
          existing_ssh_users[entry[:uid].to_s] = username
        end
      end
      existing_ssh_users
    end

    def load_existing_users
      existing_users = {}
      (node[:passwd] || node[:etc][:passwd]).each do |username, entry|
        existing_users[entry[:uid].to_s] = username
      end
      existing_users
    end

  end
end

class Chef::Recipe
  include OpsWorks::User
end
class Chef::Resource::User
  include OpsWorks::User
end
