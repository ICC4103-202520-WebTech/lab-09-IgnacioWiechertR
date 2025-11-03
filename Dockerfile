# 1. Etapa "builder" - Prepara dependencias y assets
FROM ruby:3.2.2 AS builder

# Instala dependencias del sistema
RUN apt-get update -qq && \
    apt-get install -y build-essential libvips git

# Instala Node.js (para assets) y Yarn
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn

WORKDIR /rails

# Instala gemas
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copia el código
COPY . .

# CORRECCIÓN: Precompila los assets para producción
RUN bundle exec rails assets:precompile

# ----------------------------------------------------

# 2. Etapa "final" - La imagen que se despliega
FROM ruby:3.2.2 AS final

# Instala solo las dependencias necesarias para correr la app
RUN apt-get update -qq && \
    apt-get install -y curl libvips libpq-dev && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man

WORKDIR /rails

# Copia las gemas pre-instaladas
COPY --from=builder /usr/local/bundle/ /usr/local/bundle/

# Copia los assets pre-compilados
COPY --from=builder /rails/public/assets/ /rails/public/assets/

# Copia el código de la aplicación
COPY . .

# Expone el puerto y define el punto de entrada
EXPOSE 3000
ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["bin/rails", "server"]