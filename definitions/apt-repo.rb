define :apt_repo,
    :key_package => nil,
    :key_id => nil,
    :key_url => nil,
    :keyserver => "keys.gnupg.net",
    :url => nil,
    :distribution => nil,
    :components => "main",
    :source_packages => false,
    :description => nil do

  unless params[:key_package] or params[:key_id]
    raise "Cannot find key_package or key_id"
  end

  unless params[:url]
    raise "Cannot find url"
  end

  components = params[:components]
  components = components.join(' ') if components.kind_of?(Array)
  distribution = params[:distribution] || node[:lsb][:codename]
  description = params[:description] || params[:name].capitalize

  if params[:key_id]
    key_id = params[:key_id]
    key_url = params[:key_url]
    keyserver = params[:keyserver]
    key_installed = "apt-key list | grep #{key_id}"
    if key_url
      execute "apt-key adv --fetch #{key_url}" do
        not_if key_installed
        ignore_failure true
      end
    elsif keyserver
      execute "apt-key adv --keyserver #{keyserver} --recv-keys #{key_id}" do
        not_if key_installed
        ignore_failure true
      end
    end
  end

  execute "apt-update" do
    command "apt-get clean && apt-get update && sleep 80"
    action :nothing
    ignore_failure true
  end

  directory "/etc/apt/sources.list.d"

  src_entry = "#{params[:url]} #{distribution} #{components} ##{description}"
  file_content = "deb     #{src_entry}\n"

  # only add deb-src entries if source_packages parameter was specified
  file_content << "deb-src #{src_entry}\n" if params[:source_packages]

  file "/etc/apt/sources.list.d/#{params[:name]}.list" do
    content file_content
    mode "0644"
    notifies :run, 'execute[apt-update]', :immediately
  end

  if params[:key_package]
    package params[:key_package] do
      options "--allow-unauthenticated" unless key_installed
      ignore_failure true
    end
  end
end
    #notifies :run, resources(:execute => "apt-get update"), :immediately
