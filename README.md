# PostalTransfersPl

This gem was made for the purpose of sending a mass postal order, using a properly generated csv file
windows-1250 encoded in/out, string windows-1250 or utf-8 with a bom.  
Sample files provided in spec directory, good and bad (partially utf / windows encoded)
Sample responses for main methods also provided with tests.
It wraps most of the available soap api methods regarding PPE services. (https://www.pzw.poczta-polska.pl/mkpwww/Uslugi/ObslugaPakietow.wsdl)
All methods to run a successful csv bulk postal order creation and payment monitoring afterwards.
Also it contains a 'automated' method triggered after the creation of the order,
that if succeeds orders tracking of payment in the postal system for further monitoring,
if fails either raises errors (http or soap with messages) or reads generated error reports file on the api side.
Regardless all returned at the end (unless raised errors).
Every single method can be run separately with similar outcomes.    

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'postal_transfers_pl'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install postal_transfers_pl
    
When bundled, set up a initializer to provide CLIENT CREDENTIALS

Simply create a polish_post_pl.rb file in the initializers directory, and set it up like this:
    
```ruby
PostalTransfersPl::Client.configure do |c|
  c.wsdl = ENV['PTP_WSDL'] - 'the wsdl address'
  c.namespace = ENV['PTP_NAMESPACE'] - 'methods namespacing (string converted to symbol in gem)'
  c.namespace_uri = ENV['PTP_NAMESPACE_URI'] - 'the uri used in namespaces'
  c.user = ENV['PTP_USER'] - 'User/login same as in web)'
  c.password = ENV['PTP_PASSWORD'] - 'Password (same as in web)'
  c.track = ENV['PTP_TRACK'] - 'the SOAP method to track data You need (string converted to symbol in gem)'
  c.create = ENV['PTP_CREATE'] - 'the SOAP method to create mass order You need (string converted to symbol in gem)'
  c.delete = ENV['PTP_DELETE'] - 'the SOAP method to delete order (string converted to symbol in gem)'
  c.confirm = ENV['PTP_CONFIRM'] - 'the SOAP method to confirm order (string converted to symbol in gem)'
  c.payment_tracking_trigger = ENV['PTP_PAYMENT_TRACKING_TRIGGER'] - 'the SOAP method to trigger payment tracking for new order (string converted to symbol in gem)'
  c.payment_tracking = ENV['PTP_PAYMENT_TRACKING'] - 'the SOAP method to check payment tracking for order (string converted to symbol in gem)'
  c.list_documents = ENV['PTP_LIST_DOCUMENTS'] - 'the SOAP method to list all generated documents aside order (needed if failed to create) (string converted to symbol in gem)'
  c.read_document = ENV['PTP_READ_DOCUMENT'] - 'the SOAP method to read generated document regarding csv file errors for order (needed if failed to create) (string converted to symbol in gem)'
  c.ssl_version = ENV['PTP_SSL_VERSION'] - 'the version of TLS used by server You are connecting to'
end
```
If no initializer is provided exception will be raised. In this example I store all my credentialsin env variables.

## Usage

Set of examples for PostalTransfersPl::Client methods responses

```ruby
PostalTransfersPl::Client.track_mass_order(id: 'uip')
```
example success response :
```ruby
   {
      :uip=>"B123456789123456789012",
      :data_utworzenia=>"2000-12-31T00:00:00+00:00",
      :nazwa_pliku=>"001231_120001_client.csv",
      :numer_umowy=>"ID 123456/A",
      :procent_opustu=>"0.00",
      :stan=>"ZweryfikowanyOczekujacyNaZatwierdzenie",
      :usluga=>"PPE",
      :"@xmlns:i"=>"http://www.w3.org/2001/XMLSchema-instance"
   }
```

```ruby
PostalTransfersPl::Client.payment_tracking(id: 'uip')
``` 
example success response :
```ruby
  {
    :opis_stan_pakietu=>"Zarejestrowany",
    :stan=>"BrakWplaty",
    :"@xmlns:i"=>"http://www.w3.org/2001/XMLSchema-instance"
  }
``` 
example partialy failed response - the tracking was triggered too early ( order in creation in the api )
Easy to fix just rerun the method in a couple of minutes ;)
```ruby
{
  :stan=>"BrakPakietu",
  :"@xmlns:i"=>"http://www.w3.org/2001/XMLSchema-instance"
}
``` 

```ruby
PostalTransfersPl::Client.create_mass_order(service_name: 'PPE', file_path: 'path to file / or url', auto_approve: false)
``` 
example success response :
```ruby
{
  :uip=>"B1234567890123456789012",
  :data_graniczna_wplaty=>"2000-12-31T00:00:00+00:00",
  :data_utworzenia=>"2000-12-28T00:00:00+00:00",
  :liczba_przekazow_poprawnych=>"1",
  :nazwa_pliku=>"001228_155346_user.csv",
  :numer_rachunku_bankowego_wplaty=>"66 1234 5678 9101 1001 0000 1111",
  :numer_umowy=>"ID 123456/A",
  :oplata_za_nadanie=>"5.47",
  :procent_opustu=>"0.00",
  :stan=>"Zamkniety",
  :usluga=>"PPE",
  :wartosc_przekazow_poprawnych=>"46.82",
  :"@xmlns:i"=>"http://www.w3.org/2001/XMLSchema-instance"
}
``` 
example fail response for creation - when file is bad, parsed from error report file from the api side
```ruby
 { 
   error: "\r\n            Raport Kontroli Formalnej\r\n\r\nNazwa pliku:           181231_123055_useraaa.csv   \r\nGrupa kontrahent\xF3w:    R\xF3\xBFne     \r\nKontrahent:            XXXXXXX Sp.z o.o.                 Numer: 0000001757\r\nWynik kontroli:        Plik niepoprawny\r\n-------------------------------------------------------------------------------\r\nStwierdzone b\xB3\xEAdy:\r\n\r\nOpis nag\xB3\xF3wka w linii 1:\r\n    > Dla kolumny o nr 2/B jej opis powinien by\xE6 r\xF3wny Us\xB3uga\r\n\r\nData wygenerowania dokumentu 29-11-2018.\r\nDokument zosta\xB3 wygenerowany elektronicznie i nie wymaga podpisu ani stempla." 
 }
``` 

example fail responses - most cases:

invalid id provided  or no id provided

```ruby
RuntimeError || ArgumentError
```
invalid file when creating or http errors

```ruby
Savon::SOAPFault || Savon::HTTPError
```

ALL other methods come with a simple hash response or raise one of the common errors. 

## Development

run rspec for tests. 

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/justcodeio/postal_transfers_pl.
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.
Feel free to fork and expand it to Your needs ! 

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
