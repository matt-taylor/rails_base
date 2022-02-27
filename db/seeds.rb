
params = {
  email: "mattius.taylor@gmail.com",
  first_name: 'Some',
  last_name: 'Guy',
  phone_number: ENV.fetch("PHONE_NUMBER", '6509410795'),
  password: "password1",
  password_confirmation: "password1",
  email_validated: true,
}

user = User.create!(params)
user.admin_owner!


params = {
  email: "#{ENV['GMAIL_USER_NAME']}@gmail.com",
  first_name: 'Some2',
  last_name: 'Guy2',
  phone_number: '6508675309',
  password: "password2",
  password_confirmation: "password2",
  email_validated: true,
}

User.create!(params)
