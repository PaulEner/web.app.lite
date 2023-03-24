# -*- encoding : UTF-8 -*-
class WelcomeMailer < BaseMailer
  def welcome_customer(user, token)
    @user   = user
    @token = token

    if @user.organization&.code == "ALM"
      mail(to: @user.email, subject: '[Axelium] Création de compte Axelium')
    elsif @user.organization&.code == "DK"
      mail(to: @user.email, subject: '[DK Partners] Création de compte DK Partners')
    elsif @user.organization&.code == "CEN"
      mail(to: @user.email, subject: '[Censial Online] Création de compte Censial Online')
    elsif @user.organization&.code == "OR"
      mail(to: @user.email, subject: '[My Orial] Création de compte My Orial')
    else
      mail(to: @user.email, subject: '[iDocus] Création de compte iDocus')
    end
  end

  def welcome_collaborator(collaborator, token)
    @token = token
    @collaborator = collaborator

    if "ALM".in?(@collaborator.organizations.pluck(:code))
      mail(to: @collaborator.email, subject: '[Axelium] Création de compte Axelium')
    elsif "DK".in?(@collaborator.organizations.pluck(:code))
      mail(to: @user.email, subject: '[DK Partners] Création de compte DK Partners')
    elsif "CEN".in?(@collaborator.organizations.pluck(:code))
      mail(to: @user.email, subject: '[Censial Online] Création de compte Censial Online')
    elsif "OR".in?(@collaborator.organizations.pluck(:code))
      mail(to: @user.email, subject: '[My Orial] Création de compte My Orial')
    else
      mail(to: @collaborator.email, subject: '[iDocus] Création de compte iDocus')
    end
  end

  def welcome_guest_collaborator(guest, token)
    @token = token
    @guest = guest

    if @guest.organization&.code == "ALM"
      mail(to: @guest.email, subject: '[Axelium] Création de compte Axelium')
    elsif @guest.organization&.code == "DK"
      mail(to: @guest.email, subject: '[DK Partners] Création de compte DK Partners')
    elsif @guest.organization&.code == "CEN"
      mail(to: @guest.email, subject: '[Censial Online] Création de compte Censial Online')
    elsif @guest.organization&.code == "OR"
      mail(to: @guest.email, subject: '[My Orial] Création de compte My Orial')
    else
      mail(to: @guest.email, subject: '[iDocus] Création de compte iDocus')
    end
  end
end
