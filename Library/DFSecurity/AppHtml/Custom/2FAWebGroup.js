//  Create namespace object
if(!dfsecurity){
    var dfsecurity = {};
};

dfsecurity.tU2FRegisterRequestFormat = {
    type : df.tString,
    registerRequests : [{
        version : df.tString,
        challenge : df.tString,
        appId : df.tString
    }],
    registeredKeys : [{
        version : df.tString,
        keyHandle : df.tString,
        transports : [ df.tString ],
        appId : df.tString
    }]
};

dfsecurity.tU2FSignRequestFormat = {
    type : df.tString,
    challenge : df.tString,
    registeredKeys : [{
        version : df.tString,
        keyHandle : df.tString,
        transports : [ df.tString ],
        appId : df.tString,
        challenge : df.tString
    }]
};

dfsecurity.TwoFAWebGroup = function TwoFAWebGroup(sName, oParent){
    dfsecurity.TwoFAWebGroup.base.constructor.call(this, sName, oParent);
};
df.defineClass("dfsecurity.TwoFAWebGroup", "df.WebGroup", {

doRegister : function(timeout) {
    var tData, tVT;

    tVT = this._tActionData;
    tData = df.sys.vt.deserialize(tVT, dfsecurity.tU2FRegisterRequestFormat);
    console.log("Register request", tData);

    // Register a U2F device and send the response to the server for storage
    var obj = this;
    if (typeof u2f.callbackMap_ == "undefined") {
        // builtin object using FIDO standard parameters (FF)
        u2f.register(tData.registerRequests[0].appId, tData.registerRequests, tData.registeredKeys, function(data) {
            obj.processRegister(data);
        }, timeout);
    } else {
        // use u2f-api.js (chrome/opera)
        u2f.register(tData.registerRequests, tData.registeredKeys, function(data) {
            obj.processRegister(data);
        }, timeout);
    }
},

processRegister : function(data) {
    console.log("Register callback", data);
    if (data.errorCode && data.errorCode != 0) {
//        alert("registration failed with errror: " + data.errorCode);
        return;
    } else {
        this.serverAction("DoRegister", [ data.clientData, data.registrationData]);
    }
},

doAuthenticate : function(timeout) {
    var tData, tVT;

    tVT = this._tActionData;
    tData = df.sys.vt.deserialize(tVT, dfsecurity.tU2FSignRequestFormat);
    console.log("Sign request", tData);

    var obj = this;
    if (typeof u2f.callbackMap_ == "undefined") {
        // builtin object using FIDO standard parameters (FF)
        u2f.sign(tData.registeredKeys[0].appId, tData.challenge, tData.registeredKeys, function(data) {
            obj.processAuthenticate(data);
        }, timeout);
    } else {
        // use u2f-api.js (chrome/opera)
        u2f.sign(tData.registeredKeys, function(data) {
            obj.processAuthenticate(data);
        }, timeout);
    }
},

processAuthenticate : function(data) {
    console.log("Sign callback", data);
    if (data.errorCode && data.errorCode != 0) {
//        alert("Signing failed with errror: " + data.errorCode);
        return;
    } else {
        this.serverAction("DoAuthenticate", [ data.keyHandle, data.signatureData, data.clientData]);
    }
}

}); // end of df.defineClass()
