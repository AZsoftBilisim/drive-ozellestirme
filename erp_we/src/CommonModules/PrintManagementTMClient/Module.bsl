
#Region Public

// Called from the handler of the pluggable_processingavigation Link of the document printing form (General Form.Print documents).
// Allows you to implement a handler for clicking a hyperlink that is added to the form 
// using the print Managementdefinable.Printdocumentsreferences in the server.
//
// Parameters:
//  Form                - ClientApplicationForm - General Form.Print documents.
//  Item              - FormField - the form element that triggered this event.
//  FormattedStringURL - String - value of the formatted string hyperlink. Passed by reference.
//  StandardProcessing - Boolean - indicates whether standard (system) event processing is performed. If the
//                                  value is set to False, the standard event processing will not be performed.
//
Procedure PrintDocumentsURLProcessing(Form, Item, FormattedStringURL, StandardProcessing) Export

	
EndProcedure

// Called from the Plug-in handler_Execute the document printing form command (General Form.Print documents).
// Allows you to implement the client part of the command handler that is added to the form 
// using the print Managementdefinable.Printdocumentsreferences in the server.
//
// Parameters:
//  Form                         - ClientApplicationForm - General Form.Print documents.
//  Command                       - FormCommand     - executed command.
//  ContinueExecutionAtServer - Boolean - if the value is set to True, the handler execution will continue in
//                                           the server context in the print management procedure Undefined.Print documentsperformance of the command.
//  AdditionalParameters       - Arbitrary - parameters to pass to the server context.
//
// Example:
//  If the Command.Name = "My Team" Then
//   Printform Setup = Print Control Client.Customizingcurrent Printing Form(Form);
//   
//   Additional parameters = New Structure;
//   Additional parameters.Insert("Command Name", Command.Name);
//   Additional parameters.Insert("Requesitatablecode Document name", Printform setting.ReqUisitname);
//   Additional parameters.Insert("Name of the printing form", setting up the printing form.Name);
//   
//   Continue executing the Server = True;
//  The end if;
//
Procedure PrintDocumentsExecuteCommand(Form, Command, ContinueExecutionAtServer, AdditionalParameters) Export

	
EndProcedure

// Called from the message Processing handler of the print Documents form.
// Allows you to implement an external event handler in the form.
//
// Parameters:
//  Form      - ClientApplicationForm - General Form.Print documents.
//  EventName - String - notification ID.
//  Parameter   - Arbitrary - custom notification parameter.
//  Source   - Arbitrary - event source.
//
Procedure PrintDocumentsNotificationProcessing(Form, EventName, Parameter, Source) Export

	
EndProcedure

#Region LabelsAndPriceTags

// Retrieves data for printing and opens the Processing form.Print the price tags.Form.Formatovani.
//
// Parameters:
//	CommandDetails - Structure - structure with a description of the team.
//
// Returns:
//	Undefined
//
Function PrintPriceTagsAndLabels(CommandDetails) Export
	
	AdditionalParameters = New Structure("PrintManager", CommandDetails.PrintManager);
	
	AddressInStorage =
		PrintManagementTMServerCall.DataForPrintingPriceTagsAndLabels(
			CommandDetails.Id,
			CommandDetails.PrintObjects,
			AdditionalParameters);
	
	OpenForm(
		"DataProcessor.PrintPriceTagsAndLabels.Form.FormGoods",
		New Structure("AddressInStorage, TemplateAssignment", AddressInStorage, Undefined),
		CommandDetails.Form,
		New UUID);
	
EndFunction

// Retrieves data for printing and opens the Processing form.Print the price tags.Form.Formattedmessage.
//
// Parameters:
//	CommandDetails - Structure - structure with a description of the team.
//
// Returns:
//	Undefined
//
Function LabelPrintingStorageCells(CommandDetails) Export
	
	AddressInStorage =
		PrintManagementTMServerCall.LabelPrintingDataStorageCells(
			CommandDetails.Id,
			CommandDetails.PrintObjects);
	
	OpenForm(
		"DataProcessor.PrintPriceTagsAndLabels.Form.StorageBinsForm",
		New Structure("AddressInStorage, TemplateAssignment", AddressInStorage, Undefined),
		CommandDetails.Form,
		New UUID);
	
EndFunction

// Printing delivery labels.
//
// Parameters:
//	CommandDetails - Structure - structure with a description of the team.
//
// Returns:
//	Undefined
//
Function PrintingShippingLabels(CommandDetails) Export
	
	ClearMessages();
	
	ReturnStructure = PrintManagementTMServerCall.ShippingLabelPrintingData(CommandDetails.Id,
		CommandDetails.PrintObjects);
	
	If ReturnStructure.ThereAreLabelsToPrint Then
		
		CommandParameter = New Array;
		CommandParameter.Add(PredefinedValue("Catalog.Products.EmptyRef"));
		
		PrintParameters = New Structure("AddressInStorage, StructureOfTemplateTemplate",
			ReturnStructure.AddressInStorage, Undefined);
		
		PrintManagementClient.ExecutePrintCommand("DataProcessor.PrintPriceTagsAndLabels", "ShippingLabel",
			CommandParameter, Undefined, PrintParameters);
		
	ElsIf ReturnStructure.DeliveryToOurWarehouse Then
		CommonClientServer.MessageToUser(NStr("vi = 'Cho phép in nhãn tem chỉ để giao hàng từ kho chúng ta.';
												|ru = 'Печать этикетки доступна только для доставки с нашего склада.';
												|en = 'You can print a label only for delivery from our warehouse.'; fa = 'You can print a label only for delivery from our warehouse.';
												|it = 'La stampa delle etichette è disponibile solo per la consegna dal nostro magazzino.';
												|pl = 'Wydruk etykiety jest dostępna tylko dla dostawy z naszego magazynu.';
												|tr = 'Etiket yazdırması sadece ambardan teslimat için mevcuttur.'"));	
	Else
		CommonClientServer.MessageToUser(NStr("vi = 'Mẫu in không sử dụng được.';
												|ru = 'Печатная форма недоступна.';
												|en = 'Print form is unavailable.'; fa = 'Print form is unavailable.';
												|it = 'Modulo di stampa non disponibile.';
												|pl = 'Formularz wydruku jest niedostępny.';
												|tr = 'Yazdırma formu mevcut değil.'"));
	EndIf;
	
	If ReturnStructure.ArrayOfLinksWithErrors.Count() > 0 Then
		MessageText = NStr("vi = 'Chưa tùy chỉnh khuôn mẫu nhãn tem giao hàng. Hãy liên hệ với người quản trị.';
							|ru = 'Не настроен общий шаблон этикетки доставки. Обратитесь к администратору.';
							|en = 'Common delivery label template is not configured. Please contact the administrator.'; fa = 'Common delivery label template is not configured. Please contact the administrator.';
							|it = 'Modello standard di etichetta di consegna non impostato. Rivolgersi all''amministratore.';
							|pl = 'Nie został skonfigurowany szablon etykiety dostawy. Skontaktuj się z administratorem.';
							|tr = 'Genel teslimat etiket numunesi ayarlanmadı. Yöneticiyle iletişime geç.'");
		
		CommonClientServer.MessageToUser(MessageText);
	EndIf;
	
	For Each CarrierLink In ReturnStructure.ArrayOfCarriersWithoutLabelTemplates Do
		If ValueIsFilled(CarrierLink) Then
			MessageText = NStr("vi = 'Đối với người vận chuyển ""%Carrier%"", chưa điền khuôn mẫu nhãn tem giao hàng.';
								|ru = 'Для перевозчика ""%Carrier%"" не заполнен шаблон этикетки доставки.';
								|en = 'Delivery label template is not filled in for the ""%Carrier%"" carrier.'; fa = 'Delivery label template is not filled in for the ""%Carrier%"" carrier.';
								|it = 'Modello standard di etichetta non compilato per il fornitore ""%Carrier%""';
								|pl = 'Dla przewoźnika ""%Carrier%"" nie jest wypełniony szablon etykiety dostawy.';
								|tr = 'Teslimat etiket numunesi ""%Carrier%"" taşıyıcısı için doldurulmadı.'");
			MessageText = StrReplace(MessageText, "%Carrier%", CarrierLink);
			
			CommonClientServer.MessageToUser(MessageText);
		EndIf;
	EndDo;
	
	For Each LinkOrder In ReturnStructure.ArrayOfLinksWithErrors Do
		MessageText = NStr("vi = 'Không thể in nhãn tem vận chuyển đối với chứng từ ""%ReferenceOrder%"".';
							|ru = 'Не удалось напечатать этикетку доставки для документа ""%ReferenceOrder%"".';
							|en = 'Cannot print delivery label for document ""%ReferenceOrder%"".'; fa = 'Cannot print delivery label for document ""%ReferenceOrder%"".';
							|it = 'Non è stato possibile stampare l''etichetta di consegna per il documento ""%ReferenceOrder%"".';
							|pl = 'Nie udało się wydrukować etykietę dostawy dla dokumentu ""%ReferenceOrder%"".';
							|tr = '""%ReferenceOrder%"" belgesi için bir teslimat etiketi yazdırılamadı.'");
		MessageText = StrReplace(MessageText, "%ReferenceOrder%", LinkOrder);
		
		CommonClientServer.MessageToUser(MessageText);
	EndDo;
	
	If ReturnStructure.Property("ArrayOfTasksWithoutOrders") Then
		For Each TransportationJob In ReturnStructure.ArrayOfTasksWithoutOrders Do
			MessageText = NStr("vi = 'Trong chứng từ ""%TransportationJob%"" không có lệnh mà đối với chúng có thể in nhãn tem giao hàng.';
								|ru = 'В документе ""%TransportationJob%"" отсутствуют распоряжения, для которых можно распечатать этикетки доставки.';
								|en = 'No references for which delivery labels can be printed in the ""%TransportationJob%"" document.'; fa = 'No references for which delivery labels can be printed in the ""%TransportationJob%"" document.';
								|it = 'Nel documento ""%TransportationJob%"" mancano dli ordini per i quali è possibile stampare le etichette di consegna.';
								|pl = 'W dokumencie ""%TransportationJob%"" brak zamówień, dla których można wydrukować etykiety dostawy.';
								|tr = '""%TransportationJob%"" belgesinde teslimat etiketlerinin yazdırılabileceği sipariş mevcut değil.'");
			MessageText = StrReplace(MessageText, "%TransportationJob%", TransportationJob);
			
			CommonClientServer.MessageToUser(MessageText);
		EndDo;
	EndIf;
	
EndFunction

// Printing labels for packing lists.
//
// Parameters:
//	CommandDetails - Structure - structure with a description of the team.
//
// Returns:
//	Undefined
//
Function PrintingLabelsPackingSheets(CommandDetails) Export
	
	ReturnStructure = PrintManagementTMServerCall.LabelPrintingDataPackingSheets(CommandDetails.PrintObjects);
		
	If Not ReturnStructure.ThereIsLabelTemplate Then
		MessageText = NStr("vi = 'Chưa tùy chỉnh khuôn mẫu chung của nhãn tem phiếu đóng gói. Hãy liên hệ với người quản trị.';
							|ru = 'Не настроен общий шаблон этикетки упаковочного листа. Обратитесь к администратору.';
							|en = 'Common template of packing list label is not configured. Please contact the administrator.'; fa = 'Common template of packing list label is not configured. Please contact the administrator.';
							|it = 'Modello standard di etichetta per la distinta di imballaggio non impostato. Rivolgersi all''amministratore.';
							|pl = 'Nie jest skonfigurowany szablon etykiety listy pakowej. Skontaktuj się z administratorem.';
							|tr = 'Genel ürün listesi etiket numunesi ayarlanmadı. Yöneticiyle iletişime geç.'");
		CommonClientServer.MessageToUser(MessageText);
	EndIf;
	
	If Not ReturnStructure.ThereAreLabelsToPrint Then
		CommonClientServer.MessageToUser(NStr("vi = 'Không sử dụng được mẫu in.';
												|ru = 'Печатная форма недоступна.';
												|en = 'Print form is unavailable.'; fa = 'Print form is unavailable.';
												|it = 'Modulo di stampa non disponibile.';
												|pl = 'Formularz wydruku jest niedostępny.';
												|tr = 'Yazdırma formu mevcut değil.'"));
	EndIf;
	
	If ReturnStructure.ThereAreLabelsToPrint And ReturnStructure.ThereIsLabelTemplate Then
		
		PrintManagementClient.ExecutePrintCommand(
			"DataProcessor.PrintPriceTagsAndLabels",
			"LabelPackingSheets",
			CommandDetails.PrintObjects,
			Undefined,
			New Structure(
				"AddressInStorage, LabelsTemplate, Copies",
				ReturnStructure.AddressInStorage, ReturnStructure.LabelsTemplate, 1));
		
	EndIf;
		
EndFunction

// Print labels of packing lists directly to the printer.
//
// Parameters:
//	CommandDetails - Structure - structure with a description of the team.
//
// Returns:
//	Undefined
//
Function PrintingLabelsOfPackingSheetsOnPrinter(CommandDetails) Export
	
	ReturnStructure = PrintManagementTMServerCall.LabelPrintingDataPackingSheets(CommandDetails.PrintObjects);
		
	If Not ReturnStructure.ThereIsLabelTemplate Then
		MessageText = NStr("vi = 'Chưa tùy chỉnh khuôn mẫu chung của nhãn tem phiếu đóng gói. Hãy liên hệ với người quản trị.';
							|ru = 'Не настроен общий шаблон этикетки упаковочного листа. Обратитесь к администратору.';
							|en = 'Common template of packing list label is not configured. Please contact the administrator.'; fa = 'Common template of packing list label is not configured. Please contact the administrator.';
							|it = 'Modello standard di etichetta per la distinta di imballaggio non impostato. Rivolgersi all''amministratore.';
							|pl = 'Nie jest skonfigurowany szablon etykiety listy pakowej. Skontaktuj się z administratorem.';
							|tr = 'Genel ürün listesi etiket numunesi ayarlanmadı. Yöneticiyle iletişime geç.'");
		CommonClientServer.MessageToUser(MessageText);
	EndIf;
	
	If Not ReturnStructure.ThereAreLabelsToPrint Then
		CommonClientServer.MessageToUser(NStr("vi = 'Không sử dụng được mẫu in.';
												|ru = 'Печатная форма недоступна.';
												|en = 'Print form is unavailable.'; fa = 'Print form is unavailable.';
												|it = 'Modulo di stampa non disponibile.';
												|pl = 'Formularz wydruku jest niedostępny.';
												|tr = 'Yazdırma formu mevcut değil.'"));
	EndIf;
	
	If ReturnStructure.ThereAreLabelsToPrint And ReturnStructure.ThereIsLabelTemplate Then
		
		PrintManagementClient.ExecutePrintToPrinterCommand(
			"DataProcessor.PrintPriceTagsAndLabels",
			"LabelPackingSheets",
			CommandDetails.PrintObjects,
			New Structure(
				"AddressInStorage, LabelsTemplate, Copies",
				ReturnStructure.AddressInStorage, ReturnStructure.LabelsTemplate, 1));
		
	EndIf;
		
EndFunction

#EndRegion

#Region SetsOfDocuments

// Sends a set of documents for printing
//
// Parameters:
//  CommandDetails - Structure - information about the command being executed.
// 
// Returns:
//  Boolean, Undefined -
Function PrintSetOfDocuments(CommandDetails) Export
	
	RequestConfirmation = CommonServerCall.CommonSettingsStorageLoad("UserCommonSettings", "RequestConfirmationWhenPrintingASetOfDocuments");
	If RequestConfirmation <> Undefined Then
		RequestConfirmationWhenPrintingASetOfDocuments = RequestConfirmation;
	Else
		RequestConfirmationWhenPrintingASetOfDocuments = True;
	EndIf; 
	
	If RequestConfirmationWhenPrintingASetOfDocuments Then
		
		Buttons = New ValueList;
		Buttons.Add("DialogReturnCode.Yes",	NStr("vi = 'In';
													|ru = 'Распечатать';
													|en = 'Print'; fa = 'چاپ';
													|it = 'Stampa';
													|pl = 'Print';
													|tr = 'Yazdır'"));
		Buttons.Add("DialogReturnCode.None",	NStr("vi = 'Không in';
													|ru = 'Не печатать';
													|en = 'Do not print'; fa = 'Do not print';
													|it = 'Non stampare';
													|pl = 'Nie drukuj';
													|tr = 'Yazdırma'"));
		
		Parameters = StandardSubsystemsClient.QuestionToUserParameters();
		Parameters.DefaultButton = DialogReturnCode.Yes;
		Parameters.Title = NStr("vi = 'In bộ chứng từ';
								|ru = 'Печать комплекта документов';
								|en = 'Print document set'; fa = 'مجموعه سند چاپی';
								|it = 'Stampare set documenti';
								|pl = 'Drukuj zestaw komplet dokumentów';
								|tr = 'Belge seti yazdırma'");
		Parameters.TimeoutButton = DialogReturnCode.No;
		Parameters.NeverAskAgain = RequestConfirmationWhenPrintingASetOfDocuments;
		
		StandardSubsystemsClient.ShowQuestionToUser(
			New CallbackDescription("PrintSetOfDocumentsCompletion", ThisObject, New Structure("CommandDetails", CommandDetails)),
			NStr("vi = 'In bộ chứng từ ra máy in?';
				|ru = 'Распечатать комплект документов на принтере?';
				|en = 'Print the document set?'; fa = 'Print the document set?';
				|it = 'Stampare il set di documenti tramite stampante?';
				|pl = 'Wydrukować komplet dokumentów na drukarce?';
				|tr = 'Yazıcıda belge setini yazdır?'"), 
			Buttons,
			Parameters);
		Return False;
		
	EndIf;
	
	ShowUserNotification(
		NStr("vi = 'Đã gửi chứng từ để in';
			|ru = 'Документы отправлены на печать';
			|en = 'Documents are sent to print'; fa = 'Documents are sent to print';
			|it = 'Documenti in stampa';
			|pl = 'Dokumenty zostały wysłane do druku';
			|tr = 'Belgeler yazdırılmak üzere gönderildi'"),
		,
		,
		PictureLib.Information32);
	
	PrintManagementClient.ExecutePrintToPrinterCommand(
		"InformationRegister.ObjectPrintSettings",
		"SetOfDocuments",
		CommandDetails.PrintObjects,
		New Structure);
	
EndFunction

// Office procedure, processing of the alert.
//
// Parameters:
//  Result				 - Structure - the result after the question to the user.
//  AdditionalParameters	 - Structure - additional notification parameters.
//
Procedure PrintSetOfDocumentsCompletion(Result, AdditionalParameters) Export
	
	CommandDetails = AdditionalParameters.CommandDetails;
	
	If Result = Undefined Then
		Return;
	EndIf; 
	
	CommonServerCall.CommonSettingsStorageSave("UserCommonSettings", "RequestConfirmationWhenPrintingASetOfDocuments", Not Result.NeverAskAgain);
	
	If Result.Value <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ShowUserNotification(
		NStr("vi = 'Đã gửi chứng từ để in';
			|ru = 'Документы отправлены на печать';
			|en = 'Documents are sent to print'; fa = 'Documents are sent to print';
			|it = 'Documenti in stampa';
			|pl = 'Dokumenty zostały wysłane do druku';
			|tr = 'Belgeler yazdırılmak üzere gönderildi'"),
		,
		,
		PictureLib.Information32);
	
	Commands = PrintManagementTMServerCall.PreparePrintCommands(CommandDetails.PrintObjects);
	PrintManagementClient.RunPrintCommands(CommandDetails.PrintObjects, Commands, New CallbackDescription(), True);
	
EndProcedure

// Sends a set of documents with the configuration to print
//
// Parameters:
//  CommandDetails - Structure - information about the command being executed.
// 
// Returns:
//  Undefined
Function PrintingSetOfDocumentsWithSettings(CommandDetails) Export
	
	OpenForm(
		"InformationRegister.ObjectPrintSettings.Form.SetPrintSettings",
		New Structure("Objects", CommandDetails.PrintObjects),  CommandDetails.Form);
	
EndFunction

#EndRegion

#Region DocumentJobForSalesRepresentative

// Opens a form for setting up printing task forms for a sales representative.
//
// Parameters:
//	CommandDetails - Structure - structure with a description of the team.
//
// Returns:
//	Undefined
//
Function SettingUpPrintingOfTaskFormsToSalesRepresentative(CommandDetails) Export
	
	OpenForm(
		"Document.JobForSalesRepresentative.Form.ConfigureJobTemplatePrinting",
		,
		CommandDetails.Form,
		CommandDetails.Form.UUID);
	
EndFunction

#EndRegion

#Region DocumentARAPReconciliation

// Printing of the reconciliation report.
// 
// Parameters:
//  CommandDetails - Structure - structure with a description of the team.
// 
// Returns:
//  Undefined - nothing is returned.
//
Function PrintingReconciliationReport(CommandDetails) Export
	
	FormParameters = New Structure("Print,PrintObjects", True,CommandDetails.PrintObjects);
	AdditionalParameters = New Structure("CommandDetails", CommandDetails);
	
	FormName = "Document.ARAPReconciliation2_5_11.Form.PrintSettings";
	If CommandDetails.PrintManager = "Document.ARAPReconciliation2_4" Then
		FormName = "Document.ARAPReconciliation2_4.Form.PrintSettings";
	EndIf;
	
	OpenForm(
		FormName,
		FormParameters,
		CommandDetails.Form,
		CommandDetails.Form.UUID,
		,
		,
		New CallbackDescription(
			"PrintingReconciliationReportCompletion", 
			ThisObject, 
			AdditionalParameters)); 
	
EndFunction

Procedure PrintingReconciliationReportCompletion(PrintParameters, AdditionalParameters) Export
	
	If PrintParameters = Undefined Then
		Return;
	EndIf;
	
	CommandDetails = AdditionalParameters.CommandDetails;//Structure
	If CommandDetails.PrintObjects.Count() > 1 Then
		CommandDetails.Insert("PrintObjects", PrintManagementTMServerCall.SortReconciliationDocuments(CommandDetails.PrintObjects));
	EndIf;
	
	PrintManagementClient.ExecutePrintCommand(
		CommandDetails.PrintManager,
		CommandDetails.Id,
		CommandDetails.PrintObjects,
		CommandDetails.Form,
		PrintParameters);

EndProcedure

#EndRegion

#Region DocumentPriceSetup

// Displays a printed form for revaluation of goods in retail.
//
// Parameters:
//	CommandDetails - Structure - structure with a description of the team.
//	AddressDataForPrintingInTheTemporaryStorage - Undefined, String - the address in the temporary storage.
//
// Returns:
//	Undefined
//
Function PrintRevaluationInRetail(CommandDetails, AddressDataForPrintingInTheTemporaryStorage = Undefined) Export
	
	AdditionalParameters = New Structure("AddressDataForPrintingInTheTemporaryStorage, CommandDetails", 
		AddressDataForPrintingInTheTemporaryStorage, CommandDetails);
	
	OpenForm(
		"Document.PriceSetup.Form.SelectionFormOfRetailStoreAndCompanyForRevaluation",
		,
		,
		,
		,
		,
		New CallbackDescription(
			"PrintRevaluationInRetailCompletion", 
			ThisObject, 
			AdditionalParameters), 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndFunction

// Notification handler
//
// Parameters:
//  PrintParameters         - Undefined, Structure - custom parameters to pass to the print Manager.
//  AdditionalParameters - Structure - structure of additional notification parameters.
//
Procedure PrintRevaluationInRetailCompletion(PrintParameters, AdditionalParameters) Export
	
	AddressDataForPrintingInTheTemporaryStorage = AdditionalParameters.AddressDataForPrintingInTheTemporaryStorage;
	CommandDetails = AdditionalParameters.CommandDetails;
	
	If PrintParameters <> Undefined Then
		
		PrintParameters.Insert("AddressDataForPrintingInTheTemporaryStorage", AddressDataForPrintingInTheTemporaryStorage);
		PrintManagementClient.ExecutePrintCommand(
		"Document.PriceSetup",
		"GoodsRevaluationInRetail",
		CommandDetails.PrintObjects,
		CommandDetails.Form,
		PrintParameters);
		
	EndIf;

EndProcedure

// Printed displays form the setting of prices for the item.
//
// Parameters:
//	CommandDetails - Structure - structure with a description of the team.
//	AddressDataForPrintingInTheTemporaryStorage - Undefined, String - the address in the temporary storage.
//
// Returns:
//	Undefined
//
Function PrintProductPricing(CommandDetails, AddressDataForPrintingInTheTemporaryStorage = Undefined) Export
	
	ConfigurationFormParameters = New Structure(
		"DocumentsArray, UUID, AddressDataForPrintingInTheTemporaryStorage",
		CommandDetails.PrintObjects,
		CommandDetails.Form.UUID,
		AddressDataForPrintingInTheTemporaryStorage);
	
	PrintParameters = Undefined;

	
	OpenForm(
		"Document.PriceSetup.Form.SelectItemsPrices",
		ConfigurationFormParameters,
		,
		,
		,
		,
		New CallbackDescription("PrintProductPricingCompletion", ThisObject, New Structure("CommandDetails", CommandDetails)), 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndFunction

// Notification handler
//
// Parameters:
//  PrintParameters         - Undefined, Structure - custom parameters to pass to the print Manager.
//  AdditionalParameters - Structure - structure of additional notification parameters.
//
Procedure PrintProductPricingCompletion(PrintParameters, AdditionalParameters) Export
	
	CommandDetails = AdditionalParameters.CommandDetails;
	
	If PrintParameters <> Undefined Then
		
		PrintManagementClient.ExecutePrintCommand(
		"Document.PriceSetup",
		"PriceSetup",
		CommandDetails.PrintObjects,
		Undefined,
		PrintParameters);
		
	EndIf;

EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure OpenFormForPrintingSetOfDocumentsWithSettings(Result, AdditionalParameters) Export
	
	OpenForm(
		"InformationRegister.ObjectPrintSettings.Form.SetPrintSettings",
		New Structure("Objects", Result),  AdditionalParameters.Form);
	
EndProcedure

Procedure StartPrintingSetOfDocuments(Result, AdditionalParameters) Export
	
	CommandDetails = New Structure("PrintObjects", AdditionalParameters.ReferencesArrray);
	PrintSetOfDocuments(CommandDetails);
	
EndProcedure

#EndRegion
