require 'spec_helper'
require 'json'
require 'pry'

RSpec.describe PostalTransfersPl do
  it 'has a version number' do
    expect(PostalTransfersPl::VERSION).not_to be nil
  end


  describe PostalTransfersPl::Client do
    let(:client) { PostalTransfersPl::Client }
    let(:error) { [Savon::SOAPFault.new('1', '2', '3'), Savon::HTTPError.new('1')].sample }
    let(:initializer) do
      PostalTransfersPl::Client.configure do |c|
        c.wsdl = ENV['PTP_WSDL'] || 'wsdl'
        c.namespace = ENV['PTP_NAMESPACE'] || 'v1'
        c.namespace_uri = ENV['PTP_NAMESPACE_URI'] || 'some_uri'
        c.user = ENV['PTP_USER']|| 'user'
        c.password = ENV['PTP_PASSWORD']|| 'password'
        c.track = ENV['PTP_TRACK']|| 'track_method'
        c.create = ENV['PTP_CREATE'] || 'create_method'
        c.delete = ENV['PTP_DELETE'] || 'delete_method'
        c.confirm = ENV['PTP_CONFIRM'] || 'confirm_method'
        c.payment_tracking_trigger = ENV['PTP_PAYMENT_TRACKING_TRIGGER'] || 'trigger_method'
        c.payment_tracking = ENV['PTP_PAYMENT_TRACKING'] || 'payment_tracking_method'
        c.list_documents = ENV['PTP_LIST_DOCUMENTS'] || 'list_documents_method'
        c.read_document = ENV['PTP_READ_DOCUMENT'] || 'read_document_method'
        c.ssl_version = ENV['PTP_SSL_VERSION'] || 'TLSv1'
        c.file_name_regexp = ENV['PTP_FILE_NAME_REGEXP'] || '\d{6}_\d{6}_\D{4,}'
      end
    end

    describe '#self.track_mass_order' do
      let(:track_mock_success) do
        file = File.join('spec', 'responses', 'track_success.json')
        JSON.parse(File.read(file))
      end

      context 'success' do
        before do
          allow(client).to receive(:track_mass_order).and_return(track_mock_success)
        end

        it 'returns api response for mass order' do
          expect(client.track_mass_order(id: 'B123456789123456789012')).to eq track_mock_success
        end
      end

      context 'failure' do
        it 'raises a runtime error' do
          expect { client.track_mass_order(id: nil) }.to raise_error(RuntimeError)
        end

        it 'raises a argument missing error' do
          expect { client.track_mass_order }.to raise_error(ArgumentError)
        end

        it 'raises a savon or http error' do
          allow(client).to receive(:track_mass_order).and_raise(error)
          expect { client.track_mass_order(id: 'blablabla') }.to raise_error(error)
        end
      end
    end

    describe '#self.create_mass_order' do
      let(:create_success) do
        file = File.join('spec', 'responses', 'create_success.json')
        JSON.parse(File.read(file))
      end

      let(:bad_file_path) do
        File.join('spec', 'responses', 'sample_csv', '181231_123055_useraaa.csv')
      end

      let(:good_file_path) do
        File.join('spec', 'responses', 'sample_csv', '181129_235227_kwiatek.csv')
      end

      let(:bad_file_response) { { error: "\r\n            Raport Kontroli Formalnej\r\n\r\nNazwa pliku:           181231_123055_useraaa.csv   \r\nGrupa kontrahent\xF3w:    R\xF3\xBFne     \r\nKontrahent:            XXXXXXX Sp.z o.o.                 Numer: 0000001757\r\nWynik kontroli:        Plik niepoprawny\r\n-------------------------------------------------------------------------------\r\nStwierdzone b\xB3\xEAdy:\r\n\r\nOpis nag\xB3\xF3wka w linii 1:\r\n    > Dla kolumny o nr 2/B jej opis powinien by\xE6 r\xF3wny Us\xB3uga\r\n\r\nData wygenerowania dokumentu 29-11-2018.\r\nDokument zosta\xB3 wygenerowany elektronicznie i nie wymaga podpisu ani stempla." } }

      context 'success' do
        before do
          allow(client).to receive(:create_mass_order).and_return(create_success)
        end

        it 'based on csv (windows-1250) converted to base64 creates a mass order via the api' do
          expect(client.create_mass_order(service_name: 'PPE', file_path: good_file_path, auto_approve: false)).to eq create_success
        end
      end

      context 'failure' do
        it 'returns a generated response error report hash' do
          allow(client).to receive(:create_mass_order).with(service_name: 'PPE', file_path: bad_file_path, auto_approve: false).and_return(bad_file_response)
          expect(client.create_mass_order(service_name: 'PPE', file_path: bad_file_path, auto_approve: false)).to eq bad_file_response
        end

        it 'raises a missing argument error' do
          expect { client.create_mass_order }.to raise_error(ArgumentError)
        end

        it 'raises a savon or http error' do
          allow(client).to receive(:create_mass_order).and_raise(error)
          expect { client.create_mass_order(service_name: 'PPE', file_path: nil, auto_approve: false) }.to raise_error(error)
        end
      end
    end

    describe '#self.payment_tracking' do
      let(:payment_tracking) do
        file = File.join('spec', 'responses', 'payment_tracking.json')
        JSON.parse(File.read(file))
      end

      let(:too_fresh_payment_tracking) do
        file = File.join('spec', 'responses', 'too_fresh_payment_tracking.json')
        JSON.parse(File.read(file))
      end

      context 'success' do
        before do
          allow(client).to receive(:payment_tracking).and_return(payment_tracking)
        end

        it 'returns a api tracking information - ONLY if has bee triggered by automated actions in #self.create_mass_order' do
          expect(client.payment_tracking(id: 'B1234567890123456789012')).to eq payment_tracking
        end
      end

      context 'failure' do
        it 'triggers a check but it was not fully processed by the external api - the order is not created yet' do
          allow(client).to receive(:payment_tracking).and_return(too_fresh_payment_tracking)
          expect(client.payment_tracking(id: 'B1234567890123456789012')).to eq too_fresh_payment_tracking
        end

        it 'raises a missing argument error' do
          expect { client.payment_tracking }.to raise_error(ArgumentError)
        end

        it 'raises a savon or http error' do
          allow(client).to receive(:payment_tracking).and_raise(error)
          expect { client.payment_tracking(id: 'some bad id') }.to raise_error(error)
        end
      end
    end
  end
end
