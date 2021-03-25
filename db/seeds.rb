
params = {
  email: "some.guy@gmail.com",
  first_name: 'Some',
  last_name: 'Guy',
  phone_number: '6508675309',
  password: "password1",
  password_confirmation: "password1"
}

User.create!(params)


params = {
  email: "some.guy2@gmail.com",
  first_name: 'Some2',
  last_name: 'Guy2',
  phone_number: '4158675309',
  password: "password2",
  password_confirmation: "password2"
}

User.create!(params)
