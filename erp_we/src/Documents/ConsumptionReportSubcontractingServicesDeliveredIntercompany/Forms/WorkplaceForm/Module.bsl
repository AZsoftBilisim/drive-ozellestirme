#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If TypeOf(Parameters.ListFormSelections) = Type("Structure") Then
		
		FillPropertyValues(ThisObject, Parameters.ListFormSelections);
		
	EndIf;
	
	PurposeUseKey = "ConsumptionReportSubcontractingServicesDeliveredIntercompany";
	
	CustomizeForm();
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	// If the selections are already loaded from the parameters
	If TypeOf(Parameters.ListFormSelections) = Type("Structure") Then
		If Parameters.ListFormSelections.Property("Organization") Then
			Settings.Delete("Organization");
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ConfigureDependentFormElements(ThisObject);
	
	FillOutReportsForRegistration();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ConsumptionReportSubcontractingServicesDeliveredIntercompany"
		Or EventName = "Write_BackflushProduction"
		Or EventName = "Write_ProductionCostAllocation"
		Or EventName = "Write_AllocationOfOtherCosts"
		Or EventName = "Write_ProductionStages"
		Or EventName = "Accept_FormOfCreatedDocuments"
		Or EventName = "Conducting_Storno"
		Or EventName = "Write_ReversingEntry" Then
		FillOutReportsForRegistration();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject, "Organization");
	
	FillOutReportsForRegistration();
	
EndProcedure

&AtClient
Procedure MaterialProviderOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject, "MaterialProvider");
	
	FillOutReportsForRegistration();
	
EndProcedure

&AtClient
Procedure SeeAlsoInProgressURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	ListFormSelections = New Structure;
	ListFormSelections.Insert("Organization", Organization);
	
	LogParameters = New Structure;
	LogParameters.Insert("QuickFilterStructure",     ListFormSelections);
	LogParameters.Insert("PurposeUseKey", PurposeUseKey);
	
	OpenForm(FormattedStringURL, LogParameters);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersReportsToBeProcessed

&AtClient
Procedure ReportsToBeProcessedSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.ReportsToBeProcessed.CurrentData;
	If Not CurrentData = Undefined Then
		AttributeName    = StrReplace(Field.Name, "ReportsToBeProcessed", "");
		Simple = CurrentData[AttributeName];
		If ValueIsFilled(Simple) Then
			ShowValue(, Simple);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	FillOutReportsForRegistration();
	
EndProcedure

&AtClient
Procedure ApplyAppearance(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Form.WorkplaceForm.ApplyAppearance");
	
	SelectedRows = Items.ReportsToBeProcessed.SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(SelectedRows, LogParameters()) Then
		Return;
	EndIf;
	
	ClearMessages();
	
	GroupingOrders = New Array;
	GroupFields = "Month,Organization,MaterialProvider,LineOfBusiness";
	
	For Each RowID In SelectedRows Do
		
		CurrentData = ReportsToBeProcessed.FindByID(RowID);
		CurrentGroup = Undefined;
		
		For Each GroupsValues In GroupingOrders Do
			If TMCommonUseClientServer.StructuresAreEqual(GroupsValues, CurrentData, GroupFields) Then
				CurrentGroup = GroupsValues;
				Break;
			EndIf;
		EndDo;
		
		If CurrentGroup = Undefined Then
			
			CurrentGroup = New Structure(GroupFields);
			FillPropertyValues(CurrentGroup, CurrentData);
			
			CurrentGroup.Insert("ProductionLots", New Array);
			
			GroupingOrders.Add(CurrentGroup);
			
		EndIf;
		
		CurrentGroup.ProductionLots.Add(CurrentData.ProductionLot);
		
	EndDo;
	
	If ValueIsFilled(GroupingOrders) Then
		
		Result = IssueAtServer(GroupingOrders);
		ErrorList = Result.ErrorList;
		ParametersOfCreatedDocuments = Result.ParametersOfCreatedDocuments;
		
		InvoicesClient.OpenFormForCreatedDocuments(ParametersOfCreatedDocuments, ThisObject);
		
		CommonClientServer.ReportErrorsToUser(ErrorList);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region FormSettings

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Mandatory registration for completed batches of production.
	Item = ConditionalAppearance.Items.Add();
	
	TMCommonUse.FillInConditionalAppearanceFieldsRecursively(Item.Fields, Items.ReportsToBeProcessed.ChildItems);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReportsToBeProcessed.StatusID");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 2;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
	// The Status of the party is "In progress".
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReportsToBeProcessedStatus.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReportsToBeProcessed.StatusID");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;
	
	Item.Appearance.SetParameterValue("Text", Catalogs.ProductionLots.TextOfStatusInProgress());
	
	// The Status of the batch is "Completed".
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReportsToBeProcessedStatus.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReportsToBeProcessed.StatusID");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 2;
	
	Item.Appearance.SetParameterValue("Text", Catalogs.ProductionLots.StatusTextCompleted());
	
EndProcedure

&AtServer
Procedure CustomizeForm()
	
	Items.ReportsToBeProcessedApplyAppearance.Enabled = AccessRight("Insert", Metadata.Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany);
	
	#Region SeeAlso
	
	GenerationParameters = New Structure;
	
	ArrayCalculationManagersSeeAlsoInWork = New Array();
	ArrayCalculationManagersSeeAlsoInWork.Add("Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany");
	
	SeeAlsoInProgress = TMCommonUse.CreateHyperlinkSeeAlsoIn(ArrayCalculationManagersSeeAlsoInWork, GenerationParameters);
	Items.SeeAlsoInProgress.Visible = ValueIsFilled(SeeAlsoInProgress);
	
	#EndRegion
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, Attributes = "")
	
	Items = Form.Items;
	
	Attributes = New Structure(Attributes);
	Initialize = Attributes.Count() = 0;
	
	If Initialize
		Or Attributes.Property("Organization") Then
		
		If CommonClientServer.HasAttributeOrObjectProperty(Items, "Organization") Then
			Items.ReportsToBeProcessedOrganization.Visible = Not ValueIsFilled(Form.Organization);
		EndIf;
		
	EndIf;
	
	If Initialize
		Or Attributes.Property("MaterialProvider") Then
		
		If CommonClientServer.HasAttributeOrObjectProperty(Items, "MaterialProvider") Then
			Items.ReportsToBeProcessedMaterialProvider.Visible = Not ValueIsFilled(Form.MaterialProvider);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormServiceCommandHandlers

&AtServer
Function IssueAtServer(GroupingOrders)
	
	ErrorList = Undefined;
	
	ParametersOfCreatedDocuments      = New Structure("FormName, Parameters");
	FormParametersForCreatedDocuments = FormParametersForCreatedDocuments();
	
	If GroupingOrders.Count() = 1 Then
		
		ParametersOfCreatedDocuments.FormName = "Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.ObjectForm";
		ParametersOfCreatedDocuments.Parameters = New Structure("Basis", GroupingOrders[0]);
		
	Else
		
		CreatedDocuments = New Array;
		For Each GroupsValues In GroupingOrders Do
			
			DocumentObject = Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.CreateDocument();
			DocumentObject.Fill(GroupsValues);
			DocumentObject.Date = ?(ValueIsFilled(DocumentObject.Date), DocumentObject.Date, CurrentSessionDate());
			
			Cancel = Not DocumentObject.CheckFilling();
			If Not Cancel Then
				Try
					DocumentObject.Write(DocumentWriteMode.Posting);
				Except
					WriteLogEvent(
						NStr("vi = 'Lỗi khi kết chuyển chứng từ';
							|ru = 'Ошибка при проведении документа';
							|en = 'An error occurred while posting the document'; fa = 'An error occurred while posting the document';
							|it = 'Errore durante la registrazione del documento';
							|pl = 'Błąd podczas zaksięgowania dokumentu';
							|tr = 'Belge kaydı sırasında hata'",
						Common.DefaultLanguageCode()),
						EventLogLevel.Error,,,
						ErrorProcessing.DetailErrorDescription(ErrorInfo()));
					Cancel = True;
				EndTry;
			EndIf;
			
			If Cancel Then
				
				DocumentObject.Write(DocumentWriteMode.Write);
				
				Messages = GetUserMessages(True);
				For Each Message In Messages Do
					CommonClientServer.AddUserError(ErrorList, "ReportsToBeProcessed", Message.Text, Undefined);
				EndDo;
				
				ErrorText = NStr("vi = 'Không thể kết chuyển chứng từ - %1';
								|ru = 'Не удалось провести документ - %1';
								|en = 'Cannot post the document: %1'; fa = 'Cannot post the document: %1';
								|it = 'Impossibile registrare il documento - %1';
								|pl = 'Nie udało się zaksięgować dokument - %1';
								|tr = 'Belge kaydedilemedi - %1'");
				ErrorText = StrTemplate(ErrorText, DocumentObject.Ref);
				
				CommonClientServer.AddUserError(ErrorList, "ReportsToBeProcessed", ErrorText, Undefined);
				
			EndIf;
			
			UserWorkHistory.Add(DocumentObject.Ref);
			CreatedDocuments.Add(DocumentObject.Ref);
			
		EndDo;
		
		Owner = Users.AuthorizedUser();
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(Owner, CreatedDocuments, FormParametersForCreatedDocuments.DataKey);
		SetPrivilegedMode(False);
		
		ParametersOfCreatedDocuments.FormName = "CommonForm.CreatedDocumentForm";
		ParametersOfCreatedDocuments.Parameters = FormParametersForCreatedDocuments;
		ParametersOfCreatedDocuments.Insert("NumberOfDocumentsCreated", CreatedDocuments.Count());
		
	EndIf;
	
	Result = New Structure;
	Result.Insert("ParametersOfCreatedDocuments", ParametersOfCreatedDocuments);
	Result.Insert("ErrorList", ErrorList);
	
	Return Result;
	
EndFunction

&AtServer
Function FormParametersForCreatedDocuments()
	
	FormParameters = New Structure("DataKey, VisibleColumns, UpdateEvents",
		PurposeUseKey, New Array, New Array);
	
	FormParameters.VisibleColumns.Add("Number");
	FormParameters.VisibleColumns.Add("Date");
	FormParameters.VisibleColumns.Add("ValueType");
	FormParameters.VisibleColumns.Add("BusinessOperation");
	FormParameters.VisibleColumns.Add("Organization");
	FormParameters.VisibleColumns.Add("LineOfBusiness");
	FormParameters.VisibleColumns.Add("More");
	
	FormParameters.UpdateEvents.Add("Write_ConsumptionReportSubcontractingServicesDeliveredIntercompany");
	
	Return FormParameters;
	
EndFunction

#EndRegion

#Region FillingOutReportsForRegistration

&AtClient
Procedure FillOutReportsForRegistration()
	
	BackgroundJob = FillOutReportsForRegistrationServer();
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = True;
	Handler = New CallbackDescription("FillOutReportsForRegistrationCompletion", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(BackgroundJob, Handler, WaitSettings);
	
EndProcedure

&AtServer
Function FillOutReportsForRegistrationServer()
	
	BackgroundExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	BackgroundExecutionParameters.BackgroundJobDescription = NStr("vi = 'Điền danh sách bảng kê cho người đặt gia công giữa các doanh nghiệp cần lập.';
																	|ru = 'Заполнение списка отчетов давальцу между организациями к оформлению.';
																	|en = 'Fill the list of ""Intercompany consumption reports — Subcontracting services delivered"" to register.'; fa = 'Fill the list of ""Intercompany consumption reports — Subcontracting services delivered"" to register.';
																	|it = 'Заполнение списка отчетов давальцу между организациями к оформлению.';
																	|pl = 'Fill the list of ""Intercompany consumption reports — Subcontracting services delivered"" to register.';
																	|tr = 'İş yerleri arasında düzenlenecek tedarikçi için tüketim raporları listesinin doldurulması.'");
	
	BackgroundJob =
		TimeConsumingOperations.ExecuteInBackground(
			"Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.FillOutReportsForRegistration",
			ParametersForFillingInReportsForRegistration(),
			BackgroundExecutionParameters);
		
	Return BackgroundJob;
	
EndFunction

&AtClient
Procedure FillOutReportsForRegistrationCompletion(BackgroundJob, AdditionalParameters) Export
	
	If BackgroundJob <> Undefined 
		And BackgroundJob.Status = "Completed2" Then
	
		If IsTempStorageURL(BackgroundJob.ResultAddress) Then
			UploadReportsForRegistration(BackgroundJob.ResultAddress);
		EndIf;
		
	Else
		
		If BackgroundJob <> Undefined Then
			ErrorDescription = NStr("vi = 'Không thể hoàn thành nhiệm vụ do: %Cause%';
									|ru = 'Не удалось закончить выполнения задания по причине: %Cause%';
									|en = 'Cannot complete job. Reason: %Cause%'; fa = 'Cannot complete job. Reason: %Cause%';
									|it = 'Non è stato possibile completare il task a causa di: %Cause%';
									|pl = 'Nie udało się ukończyć zadanie z powodu: %Cause%';
									|tr = 'Görev gerçekleştirmesinin bitememe nedeni: %Cause%'");
			ErrorDescription = StrReplace(ErrorDescription, "%Cause%",  BackgroundJob.DetailErrorDescription);
			ShowMessageBox(, ErrorDescription);
		EndIf;
		
		ReportsToBeProcessed.Clear();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UploadReportsForRegistration(AddressInTempStorage)
	
	Result = GetFromTempStorage(AddressInTempStorage);
	
	If Not Result = Undefined Then
		ReportsToBeProcessed.Load(Result);
	Else
		ReportsToBeProcessed.Clear();
	EndIf;
	
EndProcedure

&AtServer
Function ParametersForFillingInReportsForRegistration()
	
	FillParameters = Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.ParametersForRequestingReportBalancesForRegistration();
	
	FillParameters.Organization = Organization;
	FillParameters.MaterialProvider     = MaterialProvider;
	
	Return FillParameters;
	
EndFunction

#EndRegion

&AtClient
Function LogParameters()
	
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization", Organization);
	
	LogParameters = New Structure;
	LogParameters.Insert("QuickFilterStructure", QuickFilterStructure);
	LogParameters.Insert("WorkplaceName",        "LogOfIntercompanyDocuments");
	LogParameters.Insert("FormAssignmentKey",     "ConsumptionReportSubcontractingServicesDeliveredIntercompany");
	LogParameters.Insert("JournalSynonym",          NStr("vi = 'Chứng từ giữa các doanh nghiệp';
														|ru = 'Документы между организациями';
														|en = 'Documents between companies'; fa = 'Documents between companies';
														|it = 'Documenti tra organizzazioni';
														|pl = 'Dokumenty międzyfirmowe';
														|tr = 'İş yerleri arasındaki belgeler'"));
	
	Return LogParameters;
	
EndFunction

#EndRegion