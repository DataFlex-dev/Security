WebQrCode = function WebQrCode(sName, oParent){
    WebQrCode.base.constructor.call(this, sName, oParent);

    this.prop(df.tString, "psValue", "");

	// Private properties
	this._eQrCode = null;

    //  Determine CSS classname for outermost div
    this._sControlClass = "WebQrCode";
};
df.defineClass("WebQrCode", "df.WebImage", {

openHtml : function(aHtml){
    WebQrCode.base.openHtml.call(this, aHtml);

    aHtml.push('<div class="WebQrCode" style="display:none;"></div>');
},

closeHtml : function(aHtml){
    WebQrCode.base.closeHtml.call(this, aHtml);
},

afterRender : function(){
    //  Get references to DOM elements
    this._eControl = df.dom.query(this._eElem, "div.WebQrCode");

	// Create the real QR Code control
	this._eQrCode = new QRCode(this._eControl, {
        // width: this._eControl.parentElement.offsetWidth, height: this._eControl.parentElement.offsetWidth
        width: 200,
		height: 200
		});

    //  Forward Send
    WebQrCode.base.afterRender.call(this);

    //  Execute setters to finish initialization
    this.set_psValue(this.psValue);
},

clearCode : function(){
    this._eQrCode.clear();
    this.set_psUrl(this._eQrCode._oDrawing._elCanvas.toDataURL("image/png"));
},

makeCode : function(sValue){
    this.clearCode();
    this._eQrCode.makeCode(sValue);
    this.set_psUrl(this._eQrCode._oDrawing._elCanvas.toDataURL("image/png"));
},

resize : function(){
    //  Forward Send (before so base class can add wrapping elements)
    WebQrCode.base.resize.call(this);

    // Redraw when neccessary
    if (this._eQrCode._htOption.width != this._eControl.clientWidth 
            || this._eQrCode._htOption.height != this._eControl.clientHeight){
        var smallest = this._eControl.clientWidth;
        if (this._eControl.clientHeight < smallest) smallest = this._eControl.clientHeight;

        // For redraw
        this._eQrCode._htOption.height = smallest;
	    this._eQrCode._htOption.width = smallest;

	    // For direct resize
	    this._eQrCode._oDrawing._elCanvas.height = smallest;
	    this._eQrCode._oDrawing._elCanvas.width = smallest;

	    // Draw the QR code
	    this.makeCode(this.psValue);
    }

},

set_psValue : function(sVal){
    if(this._eQrCode){
        if (sVal == null || sVal == "") this.clearCode();
        else this.makeCode(sVal);
    }
}
});
