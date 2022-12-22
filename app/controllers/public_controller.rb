# frozen_string_literal: true

class PublicController < ApplicationController
  def index
    render html: '<h1>Hello there! This is so awesome!!! I deployed on 12/22/2022 @ 4:37PM</h1>'
  end
end