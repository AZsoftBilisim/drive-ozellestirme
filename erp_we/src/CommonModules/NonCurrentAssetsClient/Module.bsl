////////////////////////////////////////////////////////////////////////////////
// Procedures of the subsystem "Non-current assets".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Opens the address entry form with the address field values filled in from the parameter.
//
// Parameters:
//  Form				 - ClientApplicationForm - the form where you can enter the address;
//  Item				 - FormField - form element for entering an address;
//  Object				 - FormDataCollection - object that the event is being executed for;
//  NameOfAddressDetails	 - String - the name of the props;
//  StandardProcessing - Boolean - indicates whether standard processing of the start selection event is performed.
//
Procedure OpenAddressSelectionFormAndProcessResult(Form, Item, Object, NameOfAddressDetails = "LocationAddress", StandardProcessing = False) Export
	
	StandardProcessing = False;
	
	WhenChangingAddressPresentation(Item, Object[NameOfAddressDetails], Object[NameOfAddressDetails + "Value"]);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("NameOfAddressDetails", NameOfAddressDetails);
	
	Notification = New CallbackDescription("OpenAddressSelectionFormAndProcessResultCompletion", 
		ThisObject, AdditionalParameters);
		
	ContactInformationKind = New Structure;
	ContactInformationKind.Insert("Type", PredefinedValue("Enum.ContactInformationTypes.Address"));
	ContactInformationKind.Insert("OnlyNationalAddress", False);
	ContactInformationKind.Insert("IncludeCountryInPresentation", False);
	ContactInformationKind.Insert("HideObsoleteAddresses", False);
		
	ContactInformationFormParameters = ContactsManagerClient.ContactInformationFormParameters(
			ContactInformationKind,
			Object[NameOfAddressDetails + "Value"],
			Object[NameOfAddressDetails]);
	
	ContactsManagerClient.OpenContactInformationForm(ContactInformationFormParameters,, Notification);
		
EndProcedure

// Updates the CI from the input field editing text.
//
// Parameters:
//  Item - FormField - form element for entering an address;
//  AddressPresentation - String - representation of the address;
//  AddressValue - String - service information, address field values.
//
Procedure WhenChangingAddressPresentation(Item, AddressPresentation, AddressValue) Export
	
	AddressPresentation = Item.EditText;
	GeneralPurposeTMServerCall.FillInValuesOfCIFieldsOnPresentation(AddressPresentation, AddressValue);
	
EndProcedure

// Notifies when the EPA Document register changes.
// 
Procedure NotifyAboutDocumentEntryInFALog() Export
	
	NotifyChanged(Type("InformationRegisterRecordKey.FixedAssetsDocuments"));
	Notify("WritingDocumentToFALog");
	
EndProcedure

// Notifies you of a change in the document Name register.
// 
Procedure NotifyAboutEntryOfDocumentInJournalOfIA() Export
	
	NotifyChanged(Type("InformationRegisterRecordKey.IntangibleAssetsDocuments"));
	Notify("WritingDocumentToIAJournal");
	
EndProcedure

// Creates an exploitation object by type.
// 
// Parameters:
//  OSType - EnumRef.FATypes - Type of FA
Procedure CreateObjectOfOperationByType(OSType) Export
	
	SelectionData_ = New Structure;
	SelectionData_.Insert("OSType", OSType);
	
	FormParameters = New Structure;
	FormParameters.Insert("Basis", SelectionData_);
	
	OpenForm("Catalog.Assets.ObjectForm", FormParameters);
	
EndProcedure

// Handler for decoding a table document in a report form.
//
// Parameters:
//  Form - ClientApplicationForm - report form.
//  Item     - FormField        - table document.
//  Details - Arbitrary     - the value of the decoding point, series, or chart value.
//  StandardProcessing - Boolean  - indicates whether standard (system) event processing is performed.
//
Procedure ProcessingReportDecryption(Form, Item, Details, StandardProcessing) Export

	FullReportName = Form.ReportSettings.FullName;
	CurrentVariantKey = Form.CurrentVariantKey;

	If FullReportName = "Report.HelpFADepreciationCalculation2_4"
			And (CurrentVariantKey = "HelpFADepreciationCalculation"
				Or CurrentVariantKey = "ReferenceCalculationOfDocumentDepreciationFAContext") 
		Or FullReportName = "Report.StatementCalculationOfAssetsDepreciation"
			And (CurrentVariantKey = "HelpFADepreciationCalculation"
				Or CurrentVariantKey = "ReferenceCalculationOfDocumentDepreciationFAContext")
		Or FullReportName = "Report.StatementCalculationOfIntangibleAssetsDepreciation2_4"
			And (CurrentVariantKey = "StatementCalculationOfIntangibleAssetsDepreciation"
				Or CurrentVariantKey = "ReferenceCalculationOfDocumentDepreciationIAContext") 
		Or FullReportName = "Report.StatementCalculationOfIntangibleAssetsAmortization" 
			And (CurrentVariantKey = "StatementCalculationOfIntangibleAssetsDepreciation"
				Or CurrentVariantKey = "ReferenceCalculationOfDocumentDepreciationIAContext") Then
	
		ReportDetailsData = NonCurrentAssetsServerCall.DetailsData(
			Details, Form.ReportDetailsData);
	
		If ReportDetailsData.Fields.Find("Organization") = Undefined
			And ReportDetailsData.Fields.Find("FixedAsset") = Undefined
			And ReportDetailsData.Fields.Find("IntangibleAsset") = Undefined
			And ReportDetailsData.Fields.Find("DepreciationCalculationDocument") = Undefined Then
			
			// Decryption is not provided for the remaining fields
			StandardProcessing = False;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#Region Barcodes

// Retrieves data for printing and opens the Processing form.Printout of operation object labels.Form.Formaobjectsexploitation.
//
// Parameters:
//	CommandDetails - Structure - structure with a description of the team.
//
// Returns:
//	Undefined
//
Function LabelPrintingOfAssets(CommandDetails) Export
	
	OpenForm(
		"DataProcessor.LabelPrintingOfAssets.Form.AssetsForm",
		New Structure("Assets", CommandDetails.PrintObjects),
		CommandDetails.Form,
		New UUID);
	
	Return Undefined;
	
EndFunction

// Retrieves data for printing and opens the Processing form.Printout of operation object labels.Form.Formaobjectsexploitation.
//
// Parameters:
//	CommandDetails - Structure - structure with a description of the Command:
//	                    * Id - String - it can take the values "price Tags" or " Labels";
//	                    * PrintObjects - Array - print objects.
//
// Returns:
//	Undefined - Returns nothing.
//
Function PrintingLabelsOfObjectsOfOperationFromDocument(CommandDetails) Export
	
	AdditionalParameters = New Structure("PrintManager", CommandDetails.PrintManager);
	
	DataForPrint =
		PrintManagementTMServerCall.DataForPrintingPriceTagsAndLabels(
			CommandDetails.Id,
			CommandDetails.PrintObjects,
			AdditionalParameters);
	
	OpenForm(
		"DataProcessor.LabelPrintingOfAssets.Form.AssetsForm",
		New Structure("Assets", DataForPrint),
		CommandDetails.Form,
		New UUID);
	
	Return Undefined;
	
EndFunction

// Searches for objects operate under the barcode.
// Opens a form where the user enters a barcode.
// After entering, a search is performed.
// If multiple OE, then the form opens for you to select.
// After a successful search, it returns an array of links.
// 
// Parameters:
// 	ProcessingProcedure - CallbackDescription - The procedure to call when the search is successful.
//  PickingParameters - See TMCommonUseClientServer.PickingParameters
Procedure SearchForObjectsOfOperationByBarcode(ProcessingProcedure, PickingParameters = Undefined) Export
	
	AdditionalParameters = New Structure("ProcessingProcedure, PickingParameters", ProcessingProcedure, PickingParameters);
	Notification = New CallbackDescription("SearchForObjectsOfOperationByBarcodeCompletion", ThisObject, AdditionalParameters);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

// Input processing of barcode.
// 
// Parameters:
//  BarcodeData_5 - Structure, Array of String - Barcode data.
// 	ProcessingProcedure - CallbackDescription - The procedure to call when the search is successful.
//  PickingParameters - See TMCommonUseClientServer.PickingParameters
Procedure ProcessInputOfBarcodesOfObjectsOfOperation(BarcodeData_5, ProcessingProcedure, PickingParameters = Undefined) Export
	
	SearchResult = NonCurrentAssetsServerCall.FindObjectsOfOperationByBarcodes(
						BarcodeData_5, PickingParameters);
	
	If SearchResult.ObjectsArray.Count() = 0 Then
		
		ReportResultsOfSearchForOperationalObjectsByBarcode(SearchResult);
	
	ElsIf SearchResult.ObjectsArray.Count() = 1 Then
		
		RunCallback(ProcessingProcedure, SearchResult.ObjectsArray);
	
	Else
		
		AdditionalParameters = New Structure("ProcessingProcedure", ProcessingProcedure);
		Notification = New CallbackDescription("SelectionOfObjectsOfOperationByShipCompletion", ThisObject, AdditionalParameters);
		
		Parameters = New Structure;
		Parameters.Insert("BarcodeData_5", BarcodeData_5);
		Parameters.Insert("PickingParameters", PickingParameters);
		Parameters.Insert("ObjectsArray", SearchResult.ObjectsArray);
		Parameters.Insert("SearchForOperationalObjects", True);
		Parameters.Insert("SearchForNodes", False);
		OpenForm("Catalog.Assets.Form.SearchByBarcode", Parameters,,,,, Notification);
	
	EndIf;
	
EndProcedure

// Reports the barcode search results.
// 
// Parameters:
// 	SearchResult - See NonCurrentAssets.FindObjectsByBarcodes
Procedure ReportResultsOfSearchForOperationalObjectsByBarcode(SearchResult) Export
	
	ClearMessages();
	
	MessageTemplate = NStr("vi = 'Không thể tìm thấy tài sản đang vận hành theo mã vạch %1';
							|ru = 'Не удалось найти объекты эксплуатации по штрихкоду %1';
							|en = 'Cannot find assets by barcode %1'; fa = 'Cannot find assets by barcode %1';
							|it = 'Non è stato possibile trovare oggetti d''uso operativo per codice a barre %1';
							|pl = 'Nie udało się znaleźć obiektów eksploatacji wg kodu kreskowego %1';
							|tr = 'İşlem nesneleri %1 barkoduna göre bulunamıyor'");
	For Each Barcode In SearchResult.NotFound_1 Do
		MessageText = StrTemplate(MessageTemplate, Barcode);
		CommonClient.MessageToUser(MessageText); 
	EndDo; 
	
	MessageTemplate = NStr("vi = 'Không thể thêm tài sản đang vận hành ""%1"" vào chứng từ, bởi vì không thỏa mãn điều kiện lọc';
							|ru = 'Объект эксплуатации ""%1"" не может быть добавлен в документ, т.к. он не удовлетворяет условиям выбора';
							|en = 'The asset ""%1"" cannot be added to the document, as it does not meet selection conditions'; fa = 'The asset ""%1"" cannot be added to the document, as it does not meet selection conditions';
							|it = 'Oggetto d''uso operativo ""%1"" non può essere aggiunto nel documento in quanto non soddisfa i criteri di selezione';
							|pl = 'Nie można dodać obiektu operacji „%1” do dokumentu, ponieważ nie spełnia warunków wyboru';
							|tr = '""%1"" varlığı seçim koşullarını karşılamadığı için belgeye eklenemiyor'");
	For Each ObjectReference In SearchResult.DoNotFit Do
		MessageText = StrTemplate(MessageTemplate, ObjectReference);
		CommonClient.MessageToUser(MessageText, ObjectReference); 
	EndDo; 
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

Function WhenChangingPeriodOfUse(Object, AttributeName, UpdateUsagePeriod) Export
	
	AttributesList = AttributeName;
	
	If AttributeName <> "UsefulLifeManagementAccounting"
		And Object.RecordInManAccounting
		And (Object.UsefulLifeManagementAccounting = 0
			Or UpdateUsagePeriod) Then
		
		Object.UsefulLifeManagementAccounting = Object[AttributeName];
		AttributesList = AttributesList + ",UsefulLifeManagementAccounting";
		
	EndIf;
	
	If AttributeName <> "UsefulLifeAccounting"
		And Object.RecordInManAccounting
		And (Object.UsefulLifeAccounting = 0
			Or UpdateUsagePeriod) Then
		
		Object.UsefulLifeAccounting = Object[AttributeName];
		AttributesList = AttributesList + ",UsefulLifeAccounting";
		
	EndIf;
	
	If AttributeName <> "UsefulLifeTaxAccounting"
		And Object.RecordInLocalAccounting
		And (Object.UsefulLifeTaxAccounting = 0
			Or UpdateUsagePeriod) Then
		
		Object.UsefulLifeTaxAccounting = Object[AttributeName];
		AttributesList = AttributesList + ",UsefulLifeTaxAccounting";
		
	EndIf;
	
	Return AttributesList;

EndFunction

#EndRegion

#Region Private

Function ProcessingActionDetailsOfMonthClosingFormAndFADepreciation(Parameters) Export

	ProcessSucceeded = NonCurrentAssetsClientLocalization.ProcessingActionDetailsOfMonthClosingFormAndFADepreciation(Parameters);

	If Not ProcessSucceeded Then 
		FormParameters = New Structure;
		FormParameters.Insert("Period", Parameters.Period);
		FormParameters.Insert("CompanyArray", Parameters.CompanyArray);
		OpenForm("Document.FixedAssetsDepreciationCharge2_4.ListForm", FormParameters);
	EndIf; 
			
	Return True;
	
EndFunction

Function ProcessingOfActionDetailsOfMonthClosingFormAndDepreciationOfIA(Parameters) Export

	ProcessSucceeded = NonCurrentAssetsClientLocalization.ProcessingOfActionDetailsOfMonthClosingFormAndDepreciationOfIA(Parameters);

	If Not ProcessSucceeded Then 
		FormParameters = New Structure;
		FormParameters.Insert("Period", Parameters.Period);
		FormParameters.Insert("CompanyArray", Parameters.CompanyArray);
		OpenForm("Document.IntangibleAssetsAmortizationCharge2_4.ListForm", FormParameters);
	EndIf; 
			
	Return True;
	
EndFunction

Procedure NotifyAboutDepreciationCalculation(CalculationResult2, Period = Undefined) Export
	
	If CalculationResult2 = Undefined Then
		Return;
	EndIf;
	
	If CalculationResult2.HasErrors Then
		
		If ValueIsFilled(CalculationResult2.ErrorText) Then
			Raise CalculationResult2.ErrorText
		Else
			ExplanationText = NStr("vi = 'Xảy ra lỗi trong khi tính toán';
									|ru = 'При расчете возникли ошибки';
									|en = 'Errors occurred while calculating'; fa = 'Errors occurred while calculating';
									|it = 'Sono stati rilevati degli errori durante il calcolo';
									|pl = 'Przy rozliczeniu wystąpiły błędy';
									|tr = 'Hesaplamada hatalar bulunmaktadır'");
			NotificationPicture = PictureLib.DepreciationWithError;
			ShowUserNotification(,, ExplanationText, NotificationPicture);
		EndIf;
		
	Else
		ExplanationText = NStr("vi = 'Khấu hao tính toán';
								|ru = 'Амортизация рассчитана';
								|en = 'Depreciation is calculated'; fa = 'استهلاک محاسبه شده است';
								|it = 'L''ammortamento calcolato';
								|pl = 'Amortyzacja obliczona';
								|tr = 'Amortisman hesaplanmıştır'");
		NotificationPicture = PictureLib.DepreciationIsCalculated;
		ShowUserNotification(,, ExplanationText, NotificationPicture);
	EndIf;	
	
EndProcedure

Procedure OpenAddressSelectionFormAndProcessResultCompletion(Result, AdditionalParameters) Export 
	
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	Form = AdditionalParameters.Form;
	Object = AdditionalParameters.Object;
	NameOfAddressDetails= AdditionalParameters.NameOfAddressDetails;
		
	// Transfer the data to the form
	Object[NameOfAddressDetails + "Value"] = Result.Value;
	Object[NameOfAddressDetails] = Result.Presentation;
	
	Form.Modified = True;
	Form.RefreshDataRepresentation();

EndProcedure

Procedure SearchForObjectsOfOperationByBarcodeCompletion(BarcodeData_5, AdditionalParameters) Export
	
	ProcessInputOfBarcodesOfObjectsOfOperation(
		BarcodeData_5, 
		AdditionalParameters.ProcessingProcedure, 
		AdditionalParameters.PickingParameters);
	
EndProcedure

Procedure SelectionOfObjectsOfOperationByShipCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Array") And Result.Count() <> 0 Then
		RunCallback(AdditionalParameters.ProcessingProcedure, Result);
	EndIf;
	
EndProcedure

Procedure PerformActionBasedOnPhysicalInventoryCount(CurrentData, Form) Export
	
	Object = Form.Object;
	
	If ValueIsFilled(CurrentData.DocumentBasedOnAC)
		And (Not ValueIsFilled(CurrentData.TAAction)
			Or CurrentData.DocumentBasedOnAC = CurrentData.DocumentBasedOnTA) 
		And (Not ValueIsFilled(CurrentData.MAAction)
			Or CurrentData.DocumentBasedOnAC = CurrentData.DocumentBasedOnMA) Then
			
		ShowValue(, CurrentData.DocumentBasedOnAC);
		
	ElsIf ValueIsFilled(CurrentData.DocumentBasedOnTA)
		And (Not ValueIsFilled(CurrentData.LAAction)
			Or CurrentData.DocumentBasedOnTA = CurrentData.DocumentBasedOnAC) 
		And (Not ValueIsFilled(CurrentData.MAAction)
			Or CurrentData.DocumentBasedOnTA = CurrentData.DocumentBasedOnMA) Then
			
		ShowValue(, CurrentData.DocumentBasedOnTA);
		
	ElsIf ValueIsFilled(CurrentData.DocumentBasedOnMA)
		And (Not ValueIsFilled(CurrentData.LAAction)
			Or CurrentData.DocumentBasedOnMA = CurrentData.DocumentBasedOnAC) 
		And (Not ValueIsFilled(CurrentData.TAAction)
			Or CurrentData.DocumentBasedOnMA = CurrentData.DocumentBasedOnTA) Then
			
		ShowValue(, CurrentData.DocumentBasedOnMA);
		
	Else
		
		ListOfActions = New Array;
			
		If ValueIsFilled(CurrentData.DocumentBasedOnAC)
			And Object.PostInAccounting Then
			ListOfActions.Add(CurrentData.DocumentBasedOnAC);
		EndIf;
		
		If ValueIsFilled(CurrentData.DocumentBasedOnTA)
			And Object.RecordInTA Then
			ListOfActions.Add(CurrentData.DocumentBasedOnTA);
		EndIf;
		
		If ValueIsFilled(CurrentData.DocumentBasedOnMA)
			And Object.RecordInManAccounting Then
			ListOfActions.Add(CurrentData.DocumentBasedOnMA);
		EndIf;
		
		If ValueIsFilled(CurrentData.LAAction)
			And Not ValueIsFilled(CurrentData.DocumentBasedOnAC)
			And Object.PostInAccounting Then
			ListOfActions.Add(CurrentData.LAAction);
		EndIf;
		
		If ValueIsFilled(CurrentData.TAAction)
			And Not ValueIsFilled(CurrentData.DocumentBasedOnTA)
			And Object.RecordInTA Then
			ListOfActions.Add(CurrentData.TAAction);
		EndIf;
		
		If ValueIsFilled(CurrentData.MAAction)
			And Not ValueIsFilled(CurrentData.DocumentBasedOnMA)
			And Object.RecordInManAccounting Then
			ListOfActions.Add(CurrentData.MAAction);
		EndIf;
		
		If ListOfActions.Count() = 0 Then
			Return;
		EndIf;
		
		ListOfActions = CommonClientServer.CollapseArray(ListOfActions);
		ChoiceList = New ValueList();
		For Each Item In ListOfActions Do
			
			If TypeOf(Item) = Type("EnumRef.ActionsBasedOnPhysicalInventoryCount") Then
				
				If Item = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Recognition") Then
					ChoiceList.Add(Item, NStr("vi = 'Tạo chứng từ tiếp nhận vào kế toán';
												|ru = 'Создать принятие к учету';
												|en = 'Create recognition'; fa = 'ایجاد شناسایی';
												|it = 'Creare ricezione in contabilità';
												|pl = 'Utwórz przyjęcie do ewidencji';
												|tr = 'Muhasebe kabulü oluşturun'"));
				ElsIf Item = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Move") Then
					ChoiceList.Add(Item, NStr("vi = 'Tạo mới chứng từ điều chuyển';
												|ru = 'Создать перемещение';
												|en = 'Create transfer'; fa = 'ایجاد انتقال';
												|it = 'Creare spostamento';
												|pl = 'Utwórz przeniesienie';
												|tr = 'Transfer oluştur'"));
				ElsIf Item = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff") Then
					ChoiceList.Add(Item, NStr("vi = 'Tạo chứng từ ghi giảm';
												|ru = 'Создать списание';
												|en = 'Create write-off'; fa = 'ایجاد اسقاط';
												|it = 'Creare storno';
												|pl = 'Utwórz rozchód';
												|tr = 'Mahsuplaşma oluşturun'"));
				ElsIf Item = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.ReturnLeasedAssets") Then
					ChoiceList.Add(Item, NStr("vi = 'Tạo chứng từ thanh lý TSCĐ đã thuê';
												|ru = 'Создать выбытие арендованных ОС';
												|en = 'Create leased assets return (off-balance)'; fa = 'ایجاد برگشت دارایی‌های اجاره‌ای (خارج از ترازنامه)';
												|it = 'Creare cessione cespiti in affitto';
												|pl = 'Utwórz wyrejestrowanie wynajmowanych środków trwałych';
												|tr = 'Kiralanan sabit kıymetlerin iadesi oluştur'"));
				ElsIf Item = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.LeaseTermination") Then
					ChoiceList.Add(Item, NStr("vi = 'Tạo chấm dứt hợp đồng thuê';
												|ru = 'Создать прекращение договора аренды';
												|en = 'Create rental termination'; fa = 'ایجاد فسخ اجاره';
												|it = 'Create rental termination';
												|pl = 'Create rental termination';
												|tr = 'Kira sözleşmesi feshini oluştur'"));
				ElsIf Item = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Revaluation") Then
					ChoiceList.Add(Item, NStr("vi = 'Tạo mới chứng từ đánh giá lại';
												|ru = 'Создать переоценку';
												|en = 'Create revaluation'; fa = 'ایجاد تجدید ارزیابی';
												|it = 'Creare rivalutazione';
												|pl = 'Utwórz przeszacowanie';
												|tr = 'Yeniden değerlendirme oluşturun'"));
				EndIf;
				
			Else
				ChoiceList.Add(Item, StrTemplate(NStr("vi = 'Mở %1';
														|ru = 'Открыть %1';
														|en = 'Open %1'; fa = 'Open %1';
														|it = 'Open %1';
														|pl = 'Open %1';
														|tr = '%1 aç'"), Item));
			EndIf;
			
		EndDo;
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Form", Form);
		AdditionalParameters.Insert("LineNumber", CurrentData.LineNumber);
		
		If ChoiceList.Count() > 1 Then
			
			CallbackDescription = New CallbackDescription("SelectActionBasedOnPhysicalInventoryCountEnd", ThisObject, AdditionalParameters);
			ChoiceList.ShowChooseItem(CallbackDescription, NStr("vi = 'Hãy chọn thao tác';
																|ru = 'Выберите действие';
																|en = 'Select action'; fa = 'انتخاب اقدام';
																|it = 'Selezionare un''azione';
																|pl = 'Wybierz czynność';
																|tr = 'Eylem seçin'"));
			
		Else
			
			SelectActionBasedOnPhysicalInventoryCountEnd(ChoiceList[0], AdditionalParameters);
			
		EndIf;
		
	EndIf;

EndProcedure

Procedure SelectActionBasedOnPhysicalInventoryCountEnd(SelectedElement, AdditionalParameters) Export
	
	If SelectedElement = Undefined Then
		Return;
	EndIf;
	
	LineNumber = AdditionalParameters.LineNumber;
	Form = AdditionalParameters.Form;
	Object = Form.Object;
		
	If TypeOf(SelectedElement.Value) = Type("EnumRef.ActionsBasedOnPhysicalInventoryCount") Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Form", Form);
		AdditionalParameters.Insert("LineNumber", LineNumber);
		AdditionalParameters.Insert("Action", SelectedElement.Value);

		If (Not Object.Posted Or Form.Modified) Then
		
			ButtonsList = New ValueList;
			ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Tiếp tục';
														|ru = 'Продолжить';
														|en = 'Continue'; fa = 'ادامه';
														|it = 'Continue';
														|pl = 'Continue';
														|tr = 'Devam et'"));
			ButtonsList.Add(DialogReturnCode.Cancel);
			
			QueryText = NStr("vi = 'Trước khi phản ánh kết quả kiểm kê, cần phải kết chuyển chứng từ.
								|Kết chuyển chứng từ và tiếp tục?';
								|ru = 'Перед отражением результатов инвентаризации необходимо провести документ.
								|Провести документ и продолжить?';
								|en = 'Post the document before recording physical inventory count results.
								|Post the document and continue?'; fa = 'Post the document before recording physical inventory count results.
								|Post the document and continue?';
								|it = 'Post the document before recording physical inventory count results.
								|Post the document and continue?';
								|pl = 'Post the document before recording physical inventory count results.
								|Post the document and continue?';
								|tr = 'Stok sayım sonuçlarını yansıtmadan önce belgeyi kaydetmek gerekir.
								|Belge kaydedilip devam edilsin mi?'");
			
			CallbackDescription = New CallbackDescription("PerformActionBasedOnPhysicalInventoryCountCompletion", ThisObject, AdditionalParameters);
			ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
		
		Else
			
			PerformActionBasedOnPhysicalInventoryCountCompletion(DialogReturnCode.Yes, AdditionalParameters);
			
		EndIf;
		
	Else
		
		ShowValue(, SelectedElement.Value);
		
	EndIf;

EndProcedure

Procedure PerformActionBasedOnPhysicalInventoryCountCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;

	Form = AdditionalParameters.Form;
	Object = Form.Object;

	If Not Object.Posted Or Form.Modified Then
		TMCommonUseClient.Post(Form);
	EndIf;
	
	If Not Object.Posted Or Form.Modified Then
		Return;
	EndIf;

	ArrayOfLineNumbers = New Array;
	ArrayOfLineNumbers.Add(AdditionalParameters.LineNumber);
	
	FillingValues = New Structure;
	FillingValues.Insert("DocumentBasis", Object.Ref);
	FillingValues.Insert("ArrayOfLineNumbers", ArrayOfLineNumbers);
	FillingValues.Insert("ReportErrors", True);
	
	FormParameters = New Structure;
	FormParameters.Insert("FillingValues", FillingValues);
	
	Result = New Structure;
	Result.Insert("Action", AdditionalParameters.Action);
	Result.Insert("FormParameters", FormParameters);
	
	CallbackDescription = New CallbackDescription("PerformActionBasedOnPhysicalInventoryCountCompletion", Form);
	RunCallback(CallbackDescription, Result);
		
EndProcedure

// Sets the current time for the date if the user has changed the document date to the previous one.
// 
// Parameters:
//  Date - Date - Document date
Procedure SetCurrentTimeForLastDate(Date) Export
	
	SessionDate = CommonClient.SessionDate();
	
	If Date < BegOfDay(SessionDate)
		And Date = BegOfDay(Date) Then
			
		Date = Date + Hour(SessionDate) * 3600 + Minute(SessionDate) * 60 + Second(SessionDate);
		
	EndIf;
	
EndProcedure

Procedure OpenInternationalAccountingTransactions(Val Ref) Export

	FilterParameters = New Structure("Recorder", Ref);
	FormParameters = New Structure("Filter", FilterParameters);
	OpenForm("DataProcessor.DocumentPostingInFinancialAccounting.Form.FinancialAccountingPostings", FormParameters,, Ref);
	
EndProcedure

#EndRegion
