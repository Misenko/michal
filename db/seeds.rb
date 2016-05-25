# creates default user roles
roles = %w{admin owner user}
roles.each { |role| Role.where(name: role.to_sym).first_or_create! }

# creates default authn types
TokenType.where(:name => "krb5").first_or_create!(:description => "Kerberos 5 principal")
x509 = TokenType.where(:name => "x509").first_or_create!(:description => "X.509 DN from user's certificate")

# creates static admin account
x509_token = Token.new
x509_token.body = "/DC=org/DC=terena/DC=tcs/C=CZ/O=Masaryk University/CN=Michal Kimle 373866"
x509_token.token_type = x509

admin = User.where(
:name => "admin"
).first_or_create!(
:external_id => 373866,
:email => "xkimle@mail.muni.cz",
:description => "Static admin account",
:tokens => [x509_token]
)

admin.add_role :admin
