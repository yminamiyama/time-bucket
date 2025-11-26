class SessionsController < ApplicationController
  # OAuth callback handler
  def create
    auth = request.env['omniauth.auth']
    
    # Validate OAuth data
    unless auth.present? && auth['provider'].present? && auth['uid'].present? && auth.dig('info', 'email').present?
      Rails.logger.error "Invalid OAuth data received: #{auth.inspect}"
      redirect_to ENV.fetch('FRONTEND_URL', 'http://localhost:3000'), alert: 'Authentication failed. Invalid data received.'
      return
    end
    
    user = User.find_or_create_by(provider: auth['provider'], uid: auth['uid']) do |u|
      u.email = auth['info']['email']
      u.birthdate = 20.years.ago.to_date  # Default value, user can update later
      u.timezone = 'UTC'  # Default timezone
    end

    if user.persisted?
      # Create new session
      session = user.sessions.create(
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )
      
      if session.persisted?
        # Store session token in cookie
        cookies.signed[:session_token] = {
          value: session.token,
          httponly: true,
          secure: Rails.env.production?,
          same_site: :lax
        }
        
        redirect_to ENV.fetch('FRONTEND_URL', 'http://localhost:3000'), notice: 'Signed in successfully.'
      else
        Rails.logger.error "Failed to create session for user #{user.id}: #{session.errors.full_messages.join(', ')}"
        redirect_to ENV.fetch('FRONTEND_URL', 'http://localhost:3000'), alert: 'Authentication failed. Please try again.'
      end
    else
      Rails.logger.error "Failed to create user from OAuth: #{user.errors.full_messages.join(', ')}"
      redirect_to ENV.fetch('FRONTEND_URL', 'http://localhost:3000'), alert: 'Authentication failed.'
    end
  end

  def destroy
    if session_token = cookies.signed[:session_token]
      Session.find_by(token: session_token)&.destroy
    end
    
    cookies.delete(:session_token)
    redirect_to ENV.fetch('FRONTEND_URL', 'http://localhost:3000'), notice: 'Signed out successfully.'
  end
  
  # OAuth failure handler
  def failure
    redirect_to ENV.fetch('FRONTEND_URL', 'http://localhost:3000'), alert: 'Authentication failed. Please try again.'
  end
end
