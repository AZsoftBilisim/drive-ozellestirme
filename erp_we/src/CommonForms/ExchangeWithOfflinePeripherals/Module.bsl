
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Items.LocalizationPageOfflineCashRegister.Visible = False;
	CustomizeFormElementsLocalization();
	
	Workplace = EquipmentManagerServerCall.GetClientSWorkplace();
	
	Scales.Parameters.SetParameterValue("CurrentWorkplace", Workplace);
	CashRegisters.Parameters.SetParameterValue("CurrentWorkplace", Workplace);
	
	Items.CashRegistersCheckoutProductsDownloadRetailSalesReport.Enabled = AccessRight("Insert", Metadata.Documents.RetailSalesReport);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	KKMOfflineWarehouse = Settings.Get("KKMOfflineWarehouse");
	WarehouseScales = Settings.Get("WarehouseScales");
	
	LibraExchangeRule = Settings.Get("LibraExchangeRule");
	KKMOfflineExchangeRule = Settings.Get("KKMOfflineExchangeRule");
	
	CommonClientServer.SetDynamicListFilterItem(CashRegisters, "Warehouse", KKMOfflineWarehouse, DataCompositionComparisonType.Equal,, ValueIsFilled(KKMOfflineWarehouse));
	CommonClientServer.SetDynamicListFilterItem(CashRegisters, "ExchangeRule", KKMOfflineExchangeRule, DataCompositionComparisonType.Equal,, ValueIsFilled(KKMOfflineExchangeRule));
	CommonClientServer.SetDynamicListFilterItem(Scales, "Warehouse", WarehouseScales, DataCompositionComparisonType.Equal,, ValueIsFilled(WarehouseScales));
	CommonClientServer.SetDynamicListFilterItem(Scales, "ExchangeRule", LibraExchangeRule, DataCompositionComparisonType.Equal,, ValueIsFilled(LibraExchangeRule));
	
	CommonClientServer.SetDynamicListFilterItem(Scales, "ConnectedToTheCurrentWorkplace", True, DataCompositionComparisonType.Equal,, AllEquipmentScales = False);
	CommonClientServer.SetDynamicListFilterItem(CashRegisters, "ConnectedToTheCurrentWorkplace", True, DataCompositionComparisonType.Equal,, AllKKMOfflineEquipment = False);
	
EndProcedure // prizagruzkedannyhiznastroeknaver()

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "ChangedCurSessionWorkplace" Then
		
		Workplace = EquipmentManagerServerCall.GetClientSWorkplace();
		
		Scales.Parameters.SetParameterValue("CurrentWorkplace", Workplace);
		CashRegisters.Parameters.SetParameterValue("CurrentWorkplace", Workplace);
		
	ElsIf EventName = "Write_RulesOfExchangeWithOfflinePeripherals"
		Or EventName = "Recording_ProductCodesForConnectedEquipment" Then
		
		Items.Scales.Refresh();
		Items.CashRegisters.Refresh();
		
	ElsIf EventName = "ExchangeWithConnectedEquipmentOfflineIsExecuted" Then
		
		Items.Scales.Refresh();
		Items.CashRegisters.Refresh();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure LibraViewTheListOfProducts(Command)
	
	CurrentData = Items.Scales.CurrentData;
	If CurrentData <> Undefined And ValueIsFilled(CurrentData.ExchangeRule) Then
		
		FormParameters = New Structure("Device, ExchangeRule", CurrentData.Peripherals, CurrentData.ExchangeRule);
		OpenForm("InformationRegister.ItemsIDOfPeripheralsOffline.Form.GoodsList", FormParameters, UUID);
		
	Else
		
		ShowMessageBox(Undefined, NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng được chọn';
										|ru = 'Команда не может быть выполнена для указанного объекта';
										|en = 'Cannot execute the command for the specified object'; fa = 'Cannot execute the command for the specified object';
										|it = 'Il comando non può essere eseguito per l''oggetto indicato';
										|pl = 'Polecenie nie może zostać wykonane dla wskazanego obiektu';
										|tr = 'Komut belirtilen nesne için gerçekleştirilemez'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LibraAssignARuleToTheSelectedOnes(Command)
	
	Devices = New Array;
	For Each SelectedRow In Items.Scales.SelectedRows Do
		Devices.Add(SelectedRow);
	EndDo;
	
	If Devices.Count() > 0 Then
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("PeripheralType", PredefinedValue("Enum.PeripheralTypes.LabelPrintingScales"));
		ExchangeRule = Undefined;

		OpenForm("Catalog.RulesOfExchangeWithOfflinePeripherals.ChoiceForm", OpeningParameters, UUID,,,, New CallbackDescription("LibraAssignARuleToTheSelectedOnesCompletion", ThisObject, New Structure("Devices", Devices)), FormWindowOpeningMode.LockWholeInterface);
		
	Else
		
		ShowMessageBox(Undefined, NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng được chọn';
										|ru = 'Команда не может быть выполнена для указанного объекта';
										|en = 'Cannot execute the command for the specified object'; fa = 'Cannot execute the command for the specified object';
										|it = 'Il comando non può essere eseguito per l''oggetto indicato';
										|pl = 'Polecenie nie może zostać wykonane dla wskazanego obiektu';
										|tr = 'Komut belirtilen nesne için gerçekleştirilemez'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LibraAssignARuleToTheSelectedOnesCompletion(Result, AdditionalParameters) Export
    
    Devices = AdditionalParameters.Devices;
    
    
    ExchangeRule = Result;
    
    If ValueIsFilled(ExchangeRule) Then
        AssignRuleForDedicatedDevicesOnServer(Devices, ExchangeRule);
    EndIf;
    
    Items.Scales.Refresh();

EndProcedure

&AtClient
Procedure ScalesGoodsUnload(Command)
	
	CurrentData = Items.Scales.CurrentData;
	If CurrentData <> Undefined And ValueIsFilled(CurrentData.ExchangeRule) Then
		
		Devices = New Array;
		Devices.Add(CurrentData.Peripherals);
		OfflinePeripheralsClient.ExportGoodsToScales(Undefined, Devices);

	Else
		
		ShowMessageBox(Undefined, NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng được chọn';
										|ru = 'Команда не может быть выполнена для указанного объекта';
										|en = 'Cannot execute the command for the specified object'; fa = 'Cannot execute the command for the specified object';
										|it = 'Il comando non può essere eseguito per l''oggetto indicato';
										|pl = 'Polecenie nie może zostać wykonane dla wskazanego obiektu';
										|tr = 'Komut belirtilen nesne için gerçekleştirilemez'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LibraGoodsClear(Command)
	
	CurrentData = Items.Scales.CurrentData;
	If CurrentData <> Undefined And ValueIsFilled(CurrentData.ExchangeRule) Then
		
		Devices = New Array;
		Devices.Add(CurrentData.Peripherals);
		OfflinePeripheralsClient.ClearGoodsInLibra(Undefined, Devices);
	
	Else
		
		ShowMessageBox(Undefined, NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng được chọn';
										|ru = 'Команда не может быть выполнена для указанного объекта';
										|en = 'Cannot execute the command for the specified object'; fa = 'Cannot execute the command for the specified object';
										|it = 'Il comando non può essere eseguito per l''oggetto indicato';
										|pl = 'Polecenie nie może zostać wykonane dla wskazanego obiektu';
										|tr = 'Komut belirtilen nesne için gerçekleştirilemez'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LibraGoodsReload(Command)
	
	CurrentData = Items.Scales.CurrentData;
	If CurrentData <> Undefined And ValueIsFilled(CurrentData.ExchangeRule) Then
		
		Devices = New Array;
		Devices.Add(CurrentData.Peripherals);
		OfflinePeripheralsClient.UploadFullListOfProductsToLibra(Undefined, Devices);
	
	Else
		
		ShowMessageBox(Undefined, NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng được chọn';
										|ru = 'Команда не может быть выполнена для указанного объекта';
										|en = 'Cannot execute the command for the specified object'; fa = 'Cannot execute the command for the specified object';
										|it = 'Il comando non può essere eseguito per l''oggetto indicato';
										|pl = 'Polecenie nie może zostać wykonane dla wskazanego obiektu';
										|tr = 'Komut belirtilen nesne için gerçekleştirilemez'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LibraOpenExchangeRule(Command)
	
	CurrentData = Items.Scales.CurrentData;
	If CurrentData <> Undefined And ValueIsFilled(CurrentData.ExchangeRule) Then
		
		ShowValue(Undefined, CurrentData.ExchangeRule);
		
	Else
		
		ShowMessageBox(Undefined, NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng được chọn';
										|ru = 'Команда не может быть выполнена для указанного объекта';
										|en = 'Cannot execute the command for the specified object'; fa = 'Cannot execute the command for the specified object';
										|it = 'Il comando non può essere eseguito per l''oggetto indicato';
										|pl = 'Polecenie nie może zostać wykonane dla wskazanego obiektu';
										|tr = 'Komut belirtilen nesne için gerçekleştirilemez'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExportSettings(Command)
	
	
EndProcedure

&AtClient
Procedure CheckoutViewTheListOfProducts(Command)
	
	
EndProcedure

&AtClient
Procedure CheckoutAssignARuleForTheSelectedOnes(Command)
	
	
EndProcedure

&AtClient
Procedure CashRegisterProductsUnload(Command)
	
	
EndProcedure

&AtClient
Procedure CashRegisterItemsClear(Command)
	
	
EndProcedure

&AtClient
Procedure CheckoutProductsRestart(Command)
	
	
EndProcedure

&AtClient
Procedure CheckoutProductsDownloadRetailSalesReport(Command)
	
	
EndProcedure

&AtClient
Procedure CheckoutOpenExchangeRule(Command)
	
	
EndProcedure

&AtClient
Procedure AutoExchange(Command)
	
	FormParameters = New Structure("Workplace", Workplace);
	OpenForm("CommonForm.AutomaticExchangeWithOfflinePeripherals", FormParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarehouseScalesOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(Scales, "Warehouse", WarehouseScales, DataCompositionComparisonType.Equal,, ValueIsFilled(WarehouseScales));
	
EndProcedure

&AtClient
Procedure LibraExchangeRuleOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(Scales, "ExchangeRule", LibraExchangeRule, DataCompositionComparisonType.Equal,, ValueIsFilled(LibraExchangeRule));
	
EndProcedure

&AtClient
Procedure EquipmentScalesOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(Scales, "ConnectedToTheCurrentWorkplace", True, DataCompositionComparisonType.Equal,, AllEquipmentScales = False);
	
EndProcedure

&AtClient
Procedure KKMOfflineWarehouseOnChange(Item)
	
	
EndProcedure

&AtClient
Procedure KKMOfflineExchangeRuleOnChange(Item)
	
	
EndProcedure

&AtClient
Procedure KkmofflineEquipmentOnChange(Item)
	
	
EndProcedure

&AtClient
Procedure CashRegistersSelection(Item, RowSelected, Field, StandardProcessing)
	
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure AssignRuleForDedicatedDevicesOnServer(Devices, ExchangeRule)
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		
		For Each Device In Devices Do
			
			DeviceObject = Device.GetObject(); // A reference object.Plug-in equipment, directory object.Offline equipment
			DeviceObject.ExchangeRule = ExchangeRule;
			DeviceObject.Write();
			
		EndDo;
		
		CommitTransaction();
	Except
		
		RollbackTransaction();
		
		WriteLogEvent(NStr("vi = 'Bán lẻ';
							|ru = 'Розничные продажи';
							|en = 'Retail sales'; fa = 'فروش خرده‌فروشی';
							|it = 'Vendite al dettaglio';
							|pl = 'Sprzedaże detaliczne';
							|tr = 'Perakende satışlar'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
EndProcedure

&AtServer
Procedure CustomizeFormElementsLocalization()
	
	
EndProcedure


#EndRegion
