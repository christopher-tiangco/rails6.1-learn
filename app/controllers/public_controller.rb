# frozen_string_literal: true

class PublicController < ApplicationController
  def index
    render html: '<h1>Hello there! This is so awesome!!! I deployed on 01/15/2023 @ 1:42AM</h1>'
  end
end