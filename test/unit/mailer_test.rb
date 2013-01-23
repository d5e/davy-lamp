require 'test_helper'

class MailerTest < ActionMailer::TestCase
  test "alert" do
    @expected.subject = 'Mailer#alert'
    @expected.body    = read_fixture('alert')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Mailer.create_alert(@expected.date).encoded
  end

end
