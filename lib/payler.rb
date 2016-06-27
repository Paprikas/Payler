require "payler/version"

module Payler
  class << self

    # Starts payler session and returns hash
    # required: order_id, amount
    # optional: type, product, currency, recurrent, total, template, lang, userdata, pay_page_param_*
    # defaults: type=OneStep, currency=RUB, recurrent=true
    #
    # = Success request
    #  Payler.start_session({order_id: '123', amount: '100'})
    #  =>
    #    {:amount=>100,
    #     :session_id=>"v5aqGue1Hpw9TzGBBSkBRf02KDSv3Sfd7jhN",
    #     :order_id=>"123"}
    #
    # = Error
    #   Payler.start_session({order_id: '123'})
    #   =>
    #     {:error=>{:code=>20, :message=>"Некорректное значение параметра: amount"}}
    def start_session(params)
      params.reverse_merge!(session_params)
      send_request('StartSession', params)
    end

    # Creates recurrent payment
    # card template object with fields: recurrent_template_id
    # required: order_id, amount, recurrent_remplate_id
    def repeat_pay(params, card_template)
      params.reverse_merge!(recurrent_params(card_template))
      send_request('RepeatPay', params)
    end

    # Returns status of order
    # required: order_id
    def get_status(order_id)
      send_request('GetStatus', order_id: order_id)
    end

    # Returns advanced status of order
    # required: order_id
    def get_advanced_status(order_id)
      send_request('GetAdvancedStatus', order_id: order_id)
    end

    # Returns additional info about recurrent template
    # required: recurrent_template_id
    def get_template(recurrent_template_id)
      send_request('GetTemplate', recurrent_template_id: recurrent_template_id)
    end

    # Refund payment
    # required: order_id, amount
    def refund(params)
      params.reverse_merge!(password_params)
      send_request('Refund', params)
    end

    # списание средств, заблокированных на карте покупателя в рамках
    # двухстадийного платежа (в запросе StartSession параметр type должен иметь
    # значение «TwoStep​
    # required: order_id, amount
    def charge(params)
      params.reverse_merge!(password_params)
    end

    # отмена блокировки средств (частичная или полная)
    # required: order_id, amount
    def retrieve(params)
      params.reverse_merge!(password_params)
      send_request('Retrieve', params)
    end

    # Запрос активации/деактивации шаблона рекуррентных платежей
    # required: recurrent_template_id, active:boolean
    def activate_template(params)
      send_request('ActivateTemplate', params)
    end

    # Поиск платёжной сессии по идентификатору платежа (order_id). Это метод может быть полезен в некоторых случаях
    # required: order_id
    #
    # = Пример ответа на успешный запрос:
    # {
    # "id": "VLaFQpI88NpCncTA1TkhlX6HtkhzwQAKhxvz",
    # "created": "2015-10-26 17:11:30",
    # "valid_through": "2015-10-26 17:11:30",
    # "type": "OneStep",
    # "order_id": "ad7ad8b4-d50e-4b68-72f4-ca1264a8fae4",
    # "amount": 30000,
    # "product": "el-ticket",
    # "currency": "RUB",
    # "pay_page_params": "{"key": "value"}",
    # "userdata": "data",
    # "lang": "RU",
    # "recurrent": "true"
    # }
    def find_session(order_id)
      send_request('FindSession', order_id: order_id)
    end

    # Performs request to payler
    # Returns response hash
    def send_request(api_method, params)
      params.reverse_merge!(default_params)
      uri = URI.parse(server_url + api_method)

      req = Net::HTTP::Post.new(uri.path)
      req.set_form_data(params)

      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = uri.scheme == "https"

      response = https.start { |http| http.request(req) }
      response_hash = JSON.parse(response.body, symbolize_names: true)
      response_hash[:success] = true if response.kind_of? Net::HTTPSuccess
      response_hash
    end

    def server_url
      PAYLER['server_url']
    end

    def default_params
      { key: PAYLER['key'] }
    end

    def password_params
      { password: PAYLER['password'] }
    end

    def recurrent_params(card_template)
      recurrent_remplate_id = card_template.is_a?(String) ? card_template : card_template.recurrent_remplate_id
      { recurrent_remplate_id: recurrent_remplate_id }
    end

    def session_params
      {
          currency: 'RUB',
          recurrent: true,
          type: 'OneStep'
      }
    end
  end
end

