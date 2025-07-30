var _scannerVariables = {
    elemScannerDiv: null,
    // Restringindo para os tipos mais comuns de produtos para aumentar a precisão e velocidade.
    DEF_BARCODE_TYPE: ['Code128', 'Code39', 'EAN13', 'UPCA', 'QRCode'],
    camDevices: null,
    bDSMobile: /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent),
    bIsIOS: ['iPad', 'iPhone', 'iPod'].includes(navigator.platform) ||
				// iPad on iOS detection
				(navigator.userAgent.includes("Mac") && "ontouchend" in document),
    camName: ['0, facing back', 'facing back:0', 'back camera'],
};


//returns camera idx
function SelectBestCamera( camArr, cams )
{
	var _result = -1;
	camArr.forEach(function (c) { c.label = c.label.toLowerCase(); });
	cams.forEach(function (c) { c = c.toLowerCase(); });
	for( var i=0; i < camArr.length; ++i )
	{
		for( var j=0; j < cams.length; ++j )
		{
			if( camArr[i].label.includes(cams[j]) )
				return i;
		}
	}
	return _result;
}

function onDSBarcode (barcodeResult)
{
	for (var i = 0; i < barcodeResult.length; ++i) {
	    var sBarcode = DSScanner.bin2String(barcodeResult[i]);
        var dr = barcodeResult[i];
        dr.strdata = sBarcode;
        if (typeof _scannerVariables['onBarcode'] === "function")
            _scannerVariables['onBarcode'](dr);
    }
};

function onDSError(err)
{
    if (typeof _scannerVariables['onError'] === "function")
	    _scannerVariables['onError'](err);
}

function CreateScanner()
{
    var scannerSettings = {
        scanner: {
            // Chave de licença do seu demo. Essencial para o funcionamento correto.
            key: 'QURgiM+Sluy1G0eJtaGF8mx/eIBeF1ZaB0Z8RgWjzOKQJlP8mgno3uywJzXO0fQDYqW+zLBcizZqfsXsyMO/ZkwHyRJ3QGxeNAiZw2HNGk44kBM+a3+xxWzbTum7Tzt3GoA2m12yUwdJFZ8hKYfiUI3c1Q5UGqOWGsYZGYsS+QBfA3YnjOJ6674nqq/uOWMurPS8u4UsEiGco1v3eZu9H2qB/SvQc9KstmrW+QXyu/Naw2woYDczxecSo+WvTeOYGYXkfZjVcfHEmUkH9392NbGi67jTARgsFTEKWH2wS7E48ANon2hWBonxoesz5bxJa/S5E5DADRniX1EPEKNbCw==',
            frameTimeout:	100,
            barcodeTimeout:	1000,
            beep: true,
        },
        viewport: {
            id: 'datasymbol-barcode-viewport',
            width: _scannerVariables.bDSMobile ? null : 640,	//null means 100% width
        },
        camera: {
            resx: 640,
            resy: 480,
        },
        barcode: {
            // Forçando os tipos de código de barras para os mais comuns em produtos.
            // Isso evita a leitura incorreta de EAN13 como Code39.
            barcodeTypes: ['EAN13', 'UPCA', 'UPCE'],
            bQRCodeFindMicro: false,
            frameTime: 1000,
        },
    };

    if( _scannerVariables.camDevices && _scannerVariables.camDevices.length > 0 )
    {
            if( _scannerVariables.bDSMobile || _scannerVariables.bIsIOS )
            {
                var camIdx = SelectBestCamera( _scannerVariables.camDevices, _scannerVariables.camName );
                if( camIdx >= 0 )
                    scannerSettings.camera.id = _scannerVariables.camDevices[camIdx].id;
                else
                    scannerSettings.camera.facingMode = 'environment';
            }
            //non mobile, select first camera
            else
            {
                scannerSettings.camera.id = _scannerVariables.camDevices[0].id
                scannerSettings.camera.label = _scannerVariables.camDevices[0].label;
            }
    }
        
    DSScanner.addEventListener('onBarcode', onDSBarcode);

    DSScanner.addEventListener('onScannerReady', function () {
        // Garantia extra: define as configurações novamente quando o scanner está pronto.
        DSScanner.setScannerSettings({
            barcode: {
                barcodeTypes: ['EAN13', 'UPCA', 'UPCE']
            }
        });
        DSScanner.StartScanner();
    });

    DSScanner.Create(scannerSettings);
}

function embedScanner( x, y, width, height )
{
    _scannerVariables.elemScannerDiv = document.createElement('div');
    _scannerVariables.elemScannerDiv.id = 'div-datasymbol-barcode-viewport';
    _scannerVariables.elemScannerDiv.style.cssText = 'position:absolute;left:'+x+'px;top:'+y+'px;width:'+width+'px;height:'+height+'px;z-index:100;';

    _scannerVariables.elemScannerDiv.innerHTML = `
        <div id="datasymbol-barcode-viewport" style='display:block;width:100%;height:480px;font: bold 2em Tahoma;'></div>
    `;

    document.body.appendChild(_scannerVariables.elemScannerDiv);

    DSScanner.addEventListener('onError', onDSError);

	DSScanner.getVideoDevices(function (devices) {
		if(devices.length > 0)
		{
			_scannerVariables.camDevices = devices.slice();
			CreateScanner();
		}
		else
		{
			onDSError( {name: 'NotFoundError', message: 'Camera Not Connected'} );
		}
	}, true);

//    CreateScanner();
}

function updateScannerPos(x, y, width, height)
{
    if( _scannerVariables.elemScannerDiv )
    {
        _scannerVariables.elemScannerDiv.style.left = x + 'px';
        _scannerVariables.elemScannerDiv.style.top = y + 'px';
        _scannerVariables.elemScannerDiv.style.width = width + 'px';
        _scannerVariables.elemScannerDiv.style.height = height + 'px';
    }
}

function addScannerCallback(funcName, dsFuncCallback)
{
    if(funcName && funcName.length !=0 && dsFuncCallback != null && (typeof dsFuncCallback === "function") )
        _scannerVariables[funcName] = dsFuncCallback;
}
