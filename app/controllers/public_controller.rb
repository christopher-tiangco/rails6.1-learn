# frozen_string_literal: true

class PublicController < ApplicationController
  def index
    render html: '<h1>Hello there! This is so awesome!!! I deployed on 01/22/2023 @ 2:01PM</h1>'
  end
end