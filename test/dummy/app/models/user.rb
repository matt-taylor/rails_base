# This class re-opens the upstream engine User Class

class User
  def boot
    require "pry"
    binding.pry
  end
end
