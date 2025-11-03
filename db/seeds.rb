User.destroy_all
Recipe.destroy_all

admin = User.create!(
  email: "iwiechert@miuandes.cl",
  password: "Password",
  role: :admin
)

user1 = User.create!(
  email: "oliviasalinas@gmail.com",
  password: "Password",
  role: :regular
)

user2 = User.create!(
  email: "chef.juan@example.com",
  password: "Password",
  role: :regular
)

user3 = User.create!(
  email: "foodie.maria@example.com",
  password: "Password",
  role: :regular
)


recipe1 = Recipe.create!(
  title: "Avocado Toast",
  cook_time: 10,
  difficulty: "Easy",
  instructions: <<~INSTR,
    1. Toast slices of sourdough bread until golden.<br>
    2. Mash ripe avocados with lemon juice, salt, and pepper.<br>
    3. Spread the mixture over the toast.<br>
    4. Top with cherry tomatoes, chili flakes, or poached eggs if desired.
  INSTR
  user: user2
)

recipe2 = Recipe.create!(
  title: "Spaghetti Carbonara",
  cook_time: 20,
  difficulty: "Medium",
  instructions: <<~INSTR,
    1. Cook spaghetti in salted water until al dente.<br>
    2. In a bowl, whisk eggs and grated Parmesan cheese.<br>
    3. Fry pancetta until crispy, then mix with drained pasta.<br>
    4. Remove from heat and quickly stir in the egg mixture.<br>
    5. Serve immediately with extra cheese and black pepper.
  INSTR
  user: user3
)

recipe3 = Recipe.create!(
  title: "Greek Salad",
  cook_time: 15,
  difficulty: "Easy",
  instructions: <<~INSTR,
    1. Chop cucumbers, tomatoes, red onion, and bell peppers.<br>
    2. Add Kalamata olives and feta cheese cubes.<br>
    3. Drizzle with olive oil, lemon juice, and oregano.<br>
    4. Toss gently and serve chilled.
  INSTR
  user: admin
)

recipe4 = Recipe.create!(
  title: "Chocolate Lava Cake",
  cook_time: 25,
  difficulty: "Medium",
  instructions: <<~INSTR,
    1. Preheat oven to 220°C (425°F).<br>
    2. Melt chocolate and butter together.<br>
    3. Whisk eggs, yolks, sugar, and flour, then combine with chocolate mixture.<br>
    4. Pour into greased ramekins and bake for 12 minutes.<br>
    5. Serve warm with vanilla ice cream.
  INSTR
  user: user3
)

recipe5 = Recipe.create!(
  title: "Grilled Chicken Tacos",
  cook_time: 25,
  difficulty: "Easy",
  instructions: <<~INSTR,
    1. Marinate chicken in lime juice, garlic, cumin, and paprika for 30 minutes.<br>
    2. Grill chicken until cooked through, then slice thinly.<br>
    3. Serve in corn tortillas with avocado, salsa, and cilantro.<br>
    4. Squeeze fresh lime on top before serving.
  INSTR
  user: user1
)

