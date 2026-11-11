
&AtClientAtServerNoContext
Function BarcodeTemplate(SoldByWeight, Span, BarcodeNodeRange)
	
	If Not SoldByWeight Then
		Code = "ТТТТТТТТТ"; //@NON-NLS
	Else
		Code = "ТТТТВВВВВ"; //@NON-NLS
	EndIf;
	
	Return Span + "У" + Code + "К"; //@NON-NLS-1 //@NON-NLS-2
	
EndFunction

&AtClientAtServerNoContext
Function CustomizeForm(Form)
	
	Form.Items.DecorationPrefixOfTheBarcodeNode.Title = " - " + StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Tiền tố mã vạch (Trong nút này  %1)';
			|ru = 'Префикс узла штрихкода (В данном узле %1)';
			|en = 'Barcode node prefix (%1 in this node)'; fa = 'Barcode node prefix (%1 in this node)';
			|it = 'Prefisso del nodo del codice a barre (nel dato nodo %1)';
			|pl = 'Prefiks węzła kodu kreskowego (W danym węźle %1)';
			|tr = 'Barkod ünite öneki (Bu ünitede %1)'"),
		Form.BarcodeNodePrefix);
	
EndFunction

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	BarcodeNodePrefix = InformationRegisters.ItemsBarcodes.BarcodeNodePrefix();
	
	CustomizeForm(ThisForm);
	
	SettingsForBarcodeRanges = InformationRegisters.ItemsBarcodes.SettingsForBarcodeRanges();
	For Each TSRow In SettingsForBarcodeRanges Do
		Setting = Ranges.Add();
		Setting.SoldByWeight  = TSRow.SoldByWeight;
		Setting.Span = TSRow.Span;
		Setting.BarcodeTemplate = BarcodeTemplate(Setting.SoldByWeight, Setting.Span, BarcodeNodePrefix);
	EndDo;
	
EndProcedure

&AtServer
Procedure WriteAtServer()
	
	Constants.BarcodePrefixationSettings.Set(New ValueStorage(Ranges.Unload(,"SoldByWeight, Span")));
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	WriteAtServer();
	
	RefreshReusableValues();
	
	Close();
	
EndProcedure

&AtClient
Procedure RangesBarCodeTypeOnChange(Item)
	
	CurrentRow = Items.Ranges.CurrentData;
	CurrentRow.BarcodeTemplate = BarcodeTemplate(CurrentRow.SoldByWeight, CurrentRow.Span, BarcodeNodePrefix);
	
EndProcedure
