require 'postal_transfers_pl/version'
require 'savon'
require 'pry'

module PostalTransfersPl
  class Client
    attr_accessor :client

    class << self
      attr_accessor :configuration, :response, :error_report
    end

    def self.configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    class Configuration
      attr_accessor :wsdl, :namespace_uri, :namespace,
                    :list_documents, :read_document,
                    :payment_tracking_trigger, :payment_tracking,
                    :user, :password, :track, :create,
                    :delete, :confirm, :ssl_version

      def initialize
        @wsdl = nil
        @namespace = nil
        @namespace_uri = nil
        @user = nil
        @password = nil
        @track = nil
        @create = nil
        @delete = nil
        @confirm = nil
        @payment_tracking_trigger = nil
        @payment_tracking = nil
        @list_documents = nil
        @read_document = nil
        @ssl_version = nil
      end
    end

    def initialize
      raise 'No configuration credentials provided !' if PostalTransfersPl::Client.configuration.blank?
      @client = Savon.client(
        wsdl: PostalTransfersPl::Client.configuration.wsdl,
        ssl_version: PostalTransfersPl::Client.configuration.ssl_version.to_sym,
        log: true,
        pretty_print_xml: true,
        namespace_identifier: PostalTransfersPl::Client.configuration.namespace.to_sym,
        namespaces: {"xmlns:#{PostalTransfersPl::Client.configuration.namespace}" => PostalTransfersPl::Client.configuration.namespace_uri},
        wsse_auth: [PostalTransfersPl::Client.configuration.user, PostalTransfersPl::Client.configuration.password],
        headers: {'Content-Type' => 'text/xml;charset=utf-8;'}
      )
    end

    def self.track_mass_order(id:)
      self.new.client.call(
        PostalTransfersPl::Client.configuration.track.to_sym,
        message: { 'v1:UIP' => id }
      ).to_hash.fetch((PostalTransfersPl::Client.configuration.track.to_s + '_response').to_sym).fetch(:pakiet)
    end

    def self.payment_tracking(id:)
      self.trigger_payment_tracking(id: id)
      self.new.client.call(
        PostalTransfersPl::Client.configuration.payment_tracking.to_sym,
        message: { 'v1:UIP' => id }
      ).to_hash.fetch((PostalTransfersPl::Client.configuration.payment_tracking.to_s + '_response').to_sym).fetch(:stan_oplacenia_pakietu)
    end

    def self.create_mass_order(service_name:, file_path:, auto_approve: false)
      file_name = File.basename(URI.parse(file_path).path)
      base = Base64.encode64(open(file_path).read)
      resp = self.new.client.call(
        PostalTransfersPl::Client.configuration.create.to_sym,
        message: { 'v1:RodzajUslugi' => service_name, 'v1:NazwaPliku' => file_name, 'v1:ZawartoscPliku' => base, 'v1:ZatwierdzenieAutomatyczne' => auto_approve }
      ).to_hash.fetch((PostalTransfersPl::Client.configuration.create.to_s + '_response').to_sym)
      self.confirm_or_destroy_mass_order(id: resp.fetch(:uip))
    end

    def self.confirm_or_destroy_mass_order(id:)
      @response = self.track_mass_order(id: id)
      case response.fetch(:stan)
      when 'OdrzuconyZPowoduBleduWeryfikacji', 'NIEOBSLUGIWANY'
        self.destroy_mass_order(id: id)
      when 'UtworzonyCzekaNaWeryfikacjeMKP'
        sleep 5
        self.confirm_or_destroy_mass_order(id: id)
      when 'ZweryfikowanyOczekujacyNaZatwierdzenie'
        self.confirm_mass_order(id: id)
      else
        @error_report = 'File is invalid!'
      end
      error_report.blank? ? response : { error: error_report }
    end

    def self.destroy_mass_order(id:)
      doc = self.list_documents(id: id)[:opis_dokumentu]
      doc_id = doc[:identyfikator]
      @error_report = doc_id.blank? ? nil : Base64.decode64(self.read_document(id: doc_id))
      self.new.client.call(
        PostalTransfersPl::Client.configuration.delete.to_sym,
        message: { 'v1:UIP' => id }
      )
    end

    def self.confirm_mass_order(id:)
      self.new.client.call(
        PostalTransfersPl::Client.configuration.confirm.to_sym,
        message: { 'v1:UIP' => id }
      )
      @response = self.track_mass_order(id: id)
      self.trigger_payment_tracking(id: id)
    end

    def self.trigger_payment_tracking(id:)
      self.new.client.call(
        PostalTransfersPl::Client.configuration.payment_tracking_trigger.to_sym,
        message: { 'v1:UIP' => id }
      )
    end

    def self.list_documents(id:)
      self.new.client.call(
        PostalTransfersPl::Client.configuration.list_documents.to_sym,
        message: { 'v1:UIP' => id }
      ).to_hash.fetch((PostalTransfersPl::Client.configuration.list_documents.to_s + '_response').to_sym).fetch(:lista_dokumentow)
    end

    def self.read_document(id:)
      self.new.client.call(
        PostalTransfersPl::Client.configuration.read_document.to_sym,
        message: { 'v1:IdentyfikatorDokumentu' => id }
      ).to_hash.fetch((PostalTransfersPl::Client.configuration.read_document.to_s + '_response').to_sym).fetch(:zawartosc_dokumentu)
    end
  end
end
