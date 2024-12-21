# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :unsafe_inline, :unsafe_eval,
                       'https://cdnjs.cloudflare.com',
                       'https://cdn.jsdelivr.net',
                       'https://unpkg.com',
                       'https://ga.jspm.io'
    policy.style_src   :self, :unsafe_inline,
                       'https://cdnjs.cloudflare.com',
                       'https://unpkg.com'
    policy.connect_src :self, :https
  end

  # Comment out the nonce generator as it's causing issues with inline styles
  # config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  # config.content_security_policy_nonce_directives = %w(script-src style-src)

  # Report violations without enforcing the policy.
  # config.content_security_policy_report_only = true
end
