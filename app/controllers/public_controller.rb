# frozen_string_literal: true

class PublicController < ApplicationController
  def index
    render html: '<h1>Hello there! This is so awesome!!! I deployed on 01/08/2023 @ 10:13PM</h1>'
  end
end