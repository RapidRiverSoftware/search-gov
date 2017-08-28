def login(user)
  activate_authlogic
  UserSession.create(user)
end

def read_fixture_file(path)
  File.read("#{Rails.root}/spec/fixtures#{path}")
end
