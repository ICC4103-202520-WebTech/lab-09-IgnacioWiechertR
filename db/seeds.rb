User.destroy_all
Recipe.destroy_all

admin = User.create!(
  email: "sjjara@miuandes.cl",
  password: "password",
  role: :admin
)

regular_user = User.create!(
  email: "sofiajara2677@gmail.com",
  password: "password",
  role: :regular
)

recipe1 = Recipe.create!(
  title: "Tiramisu",
  cook_time: 30,
  difficulty: "Medium",
  instructions: <<~INSTR,
    1. Brew strong coffee and let it cool.<br>
    2. In a bowl, whisk egg yolks with sugar until pale and creamy.<br>
    3. Add mascarpone cheese and mix until smooth.<br>
    4. Dip ladyfingers briefly in the coffee and layer them in a dish.<br>
    5. Spread half of the mascarpone mixture, then repeat with another layer.<br>
    6. Dust with cocoa powder and refrigerate for at least 4 hours before serving.
  INSTR
  user: admin
)

recipe2 = Recipe.create!(
  title: "Japanese Ramen",
  cook_time: 45,
  difficulty: "Hard",
  instructions: <<~INSTR,
    1. In a large pot, simmer chicken broth with soy sauce, miso paste, and garlic.<br>
    2. Cook ramen noodles separately until just tender.<br>
    3. Add sliced pork, boiled egg halves, and green onions to the broth.<br>
    4. Divide noodles into bowls and pour hot broth on top.<br>
    5. Garnish with nori sheets and sesame seeds before serving.
  INSTR
  user: regular_user
)
