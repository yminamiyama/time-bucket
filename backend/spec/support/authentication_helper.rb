module AuthenticationHelper
  def auth_headers(session)
    # ActionDispatch::Cookiesを使って正しく署名されたCookieを生成
    jar = ActionDispatch::Cookies::CookieJar.build(
      ActionDispatch::TestRequest.create,
      {}
    )
    jar.signed[:session_token] = session.token
    
    # 生成されたCookieヘッダーを取得
    cookie_header = jar.instance_variable_get(:@set_cookies)
      .transform_values { |v| v[:value] }
      .map { |k, v| "#{k}=#{v}" }
      .join('; ')
    
    { 'Cookie' => cookie_header }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelper, type: :request
end
