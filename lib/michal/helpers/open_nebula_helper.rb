# OpenNebula helper class
#
class Michal::Helpers::OpenNebulaHelper
  class << self
    EXPIRATION = 12*60*60

    # Generates OpenNebula authentication token from certificates
    #
    # @param [String] opennebula source name
    # @return [String] authentication token
    def generate_token(opennebula)
      cert_path = Settings[:sources][opennebula][:certificate]
      key_path = Settings[:sources][opennebula][:key]

      certs_str = [File.open(cert_path).read]
      key_str = File.open(key_path).read

      cert_chain = certs_str.map { |cert_pem| OpenSSL::X509::Certificate.new(cert_pem) }
      key_pem = OpenSSL::PKey::RSA.new(key_str)

      expires = Time.now.to_i + EXPIRATION
      text_to_sign = "#{Settings[:sources][opennebula][:username]}:#{expires}"
      signed_text  = Base64::encode64(key_pem.private_encrypt(text_to_sign)).delete("\n").strip

      certs_pem = cert_chain.map { |cert| cert.to_pem }.join(":")
      token = Base64::encode64("#{signed_text}:#{certs_pem}").strip.delete("\n")

      login_client = OpenNebula::Client.new("#{Settings[:sources][opennebula][:username]}:#{token}", Settings[:sources][opennebula][:endpoint], :sync => true)
      user = OpenNebula::User.new(OpenNebula::User.build_xml, login_client)
      user.login(Settings[:sources][opennebula][:username], "", EXPIRATION)
    end

    # Turns OpenNebula error codes into exceptions
    #
    def handle_opennebula_error
      fail Michal::Errors::DataLoaders::OpenNebula::StubError, 'OpenNebula service-wrapper was called without a block!' unless block_given?

      return_value = yield
      return return_value unless OpenNebula.is_error?(return_value)

      case return_value.errno
      when OpenNebula::Error::EAUTHENTICATION
        fail Michal::Errors::DataLoaders::OpenNebula::AuthenticationError, return_value.message
      when OpenNebula::Error::EAUTHORIZATION
        fail Michal::Errors::DataLoaders::OpenNebula::UserNotAuthorizedError, return_value.message
      when OpenNebula::Error::ENO_EXISTS
        fail Michal::Errors::DataLoaders::OpenNebula::ResourceNotFoundError, return_value.message
      when OpenNebula::Error::EACTION
        fail Michal::Errors::DataLoaders::OpenNebula::ResourceStateError, return_value.message
      else
        fail Michal::Errors::DataLoaders::OpenNebula::ResourceRetrievalError, return_value.message
      end
    end
  end
end
