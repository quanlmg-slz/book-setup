/***
 * Excerpted from "Ruby on Rails Background Jobs with Sidekiq",
 * published by The Pragmatic Bookshelf.
 * Copyrights apply to this code. It may not be used to create training material,
 * courses, books, articles, and the like. Contact us if you are in doubt.
 * We make no guarantees that this code is fit for any purpose.
 * Visit https://pragprog.com/titles/dcsidekiq for more book information.
***/
module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme: {
    fontFamily: {
      "sans": [ "Avenir", "Helvetica", "sans-serif" ],
      "serif": [ "Baskerville", "serif" ],
      "mono": [ "Consolas", "Courier", "monospace" ],
    }
  },
}
