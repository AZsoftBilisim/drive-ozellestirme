
#Region Public

// Fills in the structure of additional parameters of the operation on the Equipment.
//
// Parameters:
//  LabelDescriptionInHTML - String - XML description of the label layout
//  DataForPrint - Array
// 
// Returns:
//  Structure
//
Function LabelPrintingOperationParameters(LabelDescriptionInHTML = Undefined, DataForPrint = Undefined) Export
	
	Result = New Structure();
	Result.Insert("LabelDescriptionInHTML", LabelDescriptionInHTML);
	Result.Insert("DataForPrint"     , DataForPrint);
	Return Result;
	
EndFunction

// Start printing labels.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartPrintingLabels(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, AdditionalParameters = Undefined) Export
	
	OperationContext = New Structure();
	OperationContext.Insert("NotificationOnCompletion", NotificationOnCompletion);
	OperationContext.Insert("ClientID"   , ClientID);   
	OperationContext.Insert("DeviceID", DeviceID);
	OperationContext.Insert("OperationParametersList"      , OperationParametersList);
	OperationContext.Insert("AdditionalParameters", AdditionalParameters); 
	OperationContext.Insert("PrepareData"      , True); 
	OperationContext.Insert("ProcessData__"       , False); 
	OperationContext.Insert("Command"  , "PrintLabels"); 
	OperationContext.Insert("Result", True);
	
	If DeviceID = Undefined Or  IsBlankString(DeviceID) Then
		
		SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
		SupportedTypes.LabelPrinters = True;
		
		Notification = New CallbackDescription("StartOperationCompletion", ThisObject, OperationContext);
		EquipmentManagerClient.SelectDevice(Notification, SupportedTypes,
			NStr("vi = 'Hãy chọn máy in nhãn tem';
				|ru = 'Выберите принтер этикеток';
				|en = 'Select label printer'; fa = 'Select label printer';
				|it = 'Selezionare la stampante di etichette';
				|pl = 'Wybierz drukarkę etykiet';
				|tr = 'Etiket yazıcısı seçin'"),
			NStr("vi = 'Chưa kết nối máy in nhãn tem.';
				|ru = 'Принтер этикеток не подключен.';
				|en = 'Label printer is not connected.'; fa = 'Label printer is not connected.';
				|it = 'La stampante di etichette non è collegata.';
				|pl = 'Drukarka etykiet nie jest podłączona.';
				|tr = 'Etiket yazıcısı bağlı değil.'"), 
			NStr("vi = 'Chưa chọn máy in nhãn tem.';
				|ru = 'Принтер этикеток не выбран.';
				|en = 'Label printer is not selected.'; fa = 'Label printer is not selected.';
				|it = 'La stampante di etichette non è selezionata.';
				|pl = 'Drukarka etykiet nie jest wybrana.';
				|tr = 'Etiket yazıcısı seçili değil.'"));
	Else
		StartOperationCompletion(OperationContext, OperationContext);
		
	EndIf
	
EndProcedure

// To start the initialization of the label printer.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartInitializingLabelPrinter(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList = Undefined, AdditionalParameters = Undefined) Export
	
	OperationContext = New Structure();
	OperationContext.Insert("NotificationOnCompletion", NotificationOnCompletion);
	OperationContext.Insert("ClientID"   , ClientID);   
	OperationContext.Insert("DeviceID", DeviceID);
	OperationContext.Insert("OperationParametersList"      , OperationParametersList);
	OperationContext.Insert("AdditionalParameters", AdditionalParameters); 
	OperationContext.Insert("PrepareData"      , False); 
	OperationContext.Insert("ProcessData__"       , False); 
	OperationContext.Insert("Command"  , "InitializePrinter"); 
	OperationContext.Insert("Result", True);
	
	If DeviceID = Undefined Or  IsBlankString(DeviceID) Then
		
		SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
		SupportedTypes.LabelPrinters = True;
		
		Notification = New CallbackDescription("StartOperationCompletion", ThisObject, OperationContext);
		EquipmentManagerClient.SelectDevice(Notification, SupportedTypes,
			NStr("vi = 'Hãy chọn máy in nhãn tem';
				|ru = 'Выберите принтер этикеток';
				|en = 'Select label printer'; fa = 'Select label printer';
				|it = 'Selezionare la stampante di etichette';
				|pl = 'Wybierz drukarkę etykiet';
				|tr = 'Etiket yazıcısı seçin'"),
			NStr("vi = 'Chưa kết nối máy in nhãn tem.';
				|ru = 'Принтер этикеток не подключен.';
				|en = 'Label printer is not connected.'; fa = 'Label printer is not connected.';
				|it = 'La stampante di etichette non è collegata.';
				|pl = 'Drukarka etykiet nie jest podłączona.';
				|tr = 'Etiket yazıcısı bağlı değil.'"), 
			NStr("vi = 'Chưa chọn máy in nhãn tem.';
				|ru = 'Принтер этикеток не выбран.';
				|en = 'Label printer is not selected.'; fa = 'Label printer is not selected.';
				|it = 'La stampante di etichette non è selezionata.';
				|pl = 'Drukarka etykiet nie jest wybrana.';
				|tr = 'Etiket yazıcısı seçili değil.'"));
	Else
		StartOperationCompletion(OperationContext, OperationContext);
	EndIf
	
EndProcedure

// Start editing the layout.
//
// Parameters:
//  NotificationWhenEditingIsCompleted - CallbackDescription 
//  LabelDescriptionInHTML - String - XML description of the label layout
//  DCSStorageAddress - String
//  AddressOfTemplate - String
//
Procedure StartEditingTemplate(NotificationWhenEditingIsCompleted, LabelDescriptionInHTML, DCSStorageAddress, AddressOfTemplate = "") Export
	
	Context = New Structure;
	Context.Insert("NextAlert", NotificationWhenEditingIsCompleted);
	Context.Insert("XMLTemplateDetails"  , LabelDescriptionInHTML);
	Context.Insert("AddressOfTemplate", AddressOfTemplate);
	NotificationOnCompletion = New CallbackDescription("StartEditingTemplate_Completion", ThisObject, Context);
	
	FormName = "Catalog.TemplatesOfPLLabelsAndPriceTags.Form.LabelEditorFormOfTemplateEditing";
	Try
		OpenForm(FormName, New Structure("DCSStorageAddress, AddressOfTemplate", DCSStorageAddress, AddressOfTemplate),,,,, NotificationOnCompletion);
	Except
		// APK: 374-off warning about critical actions
		MessageText = NStr("vi = 'Không thể sử dụng bộ soạn nhãn tem! Không hỗ trợ tính năng này.';
							|ru = 'Использование редактора этикеток невозможно! Функциональность не поддерживается.';
							|en = 'Label editor is not available. The functionality is not supported.'; fa = 'Label editor is not available. The functionality is not supported.';
							|it = 'Non è possibile utilizzare l''editor di etichette! La funzionalità non è supportata.';
							|pl = 'Używanie edytora etykiet jest niemożliwe! Funkcjonalność nie jest obsługiwana.';
							|tr = 'Etiket düzenleyicisinin kullanımı mümkün değil! İşlev desteklenmiyor.'");
		CommonCELClient.MessageToUser(MessageText);
		// APK: 374-on
	EndTry;
	
EndProcedure

// Completing Layout editing
//
// Parameters:
//  Result - Structure
//  AdditionalParameters - Structure
//
Procedure StartEditingTemplate_Completion(Result, AdditionalParameters) Export
	
	AddlParameters = New Structure;
	AddlParameters.Insert("TemplateSize",      ?(Result <> Undefined, AdditionalParameters.TemplateSize, Undefined));
	AddlParameters.Insert("XMLTemplateDetails", ?(Result <> Undefined, AdditionalParameters.XMLTemplateDetails, Undefined));
	AddlParameters.Insert("Fields",              ?(Result <> Undefined, AdditionalParameters.Fields, Undefined));
	AddlParameters.Insert("Template",             ?(Result <> Undefined, AdditionalParameters.Template, Undefined));
	
	CallbackDescription = New CallbackDescription(AdditionalParameters.NextAlert.ProcedureName, AdditionalParameters.NextAlert.Module, AddlParameters);
	RunCallback(CallbackDescription, ?(Result <> Undefined, Result, DialogReturnCode.Cancel));
	
EndProcedure

#EndRegion

#Region Private

Procedure StartOperationCompletion(SelectionResult, OperationContext) Export
	
	If SelectionResult.Result Then 
		ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution(OperationContext.Command, "PeripheralsLabelPrintersServer",
		OperationContext.AdditionalParameters, OperationContext.PrepareData, OperationContext.ProcessData__);
		EquipmentManagerClient.StartCommandExecution(OperationContext.NotificationOnCompletion, OperationContext.ClientID, 
			SelectionResult.DeviceID, OperationContext.OperationParametersList, ParametersCommandExecution);
	Else
		RunCallback(OperationContext.NotificationOnCompletion, SelectionResult);
	EndIf;
	
EndProcedure

#EndRegion