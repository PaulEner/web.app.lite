//= require './jose'

class BudgeaApi{
  constructor(){
    this.applicationJS = new ApplicationJS();
    //IMPORTANT : SET TO TRUE OR FALSE TO ACTIVATE / DEACTIVATE BUDGEA ENCRYPTION
      // ENCRYPTION DOESN T WORK ON LOCAL MACHINE
      this.activate_encryption = true && ( VARIABLES.get('rails_env') != 'development' );
      console.log("is encryption activated : " + this.activate_encryption);


    this.encryptor = null;
    this.user_profiles = {};
    this.local_host = location.protocol + "//" + location.host;
    this.request_source = '';

    this.init_api_configuration();

    this.listen_to_user_change();
  }

  init_api_configuration(){
    let ajax_params = {
                        url: '/retriever/api_config',
                        data: { q: 'conf' },
                        type: 'POST',
                        dataType: 'json'
                      };

    this.applicationJS.sendRequest(ajax_params)
                      .then(async (e)=>{
                        await this.get_user_tokens();

                        let config = JSON.parse(atob(e.id));

                        if (config === void 0 || config === '' || config === null) {
                          this.applicationJS.noticeErrorMessageFrom(null, 'Erreur lors du chargement de la congiguration de base');
                        } else {
                          this.api_base_url = config.url;
                          this.api_client_id = config.c_id;
                          this.api_client_secret = config.c_ps;
                          this.api_ky = {};
                          if (config.c_ky !== void 0 && config.c_ky !== '') {
                            this.api_ky = JSON.parse(atob(config.c_ky));
                            this.init_encryptor();
                          }
                        }

                        AppEmit('window.budgea_api_initialized');
                      });
  };

  listen_to_user_change(){
    let self = this;
    AppListenTo('budgeaApi.user_changed', (e)=>{
      let user_id = e.detail.user_id;
      self.get_user_tokens((user_id != 'all')? user_id : '');
    });
  }

  get_user_tokens(user_id='') {
    return new Promise(async(resolve, reject)=>{
      let ajax_params = {
                        url: '/retriever/account_infos',
                        data: { q: 'conf', user_id: user_id },
                        type: 'POST',
                        dataType: 'json'
                      };

      await this.applicationJS.sendRequest(ajax_params).then((e)=>{ this.set_tokens(e); resolve(); }).catch(e=>{ reject(e); });
    });
  };

  set_tokens(options) {
    this.user_token = options.user_token;
    this.bi_token = options.bi_token;
  };

  check_cgu() {
    var got_error, not_registered, self;
    self = this;
    got_error = function(error) {
      return alert(error);
    };
    not_registered = function() {
      return self.remote_fetch({
        url: "/terms",
        type: "GET",
        onError: function(error) {
          return got_error(error);
        },
        onSuccess: function(data) {
          var content;
          self.cgu_id = data.terms.id;
          self.cgu_version = data.terms.version;
          content = data.content.replace(/\n/g, "<br>");
          $('#terms').html("<p>" + content + "</p>");

          $('#cgu_bi_validate').on('click', function() {
            self.validate_cgu(self);
          });

          $('#cgu_bi_exit').on('click', function() {
            $('#showCguBI').modal('hide');
            $('.modal#add-retriever').modal('hide');
          });

          $('#showCguBI').modal('show');
        }
      });
    };
    if (this.bi_token.length === 0) {
      return not_registered();
    } else {
      return this.remote_fetch({
        url: "/users/me/terms",
        type: "GET",
        onError: function(error) {
          return got_error(error);
        },
        onSuccess: function(data) {
          if (data.to_sign === true) {
            return not_registered();
          } else {
            return self.init_or_create_user();
          }
        }
      });
    }
  };

  validate_cgu(self) {
    var callback;
    callback = function() {
      return self.remote_fetch({
        url: '/users/me/terms',
        type: 'POST',
        data: {
          id_terms: self.cgu_id
        },
        onError: function(error) {
          alert(error);
        },
        onSuccess: function(remote_data, local_data) {
          $('#showCguBI').modal('hide');
        }
      });
    };

    self.init_or_create_user().then(callback);
  };

  init_or_create_user() {
    var got_error, promise, self;
    self = this;
    got_error = function(error) {
      alert(error);
    };

    return promise = new Promise(function(resolve, reject) {
      if (self.bi_token.length === 0) {
        self.remote_fetch({
          url: '/auth/init',
          use_secrets: true,
          type: 'POST',
          onError: function(error) {
            got_error(error);
          },
          onSuccess: function(data) {
            self.bi_token = data.auth_token;
            if (data.type === 'permanent') {
              self.double_fetch({
                remote: {
                  url: "/users/me/profiles",
                  type: 'GET',
                  collection: 'profiles'
                },
                local: {
                  url: "/retriever/create_budgea_user",
                  data: {
                    auth_token: data.auth_token
                  }
                },
                onError: function(error) {
                  got_error(error);
                },
                onSuccess: function(remote_data, local_data) {
                  resolve();
                }
              });
            } else {
              got_error('Impossible de créer un compte budget insight');
            }
          }
        });
      } else {
        self.remote_fetch({
          url: '/users/me/profiles',
          type: 'GET',
          collection: 'profiles',
          onError: function(error) {
            resolve();
          },
          onSuccess: function(remote_data) {
            self.user_profiles = remote_data[0];
            resolve();
          }
        });
      }
    });
  };

  get_accounts_of(connector_id, full_result) {
    var my_accounts, promise, remote_accounts, remote_url, self;
    self = this;
    remote_accounts = [];
    my_accounts = [];
    full_result = full_result || false;
    if (parseInt(connector_id) > 0) {
      remote_url = "/users/me/connections/" + connector_id + "/accounts?all";
    } else {
      remote_url = "/users/me/accounts?all";
    }
    return promise = new Promise(function(resolve, reject) {
      return self.double_fetch({
        remote: {
          url: remote_url,
          type: 'GET',
          collection: 'accounts'
        },
        local: {
          url: '/retriever/my_accounts',
          data: {
            connector_id: connector_id,
            full_result: full_result
          }
        },
        onSuccess: function(remote_response, local_response) {
          /* Respond to remote response */
          remote_accounts = [];
          remote_response.forEach((account)=>{
            if(account['deleted'] == '' || account['deleted'] == null || account['deleted'] == undefined){
              remote_accounts.push(account);
            }
          });

          /* Respond to local response */
          my_accounts = local_response.accounts;
          return resolve({
            remote_accounts: remote_accounts,
            my_accounts: my_accounts
          });
        },
        onError: function(error) {
          if (parseInt(connector_id) > 0){
            return reject('Impossible de récupérer les comptes bancaires');
          }else{
            return resolve({ remote_accounts: [], my_accounts: [] });
          }
        }
      });
    });
  };

  update_my_accounts(accounts, options) {
    var promise, self;
    self = this;
    return promise = new Promise(function(resolve, reject) {
      var account, error, _i, _len;
      error = false;
      for (_i = 0, _len = accounts.length; _i < _len; _i++) {
        account = accounts[_i];
        if (!error) {
          self.remote_fetch({
            url: "/users/me/connections/" + account.id_connection + "/accounts/" + account.id + "?all",
            type: 'POST',
            data: {
              disabled: 0
            },
            collection: 'accounts',
            onError: function(data) {
              return error = true;
            }
          });
        }
      }

      if (!error) {
        return self.local_fetch({
          url: '/retriever/create_bank_accounts',
          data: {
            accounts: accounts,
            options: options || {}
          },
          onSuccess: function(data) {
            return resolve(data);
          },
          onError: function(error) {
            return reject(error);
          }
        });
      } else {
        return reject("Erreur lors de l'activation des comptes bancaires séléctionnés");
      }
    });
  };

  get_connectors() {
    var connectors_list, get_banks, get_providers, promise, self;
    self = this;
    connectors_list = [];
    get_banks = function(resolve, reject) {
      return self.remote_fetch({
        type: 'GET',
        url: "/banks?expand=fields",
        collection: 'banks',
        onSuccess: function(data) {
          console.log('banks size :');
          console.log(data.length);

          connectors_list = connectors_list.concat(data);
          return setTimeout(resolve, 2000);
        },
        onError: function(error) {
          return reject(error);
        }
      });
    };
    get_providers = function(resolve, reject) {
      return self.remote_fetch({
        type: 'GET',
        url: "/providers?expand=fields",
        collection: 'banks',
        onSuccess: function(data) {
          console.log('providers size :');
          console.log(data.length);

          connectors_list = connectors_list.concat(data);
          return setTimeout(resolve, 2000);
        },
        onError: function(error) {
          return reject(error);
        }
      });
    };

    return promise = new Promise(function(resolve, reject) {
      return get_banks(get_providers(function() {
        return resolve(connectors_list);
      }, reject), reject);
    });
  };

  create_or_update_connection(id, remote_params, local_params) {
    var id_params, promise, self;
    self = this;
    id_params = "";
    this.request_source = 'create';
    if (id > 0) {
      id_params = "/" + id;
      this.request_source = 'update';
    }
    return promise = new Promise(function(resolve, reject) {
      return self.encrypt_params(remote_params, ["id_provider", "id_bank", "openapiwebsite", "directaccesswebsite"]).then(function(remote_params_encrypted) {
        return self.double_fetch({
          remote: {
            url: "/users/me/connections" + id_params,
            data: remote_params_encrypted,
            type: 'POST'
          },
          local: {
            url: "/retriever/create",
            data: local_params
          },
          onError: function(error) {
            self.request_source = '';
            return reject(error);
          },
          onSuccess: function(remote_response, local_response) {
            self.request_source = '';
            return resolve({
              remote_response: remote_response,
              local_response: local_response
            });
          }
        });
      });
    });
  };

  update_additionnal_infos(id, remote_params, local_params) {
    var promise, self;
    self = this;
    return promise = new Promise(function(resolve, reject) {
      if (id > 0) {
        return self.encrypt_params(remote_params, ["openapiwebsite", "directaccesswebsite"]).then(function(remote_params_encrypted) {
          return self.double_fetch({
            remote: {
              url: "/users/me/connections/" + id,
              data: remote_params_encrypted,
              type: 'POST'
            },
            local: {
              url: "/retriever/add_infos",
              data: local_params
            },
            onError: function(error) {
              return reject(error);
            },
            onSuccess: function(response_remote, response_local) {
              return resolve({
                response_remote: response_remote,
                response_local: response_local
              });
            }
          });
        });
      } else {
        return reject('Erreur de chargement du connecteur');
      }
    });
  };

  delete_connection(id) {
    var promise, self;
    self = this;
    return promise = new Promise(function(resolve, reject) {
      return self.sync_connection('destroy', id).then(resolve, reject);
    });
  };

  trigger_connection(id) {
    var promise, self;
    self = this;
    return promise = new Promise(function(resolve, reject) {
      return self.sync_connection('trigger', id).then(resolve, reject);
    });
  };

  request_new_connector(remote_params, local_params) {
    var promise, self;
    self = this;
    return promise = new Promise(function(resolve, reject) {
      return self.encrypt_params(remote_params, ["api", "name", "url", "types", "comment", "email", "login", "password"]).then(function(remote_params_encrypted) {
        return self.double_fetch({
          remote: {
            url: "/connectors",
            data: remote_params_encrypted,
            type: 'POST'
          },
          local: {
            url: "/account/new_provider_requests",
            data: local_params
          },
          onError: function(error) {
            return reject(error);
          },
          onSuccess: function(response_remote, response_local) {
            return resolve({
              response_remote: response_remote,
              response_local: response_local
            });
          }
        });
      });
    });
  };

  update_contact(data) {
    var promise, self;
    self = this;
    return promise = new Promise(function(resolve, reject) {
      return self.remote_fetch({
        url: "/users/me/profiles/me",
        data: {
          contact: data
        },
        type: "POST",
        onSuccess: function(data) {
          return resolve(data);
        },
        onError: function(error) {
          return reject(error);
        }
      });
    });
  };

  sync_connection(type, id) {
    var promise, self;
    self = this;
    return promise = new Promise(function(resolve, reject) {
      var budgea_id, do_sync, local_request, remote_method;
      budgea_id = '';
      if (type === 'destroy') {
        remote_method = 'DELETE';
      } else {
        remote_method = "PUT";
      }
      local_request = function(params) {
        return self.local_fetch({
          url: "/retriever/" + type,
          data: params,
          onSuccess: function(data) {
            return resolve(data);
          },
          onError: function(error) {
            return reject(error);
          }
        });
      };
      do_sync = function() {
        if (budgea_id !== '') {
          return self.remote_fetch({
            url: "/users/me/connections/" + budgea_id,
            type: remote_method,
            success_only: true,
            onSuccess: function(data) {
              var connections, message, _success;
              connections = data['collection'];
              message = data['message'];
              _success = false;
              if (message === '') {
                _success = true;
              }
              if (message.match(/Erreur: 404/) && remote_method === 'DELETE') {
                _success = true;
                connections = {};
              }
              return local_request({
                id: id,
                success: _success,
                data_remote: connections
              });
            }
          });
        } else {
          return local_request({
            id: id,
            success: true,
            data_remote: {}
          });
        }
      };
      return self.local_fetch({
        url: "/retriever/retriever_infos",
        data: {
          id: id,
          remote_method: remote_method
        },
        onSuccess: function(data) {
          budgea_id = data.budgea_id;
          self.set_tokens({
            bi_token: data.bi_token
          });
          if (data.deleted !== void 0 && data.deleted === true) {
            return resolve({
              success: true
            });
          } else {
            return do_sync();
          }
        },
        onError: function(error) {
          return reject(error);
        }
      });
    });
  };

  refresh_connection(id, data_refresh) {
    var budgea_id, promise, self;
    self = this;
    budgea_id = '';
    return promise = new Promise(function(resolve, reject) {
      var do_sync, local_request;
      local_request = function(params) {
        return self.local_fetch({
          url: "/retriever/update_budgea_error_message",
          type: 'POST',
          data: params,
          onSuccess: function(data) {
            return resolve(data);
          },
          onError: function(error) {
            return reject(error);
          }
        });
      };
      do_sync = function() {
        if (budgea_id !== '') {
          return self.remote_fetch({
            url: "/users/me/connections/" + budgea_id,
            type: 'POST',
            data: data_refresh,
            success_only: true,
            onSuccess: function(data) {
              var _success;
              _success = false;
              if (data['message'] === '') {
                _success = true;
              }
              return local_request({
                id: id,
                success: _success,
                connections: data['collection']
              });
            }
          });
        } else {
          return local_request({
            id: id,
            success: false,
            connections: {}
          });
        }
      };
      return self.local_fetch({
        url: "/retriever/retriever_infos",
        data: {
          id: id,
          remote_method: 'POST'
        },
        onSuccess: function(data) {
          budgea_id = data.budgea_id;
          self.set_tokens({
            bi_token: data.bi_token
          });
          if (data.deleted !== void 0 && data.deleted === true) {
            return resolve({
              success: true
            });
          } else {
            return do_sync();
          }
        },
        onError: function(error) {
          return reject(error);
        }
      });
    });
  };

  webauth(user_id, id, is_new, params={}) {
    var self, error, ido_capabilities, ido_custom_name, ido_connector_id, ido_connector_name, state, success;

    self = this;
    ido_capabilities = params['ido_capabilities'].replace(/["]/g, '\'');
    ido_connector_id = params['ido_connector_id'].replace(/["]/g, '\'');
    ido_custom_name  = params['ido_custom_name'].replace(/["]/g, '\'');
    ido_connector_name = params['ido_connector_name'].replace(/["]/g, '\'');
    state = btoa("{ \"user_id\": \"" + user_id + "\", \"ido_capabilities\": \"" + (ido_capabilities) + "\", \"ido_connector_id\": \"" + (ido_connector_id) + "\", \"ido_custom_name\": \"" + (ido_custom_name) + "\", \"ido_connector_name\": \"" + (ido_connector_name) + "\" }");

    error = function(response) {
      $('#budgea_information_fields .feedparagraph').remove();
      $('#budgea_information_fields .actions').show();
      return alert(response.error);
    };
    success = function(response) {
      var data, domparser, redirect_url;
      $('#budgea_information_fields .feedparagraph').remove();
      $('#budgea_information_fields .actions').show();
      domparser = new DOMParser();
      data = domparser.parseFromString(response.html_dom, 'text/html');
      redirect_url = $(data).find('a').attr('href');
      if (redirect_url !== void 0 && redirect_url !== null) {
        return window.location.href = redirect_url;
      } else {
        return error({
          error: `Erreur de paramètre: ${response.html_dom}`
        });
      }
    };

    $('#budgea_information_fields .actions').hide();
    $('#budgea_information_fields .actions').after('<p class="feedparagraph">Redirection en cours ... </p>');

    this.remote_fetch({
      url: "/auth/token/code",
      use_secrets: true,
      type: 'GET',
      success_only: true,
      onSuccess: function(data) {
        var secure_token = '';
        try{
          secure_token = data['collection']['code'];
        }catch(e){ secure_token = '' }

        self.local_fetch({
          url: '/retriever/fetch_webauth_url',
          type: 'POST',
          data: {
            id: id,
            user_id: user_id,
            is_new: is_new,
            state: state,
            secure_token: secure_token
          },
          onSuccess: success,
          onError: error
        });
      }
    });
  };

  local_fetch(options) {
    var auth_params, method, onError, onSuccess, params, url;
    method = options.type || 'POST';
    url = options.url || '';
    params = this.data_compact(options.data) || {};
    onSuccess = options.onSuccess || function() {
      return {};
    };
    onError = options.onError || function() {
      return {};
    };
    if (this.user_token !== void 0 && this.user_token !== null) {
      auth_params = {
        access_token: this.user_token
      };
      Object.assign(params, params, auth_params);
    }
    return $.ajax({
      url: "" + this.local_host + url,
      data: params,
      type: method,
      beforeSend: function(){
        if( !($('div.loading_box').hasClass('force')) )
          $('div.loading_box').removeClass('hide');
      },
      success: function(data) {
        if( !($('div.loading_box').hasClass('force')) )
          $('div.loading_box').addClass('hide');

        if (data.success) {
          return onSuccess(data);
        } else {
          return onError(data.error_message);
        }
      },
      error: function(data) {
        if( !($('div.loading_box').hasClass('force')) )
          $('div.loading_box').addClass('hide');
        return onError("Service interne non disponible");
      }
    });
  };

  remote_fetch(options) {
    var auth_params, body, collection, headers, method, onError, onSuccess, parse_error, self, success_only, url, use_secrets, xhr;
    self = this;
    method = options.type || 'GET';
    url = options.url || '';
    body = this.data_compact(options.data) || {};
    headers = options.headers || {};
    use_secrets = options.use_secrets || false;
    onSuccess = options.onSuccess || function() {
      return {};
    };
    onError = options.onError || function() {
      return {};
    };
    collection = options.collection || '';
    success_only = options.success_only || false;
    xhr = new XMLHttpRequest();
    xhr.open(method, "" + this.api_base_url + url);
    xhr.setRequestHeader("Accept", "json");
    xhr.setRequestHeader("Content-Type", "application/json");
    if (this.bi_token !== void 0 && this.bi_token !== null && this.bi_token !== '') {
      xhr.setRequestHeader("Authorization", "Bearer " + this.bi_token);
    }
    parse_error = function(status) {
      var message;
      message = "Service non disponible (Erreur: " + status + ")";
      if (status === 404) {
        message = "Connecteur externe innexistant ou supprimé (Erreur: " + status + ")";
      } else if (status === 401) {
        message = "Authorisation requise (Erreur: " + status + ")";
      }
      if (success_only) {
        return onSuccess({
          collection: {},
          message: message
        });
      } else {
        return onError(message);
      }
    };
    xhr.onload = function() {
      setTimeout(function(){ if( !($('div.loading_box').hasClass('force')) ){ $('div.loading_box').addClass('hide'); } }, 3000);
      var data_collect, error_message, message, response, success;
      if ([200, 202, 204, 400, 403, 500, 503].includes(xhr.status)) {
        try {
          response = JSON.parse(xhr.responseText);
          message = response.message || response.description || '';
          if (message !== '') {
            message = "(" + message + ")";
          }
          if (self.request_source === 'create' && response.id !== 'undefined' && response.id !== null && parseInt(response.id) > 0) {
            console.log('----jump-creation---');
            console.error(response);
            error_message = '';
          } else {
            switch (response.code) {
              case 'wrongpass':
                error_message = "Mot de passe incorrecte. " + message;
                break;
              case 'websiteUnavailable':
                error_message = "Site web indisponible. " + message;
                break;
              case 'bug':
                error_message = "Service indisponible. " + message;
                break;
              case 'config':
                error_message = response.description;
                break;
              case 'actionNeeded':
                error_message = "Veuillez confirmer les nouveaux termes et conditions. " + message;
                break;
              case 'missingParameter':
                error_message = "Erreur de paramètre " + message;
                break;
              case 'invalidValue':
                error_message = "Erreur de paramètre " + message;
                break;
              case 'keymanager':
                error_message = "Erreur de cryptage interne " + message;
                break;
              case 'internalServerError':
                error_message = "Erreur du service externe " + message;
                break;
              default:
                error_message = "" + message;
            }
          }
          success = error_message.length > 0 ? false : true;
          data_collect = collection.length > 0 ? response[collection] : response;
          if (success_only) {
            onSuccess({
              collection: data_collect,
              message: error_message
            });
          } else {
            if (success) {
              onSuccess(data_collect);
            } else {
              onError(error_message);
            }
          }
        } catch (_error) {}
        return {
          "catch": function(e) {
            return parse_error(xhr.status);
          }
        };
      } else {
        return parse_error(xhr.status);
      }
    };
    xhr.onerror = function() {
      if( !($('div.loading_box').hasClass('force')) )
        $('div.loading_box').addClass('hide');
      return parse_error(xhr.status);
    };
    auth_params = {
      client_id: this.api_client_id,
      client_secret: this.api_client_secret
    };
    if (use_secrets) {
      Object.assign(body, body, auth_params);
    }
    body = JSON.stringify(body);

    if( !($('div.loading_box').hasClass('force')) )
      $('div.loading_box').removeClass('hide');
    return xhr.send(body);
  };

  double_fetch(options) {
    var collection_remote, onError, onSuccess, params_local, params_remote, self, type_local, type_remote, url_local, url_remote, use_secrets_remote;
    url_local = options.local.url;
    type_local = options.local.type || 'POST';
    params_local = options.local.data || {};
    url_remote = options.remote.url;
    type_remote = options.remote.type || 'GET';
    params_remote = options.remote.data || {};
    collection_remote = options.remote.collection || '';
    use_secrets_remote = options.remote.use_secrets || false;
    onError = options.onError || function() {
      return {};
    };
    onSuccess = options.onSuccess || function() {
      return {};
    };
    self = this;
    return this.remote_fetch({
      url: url_remote,
      type: type_remote,
      data: params_remote,
      collection: collection_remote,
      use_secrets: use_secrets_remote,
      onError: function(error) {
        return onError(error);
      },
      onSuccess: function(remote_response) {
        return self.local_fetch({
          url: url_local,
          type: type_local,
          data: {
            data_local: self.data_compact(params_local),
            data_remote: self.data_compact(remote_response)
          },
          onError: function(error) {
            return onError(error);
          },
          onSuccess: function(local_response) {
            return onSuccess(remote_response, local_response);
          }
        });
      }
    });
  };

  init_encryptor() {
    this.encryptor = null;

    if(this.activate_encryption){
      var cryptographer, public_rsa_key;
      cryptographer = new Jose.WebCryptographer();
      public_rsa_key = Jose.Utils.importRsaPublicKey(this.api_ky, "RSA-OAEP");
      this.encryptor = new JoseJWE.Encrypter(cryptographer, public_rsa_key);
      this.encryptor.addHeader("kid", this.api_ky.kid);
    }
  };

  encrypt_params(data, _except) {
    var promise, self;
    self = this;
    data = this.data_compact(data);
    return promise = new Promise(function(resolve) {
      var count, except, k, keys, _i, _len, _results;
      except = _except || [];
      keys = Object.keys(data);
      count = keys.length || 0;
      if (self.encryptor !== void 0 && self.encryptor !== null && count > 0) {
        _results = [];
        for (_i = 0, _len = keys.length; _i < _len; _i++) {
          k = keys[_i];
          if (!except.includes(k)) {
            _results.push(self.encrypt(data[k], k).then(function(encrypted) {
              var _k, _value;
              _k = encrypted.key;
              _value = encrypted.response;
              data[_k] = _value;
              count--;
              if (count <= 0) {
                return resolve(data);
              }
            }));
          } else {
            count--;
            if (count <= 0) {
              _results.push(resolve(data));
            } else {
              _results.push(void 0);
            }
          }
        }
        return _results;
      } else {
        return resolve(data);
      }
    });
  };

  encrypt(value, key) {
    var promise, self;
    self = this;
    return promise = new Promise(function(resolve) {
      return self.encryptor.encrypt(value).then(function(result) {
        return resolve({
          key: key,
          response: result
        });
      })["catch"](function(e) {
        return resolve({
          key: key,
          response: value
        });
      });
    });
  };

  data_compact(params) {
    var filtered, k, keys, value, _i, _len;
    filtered = params;
    if ($.isArray(params)) {
      filtered = params.filter(function(n) {
        return n !== void 0 && n !== null;
      });
    } else if ($.isPlainObject(params)) {
      keys = Object.keys(filtered);
      for (_i = 0, _len = keys.length; _i < _len; _i++) {
        k = keys[_i];
        value = filtered[k];
        if (value === void 0 || value === null) {
          delete filtered[k];
        }
      }
    }
    return filtered;
  };
}