require 'spec_helper'

describe User do

	before do
		@user = User.new(name: "Example User", email: "user@example.com", password: "foobar", password_confirmation: "foobar")
	end

	subject { @user }

	it { should respond_to(:name) }
	it { should respond_to(:email) }
	it { should respond_to(:password_digest) }
	it { should respond_to(:password) }
	it { should respond_to(:password_confirmation) }
	it { should respond_to(:remember_token) }
	it { should respond_to(:authenticate) }
	it { should respond_to(:admin) }

	it { should be_valid }
	it { should_not be_admin }

	describe "with admin attribute set to 'true'" do
		before do
			@user.save!
			@user.toggle!(:admin)
		end

		it { should be_admin }
	end

	describe "when name is not present" do
		before { @user.name = " " }
		it { should_not be_valid }
	end

	describe "when name is too long" do
		before { @user.name = "a" * 51 }
		it { should_not be_valid }
	end

	describe "when email is not present" do
		before { @user.email = " " }
		it { should_not be_valid }
	end

	describe "when email format is valid" do
		it "should be valid" do
			addresses = %w[user@foo.COM A_US-ER@f.b.org frst.lst@foo.jp a+b@baz.cn]
			addresses.each do |valid_address|
				@user.email = valid_address
				expect(@user).to be_valid
			end
		end
	end

	describe "when email address is already taken" do
		before do
			user_with_same_email = @user.dup
			user_with_same_email.email = @user.email.upcase
			user_with_same_email.save
		end

		it { should_not be_valid }
	end

	describe "email address with mixed case" do
		let(:mixed_case_email) { "Foo@ExAMPle.CoM" }

		it "should be saved as all lower-case" do
			@user.email = mixed_case_email
			@user.save
			expect(@user.reload.email).to eq mixed_case_email.downcase
		end
	end

	describe "with a password that's too short" do
		before { @user.password = @user.password_confirmation = "a" * 5 }
		it { should be_invalid }
	end

	describe "when password is not present" do
		before do
			@user = User.new(name: "Example User", email: "user@example.com",
				password: " ", password_confirmation: " ")
		end
		it { should_not be_valid }
	end

	describe "when password doesn't match confirmation" do
		before { @user.password_confirmation = "mismatch" }
		it { should_not be_valid }
	end

	describe "return value of authenticate method" do
		before { @user.save }
		let(:found_user) { User.find_by(email: @user.email) }

		describe "with valid password" do
			it { should eq found_user.authenticate(@user.password) }
		end

		describe "with invalid password" do
			let(:user_for_invalid_password) { found_user.authenticate("invalid") }

			it { should_not eq user_for_invalid_password }
			specify { expect(user_for_invalid_password).to be_false }
		end
	end

	describe "User pages" do

		subject { page }

		describe "index" do
			let(:user) { FactoryGirl.create(:user) }

			before do
				sign_in user
				visit users_path
			end

			it { should have_title('All users') }
			it { should have_content('All users') }

			describe "pagination" do

				before(:all) { 30.times { FactoryGirl.create(:user) } }
				after(:all)  { User.delete_all }

				it { should have_selector('div.pagination') }

				it "should list each user" do
					User.paginate(page: 1).each do |user|
						expect(page).to have_selector('li', text: user.name)
					end
				end
			end

			describe "delete links" do

				it { should_not have_link('delete') }

				describe "as an admin user" do
					let(:admin) { FactoryGirl.create(:admin) }
					before do
						sign_in admin
						visit users_path
					end

					it { should have_link('delete', href: user_path(User.first)) }
					it "should be able to delete another user" do
						expect do
							click_link('delete', match: :first)
						end.to change(User, :count).by(-1)
					end
					it { should_not have_link('delete', href: user_path(admin)) }
				end
			end

			it "should list each user" do
				User.all.each do |user|
					expect(page).to have_selector('li', text: user.name)
				end
			end
		end

		describe "profile page" do
			let(:user) { FactoryGirl.create(:user) }
			before { visit user_path(user) }

			it { should have_content(user.name) }
			it { should have_title(user.name) }
		end

		describe "signup page" do
			before { visit signup_path }

			it { should have_content('Sign up') }
			it { should have_title(full_title('Sign up')) }
		end

		describe "signup" do

			before { visit signup_path }

			let(:submit) { "Create my account" }

			describe "with invalid information" do
				it "should not create a user" do
					expect { click_button submit }.not_to change(User, :count)
				end

			end

			describe "with valid information" do
				before do
					fill_in "Name",         with: "Example User"
					fill_in "Email",        with: "user@example.com"
					fill_in "Password",     with: "foobar"
					fill_in "Confirmation", with: "foobar"
				end

				it "should create a user" do
					expect { click_button submit }.to change(User, :count).by(1)
				end

				describe "after saving the user" do
					before { click_button submit }
					let(:user) { User.find_by(email: 'user@example.com') }

					it { should have_link('Sign out') }
					it { should have_title(user.name) }
					it { should have_selector('div.alert.alert-success', text: 'Welcome') }
				end

			end
		end

		describe "edit" do
			let(:user) { FactoryGirl.create(:user) }
			before do
				sign_in user
				visit edit_user_path(user)
			end
			before { visit edit_user_path(user) }

			describe "page" do
				it { should have_content("Update your profile") }
				it { should have_title("Edit user") }
				it { should have_link('change', href: 'http://gravatar.com/emails') }
			end

			describe "with invalid information" do
				before { click_button "Save changes" }

				it { should have_content('error') }
			end

			describe "with valid information" do
				let(:new_name)  { "New Name" }
				let(:new_email) { "new@example.com" }
				before do
					fill_in "Name",             with: new_name
					fill_in "Email",            with: new_email
					fill_in "Password",         with: user.password
					fill_in "Confirm Password", with: user.password
					click_button("Save changes")
				end

				it { should have_title(new_name) }
				it { should have_selector('div.alert.alert-success') }
				it {
					should have_link('Sign out', href: signout_path) }
					specify { expect(user.reload.name).to  eq new_name }
					specify { expect(user.reload.email).to eq new_email }
				end
			end

		end

	end