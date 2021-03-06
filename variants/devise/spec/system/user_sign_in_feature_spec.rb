require "rails_helper"

RSpec.describe "User sign-in", type: :system do
  describe "accessibility" do
    before { visit new_user_session_path }
    it_behaves_like "an accessible page"
  end

  let(:email) { "miles.obrien@transporterrm3.enterprise.uss" }
  let(:password) { "aabbccdd" }
  let(:user) { FactoryBot.create(:user, email: email, password: password) }

  before(:each) do
    user # create the user
    visit new_user_session_path
  end

  context "A user with valid account details" do
    it "can sign-in and sign-out successfully" do
      # when we fill in the sign-in form
      fill_in "Email", with: email
      fill_in "Password", with: password
      click_button "Log in"

      # we expect to be redirected to the home page with a helpful flash message
      expect(page.current_path).to eq(root_path)
      expect(page).to have_text("Signed in successfully")

      # we expect there to be exactly one cookie set and that cookie has a name
      # which ends in "_session"
      response_cookies = Capybara.current_session.driver.request.cookies
      expect(response_cookies.keys.length).to eq(1)
      expect(response_cookies.keys.first).to match(/_session\z/)

      # when we click on the sign out link
      click_link "Sign out"

      # we expect to still be on the home page with a flash message
      # telling us we have signed out.
      expect(page.current_path).to eq(root_path)
      expect(page).to have_text("Signed out successfully")
    end

    context "when user ticks the 'remember me' box on the sign-in page" do
      it "user gets a new cookie which allows their login to persist for two weeks" do
        # when we fill in the sign-in form **and** check the "Remember me" box
        fill_in "Email", with: email
        fill_in "Password", with: password
        check "Remember me"
        click_button "Log in"

        # we expect to be redirected to the home page with a helpful flash message
        expect(page.current_path).to eq(root_path)
        expect(page).to have_text("Signed in successfully")

        # we expect there to be exactly two cookies set and that one of them
        # has the name "remember_user_token"
        response_cookies = Capybara.current_session.driver.request.cookies
        expect(response_cookies.keys.length).to eq(2)
        expect(response_cookies["remember_user_token"]).to_not eq(nil)

        # We expect the "remember me" cookie to have a 14 day expiry
        remember_me_cookie_expiry_date = JSON
                                         .parse(Base64.decode64(response_cookies.fetch("remember_user_token")))
                                         .dig("_rails", "exp")
                                         .to_date
        expect(Integer(remember_me_cookie_expiry_date - Time.zone.today)).to eq(14)

        # when we click on the sign out link
        click_link "Sign out"

        # we expect the "remember_user_token" cookie to have been removed i.e.
        # there will be exactly one cookie now (the session cookie)
        response_cookies = Capybara.current_session.driver.request.cookies
        expect(response_cookies.keys.length).to eq(1)
        expect(response_cookies.keys.first).to match(/_session\z/)
      end
    end
  end

  context "A user with invalid account details" do
    context "when the user fails to login" do
      it "a helpful flash message is shown on the sign-in page" do
        # when we fill in the sign-in form with a bad password
        fill_in "Email", with: email
        fill_in "Password", with: "wrong password"
        click_button "Log in"

        # we expect to still be on the sign-in page with a helpful flash message
        # telling us something went wrong
        expect(page.current_path).to eq(new_user_session_path)
        expect(page).to have_text("Invalid Email or password")
      end
    end
  end
end
