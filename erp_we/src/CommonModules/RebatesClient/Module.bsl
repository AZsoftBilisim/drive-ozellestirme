// @strict-types

#Region Internal

// Parameters:
//  ObjectReference - DocumentRef.ConditionsOfCustomerRebates, DocumentRef.AccrualOfCustomerRebates -
//  ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CalculateCustomerRebates(ObjectReference, ExecutionParameters) Export
	
	DocumentForm = ExecutionParameters.Form;
	
	FormParameters = CommonClientServer.StructureProperty(ExecutionParameters.CommandDetails, "FormParameters"); // Structure
	FormParameters.Insert("CommandParameter", ObjectReference);
	
	ReportFormName = "Report.CalculateCustomerRebates.Form";
	OpenForm(ReportFormName, FormParameters, DocumentForm, True);
	
EndProcedure

// Parameters:
//  ObjectReference - DocumentRef.ConditionsOfVendorRebates, DocumentRef.AccrualOfVendorRebates -
//  ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CalculateVendorRebates(ObjectReference, ExecutionParameters) Export
	
	DocumentForm = ExecutionParameters.Form;
	
	FormParameters = CommonClientServer.StructureProperty(ExecutionParameters.CommandDetails, "FormParameters"); // Structure
	FormParameters.Insert("CommandParameter", ObjectReference);
	
	ReportFormName = "Report.CalculateVendorRebates.Form";
	OpenForm(ReportFormName, FormParameters, DocumentForm, True);
	
EndProcedure

// Fixes the current composition of the conditions document for further calculation
// 
// Parameters:
//  Document - DocumentRef.ConditionsOfCustomerRebates, DocumentRef.ConditionsOfVendorRebates -
//  Form - ClientApplicationForm -
//  CallbackOnCompletion - CallbackDescription -
//  NotificationOfOperationsAreBeingPerformed - CallbackDescription, Undefined -
//
Procedure FixCompositionOfConditionsDocument(Document, Form, CallbackOnCompletion, NotificationOfOperationsAreBeingPerformed = Undefined) Export
	
	TimeConsumingOperation = RebatesServerCall.LongTermOperationOfFixingCompositionOfDocumentConditions(Document);
	If TimeConsumingOperation <> Undefined Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
		IdleParameters.Title = NStr("vi = 'Ghi nhận thành phần chứng từ điều kiện';
									|ru = 'Фиксация состава документа условий';
									|en = 'Condition document recording'; fa = 'Condition document recording';
									|it = 'Condition document recording';
									|pl = 'Condition document recording';
									|tr = 'Şartlar belgesi içeriğinin sabitlenmesi'");
		IdleParameters.OpeningModeForWaitDialog = FormWindowOpeningMode.LockOwnerWindow;
		
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
		
	ElsIf NotificationOfOperationsAreBeingPerformed <> Undefined Then
		
		RunCallback(NotificationOfOperationsAreBeingPerformed);
		
	EndIf;
	
EndProcedure

// Cancels fixing the composition of the conditions document
// 
// Parameters:
//  Document - DocumentRef.ConditionsOfCustomerRebates, DocumentRef.ConditionsOfVendorRebates -
//  Form - ClientApplicationForm -
//  CallbackOnCompletion - CallbackDescription -
//  NotificationOfOperationsAreBeingPerformed - CallbackDescription, Undefined -
//
Procedure CancelFixingCompositionOfConditionsDocument(Document, Form, CallbackOnCompletion, NotificationOfOperationsAreBeingPerformed = Undefined) Export
	
	TimeConsumingOperation = RebatesServerCall.LongTermOperationToCancelFixingCompositionOfDocumentConditions(Document);
	If TimeConsumingOperation <> Undefined Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
		IdleParameters.Title = NStr("vi = 'Hủy ghi nhận thành phần chứng từ điều kiện';
									|ru = 'Отмена фиксации состава документа условий';
									|en = 'Cancel condition document recording'; fa = 'Cancel condition document recording';
									|it = 'Cancel condition document recording';
									|pl = 'Cancel condition document recording';
									|tr = 'Şartlar belgesi içeriğinin sabitlenmesinin iptali'");
		IdleParameters.OpeningModeForWaitDialog = FormWindowOpeningMode.LockOwnerWindow;
		
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
		
	ElsIf NotificationOfOperationsAreBeingPerformed <> Undefined Then
		
		RunCallback(NotificationOfOperationsAreBeingPerformed);
		
	EndIf;
	
EndProcedure

// Returns a table of calculated retro-bonuses of customers under the specified conditions with details up to the sales document.
// 
// Parameters:
//  CalculationParameters - See Reports.CalculateCustomerRebates.RebatesCalculationParameters
//  Form - ClientApplicationForm
//  CallbackOnCompletion - CallbackDescription
//
Procedure RebatesForPeriodAccordingToSalesDocuments(CalculationParameters, Form, CallbackOnCompletion) Export
	
	TimeConsumingOperation = RebatesServerCall.LongTermOperationOfReceivingRebatesAccordingToSalesDocuments(
		CalculationParameters,
		Form.UUID);

	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	IdleParameters.Title = NStr("vi = 'Nhận dữ liệu về thưởng lũy kế đã tính';
								|ru = 'Получение данных о рассчитанных ретро-бонусах';
								|en = 'Get data on calculated rebates'; fa = 'Get data on calculated rebates';
								|it = 'Получение данных о рассчитанных ретро-бонусах';
								|pl = 'Get data on calculated rebates';
								|tr = 'Hesaplanan retro-bonuslara ilişkin verilerin elde edilmesi'");
	IdleParameters.OpeningModeForWaitDialog = FormWindowOpeningMode.LockOwnerWindow;
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

// Returns a table of calculated retro-bonuses of suppliers under the specified conditions with details
// up to the receipt document.
// 
// Parameters:
//  CalculationParameters - See Reports.CalculateVendorRebates.RebatesCalculationParameters
//  Form - ClientApplicationForm
//  CallbackOnCompletion - CallbackDescription
//
Procedure RebatesForPeriodAccordingToPurchaseDocuments(CalculationParameters, Form, CallbackOnCompletion) Export
	
	TimeConsumingOperation = RebatesServerCall.LongTermOperationOfObtainingRebateOnPurchaseDocuments(
		CalculationParameters,
		Form.UUID);

	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	IdleParameters.Title = NStr("vi = 'Nhận dữ liệu về thưởng lũy kế đã tính';
								|ru = 'Получение данных о рассчитанных ретро-бонусах';
								|en = 'Get data on calculated rebates'; fa = 'Get data on calculated rebates';
								|it = 'Получение данных о рассчитанных ретро-бонусах';
								|pl = 'Get data on calculated rebates';
								|tr = 'Hesaplanan retro-bonuslara ilişkin verilerin elde edilmesi'");
	IdleParameters.OpeningModeForWaitDialog = FormWindowOpeningMode.LockOwnerWindow;
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

// Generates documents for accrual of retro bonuses based on the transmitted data
// 
// Parameters:
//  AddressOfDataToGenerate - String
//  CalculationParameters - See Reports.CalculateCustomerRebates.RebatesCalculationParameters
//  GenerationParameters - See DataProcessors.BulkAccrualOfCustomerRebates.DocumentGenerationParameters
//  Form - ClientApplicationForm
//  CallbackOnCompletion - CallbackDescription
//
Procedure GenerateAccrualDocuments(AddressOfDataToGenerate, CalculationParameters, GenerationParameters, Form, CallbackOnCompletion) Export
	
	TimeConsumingOperation = RebatesServerCall.LongTermOperationOfGeneratingAccrualDocuments(
		AddressOfDataToGenerate,
		CalculationParameters,
		GenerationParameters,
		Form.UUID);

	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	IdleParameters.Title = NStr("vi = 'Lập chứng từ tính thưởng lũy kế cho khách hàng';
								|ru = 'Формирование документов начисления ретро-бонусов клиентов';
								|en = 'Generate accrual of customer rebates documents'; fa = 'Generate accrual of customer rebates documents';
								|it = 'Формирование документов начисления ретро-бонусов клиентов';
								|pl = 'Generate accrual of customer rebates documents';
								|tr = 'Müşteri retro-bonus hesaplamaları için belgelerin oluşturulması'");
	IdleParameters.OpeningModeForWaitDialog = FormWindowOpeningMode.LockOwnerWindow;
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

#Region WorkingWithReports

// Occurs after the report is generated.
//
// Parameters:
//   ReportForm - ClientApplicationForm - report form.
//
Procedure AfterReportIsGenerated(ReportForm) Export
	
	AuxProperties = CommonClientServer.GetFormAttributeByPath(
		ReportForm, "Report.SettingsComposer.UserSettings.AdditionalProperties");
	FirstLayoutWhenOpened = CommonClientServer.StructureProperty(
		AuxProperties, "FirstLayoutWhenOpened", False);
	
	If FirstLayoutWhenOpened Then
		
		AuxProperties.Insert("FirstLayoutWhenOpened", False);
		AuxProperties.Insert("VariantModified", False);
		AuxProperties.Insert("UserSettingsModified", False);
		
		CommonClientServer.SetFormAttributeByPath(ReportForm, "FirstLayoutWhenOpened", False);
		CommonClientServer.SetFormAttributeByPath(ReportForm, "VariantModified", False);
		CommonClientServer.SetFormAttributeByPath(ReportForm, "UserSettingsModified", False);
		
	EndIf;
	
EndProcedure

// Parameters:
//   ThisForm - See CommonForm.ReportForm
//   Item - FormField, SpreadsheetDocumentField - table document.
//   Details - Arbitrary - the value of the decoding point, series, or chart value.
//   StandardProcessing - Boolean - indicates whether standard (system) event processing is performed.
//   ReportMenu - Array of Structure
//   ActionMenu - Array of Structure
//
Procedure DetailProcessing(ThisForm, Item, Details, StandardProcessing, ReportMenu, ActionMenu) Export
	
	FullReportName = ThisForm.ReportSettings.FullName; // String
	CurrentVariantKey = ThisForm.CurrentVariantKey; // String
	
	If FullReportName = "Report.CalculateCustomerRebates" Then
		
		ProcessDecryptionCalculationOfCustomerRebates(
			ThisForm, ReportMenu, CurrentVariantKey);
		
	ElsIf FullReportName = "Report.CalculateVendorRebates" Then
		
		ProcessDecryptionCalculationOfVendorRebates(
			ThisForm, ReportMenu, CurrentVariantKey);
		
	EndIf;
	
EndProcedure

// Parameters:
//   ThisForm - See CommonForm.ReportForm
//   Item - FormField, SpreadsheetDocumentField - table document.
//   Details - Arbitrary - the value of the decoding point, series, or chart value.
//   StandardProcessing - Boolean - indicates whether standard (system) event processing is performed.
//   ReportMenu - Array of Structure
//   ActionMenu - Array of Structure
//
Procedure AdditionalDetailProcessing(ThisForm, Item, Details, StandardProcessing, ReportMenu, ActionMenu) Export
	
	FullReportName = ThisForm.ReportSettings.FullName; // String
	
	If FullReportName = "Report.VendorRebateStatement" Then
		
		ActionParameters = New Structure;
		ActionParameters.Insert("Name", "CloseBonusCalculations");
		ActionParameters.Insert("Title", NStr("vi = 'Đóng hạch toán theo thưởng';
												|ru = 'Закрыть расчеты по бонусам';
												|en = 'Close rebate calculations'; fa = 'Close rebate calculations';
												|it = 'Закрыть расчеты по бонусам';
												|pl = 'Close rebate calculations';
												|tr = 'Bonus hesaplarını kapat'"));
		ActionParameters.Insert("CommonModuleName", "RebatesClient");
		ActionParameters.Insert("ThisForm", ThisForm);
		
		DecryptionFields = New Array; // Array of String
		DecryptionFields.Add("TermDocument");
		ActionParameters.Insert("DecryptionFields", DecryptionFields);
		
		RequiredParameters = New Structure;
		RequiredParameters.Insert("TermDocument");
		ActionParameters.Insert("RequiredParameters", RequiredParameters);
		
		ActionMenu.Add(ActionParameters);
		
		ActionParameters = New Structure;
		ActionParameters.Insert("Name", "ResumeBonusPayments");
		ActionParameters.Insert("Title", NStr("vi = 'Khôi phục hạch toán theo thưởng';
												|ru = 'Возобновить расчеты по бонусам';
												|en = 'Resume rebate calculations'; fa = 'Resume rebate calculations';
												|it = 'Возобновить расчеты по бонусам';
												|pl = 'Resume rebate calculations';
												|tr = 'Bonus hesaplarını devam ettir'"));
		ActionParameters.Insert("CommonModuleName", "RebatesClient");
		ActionParameters.Insert("ThisForm", ThisForm);
		
		DecryptionFields = New Array; // Array of String
		DecryptionFields.Add("TermDocument");
		ActionParameters.Insert("DecryptionFields", DecryptionFields);
		
		RequiredParameters = New Structure;
		RequiredParameters.Insert("TermDocument");
		ActionParameters.Insert("RequiredParameters", RequiredParameters);
		
		ActionMenu.Add(ActionParameters);
		
	EndIf;
	
EndProcedure

// Handler for special actions when decrypting reports.
// For example, opening specialized forms with parameterization.
//
// Parameters:
//	ActionParameters - Structure:
//	  *Name - String - Name of the action being performed
//	  *ThisForm - ClientApplicationForm - required Attributes in the form:
//	    **ReportSpreadsheetDocument - SpreadsheetDocument
//	    **ReportDetailsData - String
//	  *DecryptionFields - Array of String
//	DetailsParameters - Structure - Parameters passed to the form.
//
Procedure PerformDecryptionAction(ActionParameters, DetailsParameters) Export
	
	ThisForm = ActionParameters.ThisForm;
	DecryptionFields = ActionParameters.DecryptionFields;
	DecryptionAction = ActionParameters.Name;
	
	If DecryptionAction = "CloseBonusCalculations" Then
		
		CloseResumeBonusCalculationsFromReportForm(ThisForm, DecryptionFields);
		
	ElsIf DecryptionAction = "ResumeBonusPayments" Then
		
		CloseResumeBonusCalculationsFromReportForm(ThisForm, DecryptionFields, False);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region BatchProcessingOfStrings

// Parameters:
//  CurrentRow - FormDataCollectionItem: See Document.ConditionsOfCustomerRebates.Form.DocumentForm.Items.ContractsTermsOfSales
//  			  - Structure:
//  				* Terms - CatalogRef.TermsOfSale -
//  				* TermDocument - DocumentRef.ConditionsOfVendorRebates -
//  StructureOfActions - See BatchProcessingOfTablePartClient.ProcessTSString.StructureOfActions
//  Cached_Values - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues 
// 
// Returns:
//  Boolean
//
Function ServerCallIsRequiredToProcessTSString(CurrentRow, StructureOfActions, Cached_Values) Export
	
	Var ActionParameters; // Structure
	Result = False;
	
	If StructureOfActions.Property("FillInAgreementAttributeInTSLine", ActionParameters) Then
		
		If ValueIsFilled(CurrentRow.Terms)
		   And Cached_Values.SignsOfAgreements.Get(CurrentRow.Terms) = Undefined Then
			Result = True;
		EndIf;
		
	EndIf;
	
	If StructureOfActions.Property("FillInCurrencyIndicationForRebatesOfSuppliers", ActionParameters) Then
		
		For Each Field In ActionParameters Do // KeyAndValue
			
			FieldName = String(Field.Key);
			Result = ValueIsFilled(CurrentRow[FieldName])
			
		EndDo;
		
	EndIf;
	
	If StructureOfActions.Property("FillInCurrencyOfVendorSRebates", ActionParameters) Then
		
		For Each Field In ActionParameters Do // KeyAndValue
			
			FieldName = String(Field.Key);
			Result = ValueIsFilled(CurrentRow[FieldName])
			
		EndDo;
		
	EndIf;
	
	If StructureOfActions.Property("FillInRebateTypeOfSuppliers", ActionParameters) Then
		
		For Each Field In ActionParameters Do // KeyAndValue
			
			FieldName = String(Field.Key);
			Result = ValueIsFilled(CurrentRow[FieldName])
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

// See BatchProcessingOfTablePartClient.ProcessTSString
Procedure ProcessTSString(CurrentRow, StructureOfActions, CachedValues, AdditionalFillingParameters = Undefined) Export
	
	ProcessingOfLinesFillInSignOfAgreementInLineTS(CurrentRow, StructureOfActions, CachedValues);
	ProcessingStringsToFillInPropertiesOfRebatesSuppliers(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region BatchProcessingOfStrings

// Parameters:
//	CurrentRow - Structure:
//		* Terms - CatalogRef.TermsOfSale
//		* ThisIsModelAgreement - Boolean
//	StructureOfActions - See ProcessTSString.StructureOfActions
//	Cached_Values - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure ProcessingOfLinesFillInSignOfAgreementInLineTS(CurrentRow, StructureOfActions, Cached_Values)
	
	If Not StructureOfActions.Property("FillInAgreementAttributeInTSLine") Then
		Return;
	EndIf;
	
	SignOfAgreement = Cached_Values.SignsOfAgreements.Get(CurrentRow.Terms); // Boolean
	
	If SignOfAgreement <> Undefined Then
		CurrentRow.ThisIsModelAgreement = SignOfAgreement;
	EndIf;
	
EndProcedure

// Parameters:
//	CurrentRow - Structure:
//		* TermDocument - DocumentRef.ConditionsOfVendorRebates
//		* CurrencyIsDeterminedByCondition - Boolean
//		* BonusCurrency - CatalogRef.Currencies
//		* BonusType - EnumRef.VendorRebateTypes
//	StructureOfActions - See ProcessTSString.StructureOfActions
//	Cached_Values - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure ProcessingStringsToFillInPropertiesOfRebatesSuppliers(CurrentRow, StructureOfActions, Cached_Values)
	
	If StructureOfActions.Property("FillInCurrencyIndicationForRebatesOfSuppliers") Then
		CurrentRow.CurrencyIsDeterminedByCondition = False;
	EndIf;
	
	If StructureOfActions.Property("FillInCurrencyOfVendorSRebates") Then
		CurrentRow.BonusCurrency = PredefinedValue("Catalog.Currencies.EmptyRef");
	EndIf;
	
	If StructureOfActions.Property("FillInRebateTypeOfSuppliers") Then
		CurrentRow.BonusType = PredefinedValue("Enum.VendorRebateTypes.EmptyRef");
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

Procedure AddDecryptionFieldsByPartnerCounterparty(BonusType, DecryptionFields)
	
	If BonusType = PredefinedValue("Enum.VendorRebateTypes.Sales") Then
		
		DecryptionFields.Add("CounterpartyCustomer");
		
	ElsIf BonusType = PredefinedValue("Enum.VendorRebateTypes.Purchases") Then
		
		DecryptionFields.Add("CounterpartySupplier");
		DecryptionFields.Add("PartnerVendor");
		
	Else
		
		ErrorTemplate = NStr("vi = 'Sai loại thưởng ""%1""';
							|ru = 'Некорректный тип бонуса ""%1""';
							|en = 'Incorrect rebate type: ""%1""'; fa = 'Incorrect rebate type: ""%1""';
							|it = 'Некорректный тип бонуса ""%1""';
							|pl = 'Incorrect rebate type: ""%1""';
							|tr = '""%1"" bonus türü yanlış'");
		BonusTypeByString = String(BonusType);
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, BonusTypeByString);
		Raise ErrorText;
		
	EndIf;
	
EndProcedure

Procedure CloseResumeBonusCalculationsFromReportForm(ThisForm, DecryptionFields, CloseCalculations = True)
	
	ReportSpreadsheetDocument = ThisForm.ReportSpreadsheetDocument;
	DetailsDataAddress = ThisForm.ReportDetailsData;
	AreasWithTranscripts = DecryptionOfSelectedArea(ReportSpreadsheetDocument);
	Result = RebatesServerCall.CloseResumeBonusCalculationsFromReportForm(
		AreasWithTranscripts,
		DetailsDataAddress,
		DecryptionFields,
		CloseCalculations);
	
	ResultOfAnalysisOfAreas = Result.ResultOfAnalysisOfAreas;
	ResultOfStatusChange = Result.ResultOfStatusChange;
	
	TermsAndConditionsDocumentsWithAddresses = ResultOfAnalysisOfAreas.TermsAndConditionsDocumentsWithAddresses;
	ArrayOfAreaNames = ResultOfAnalysisOfAreas.ArrayOfAreaNames;
	ArrayOfConditionDocuments = ResultOfAnalysisOfAreas.ArrayOfConditionDocuments;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ThisForm", ThisForm);
	AdditionalParameters.Insert("SpreadsheetDocument", ReportSpreadsheetDocument);
	AdditionalParameters.Insert("ArrayOfConditionDocuments", ArrayOfConditionDocuments);
	AdditionalParameters.Insert("ArrayOfAreaNames", ArrayOfAreaNames);
	AdditionalParameters.Insert("TermsAndConditionsDocumentsWithAddresses", TermsAndConditionsDocumentsWithAddresses);
	AdditionalParameters.Insert("CloseCalculations", CloseCalculations);
	
	ReflectChangesInReportForm(ResultOfStatusChange, AdditionalParameters);
	
EndProcedure

// Parameters:
//  Result - Structure:
//   * HasErrors - Boolean
//   * ErrorInfo - String
//  AdditionalParameters - Structure:
//   * ThisForm - ClientApplicationForm:
//   ** CommentInHeader - String
//   * SpreadsheetDocument - SpreadsheetDocument
//   * ArrayOfConditionDocuments - Array of DocumentRef.ConditionsOfVendorRebates
//   * ArrayOfAreaNames - Array of String
//   * TermsAndConditionsDocumentsWithAddresses - Map of KeyAndValue:
//      ** Key - DocumentRef.ConditionsOfVendorRebates
//      ** Value - String 
//   * CloseCalculations - Boolean
//
Procedure ReflectChangesInReportForm(Result, AdditionalParameters)
	
	ClearMessages();
	
	ThisForm = AdditionalParameters.ThisForm;
	SpreadsheetDocument = AdditionalParameters.SpreadsheetDocument;
	CloseCalculations = AdditionalParameters.CloseCalculations;
	ArrayOfConditionDocuments = AdditionalParameters.ArrayOfConditionDocuments;
	TermsAndConditionsDocumentsWithAddresses = AdditionalParameters.TermsAndConditionsDocumentsWithAddresses;
	ArrayOfAreaNames = AdditionalParameters.ArrayOfAreaNames;
	
	If ArrayOfConditionDocuments.Count() = 0 Then
		
		MessageText = NStr("vi = 'Trong vùng được chọn, không có chứng từ để thay đổi trạng thái hạch toán';
							|ru = 'В выделенной области нет документов для изменения статуса расчета';
							|en = 'There are no documents in the selected area to change the calculation status'; fa = 'There are no documents in the selected area to change the calculation status';
							|it = 'В выделенной области нет документов для изменения статуса расчета';
							|pl = 'There are no documents in the selected area to change the calculation status';
							|tr = 'Seçili alanda alacak/borç muhasebesi durumunu değiştirecek belge yok'");
		CommonClient.MessageToUser(MessageText);
		Return;
		
	EndIf;
	
	If CloseCalculations Then
		
		Template = NStr("vi = '%1 (trạng thái hạch toán bị thay đổi sang ""Hạch toán bị đóng"")';
						|ru = '%1 (статус расчетов изменен на ""Расчеты закрыты"")';
						|en = '%1 (the status of settlements has been changed to ""Settlements closed"")'; fa = '%1 (the status of settlements has been changed to ""Settlements closed"")';
						|it = '%1 (статус расчетов изменен на ""Расчеты закрыты"")';
						|pl = '%1 (the status of settlements has been changed to ""Settlements closed"")';
						|tr = '%1 (""Alacak/borç muhasebesi"" kapatıldı)'");
		
	Else
		
		Template = NStr("vi = '%1 trạng thái hạch toán bị thay đổi sang ""Hạch toán được khôi phục"")';
						|ru = '%1 (статус расчетов изменен на ""Расчеты возобновлены"")';
						|en = '%1 (the status of settlements has been changed to ""Settlements resumed"")'; fa = '%1 (the status of settlements has been changed to ""Settlements resumed"")';
						|it = '%1 (статус расчетов изменен на ""Расчеты возобновлены"")';
						|pl = '%1 (the status of settlements has been changed to ""Settlements resumed"")';
						|tr = '%1 (""Alacak/borç muhasebesi"" yeniden başlatıldı)'");
		
	EndIf;
	
	HasErrors = Result.HasErrors;
	ErrorInfo = Result.ErrorInfo;
	
	If HasErrors Then
		
		CommonClient.MessageToUser(ErrorInfo);
		
	Else
		
		BackColor = CommonClient.StyleColor("BackgroundColorOfCompletedOperation");
		
		For Each AreaName In ArrayOfAreaNames Do
			
			TermDocument = TermsAndConditionsDocumentsWithAddresses[AreaName];
			Area = SpreadsheetDocument.Area(AreaName);
			Area.BackColor =  BackColor;
			
			ConditionsDocumentIsString = String(TermDocument);
			Text = StringFunctionsClientServer.SubstituteParametersToString(Template, ConditionsDocumentIsString);
			Area.Text = Text;
			
		EndDo;
		
		If CommonClientServer.HasAttributeOrObjectProperty(ThisForm, "CommentInHeader") Then
			
			ThisForm.CommentInHeader = NStr("vi = 'Đã thay đổi dữ liệu của trạng thái hạch toán. Cần tạo lại báo cáo';
											|ru = 'Изменились данные статусов расчетов. Необходимо повторно сформировать отчет';
											|en = 'The settlement status data has changed. The report must be regenerated'; fa = 'The settlement status data has changed. The report must be regenerated';
											|it = 'Изменились данные статусов расчетов. Необходимо повторно сформировать отчет';
											|pl = 'The settlement status data has changed. The report must be regenerated';
											|tr = 'Yerleştirme durumlarına dair veriler değiştirildi. Rapor yeniden oluşturulmalıdır'");
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
//  ReportSpreadsheetDocument - SpreadsheetDocument - Report tabular document
// 
// Returns:
//  Structure - Decryption Of The Selected Area:
//    * ArrayOfDecryptionIds - Array of DataCompositionDetailsID
//    * Decryption_Area - Map of KeyAndValue:
//      ** Key - DataCompositionDetailsID
//      ** Value - String - Area name
//
Function DecryptionOfSelectedArea(ReportSpreadsheetDocument)
	
	SplitString = "R";
	SeparatorColumn = "C";
	
	ArrayOfDecryptionIds = New Array; // Array of DataCompositionDetailsID
	Decryption_Area = New Map;
	SelectedAreas = ReportSpreadsheetDocument.SelectedAreas;
	
	For Each SelectedArea1 In SelectedAreas Do
		
		IndexOfStartColumn = SelectedArea1.Left;
		ColumnIndexEnd = SelectedArea1.Right;
		IndexOfLineIsBeginning = SelectedArea1.Top;
		IndexOfLineIsEnd = SelectedArea1.Bottom;
		
		If SelectedAreas.Count() = 1
		   And ColumnIndexEnd = 0
		   And IndexOfLineIsEnd = 0 Then
			
			IndexOfStartColumn = 1;
			ColumnIndexEnd = ReportSpreadsheetDocument.TableWidth;
			IndexOfLineIsBeginning = 1;
			IndexOfLineIsEnd = ReportSpreadsheetDocument.TableHeight;
			
		EndIf;
		
		While IndexOfStartColumn <= ColumnIndexEnd Do
			
			RowIndex = IndexOfLineIsBeginning;
			
			While RowIndex <= IndexOfLineIsEnd Do
				
				AreaNameCells = 
					SplitString
					+ Format(RowIndex, "NG=")
					+ SeparatorColumn
					+ Format(IndexOfStartColumn, "NG=");
					
				TableCellArea = ReportSpreadsheetDocument.Area(AreaNameCells);
				DetailsCell = TableCellArea.Details; // DataCompositionDetailsID
				
				If DetailsCell <> Undefined Then
					
					Decryption_Area.Insert(DetailsCell, AreaNameCells);
					ArrayOfDecryptionIds.Add(DetailsCell);
					
				EndIf;
				
				RowIndex = RowIndex + 1;
				
			EndDo;	
			
			IndexOfStartColumn = IndexOfStartColumn + 1;
			
		EndDo;	
		
	EndDo;
	
	Result = New Structure;
	Result.Insert("Decryption_Area", Decryption_Area);
	Result.Insert("ArrayOfDecryptionIds", ArrayOfDecryptionIds);
	
	Return Result;
	
EndFunction

// Parameters:
//   ThisForm - See CommonForm.ReportForm
//   ReportMenu - Array of Structure
//   CurrentVariantKey - String
//
Procedure ProcessDecryptionCalculationOfCustomerRebates(ThisForm, ReportMenu, CurrentVariantKey)
	
	If StrFind(Upper(CurrentVariantKey), Upper("Details")) > 0 Then
		Return;
	EndIf;
	
	SettingsReport = ThisForm.Report.SettingsComposer.UserSettings;
	
	KeyOfDecryptionOptionByItem = CommonClientServer.StructureProperty(
		SettingsReport.AdditionalProperties, "KeyOfDecryptionOptionByItem", "");
	KeyOfDecryptionOptionForDocuments = CommonClientServer.StructureProperty(
		SettingsReport.AdditionalProperties, "KeyOfDecryptionOptionForDocuments", "");
	
	ReportParameters = New Structure;
	ReportParameters.Insert("Name", KeyOfDecryptionOptionByItem);
	ReportParameters.Insert("Title", NStr("vi = 'Diễn giải theo mặt hàng';
											|ru = 'Расшифровка по номенклатуре';
											|en = 'Drill-down by items'; fa = 'تفکیک بر اساس اقلام';
											|it = 'Расшифровка по номенклатуре';
											|pl = 'Drill-down by items';
											|tr = 'Öğeye göre detaylandırılma'"));
	ReportParameters.Insert("ReportName", "Report.CalculateCustomerRebates");
	
	DecryptionFields = New Array; // Array of String
	DecryptionFields.Add("Organization");
	DecryptionFields.Add("Counterparty");
	DecryptionFields.Add("Partner");
	ReportParameters.Insert("DecryptionFields", DecryptionFields);
	
	ParametersList = New Array; // Array of String
	ParametersList.Add("DocumentTermsOfRetroBonuses");
	ParametersList.Add("Organization");
	ParametersList.Add("Counterparty");
	ParametersList.Add("Partner");
	ParametersList.Add("StartDate");
	ParametersList.Add("EndDate");
	ParametersList.Add("ReportData");
	ReportParameters.Insert("ParametersList", ParametersList);
	
	ReportMenu.Add(ReportParameters);
	
	ReportParameters = New Structure;
	ReportParameters.Insert("Name", KeyOfDecryptionOptionForDocuments);
	ReportParameters.Insert("Title", NStr("vi = 'Diễn giải theo chứng từ';
											|ru = 'Расшифровка по документам';
											|en = 'Drill-down by documents'; fa = 'تفکیک بر اساس اسناد';
											|it = 'Расшифровка по документам';
											|pl = 'Drill-down by documents';
											|tr = 'Belgeye göre detaylandırılma'"));
	ReportParameters.Insert("ReportName", "Report.CalculateCustomerRebates");
	
	DecryptionFields = New Array; // Array of String
	DecryptionFields.Add("Organization");
	DecryptionFields.Add("Counterparty");
	DecryptionFields.Add("Partner");
	ReportParameters.Insert("DecryptionFields", DecryptionFields);
	
	ParametersList = New Array; // Array of String
	ParametersList.Add("DocumentTermsOfRetroBonuses");
	ParametersList.Add("Organization");
	ParametersList.Add("Counterparty");
	ParametersList.Add("Partner");
	ParametersList.Add("StartDate");
	ParametersList.Add("EndDate");
	ParametersList.Add("ReportData");
	ReportParameters.Insert("ParametersList", ParametersList);
	
	ReportMenu.Add(ReportParameters);
	
EndProcedure

// Parameters:
//   ThisForm - See CommonForm.ReportForm
//   ReportMenu - Array of Structure
//   CurrentVariantKey - String
//
Procedure ProcessDecryptionCalculationOfVendorRebates(ThisForm, ReportMenu, CurrentVariantKey)
	
	If StrFind(Upper(CurrentVariantKey), Upper("Details")) > 0 Then
		Return;
	EndIf;
	
	SettingsReport = ThisForm.Report.SettingsComposer.UserSettings;
	
	KeyOfDecryptionOptionByItem = CommonClientServer.StructureProperty(
		SettingsReport.AdditionalProperties, "KeyOfDecryptionOptionByItem", "");
	KeyOfDecryptionOptionForDocuments = CommonClientServer.StructureProperty(
		SettingsReport.AdditionalProperties, "KeyOfDecryptionOptionForDocuments", "");
	BonusType = CommonClientServer.StructureProperty(
		SettingsReport.AdditionalProperties,
		"BonusType",
		PredefinedValue("Enum.VendorRebateTypes.EmptyRef"));
	
	If ValueIsFilled(KeyOfDecryptionOptionByItem)
	   And BonusType <> PredefinedValue("Enum.VendorRebateTypes.Balance") Then
		
		ReportParameters = New Structure;
		ReportParameters.Insert("Name", KeyOfDecryptionOptionByItem);
		ReportParameters.Insert("Title", NStr("vi = 'Diễn giải theo mặt hàng';
												|ru = 'Расшифровка по номенклатуре';
												|en = 'Drill-down by items'; fa = 'تفکیک بر اساس اقلام';
												|it = 'Расшифровка по номенклатуре';
												|pl = 'Drill-down by items';
												|tr = 'Öğeye göre detaylandırılma'"));
		ReportParameters.Insert("ReportName", "Report.CalculateVendorRebates");
		
		DecryptionFields = New Array; // Array of String
		DecryptionFields.Add("Organization");
		AddDecryptionFieldsByPartnerCounterparty(BonusType, DecryptionFields);
		ReportParameters.Insert("DecryptionFields", DecryptionFields);
		
		ParametersList = New Array; // Array of String
		ParametersList.Add("DocumentTermsOfRetroBonuses");
		ParametersList.Add("Organization");
		AddDecryptionFieldsByPartnerCounterparty(BonusType, ParametersList);
		ParametersList.Add("StartDate");
		ParametersList.Add("EndDate");
		ParametersList.Add("ReportData");
		ReportParameters.Insert("ParametersList", ParametersList);
		
		ReportMenu.Add(ReportParameters);
		
	EndIf;
	
	If BonusType = PredefinedValue("Enum.VendorRebateTypes.Purchases") Then
		
		ReportParameters = New Structure;
		ReportParameters.Insert("Name", KeyOfDecryptionOptionForDocuments);
		ReportParameters.Insert("Title", NStr("vi = 'Diễn giải theo chứng từ';
												|ru = 'Расшифровка по документам';
												|en = 'Drill-down by documents'; fa = 'تفکیک بر اساس اسناد';
												|it = 'Расшифровка по документам';
												|pl = 'Drill-down by documents';
												|tr = 'Belgeye göre detaylandırılma'"));
		ReportParameters.Insert("ReportName", "Report.CalculateVendorRebates");
		
		DecryptionFields = New Array; // Array of String
		DecryptionFields.Add("Organization");
		DecryptionFields.Add("Currency");
		DecryptionFields.Add("CalculationPeriod");
		AddDecryptionFieldsByPartnerCounterparty(BonusType, DecryptionFields);
		DecryptionFields.Add("Products");
		DecryptionFields.Add("Characteristic");
		DecryptionFields.Add("PropertyValue");
		ReportParameters.Insert("DecryptionFields", DecryptionFields);
		
		ParametersList = New Array; // Array of String
		ParametersList.Add("DocumentTermsOfRetroBonuses");
		ParametersList.Add("Organization");
		ParametersList.Add("Currency");
		ParametersList.Add("CalculationPeriod");
		AddDecryptionFieldsByPartnerCounterparty(BonusType, ParametersList);
		ParametersList.Add("StartDate");
		ParametersList.Add("EndDate");
		ParametersList.Add("ReportData");
		ReportParameters.Insert("ParametersList", ParametersList);
		
		ReportMenu.Add(ReportParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion