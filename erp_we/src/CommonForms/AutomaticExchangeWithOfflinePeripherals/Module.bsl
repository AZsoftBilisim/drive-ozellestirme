
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Query = New Query;
	
	QueryText =
	"SELECT
	|	CatalogPeripherals.Ref AS Device,
	|	CatalogPeripherals.EquipmentType AS EquipmentType
	|FROM
	|	Catalog.Peripherals AS CatalogPeripherals
	|WHERE
	|	CatalogPeripherals.EquipmentType = VALUE(Enum.PeripheralTypes.LabelPrintingScales)
	|	AND CatalogPeripherals.ExchangeRule <> VALUE(Catalog.RulesOfExchangeWithOfflinePeripherals.EmptyRef)
	|	AND CatalogPeripherals.DeviceIsInUse";
	
	
	Query.Text = QueryText;
	Query.SetParameter("CurrentWorkplace", Parameters.Workplace);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		NewRow = Equipment.Add();
		NewRow.PerformAnExchange         = True;
		NewRow.Device             = Selection.Device;
		NewRow.EquipmentType        = Selection.EquipmentType;
		NewRow.ExportState      = NStr("vi = '<Việc kết xuất đã không được thực hiện>';
										|ru = '<Выгрузка не производилась>';
										|en = '<Export was not made>'; fa = '<Export was not made>';
										|it = '<upload non riuscito>';
										|pl = '<Przesyłanie nie było wykonywane>';
										|tr = '<Dışa aktarma yapılmadı>'");
		NewRow.ImportPictureIndex = 1;
		NewRow.ExportPictureIndex = 1;
		
		If NewRow.EquipmentType = Enums.PeripheralTypes.LabelPrintingScales Then
			NewRow.ImportState = NStr("vi = '<Không bắt buộc>';
										|ru = '<Не требуется>';
										|en = '<Not needed>'; fa = '<Not needed>';
										|it = '<non richiesto>';
										|pl = '<Nie jest wymagane>';
										|tr = '<Gerekli değil>'");
		Else
			NewRow.ImportState = NStr("vi = '<Việc kết nhập đã không được thực hiện>';
										|ru = '<Загрузка не производилась>';
										|en = '<Import was not made>'; fa = '<Import was not made>';
										|it = '<download non riuscito>';
										|pl = '<Pobieranie nie było wykonywane>';
										|tr = '<İçe aktarma yapılmadı>'");
		EndIf;
		
	EndDo;
	
	State = "";
	
	Items.ToBegin.Enabled              = True;
	Items.ExitApp.Enabled           = False;
	
	Items.EquipmentExecuteNow.Enabled = AccessRight("Insert", Metadata.Documents.RetailSalesReport);
	
EndProcedure

#Region ProceduresCommandHandlers

&AtClient
Procedure ToBegin(Command)
	
	ClearMessages();
	
	If Not ValueIsFilled(ExchangeFrequency) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa xác định chu kỳ trao đổi với thiết bị';
												|ru = 'Не задана периодичность обмена с оборудованием';
												|en = 'Frequency of exchange with equipment is not specified'; fa = 'Frequency of exchange with equipment is not specified';
												|it = 'Intervallo di tempo dello scambio con l''apparecchiatura non indicato';
												|pl = 'Nie określono okresowości wymiany ze sprzętem';
												|tr = 'Ekipman ile değişim sıklığı belirlenmedi'"),,"ExchangeFrequency");
		Return;
	EndIf;
	
	If Not ThereIsEquipmentForExchange() Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa chọn thiết bị để trao đổi';
												|ru = 'Не выбрано оборудование для обмена';
												|en = 'Equipment for exchange is not selected'; fa = 'Equipment for exchange is not selected';
												|it = 'Apparecchiatura per lo scambio non selezionata';
												|pl = 'Nie wybrano sprzętu do wymiany';
												|tr = 'Değişim için ekipman seçilmedi'"),,"Equipment");
		Return;
	EndIf;
	
	Items.ExchangeFrequency.Enabled                         = False;
	Items.EquipmentPerformAnExchange.Enabled                  = False;
	Items.EquipmentCheckAll.Enabled                = False;
	Items.EquipmentUncheckAll.Enabled                     = False;
	Items.EquipmentContextMenuCheckAll.Enabled = False;
	Items.EquipmentContextMenuUncheckAll.Enabled      = False;
	
	Items.ToBegin.Enabled              = False;
	Items.ExitApp.Enabled           = True;
	
	State = NStr("vi = 'Đang thực hiện trao đổi với thiết bị bán hàng...';
				|ru = 'Выполняется обмен с подключенным оборудованием...';
				|en = 'Performing data exchange with peripherals...'; fa = 'Performing data exchange with peripherals...';
				|it = 'Scambio con connessione dell''apparecchiatura in corso...';
				|pl = 'Trwa wymiana z urządzeniem peryferyjnym...';
				|tr = 'Bağlanan ekipman ile değişim gerçekleştiriliyor...'");
	
	AttachIdleHandler("WaitHandlerExchange", ExchangeFrequency * 60, False);
	
	ExchangeIsInProgress = True;
	
EndProcedure

&AtClient
Procedure ExitApp(Command)
	
	Items.ExchangeFrequency.Enabled                         = True;
	Items.EquipmentPerformAnExchange.Enabled                  = True;
	Items.EquipmentCheckAll.Enabled                = True;
	Items.EquipmentUncheckAll.Enabled                     = True;
	Items.EquipmentContextMenuCheckAll.Enabled = True;
	Items.EquipmentContextMenuUncheckAll.Enabled      = True;
	
	Items.ToBegin.Enabled              = True;
	Items.ExitApp.Enabled           = False;
	
	State = NStr("vi = 'Trao đổi đã kết thúc';
				|ru = 'Обмен завершен';
				|en = 'Exchange completed'; fa = 'Exchange completed';
				|it = 'Scambio effettuato';
				|pl = 'Wymiana została zakończona';
				|tr = 'Değişim tamamlandı'");
	
	DetachIdleHandler("WaitHandlerExchange");
	
	ExchangeIsInProgress = False;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If ExchangeIsInProgress Then
		
		Cancel = True;
		ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject), 
			NStr("vi = 'Sau khi đóng, việc trao đổi với thiết bị sẽ không được thực hiện. Đóng và ngừng trao đổi?';
				|ru = 'После закрытия обмен с оборудованием выполняться не будет. Закрыть и остановить обмен?';
				|en = 'Exchange with the equipment will not be executed after closing. Close and stop the exchange?'; fa = 'Exchange with the equipment will not be executed after closing. Close and stop the exchange?';
				|it = 'Dopo la chiusura, lo scambio con l''apparecchiatura non sarà eseguito. Chiudere e interrompere lo scambio?';
				|pl = 'Po zamknięciu wymiana z urządzeniem nie zostanie wykonana. Zamknij i przestań udostępniać?';
				|tr = 'Kapanış sonrası ekipman ile değişim yapılmayacaktır. Değişim kapatılıp ve durdurulsun mu?'"), 
			QuestionDialogMode.YesNo);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		ExchangeIsInProgress = False;
		Close();
	EndIf;

EndProcedure

&AtClient
Procedure CheckAll(Command)
	CheckBoxesOnServer();
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	UncheckBoxesOnServer();
EndProcedure

&AtClient
Procedure ExecuteNow(Command)
	
	State = NStr("vi = 'Đang thực hiện trao đổi với thiết bị bán hàng...';
				|ru = 'Выполняется обмен с подключенным оборудованием...';
				|en = 'Performing data exchange with peripherals...'; fa = 'Performing data exchange with peripherals...';
				|it = 'Scambio con connessione dell''apparecchiatura in corso...';
				|pl = 'Trwa wymiana z urządzeniem peryferyjnym...';
				|tr = 'Bağlanan ekipman ile değişim gerçekleştiriliyor...'");
	ExecuteExchange();
	State = NStr("vi = 'Trao đổi đã kết thúc';
				|ru = 'Обмен завершен';
				|en = 'Exchange completed'; fa = 'Exchange completed';
				|it = 'Scambio effettuato';
				|pl = 'Wymiana została zakończona';
				|tr = 'Değişim tamamlandı'");
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region Other

&AtClient
Procedure ExecuteExchange()
	
	For Each TSRow In Equipment Do
		
		If Not TSRow.PerformAnExchange Then
			Continue;
		EndIf;
		
		DeviceArray = New Array;
		DeviceArray.Add(TSRow.Device);
		
		// UPLOADING DATA
		If TSRow.EquipmentType = PredefinedValue("Enum.PeripheralTypes.LabelPrintingScales") Then
			OfflinePeripheralsClient.ExportGoodsToScales(
				New CallbackDescription("UploadGoodsCompletion", ThisObject, TSRow),
				DeviceArray,
				False);
		EndIf;
		
		
	EndDo;
	
EndProcedure

&AtClient
Procedure UploadGoodsCompletion(Result, TSRow) Export

	TSRow.ExportState      = Result.MessageText;
	TSRow.ExportPictureIndex = ?(Result.Completed2 > 0, 1, 0);
	TSRow.ExportEndDate = CurrentDate();

EndProcedure

&AtClient
Procedure AfterPerformingExchange(Result, TSRow) Export
	
	If TypeOf(Result) = Type("Structure")
		And Result.Property("ErrorDescription")
		And Result.Property("Result") Then
		
		TSRow.ExportState      = Result.ErrorDescription;
		TSRow.ExportPictureIndex = ?(Result.Result, 1, 0);
		TSRow.ExportEndDate = CurrentDate();
	EndIf;
	
EndProcedure

&AtClient
Procedure WaitHandlerExchange()
	
	ExecuteExchange();
	
	DetachIdleHandler("WaitHandlerExchange");
	AttachIdleHandler("WaitHandlerExchange", ExchangeFrequency * 60, False);
	
EndProcedure

&AtServer
Procedure CheckBoxesOnServer()
	
	For Each TSRow In Equipment Do
		TSRow.PerformAnExchange = True;
	EndDo;
	
EndProcedure

&AtServer
Procedure UncheckBoxesOnServer()
	
	For Each TSRow In Equipment Do
		TSRow.PerformAnExchange = False;
	EndDo;
	
EndProcedure

&AtServer
Function ThereIsEquipmentForExchange()
	
	Return Equipment.FindRows(New Structure("PerformAnExchange", True)).Count() > 0;
	
EndFunction

#EndRegion

#EndRegion
