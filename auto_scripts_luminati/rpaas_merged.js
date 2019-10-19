/* ____AllTogether/Base.js____ */

'use strict';
function Where(){
  var ThreadDef = Java.use('java.lang.Thread');
  var stack = ThreadDef.currentThread().getStackTrace();
  var at = "";
  for(var i = stack.length - 1; i >= 2; i--){
    at += stack[i].toString() + "\n";
  }
  return at;
}
function getApplication() {
  const ActivityThread = Java.use('android.app.ActivityThread');
  const app = ActivityThread.currentApplication();
  var appName = app.toString().split("@")[0];
  return appName;
}
function getProcessNameById(process_id) {
  var FileInputStream =  Java.use("java.io.FileInputStream");
  var InputStreamReader = Java.use("java.io.InputStreamReader");
  var BufferedReader = Java.use("java.io.BufferedReader");
  var file_path = '/proc/' + process_id + '/cmdline';
  var fileInputStream = FileInputStream.$new(file_path);
  var inputStreamReader = InputStreamReader.$new(fileInputStream, "iso-8859-1");
  var bufferedReader = BufferedReader.$new(inputStreamReader);
  var buffer = -1;
  var processName = "";
  while ((buffer = bufferedReader.read()) > 0) {
    processName += String.fromCharCode(buffer);
  }
  bufferedReader.close();
  return processName;
}
var base_result_file = 'rpaas.log';
var external_base_result_file = '/sdcard/rpaas/rpaas.log';
function rpaas_log_internal(message, message_type){
  var log_data_str;
  try{
    var Process = Java.use('android.os.Process');
    var log_data = {};
    log_data.time = new Date();
    log_data.message = message;
    log_data.message_type = message_type;
    log_data.call_stack = Where();
    log_data.app_name = getApplication();
    log_data.myUserID = Process.myUid();
    log_data.myProcessID = Process.myPid();
    log_data.myThreadID = Process.myTid();
    log_data_str = JSON.stringify(log_data);
  } catch(e) {
    log_data_str = 'rpaas_log_exception' + e + e.stack;
  }
  var Context = Java.use("android.content.Context");
  const ActivityThread = Java.use('android.app.ActivityThread');
  const app_context = ActivityThread.currentApplication();
  var app_dir_file = app_context.getFilesDir();
  var app_dir = app_dir_file.getCanonicalPath();
  var log_file = new File(app_dir + '/' + base_result_file, 'a');
  log_file.write(log_data_str + '\n');
  log_file.flush();
  log_file.close();
}
function rpaas_log(message, message_type){
  var log_data_str;
  try{
    var Process = Java.use('android.os.Process');
    var log_data = {};
    log_data.time = new Date();
    log_data.message = message;
    log_data.message_type = message_type;
    log_data.call_stack = Where();
    log_data.app_name = getApplication();
    log_data.myUserID = Process.myUid();
    log_data.myProcessID = Process.myPid();
    log_data.myProcessName = getProcessNameById(log_data.myProcessID);
    log_data.myThreadID = Process.myTid();
    log_data_str = JSON.stringify(log_data);
  } catch(e) {
    log_data_str = 'rpaas_log_exception' + e.stack;
  }
  var log_file = new File(external_base_result_file, 'a');
  log_file.write(log_data_str + '\n');
  log_file.flush();
  log_file.close();
}
setTimeout(function(){
  Java.perform(function() {
    try{
      const ActivityThread = Java.use('android.app.ActivityThread');
      const app_context = ActivityThread.currentApplication();
      var app_dir_file = app_context.getFilesDir();
      var app_dir = app_dir_file.getCanonicalPath();
      rpaas_log('load_rpaas_script', 'script_init: ' + app_dir);
    } catch (e) {
      console.log(e, e.stack);
    }
  });
}, 0);


/* ____Network/HTTP.js____ */

/**
 * Copyright (c) 2016 Nishant Das Patnaik.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
**/

'use strict';
setTimeout(function(){
  // ajax request in topvpn library, while it leverages https://github.com/androidquery/, but the androidquery can be obfuscated.
  // Therefore, let's hook o/topvpn/vpn_api/zajax$1 o/topvpn/vpn_api/zajax$1$1 o/topvpn/vpn_api/zajax$1$2 o/topvpn/vpn_api/zajax$1$3 
  // we may also hook on apache http libraries underlying androidquery level
  Java.perform(function() {
    try {
      var CBBase = Java.use("io.topvpn.vpn_api.zajax$1");
      var CBBase1 = Java.use("io.topvpn.vpn_api.zajax$1$1");
      var CBBase2 = Java.use("io.topvpn.vpn_api.zajax$1$2");
      var CBBase3 = Java.use("io.topvpn.vpn_api.zajax$1$3");
      var new_callback = function(url, json_obj, cb_status) {
        try {
          var ajax_data = {}
          ajax_data.url = url
          ajax_data.params = this._params.toString();
          ajax_data.json_str = json_obj.toString();
          ajax_data.status_code = cb_status.f();
          ajax_data.type = 'Topvpn Ajax Hook';
          var proxy_obj = this._proxy;
          console.log(typeof proxy_obj);
          if (typeof(proxy_obj) !== "undefined" && proxy_obj !== null) {
            ajax_data.proxy = proxy_obj.toString();
          } else {
            ajax_data.proxy = "";
          }
          var ajax_data_str = JSON.stringify(ajax_data);
          rpaas_log(ajax_data_str);
        } catch (e) {
          rpaas_log('error when hook topvpn ajax' + e.stack);
        }
        return this.callback.overload('java.lang.String', 'org.json.JSONObject', 'com.b.b.c').apply(this, arguments);
      };
      CBBase.callback.overload('java.lang.String', 'org.json.JSONObject', 'com.b.b.c').implementation = new_callback;
      CBBase1.callback.overload('java.lang.String', 'org.json.JSONObject', 'com.b.b.c').implementation = new_callback;
      CBBase2.callback.overload('java.lang.String', 'org.json.JSONObject', 'com.b.b.c').implementation = new_callback;
      CBBase3.callback.overload('java.lang.String', 'org.json.JSONObject', 'com.b.b.c').implementation = new_callback;
      //CBBase.callback.overloads[1].implementation = new_callback;
      //CBBase1.callback.overloads[1].implementation = new_callback;
      //CBBase2.callback.overloads[1].implementation = new_callback;
      //CBBase3.callback.overloads[1].implementation = new_callback;
    } catch(e) {
      rpaas_log('hook ajax failed' + e.stack);
    }
  });

  Java.perform(function() {
    try {
      var HttpURLConnection = Java.use("com.android.okhttp.internal.http.HttpURLConnectionImpl");
    } catch (e) {
      try {
        var HttpURLConnection = Java.use("com.android.okhttp.internal.huc.HttpURLConnectionImpl");
      } catch (e) { return }
    }
    //var BufferedInputStream = Java.use("java.io.BufferedInputStream");
    var StringBuilder = Java.use("java.lang.StringBuilder");
    var InputStreamReader =  Java.use("java.io.InputStreamReader");
    var BufferedReader = Java.use("java.io.BufferedReader");
    var GZIPInputStream = Java.use("java.util.zip.GZIPInputStream");
    var ByteArrayOutputStream = Java.use("java.io.ByteArrayOutputStream");
    var BufferedReader = Java.use("java.io.BufferedReader");
    var GZIPOutputStream = Java.use("java.util.zip.GZIPOutputStream");
    var ByteArrayInputStream = Java.use("java.io.ByteArrayInputStream");
    var Log = Java.use("android.util.Log");

    HttpURLConnection.getInputStream.overloads[0].implementation = function() {
      var methodURL = "";
      var requestHeaders = "";
      var requestBody = "";
      var responseHeaders = "";
      var responseBody = "";
      try {
        console.log('hook get input stream');
        methodURL = "";
        responseHeaders = "";
        responseBody = "";
        var Connection = this;
        //var stream = this.getInputStream.overloads[0].apply(this, arguments);
        var requestURL = Connection.getURL().toString();
        var requestMethod = Connection.getRequestMethod();
        methodURL = requestMethod + " " + requestURL;
        var headFields = Connection.getHeaderFields();
        try{
          if (headFields && !headFields.isEmpty()) {
              responseHeaders = "";
              //var entry_array = Array.from(entrySet);
              //for (var i = 0; i < entry_array.length; i++) {
              //  var entry = entry_array[i];
              //  var headerName = entry.getKey();
              //  var headerValues = entry.getValue();
              //  responseHeaders += headerName.toString() + ": ";
              //  for (var j = 0; j < headerValues.length; j++) {
              //    var value = headerValues[j];
              //    responseHeaders += value.toString() + ";";
              //  }
              //  responseHeaders += "\n";
              //}
              var Keys = headFields.keySet().toArray();
              var Values = headFields.values().toArray();
              for (var key in Keys) {
                if (Keys[key] && Keys[key] !== null && Values[key]) {
                  responseHeaders += Keys[key] + ": " + Values[key].toString().replace(/\[/gi, "").replace(/\]/gi, "") + "\n";
                } else if (Values[key]) {
                  responseHeaders += Values[key].toString().replace(/\[/gi, "").replace(/\]/gi, "") + "\n";
                }
              }
          }
        } catch(e) {
          console.error(e, e.stack);
          rpaas_log('\n' + e.stack + '\n');
        }
        /*   --- Payload Header --- */
        var send_data = {};
        var is_use_proxy = Connection.usingProxy();
        var proxy;
        try{
          if (is_use_proxy == true) {
            var proxy_obj = Connection.getProxy();
            proxy = proxy_obj.toString();
          }
        } catch(e) {
          rpaas_log('\n' + e.stack + '\n');
        }
        send_data.is_use_proxy = is_use_proxy;
        send_data.proxy = proxy;
        send_data.time = new Date();
        send_data.txnType = 'HTTP';
        send_data.lib = 'com.android.okhttp.internal.http.HttpURLConnectionImpl';
        send_data.method = 'getInputStream before dumping input';
        send_data.methodURL = methodURL;
        send_data.responseHeaders = responseHeaders;
        var send_data_str = JSON.stringify(send_data);
        //console.log(send_data_str);
        rpaas_log(send_data_str);
        var retval;
        var stream;
        if("gzip" == Connection.getContentEncoding())
        {
            stream = InputStreamReader.$new(GZIPInputStream.$new(this.getInputStream.apply(this, arguments)));
        }   
        else
        {
            stream = InputStreamReader.$new(this.getInputStream.apply(this, arguments));
        }
        if (false && stream) {
          var baos = ByteArrayOutputStream.$new();
          var buffer = -1;
          var bufferedReaderStream = BufferedReader.$new(stream);
          var line;
          //console.log('start to read data');
          //while ((line = bufferedReaderStream.readLine()) != null){
          //    console.log('read data', line);
          //    baos.write(line.getBytes());
          //    response.append(line)
          //}
          var buffer = -1;
          while ((buffer = bufferedReaderStream.read()) != -1){
              //console.log('read data', buffer);
              baos.write(buffer);
          }
          bufferedReaderStream.close();
          baos.flush();
          var response_byte_array = baos.toByteArray();
          if("gzip" == Connection.getContentEncoding())
          {
              retval = GZIPOutputStream.$new(ByteArrayInputStream.$new(response_byte_array));
          }
          else
          {
              retval = ByteArrayInputStream.$new(response_byte_array);
          }
          responseBody += baos.toString('UTF-8');
        }
        send_data.method = 'getInputStream after dumping input';
        send_data.responseBody = responseBody;
        send_data.responseBodyLen = responseBody.length;
        send_data_str = JSON.stringify(send_data);
        //console.log(send_data_str);
        rpaas_log(send_data_str);
        if(retval)
            return retval;
        return this.getInputStream.overloads[0].apply(this, arguments);
      } catch (e) {
        console.error(e, e.stack);
        rpaas_log('\n' + e.stack + '\n');
        return this.getInputStream.overloads[0].apply(this, arguments);
      } finally {
      }
    };

    HttpURLConnection.getOutputStream.overloads[0].implementation = function() {
      var methodURL = "";
      var requestHeaders = "";
      var requestBody = "";
      var responseHeaders = "";
      var responseBody = "";
      try{
        console.log('hook get output stream');
        //console.log('hook get output stream');
        //Log.v('[rpaas]', 'hook get output stream');
        requestHeaders = "";
        requestBody = "";
        var Connection = this;
        try {
          if (!Connection.connected && Connection.getRequestProperties()) {
            var Keys = Connection.getRequestProperties().keySet().toArray();
            var Values = Connection.getRequestProperties().values().toArray();
            requestHeaders = "";
            for (var key in Keys) {
              if (Keys[key] && Keys[key] !== null && Values[key]) {
                requestHeaders += Keys[key] + ": " + Values[key].toString().replace(/\[/gi, "").replace(/\]/gi, "") + "\n";
              } else if (Values[key]) {
                requestHeaders += Values[key].toString().replace(/\[/gi, "").replace(/\]/gi, "") + "\n";
              }
            }
          }

        } catch(e) {
          console.error(e, e.stack);
          rpaas_log('\n' + e.stack + '\n');
        }
        var requestURL = Connection.getURL().toString();
        var requestMethod = Connection.getRequestMethod();
        methodURL = requestMethod + " " + requestURL;
        var send_data = {};
        var is_use_proxy = Connection.usingProxy();
        var proxy;
        try{
          if (is_use_proxy == true) {
            var proxy_obj = Connection.getProxy();
            proxy = proxy_obj.toString();
          }
        } catch(e) {
          rpaas_log('\n' + e.stack + '\n');
        }
        send_data.is_use_proxy = is_use_proxy;
        send_data.proxy = proxy;
        send_data.time = new Date();
        send_data.txnType = 'HTTP';
        send_data.lib = 'com.android.okhttp.internal.http.HttpURLConnectionImpl';
        send_data.method = 'getOutputStream';
        send_data.artifact = [];
        var data = {};
        data.requestUrl = methodURL;
        data.requestHeaders = requestHeaders;
        data.requestBody = requestBody;
        send_data.artifact.push(data);
        var send_data_str = JSON.stringify(send_data);
        // console.log(send_data_str);
        // Log.v("[rpaas]", send_data_str);
        rpaas_log(send_data_str);
        return this.getOutputStream.overloads[0].apply(this, arguments);
      } catch(e) {
        // console.error(e, e.stack);
        rpaas_log('\n' + e.stack + '\n');
        return this.getOutputStream.overloads[0].apply(this, arguments);
      } finally {
      }
    };
  });
}, 0);
setTimeout(function(){
    Java.perform(function() {
      var array_list = Java.use("java.util.ArrayList");
      var ApiClient = Java.use('com.android.org.conscrypt.TrustManagerImpl');
      ApiClient.checkTrustedRecursive.implementation = function(a1, a2, a3, a4, a5, a6) {
          rpaas_log('Bypassing SSL Pinning');
          var k = array_list.$new();
          return k;
      }
    });
},0);


