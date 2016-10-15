# name: discourse-plugin-office365-auth
# about: Enable Login via Office365
# version: 0.0.1
# authors: Matthew Wilkin
# url: https://github.com/cpradio/discourse-plugin-office365-auth

require 'auth/oauth2_authenticator'

gem 'omniauth-microsoft-office365', '0.0.7'

enabled_site_setting :office365_enabled

class Office365Authenticator < ::Auth::OAuth2Authenticator
  PLUGIN_NAME = 'oauth-office365'

  def name
    'office365'
  end

  def after_authenticate(auth_token)
    result = super

    if result.user && result.email && (result.user.email != result.email)
      begin
        result.user.update_columns(email: result.email)
      rescue
        used_by = User.find_by(email: result.email).try(:username)
        Rails.loger.warn("FAILED to update email for #{user.username} to #{result.email} cause it is in use by #{used_by}")
      end
    end

    result
  end

  def register_middleware(omniauth)
    omniauth.provider :office365,
                      setup: lambda { |env|
                        strategy = env['omniauth.strategy']
                        strategy.options[:client_id] = SiteSetting.office365_client_id
                        strategy.options[:client_secret] = SiteSetting.office365_secret
                      }
  end
end

auth_provider :title => 'with Office365',
              enabled_setting: "office365_enabled",
              :message => 'Log in via Office365',
              :frame_width => 920,
              :frame_height => 800,
              :authenticator => Office365Authenticator.new('office365',
                                                          trusted: true,
                                                          auto_create_account: true)


register_css <<CSS

.btn-social.office365 {
  background: #EB3D01;
}

CSS