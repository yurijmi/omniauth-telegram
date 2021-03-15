RSpec.describe Omniauth::Telegram do
  def make_env(path = '/auth/test', props = {})
    {
      'REQUEST_METHOD' => 'POST',
      'PATH_INFO' => path,
      'rack.session' => {},
      'rack.input' => StringIO.new('test=true')
    }.merge(props)
  end

  before do
  end

  it 'fails with field_missing' do
    env = make_env('/auth/telegram/callback')
    app = lambda { |_env| [200, env, ['Telegram']] }
    strategy = OmniAuth::Strategies::Telegram.new(app)
    response = strategy.call!(env)

    expect(response).to eq([302, {"Location"=>"/auth/failure?message=field_missing&strategy=telegram"}, ["302 Moved"]])
  end

  it 'fails with session_expired' do
    params = {
      'id' => '123',
    }
    hash = OmniAuth::Strategies::Telegram.calculate_signature('some-secret', params)
    env = make_env('/auth/telegram/callback', 'rack.input' => StringIO.new(params.merge('hash' => hash).map {|k, v| "#{k}=#{v}" }.join('&')))
    app = lambda { |_env| [200, env, ['Telegram']] }
    strategy = OmniAuth::Strategies::Telegram.new(app)
    strategy.options.bot_secret = 'some-secret'
    strategy.options.bot_name = 'some-name'
    response = strategy.call!(env)

    expect(response).to eq([302, {"Location"=>"/auth/failure?message=session_expired&strategy=telegram"}, ["302 Moved"]])
  end

  it 'works' do
    params = {
      'id' => '123',
      'auth_date' => Time.now.to_i,
    }
    hash = OmniAuth::Strategies::Telegram.calculate_signature('some-secret', params)
    env = make_env('/auth/telegram/callback', 'rack.input' => StringIO.new(params.merge('hash' => hash).map {|k, v| "#{k}=#{v}" }.join('&')))
    app = lambda { |_env| [200, env, ['Telegram']] }
    strategy = OmniAuth::Strategies::Telegram.new(app)
    strategy.options.bot_secret = 'some-secret'
    strategy.options.bot_name = 'some-name'
    response = strategy.call!(env)

    expect(response.first).to eq(200)
  end
end
