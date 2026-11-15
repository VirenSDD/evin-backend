require "test_helper"

# specs/game-catalog/spec.md — Requirement: Public catalog listing
module Api
  module V1
    module GameCatalog
      class PublicCatalogListingTest < ActionDispatch::IntegrationTest
        test "Public catalog listing: Without a token" do
          get "/api/v1/juegos"

          assert_response :ok
          assert_equal [ "Cierre visual", "Encuentra las diferencias", "Encuentra las parejas",
                         "Exploraciones", "Puzzle", "Recuerda las casillas" ],
                       json.map { |juego| juego["nombre"] }
        end

        test "Public catalog listing: Fields of each game" do
          get "/api/v1/juegos"

          assert_response :ok
          assert_not_empty json
          json.each do |juego|
            assert_empty %w[id nombre descripcion img nivel tipo] - juego.keys, "fields of #{juego['nombre']}"
          end
        end
      end
    end
  end
end
