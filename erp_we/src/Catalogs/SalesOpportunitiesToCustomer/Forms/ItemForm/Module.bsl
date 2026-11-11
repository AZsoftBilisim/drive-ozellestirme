
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
		
	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// Handler of the "Properties" mechanism
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// caching values
	CurrencyOfManAccounting                   = Constants.ManagementAccountingCurrency.Get();
	LostTransaction                  = (Object.Status = Enums.OpportunityStatuses.Lost);
	ProcessesAreUsed             = GetFunctionalOption("UseOpportunityManagement");
	LossReasonIsNotDetermined     = Catalogs.ReasonsForLosingSalesOpportunities.EmptyRef();
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	
	UseRolesOfPartnersAndContactPersons = GetFunctionalOption("UseRolesOfPartnersAndContactPersonsInSalesOpportunitiesAndProjects");
	If UseRolesOfPartnersAndContactPersons Then
		RoleClient    = Catalogs.PartnerRolesInSalesOpportunitiesAndProjects.Client;
		RoleCompetitor = Catalogs.PartnerRolesInSalesOpportunitiesAndProjects.Competitor;
	EndIf;
	
	ManagingVisibilityOfCommandsOnServer();
	
	// Handler of the "Interaction" subsystem
	Interactions.PrepareNotifications(ThisForm,Parameters);
	
	If Not NotificationRequired And Parameters.Property("NotificationRequired") Then
		NotificationRequired = True;
	EndIf;
	
	If Object.Ref.IsEmpty() Then
		OnCreatReadAtServer();
	EndIf;
	
	SetDetailsHeaders();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	ProcessesAreUsed = GetFunctionalOption("UseOpportunityManagement");
	OnCreatReadAtServer();
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If EventName = "Write_PerformerTask" Or EventName = "Write_StatisticsOfCustomerOpportunities" Then
		If Parameter.Property("SalesOpportunity") And Parameter.SalesOpportunity = Object.Ref Then
			SaleProcessStage = CurrentStep(Object.Ref);
			If ValueIsFilled(SaleProcessStage) And ValueIsFilled(ProcessSteps) Then
				IndexOfCurrentStage = ProcessSteps.Find(SaleProcessStage);
				InstallStageManagement();
			EndIf;
		EndIf;
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	TypeOfTransactionType = Common.ObjectAttributeValue(Object.SalesOpportunityKind, "SalesOpportunityType");

	If Object.SalesOpportunityKind <> CurrentObject.SalesOpportunityKind Then
		OpportunityKindIsChanged = True;
		SalesOpportunityType = TypeOfTransactionType;
	EndIf;

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	// Confirm the fixation of the loss at the current stage for sales processes managed "manually".
	If ProcessesAreUsed And Not LostTransaction And Not ResponseToLossRecordingIsReceived
		And Object.Status = PredefinedValue("Enum.OpportunityStatuses.Lost")
		And (SalesOpportunityType = PredefinedValue("Enum.TypesOfCustomerOpportunities.SalesOpportunitiesWithManualStageAdvancement") Or Object.ManualControlEnabled) Then
		
		Cancel = True;
		
		NotifyDescriptionQuestion = New CallbackDescription("QuestionFixingLossOfTransactionAtEnd", ThisObject, WriteParameters);
		ShowQueryBox(NotifyDescriptionQuestion ,NStr("vi = 'Ghi nhận thất bại vụ việc trong giai đoạn này. Tiếp tục?';
													|ru = 'Фиксация проигрыша сделки на текущем этапе. Продолжить?';
													|en = 'Recording loss of the sales opportunity during the current stage. Continue?'; fa = 'Recording loss of the sales opportunity during the current stage. Continue?';
													|it = 'Fissazione della perdita di transazione nella fase attuale. Continuare?';
													|pl = 'Zachowanie przegranej umowy na bieżącym etapie. Kontynuować?';
													|tr = 'Mevcut aşamada satış fırsatının kaybedilmesinin düzeltilmesi. Devam edilsin mi?'"),
		               QuestionDialogMode.YesNo, , DialogReturnCode.No);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject)

	SetPrivilegedMode(True);
	
	// Let's establish the subject of interaction
	If ValueIsFilled(InteractionBasis) Then
		Interactions.OnWriteSubjectFromForm(
			CurrentObject.Ref, InteractionBasis, Cancel);
	EndIf;

	// process process management
	If ValueIsFilled(Object.SalesOpportunityKind)
		And ProcessesAreUsed
		And SalesOpportunityType <> Enums.TypesOfCustomerOpportunities.OtherNonProcessSalesOpportunities Then
		
		If OpportunityKindIsChanged Then
			InstallProcessManagement();
		EndIf;

		Items.SalesOpportunityKind.ReadOnly = True;
		If SalesOpportunityType = Enums.TypesOfCustomerOpportunities.SalesOpportunitiesWithManualStageAdvancement
			Or CurrentObject.ManualControlEnabled Then

			If OpportunityKindIsChanged Then
				InstallProcessManagement();
			EndIf;
			
			// fix the transition to the selected stage
			If SaleProcessStage <> SalesOpportunitiesServer.GetCurStage(CurrentObject.Ref) Then
				SalesOpportunitiesServer.SetProcessStage(CurrentObject.Ref, SaleProcessStage);
			EndIf;
		ElsIf (CurrentObject.Status = Enums.OpportunityStatuses.Lost) And Not LostTransaction Then
			SalesOpportunitiesServer.RestartSalesProcess(CurrentObject.Ref, SalesOpportunityType);
			LostTransaction = True;
		ElsIf Not Object.Closed_ Then
			SalesOpportunitiesServer.StartProcess(CurrentObject.Ref);
		EndIf;
	EndIf;

	// fix primary interest
	Interest = PrimaryInterest(CurrentObject.Ref);
	If ChannelOfInitialRequest <> Interest.ChannelOfInitialRequest
		Or SourceOfInitialRequest <> Interest.SourceOfInitialRequest 
		Or CurrentObject.Partner <> Interest.Partner Then
		
		RecordSet = InformationRegisters.SourcesOfInitialRequests.CreateRecordSet();
		RecordSet.Filter.SalesOpportunity.Set(CurrentObject.Ref);
		
		If ValueIsFilled(ChannelOfInitialRequest)
		   Or ValueIsFilled(SourceOfInitialRequest) Then
			Record = RecordSet.Add();
			Record.Partner                    = CurrentObject.Partner;
			Record.SalesOpportunity                     = CurrentObject.Ref;
			Record.SourceOfInitialRequest = SourceOfInitialRequest;
			Record.ChannelOfInitialRequest    = ChannelOfInitialRequest;
		EndIf;
		
		RecordSet.Write();
		
	EndIf;

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	SetPrivilegedMode(True);
	
	// process process management
	If ValueIsFilled(Object.SalesOpportunityKind) And ProcessesAreUsed Then

		// update the current stage
		If SalesOpportunityType <> Enums.TypesOfCustomerOpportunities.OtherNonProcessSalesOpportunities Then
			SaleProcessStage = SalesOpportunitiesServer.GetCurStage(Object.Ref);
		EndIf;

		InstallProcessManagement();
	EndIf;
	
	DetermineAvailabilityOfTransactionType();

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	If NotificationRequired Then
		
		WriteParameters.Insert("Partner",Object.Partner);
		WriteParameters.Insert("CustomerTermsOfSales",Object.CustomerTermsOfSales);
		InteractionsClient.InteractionSubjectAfterWrite(ThisForm,Object,WriteParameters,"SalesOpportunitiesToCustomer");
		
	EndIf;
	
	AvailabilityControl();

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	AvailabilityControl();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "GroupAdditionalAttributes"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure CustomerTermsOfSalesStartChoice(Item, ChoiceData, StandardProcessing)

	AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
	
	AgreementSelectionParameters.Item              = Item;
	AgreementSelectionParameters.Partner              = Object.Partner;
	AgreementSelectionParameters.Document             = Object.CustomerTermsOfSales;
	AgreementSelectionParameters.FormDataStructure = Object;

	SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure StatusOnChange(Item)

	If Object.Status = PredefinedValue("Enum.OpportunityStatuses.InProgress") Then
		If Not (SalesOpportunityType = PredefinedValue("Enum.TypesOfCustomerOpportunities.OtherNonProcessSalesOpportunities")
			Or SalesOpportunityType = PredefinedValue("Enum.TypesOfCustomerOpportunities.EmptyRef")) Then
			InstallProcessManagement();
		EndIf;
		Items.PreviousStage.Enabled = True;
		Items.NextStage.Enabled  = True;
		Items.ReasonForLosingSalesOpportunity.ReadOnly = True;
		Object.ReasonForLosingSalesOpportunity       = LossReasonIsNotDetermined;
	Else
		Items.PreviousStage.Enabled = False;
		Items.NextStage.Enabled  = False;
		If Not Object.Status = PredefinedValue("Enum.OpportunityStatuses.Lost") Then
			Object.ReasonForLosingSalesOpportunity = LossReasonIsNotDetermined;
		EndIf;
	EndIf;
	
	ClearMarkIncomplete();
	AvailabilityControl();

EndProcedure

&AtClient
Procedure Closed_OnChange(Item)
	
	If Object.Closed_ Then
		Object.EndDate = CommonClient.SessionDate();
	Else
		Object.EndDate = '00010101';
	EndIf;
	
	AvailabilityControl();
	
EndProcedure

&AtClient
Procedure ChannelOfInitialRequestOnChange(Item)

	SourceOfInitialRequest = Undefined;
	Items.SourceOfInitialRequest.ReadOnly = Not ValueIsFilled(ChannelOfInitialRequest);

EndProcedure

&AtClient
Procedure StatusClearing(Item, StandardProcessing)

	StandardProcessing = False;

EndProcedure

&AtClient
Procedure ClientOnChange(Item)
	
	If ToUseTermsOfSales Then
		If Object.Partner.IsEmpty() Then
			Object.CustomerTermsOfSales = PredefinedValue("Catalog.TermsOfSale.EmptyRef");
		Else
			
			StructureCustomerAgreement = GetDefaultSalesTerms(Object.Partner);
			
			If StructureCustomerAgreement = Undefined Then
				Object.CustomerTermsOfSales = PredefinedValue("Catalog.TermsOfSale.EmptyRef");
			Else
				Object.CustomerTermsOfSales = StructureCustomerAgreement.Terms;
			EndIf;
			
		EndIf;
	EndIf;
	TransactionParticipantParametersAreChanged = True;
	
EndProcedure

&AtClient
Procedure SalesOpportunityKindOnChange(Item)
	
	WhenChangingTransactionTypeServer();
	AvailabilityControl();
	
EndProcedure

&AtServer
Procedure WhenChangingTransactionTypeServer()

	DetermineTypeOfTransaction();
	UsingPrimaryDemand();
	
	If ValueIsFilled(Object.SalesOpportunityKind) Then
		Object.EnabledGoodsAssignmentInSalesOpportunity = Common.ObjectAttributeValue(Object.SalesOpportunityKind, "EnabledGoodsAssignmentInSalesOpportunity");
	EndIf;

EndProcedure

&AtServer
Procedure DetermineTypeOfTransaction()
	
	If ValueIsFilled(Object.SalesOpportunityKind) Then
		SalesOpportunityType = Common.ObjectAttributeValue(Object.SalesOpportunityKind,"SalesOpportunityType");
	Else
		SalesOpportunityType = Enums.TypesOfCustomerOpportunities.EmptyRef();
	EndIf;
	
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure ReasonForLosingSalesOpportunityOnChange(Item)
	
	AvailabilityControl();
	ClearMarkIncomplete();
	
EndProcedure

&AtClient
Procedure EmployeeResponsibleOnChange(Item)
	ClearMarkIncomplete();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPrimaryDemand

&AtClient
Procedure SatisfactionPercentageOnChange(Item)
	
	CurrentData = Items.PrimaryDemand.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	SatisfactionPercentage = CurrentData.SatisfactionPercentage;
	
	If SatisfactionPercentage = 100 Then
		
		CurrentData.ReasonForNonFulfillment = PredefinedValue("Catalog.ReasonsForPrimaryDemandNonFulfillment.EmptyRef");
		
	EndIf;
	
EndProcedure 

&AtClient
Procedure ReasonForNonFulfillmentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.PrimaryDemand.CurrentData;
	If CurrentData = Undefined Then
		StandardProcessing = False;
		Return;
	EndIf;
	
	If CurrentData.SatisfactionPercentage >= 100 Then
		StandardProcessing = False;
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure SumOnChange(Item)
	
	CurrentData = Items.PrimaryDemand.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure PrimaryDemandOnActivateCell(Item)
	
	CurrentData = Items.PrimaryDemand.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Item.CurrentItem.Name = "SatisfactionPercentage" Then
		
		Items.SatisfactionPercentage.ChoiceList.Clear();
		For Indus = 0 To 9 Do
			Items.SatisfactionPercentage.ChoiceList.Add(Indus*10,String(Indus*10) + "% (" + String(Format(CurrentData.Sum/10 * Indus,"NFD=2")) + ")");
		EndDo;
		Items.SatisfactionPercentage.ChoiceList.Add(100,String(100) + "% (" + String(Format(CurrentData.Sum,"NFD=2")) + ")");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPartnersAndContactPersons

&AtClient
Procedure ContactPersonOnChange(Item)

	CurrentData = Items.PartnersAndContactPersons.CurrentData;
	CurrentData.Partner = ContactPersonSPartner(CurrentData.ContactPerson);
	If UseRolesOfPartnersAndContactPersons And CurrentData.Partner = Object.Partner Then
		CurrentData.PartnerSRole = RoleClient;
	EndIf;

EndProcedure

&AtClient
Procedure PartnerOnChange(Item)

	CurrentData = Items.PartnersAndContactPersons.CurrentData;
	If UseRolesOfPartnersAndContactPersons Then
		If CurrentData.Partner = Object.Partner Then
			CurrentData.PartnerSRole = RoleClient;
		Else
			CurrentData.PartnerSRole = Undefined;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure PartnersAndContactPersonsOnStartEdit(Item, NewRow, Copy)

	If NewRow Then
		Item.CurrentData.SalesOpportunityWinner = False;
	EndIf;

EndProcedure

&AtClient
Procedure PartnersAndContactPersonsOnChange(Item)
	
	TransactionParticipantParametersAreChanged = True;
	
EndProcedure

&AtClient
Procedure SalesOpportunityWinnerOnChange(Item)
	
	CurrentData = Items.PartnersAndContactPersons.CurrentData;
	
	If CurrentData <> Undefined Then
		If CurrentData.SalesOpportunityWinner Then
			
			CurrentIndex = Object.PartnersAndContactPersons.IndexOf(CurrentData);
			For Each StringMembers In Object.PartnersAndContactPersons Do
				If Object.PartnersAndContactPersons.IndexOf(StringMembers) <> CurrentIndex Then
					StringMembers.SalesOpportunityWinner = False;
				EndIf;
			EndDo;
			
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure PartnerSRoleOnChange(Item)
	
	CurrentData = Items.PartnersAndContactPersons.CurrentData;
	If CurrentData <> Undefined
		And CurrentData.PartnerSRole <> PredefinedValue("Catalog.PartnerRolesInSalesOpportunitiesAndProjects.Competitor")
		And CurrentData.SalesOpportunityWinner Then
		
		 CurrentData.SalesOpportunityWinner = False;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

&AtClient
Procedure NextStage(Command)

	GoToProcessStage(1);

EndProcedure

&AtClient
Procedure PreviousStage(Command)

	GoToProcessStage(-1);

EndProcedure

&AtClient
Procedure CalculateByDocuments(Command)

	ClearMessages();
	
	If ValueIsFilled(CurrencyOfManAccounting) Then
		CancelingObjectRecording(New CallbackDescription("CalculateByDocumentsAfterCancellationOfRecord", ThisObject));	
		Modified = True;
	Else
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa chỉ ra tiền tệ kế toán quản trị. Không thể tính.';
												|ru = 'Не указана валюта управленческого учета. Расчет невозможен.';
												|en = 'Currency of management accounting is not specified. Cannot calculate.'; fa = 'Currency of management accounting is not specified. Cannot calculate.';
												|it = 'Valuta della contabilità gestionale non è specificata. Il calcolo non è possibile.';
												|pl = 'Nie wskazano waluty ewidencji zarządczej. Rozliczenie nie jest możliwe.';
												|tr = 'Yönetim muhasebesi para birimi belirtilmedi. Hesaplama mümkün değil.'"));
	EndIf;

EndProcedure

&AtClient
Procedure CalculateByDocumentsAfterCancellationOfRecord(Result, AdditionalParameters) Export
    
    If Not ValueIsFilled(Object.Ref) And Result Then
        Return;
    EndIf;
    
    OpenForm(
    "Catalog.SalesOpportunitiesToCustomer.Form.CalculatePotential",
    New Structure("Key, CurrencyOfManAccounting", Object.Ref, CurrencyOfManAccounting),,,,, New CallbackDescription("CalculateByDocumentsCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure CalculateByDocumentsCompletion(Result, AdditionalParameters) Export
    
    Potential = Result;
    
    If Not Result = DialogReturnCode.Cancel And  ValueIsFilled(Potential) Then
        Object.PotentialSaleAmount = Potential;
    EndIf;

EndProcedure

&AtClient
Procedure OpenTheRouteMapExecute()

	Process_ = SalesProcess(SalesOpportunityType, Object.Ref);
	OpenForm("DataProcessor.BusinessProcessFlowchart.Form",
		New Structure("BusinessProcess", Process_),);

EndProcedure

&AtClient
Procedure SwitchToManualControl(Command)

	If Not ValueIsFilled(Object.Ref) Then
		
		Response = Undefined;

		
		ShowQueryBox(New CallbackDescription("SwitchToManualControlAfterQuestion", ThisObject), 
		NStr("vi = 'Trước khi thực hiện, cần ghi lại vụ việc.
			|Ghi lại và tiếp tục?';
			|ru = 'Перед выполнением необходимо записать сделку.
			|Записать и продолжить?';
			|en = 'You need to save the sales opportunity before performing this operation.
			|Do you want to save and continue?'; fa = 'You need to save the sales opportunity before performing this operation.
			|Do you want to save and continue?';
			|it = 'Prima di eseguire, è necessario registrare la transazione.
			|Registrare e continuare?';
			|pl = 'Przed wykonaniem należy zapisać umowę.
			|Zapisać i kontynuować?';
			|tr = 'İşlem yapmadan önce satış fırsatını kaydetmeniz gerekmektedir.
			|Kaydedilsin ve devam edilsin mi?'"
		),
		QuestionDialogMode.YesNo);
        Return;
		
	EndIf;

	SwitchToManualFragmentManagement();
EndProcedure

&AtClient
Procedure SwitchToManualControlAfterQuestion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
    
    
    SwitchToManualFragmentManagement();

EndProcedure

&AtClient
Procedure SwitchToManualFragmentManagement()
	
	ShowQueryBox(New CallbackDescription("SwitchToManualControlCompletion", ThisObject), 
	               NStr("vi = 'Tất cả nhiệm vụ hiện tại theo quy trình bán hàng sẽ bị hủy, quy trình nghiệp vụ sẽ hoàn thành.
	                         |Tiếp tục?';
	                         |ru = 'Все текущие задачи по процессу продажи будут отменены, бизнес-процесс будет завершен.
	                         |Продолжить?';
	                         |en = 'All the current sale tasks will be canceled, business process will be finished.
	                         |Continue?'; fa = 'All the current sale tasks will be canceled, business process will be finished.
	                         |Continue?';
	                         |it = 'Tutte le attività correnti nel processo di vendita saranno annullate, il processo aziendale verrà completato.
	                         |Continuare?';
	                         |pl = 'Wszystkie bieżące zadania w ramach procesu sprzedaży zostaną anulowane, proces biznesowy zostanie zakończony.
	                         |Kontynuować?';
	                         |tr = 'Mevcut tüm satış süreci görevleri iptal edilecek ve iş süreci tamamlanacaktır.
	                         |Devam edilsin mi?'"),
	               QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SwitchToManualControlCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
    
    CompleteSaleProcess();

EndProcedure

&AtClient
Procedure ViewProcessPlan(Command)

	CancelingObjectRecording(New CallbackDescription("ViewProcessPlanCompletion", ThisObject));

EndProcedure

&AtClient
Procedure ViewProcessPlanCompletion(Result, AdditionalParameters) Export
	
	If (Modified Or Not ValueIsFilled(Object.Ref)) And Result Then
		Return;
	EndIf;
	
	OpenForm("Catalog.SalesOpportunitiesToCustomer.Form.SalesOpportunityTasksWithManualControl",
	             New Structure("Key, ReadOnly", Object.Ref, ReadOnly),
	             ,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CalculateProbability(Command)
	
	ClearMessages();
	
	CancelingObjectRecording(New CallbackDescription("CalculateProbabilityAfterWriteCancellation", ThisObject));
	Modified = True;
	
EndProcedure

&AtClient
Procedure CalculateProbabilityAfterWriteCancellation(Result, AdditionalParameters) Export
    
    If Not ValueIsFilled(Object.Ref) And Result Then
        Return;
    EndIf;
    
    OpenForm(
    "Catalog.SalesOpportunitiesToCustomer.Form.EstimatedProbability",
    New Structure("Key",Object.Ref),
    ThisForm,,,, New CallbackDescription("CalculateProbabilityCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure CalculateProbabilityCompletion(Result, AdditionalParameters) Export
    
    EstimatedProbability = Result;
    
    If ValueIsFilled(EstimatedProbability) Then
        Object.ProbabilityOfSuccessfulCompletion = EstimatedProbability;
    EndIf;

EndProcedure

&AtClient
Procedure RecordLoss(Command)

	QueryText = NStr("vi = 'Khi ghi lại vụ việc sẽ ghi nhận thất bại trong giai đoạn này.';
					|ru = 'При записи сделки будет зафиксирован проигрыш на текущем этапе.';
					|en = 'Loss during the current stage will be recorded while saving the sales opportunity.'; fa = 'Loss during the current stage will be recorded while saving the sales opportunity.';
					|it = 'Durante la registrazione della transazione, la perdita verrà registrata nella fase attuale.';
					|pl = 'Podczas zapisu umowy zostanie zarejestrowana przegrana na bieżącym etapie.';
					|tr = 'Satış fırsatı kaydedilirken mevcut aşamadaki kayıp saptanacaktır.'");
	Response = Undefined;

	ShowQueryBox(New CallbackDescription("RecordLossCompletion", ThisObject), QueryText, QuestionDialogMode.OKCancel, , DialogReturnCode.Cancel);

EndProcedure

&AtClient
Procedure RecordLossCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.OK Then
        Object.Status = PredefinedValue("Enum.OpportunityStatuses.Lost") ;
        Modified = True;
        Items.ReasonForLosingSalesOpportunity.ReadOnly = False;
    EndIf;

EndProcedure

&AtClient
Procedure SetFulfillmentPercentage(Command)
	
	SelectedNumber = 100;
	ShowInputNumber(New CallbackDescription("SetFulfillmentPercentageCompletion", ThisObject, New Structure("SelectedNumber", SelectedNumber)), SelectedNumber,NStr("vi = 'Hãy nhập số';
																																									|ru = 'Введите число';
																																									|en = 'Enter number'; fa = 'Enter number';
																																									|it = 'Inserire il numero';
																																									|pl = 'Wprowadź liczbę';
																																									|tr = 'Sayı girin'"),3,0);
	
EndProcedure

&AtClient
Procedure SetFulfillmentPercentageCompletion(Number, AdditionalParameters) Export
    
    SelectedNumber = ?(Number = Undefined, AdditionalParameters.SelectedNumber, Number);
    
    
    If (Number <> Undefined) Then
        If SelectedNumber > 100 Then
            SelectedNumber = 100;
        ElsIf SelectedNumber < 0 Then
            SelectedNumber = 0;
        EndIf;
        For Each SelectedRow In Items.PrimaryDemand.SelectedRows Do
            DataToChange = Object.PrimaryDemand.FindByID(SelectedRow);
            DataToChange.SatisfactionPercentage = SelectedNumber; 
            If ValueIsFilled(DataToChange.ReasonForNonFulfillment) Then
                If SelectedNumber = 100 Then
                    DataToChange.ReasonForNonFulfillment = PredefinedValue("Catalog.ReasonsForPrimaryDemandNonFulfillment.EmptyRef");
                EndIf;
            EndIf;
        EndDo;
    EndIf;

EndProcedure

&AtClient
Procedure ChooseTheReasonForDissatisfaction(Command)
	
	ValueSelected = Undefined;

	
	OpenForm("Catalog.ReasonsForPrimaryDemandNonFulfillment.Form.ChoiceForm",,ThisForm,,,, New CallbackDescription("ChooseTheReasonForDissatisfactionCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ChooseTheReasonForDissatisfactionCompletion(Result, AdditionalParameters) Export
    
    ValueSelected = Result;
    If ValueSelected <> Undefined Then
        
        For Each SelectedRow In Items.PrimaryDemand.SelectedRows Do
            
            CurrentData = Object.PrimaryDemand.FindByID(SelectedRow);
            If CurrentData.SatisfactionPercentage < 100  Then
                
                CurrentData.ReasonForNonFulfillment = ValueSelected;
                
            EndIf;
        EndDo;
    EndIf;

EndProcedure

&AtClient
Procedure CallExecute(Command)

	CreateInteraction("Document.PhoneCall.ObjectForm");

EndProcedure

&AtClient
Procedure PlanInteractionExecute(Command)

	CreateInteraction("Document.PlannedInteraction.ObjectForm");

EndProcedure

&AtClient
Procedure PlanMeetingExecute(Command)

	CreateInteraction("Document.Meeting.ObjectForm");

EndProcedure

&AtClient
Procedure WriteEmail1Execute(Command)

	CreateInteraction("Document.OutgoingEmail.ObjectForm");

EndProcedure

&AtClient
Procedure WriteSMS(Command)
	
	CreateInteraction("Document.SMSMessage.ObjectForm");
	
EndProcedure


&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReasonForNonFulfillment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PrimaryDemand.ReasonForNonFulfillment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.ReasonsForPrimaryDemandNonFulfillment.EmptyRef();

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PrimaryDemand.SatisfactionPercentage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 100;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OpportunityStatuses.InProgress;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EmployeeResponsible.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.EmployeeResponsible");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.Users.EmptyRef();

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SalesOpportunityType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TypesOfCustomerOpportunities.StandardSale;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReasonForNonFulfillment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PrimaryDemand.SatisfactionPercentage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 100;

	Item.Appearance.SetParameterValue("Enabled", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SalesOpportunityWinner.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.OpportunityStatuses.Lost;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseRolesOfPartnersAndContactPersons");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PartnersAndContactPersons.PartnerSRole");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Catalogs.PartnerRolesInSalesOpportunitiesAndProjects.Competitor;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReasonForLosingSalesOpportunity.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReasonForLosingSalesOpportunity");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OpportunityStatuses.Lost;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReasonForNonFulfillment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PrimaryDemand.SatisfactionPercentage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 100;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đáp ứng nhu cầu>';
													|ru = '<потребность удовлетворена>';
													|en = '<demand is fulfilled>'; fa = '<demand is fulfilled>';
													|it = '<il fabbisogno è soddisfatto>';
													|pl = '<zapotrzebowanie zaspokojono>';
													|tr = '<gereksinim karşılandı>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

EndProcedure

&AtServer
Function UsingPrimaryDemand()
	
	UsePrimaryDemand = ((Not Object.SalesOpportunityKind.IsEmpty()) And Common.ObjectAttributeValue(Object.SalesOpportunityKind,"RecordPrimaryDemand"))
	                             Or (Not ProcessesAreUsed And GetFunctionalOption("UsePrimaryDemand"));
	
EndFunction

&AtServer
Procedure OnCreatReadAtServer()

	// identify the channel and source of primary interest
	If GetFunctionalOption("RecordInitialRequest") Then
		If Not Object.Ref.IsEmpty() Then
			Interest = PrimaryInterest(Object.Ref);
			ChannelOfInitialRequest    = Interest.ChannelOfInitialRequest;
			SourceOfInitialRequest = Interest.SourceOfInitialRequest;
			Items.SourceOfInitialRequest.ReadOnly = Not ValueIsFilled(ChannelOfInitialRequest);
		EndIf;
	Else
		Items.PrimaryInterestGroup.Visible = False;
	EndIf;

	// determining the period of work
	Deadlines = NStr("vi = 'Bắt đầu';
					|ru = 'Начало';
					|en = 'Start'; fa = 'شروع';
					|it = 'Inizio';
					|pl = 'Początek';
					|tr = 'Başlangıç'") + ": " + Format(Object.StartDate,"DLF=D");
	If ValueIsFilled(Object.EndDate) Then
		Deadlines = Deadlines + " " + NStr("vi = 'Kết thúc';
											|ru = 'Окончание';
											|en = 'End'; fa = 'پایان';
											|it = 'Fine';
											|pl = 'Zakończenie';
											|tr = 'Bitiş'") + ": " + Format(Object.EndDate,"DLF=D");
	EndIf;

	Items.ReasonForLosingSalesOpportunity.ReadOnly = Not LostTransaction;

	// set the default currency of primary demand = currency of management accounting
	Object.PrimaryDemandCurrency =?(
		ValueIsFilled(Object.PrimaryDemandCurrency),
		Object.PrimaryDemandCurrency, CurrencyOfManAccounting);
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "PrimaryDemandCurrency", "Visible", GetFunctionalOption("UseMultipleCurrencies"));
	
	DetermineTypeOfTransaction();
	
	// configure process management
	If  ProcessesAreUsed And (Not Object.Ref.IsEmpty()) Then
		
		If ValueIsFilled(Object.SalesOpportunityKind) Then

			If SalesOpportunityType <> Enums.TypesOfCustomerOpportunities.OtherNonProcessSalesOpportunities Then
				SaleProcessStage = SalesOpportunitiesServer.GetCurStage(Object.Ref);
				Items.SalesOpportunityKind.ReadOnly = True;
			EndIf;

			If SalesOpportunityType = Enums.TypesOfCustomerOpportunities.SalesOpportunitiesWithManualStageAdvancement
				 Or Object.ManualControlEnabled Then
				ProcessSteps = New FixedArray(ProcessSteps(Object.SalesOpportunityKind));
			EndIf;

			InstallProcessManagement();
		EndIf;
		
	EndIf;
	
	TransactionParticipantParametersAreChanged = False;
	DetermineAvailabilityOfTransactionType();
	UsingPrimaryDemand();

EndProcedure 

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtServer
Procedure DetermineAvailabilityOfTransactionType()
	
	Items.SalesOpportunityKind.ReadOnly = Not (Object.Ref.IsEmpty() Or (SalesOpportunityType.IsEmpty() Or SalesOpportunityType = Enums.TypesOfCustomerOpportunities.OtherNonProcessSalesOpportunities));
	
EndProcedure

&AtClient
Procedure AvailabilityControl()
	
	Items.Closed_.Enabled                   = ManualClosureAvailable() 
	                                               And (Object.Status = PredefinedValue("Enum.OpportunityStatuses.Won") 
	                                               Or (Object.Status = PredefinedValue("Enum.OpportunityStatuses.Lost") And Not Object.ReasonForLosingSalesOpportunity.IsEmpty()));
	Items.Status.ReadOnly                 = Object.Closed_;
	Items.PrimaryDemandGroup.Visible        = UsePrimaryDemand;
	Items.ReasonForLosingSalesOpportunity.ReadOnly = (Object.Status <> PredefinedValue("Enum.OpportunityStatuses.Lost")) Or Object.Closed_;
	
EndProcedure

&AtClient
Function ManualClosureAvailable()

	Return Not ProcessesAreUsed 
			Or SalesOpportunityType = PredefinedValue("Enum.TypesOfCustomerOpportunities.OtherNonProcessSalesOpportunities")
			Or SalesOpportunityType = PredefinedValue("Enum.TypesOfCustomerOpportunities.SalesOpportunitiesWithManualStageAdvancement")
			Or Object.ManualControlEnabled;

EndFunction

&AtServerNoContext
Function ProcessSteps(SalesOpportunityKind)
	
	Query = New Query("SELECT
	|	CustomerOpportunityKindsSalesOpportunityStages.SaleProcessStage
	|FROM
	|	Catalog.CustomerOpportunityKinds.SalesOpportunityStages AS CustomerOpportunityKindsSalesOpportunityStages
	|WHERE
	|	CustomerOpportunityKindsSalesOpportunityStages.Ref = &SalesOpportunityKind
	|
	|ORDER BY
	|	CustomerOpportunityKindsSalesOpportunityStages.LineNumber");
	Query.SetParameter("SalesOpportunityKind", SalesOpportunityKind);
	
	Return Query.Execute().Unload().UnloadColumn(0);
	
EndFunction

&AtServerNoContext
Function PrimaryInterest(SalesOpportunity)
	
	If ValueIsFilled(SalesOpportunity) Then
		
		Query = New Query;
		Query.Text = "SELECT 
		|	SourcesOfInitialRequests.ChannelOfInitialRequest,
		|	SourcesOfInitialRequests.SourceOfInitialRequest,
		|	SourcesOfInitialRequests.Partner
		|FROM
		|	InformationRegister.SourcesOfInitialRequests AS SourcesOfInitialRequests
		|WHERE
		|	SourcesOfInitialRequests.SalesOpportunity = &SalesOpportunity";
		
		Query.SetParameter("SalesOpportunity",SalesOpportunity);
		
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			Return Selection;
		EndIf;
		
	EndIf;
	
	Return New Structure("ChannelOfInitialRequest,SourceOfInitialRequest,Partner",
	ChartsOfCharacteristicTypes.ChannelsOfAdvertisingImpacts.EmptyRef(),
	Undefined,
	Catalogs.Partners.EmptyRef());
	
EndFunction

&AtClient
Procedure CreateInteraction(Var_FormName)

	ClearMessages();
	
	If Modified Then
		If Not WriteToServer() Then
			Return;
		EndIf;
	EndIf;
	
	Basis = New Structure();
	Basis.Insert("SubjectOf", Object.Ref);
	
	CurrentData = Items.PartnersAndContactPersons.CurrentData;
	If Not CurrentData = Undefined Then
		Contact = ?(ValueIsFilled(CurrentData.ContactPerson),
		            CurrentData.ContactPerson,
		            CurrentData.Partner);
		If ValueIsFilled(Contact) Then
			Basis.Insert("Contact", Contact);
		EndIf;
	EndIf;
	
	OpenForm(Var_FormName, New Structure("Basis", Basis),,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtServer
Function WriteToServer()

	If CheckFilling() Then
		Write();
		Return True;
	Else
		Return False;
	EndIf;

EndFunction 

&AtServer
Procedure InstallProcessManagement()

	If SalesOpportunityType = Enums.TypesOfCustomerOpportunities.OtherNonProcessSalesOpportunities Then
		Items.SaleProcessStage.Visible		= False;
		Items.GroupManagementOptions.Visible	= False;
	Else

		Items.SaleProcessStage.Visible		= True;
		Items.GroupManagementOptions.Visible	= True;

		If SalesOpportunityType = Enums.TypesOfCustomerOpportunities.SalesOpportunitiesWithManualStageAdvancement Or Object.ManualControlEnabled Then

			Items.GroupManagementOptions.CurrentPage = Items.PageManualTransfer;

			// upload process steps
			If OpportunityKindIsChanged Then
				ProcessSteps = New FixedArray(ProcessSteps(Object.SalesOpportunityKind));
				OpportunityKindIsChanged = False;
			EndIf;

			// determine the index of the current stage
			If ProcessSteps <> Undefined Then
				If ProcessSteps.Count() = 0 Then
				CommonClientServer.MessageToUser(
					NStr("vi = 'Tùy chỉnh sai dạng vụ việc.';
						|ru = 'Вид сделки настроен некорректно.';
						|en = 'Sales opportunity kind is invalid.'; fa = 'Sales opportunity kind is invalid.';
						|it = 'Il tipo di transazione è configurato in modo errato.';
						|pl = 'Rodzaj umowy został ustawiony niepoprawnie.';
						|tr = 'Satış fırsatı türü yanlış ayarlandı.'"));
				Else
					If ValueIsFilled(SaleProcessStage) Then
						IndexOfCurrentStage = ProcessSteps.Find(SaleProcessStage);
					ElsIf Object.Status <> Enums.OpportunityStatuses.InProgress Then
						IndexOfCurrentStage = 0;
						SaleProcessStage = Catalogs.ProcessesStates.EmptyRef();
					Else
						IndexOfCurrentStage = 0;
						SaleProcessStage = ProcessSteps[0];
					EndIf;
				EndIf;
			EndIf;

			// install stage management
			If ProcessSteps = Undefined Then
				Items.NextStage.Enabled	= False;
				Items.PreviousStage.Enabled	= False;
			ElsIf Object.Status = Enums.OpportunityStatuses.InProgress Then
				IndexOfCurrentStage = ProcessSteps.Find(SaleProcessStage);
				If IndexOfCurrentStage = Undefined Then
					IndexOfCurrentStage = 0;
					SaleProcessStage = ProcessSteps[0];
				EndIf;
				Items.NextStage.Enabled  = IndexOfCurrentStage < ProcessSteps.Count() - 1;
				Items.PreviousStage.Enabled = IndexOfCurrentStage > 0;
			EndIf; //install stage management
		Else
			Items.GroupManagementOptions.CurrentPage	= Items.PageBusinessProcess;
			Items.Status.ReadOnly						= True;
			Items.SwitchToManualControl.Enabled		= Not Object.Closed_;
			Items.RecordLoss.Enabled =
				Not Object.Closed_ And (Object.Status = Enums.OpportunityStatuses.InProgress);
		EndIf;
	EndIf;

EndProcedure

&AtServer
Procedure CompleteSaleProcess()
	
	SetPrivilegedMode(True);
	SalesOpportunitiesServer.CompleteSaleProcess(Object.Ref, SalesOpportunityType);
	Object.ManualControlEnabled = True;
	ProcessSteps = New FixedArray(ProcessSteps(Object.SalesOpportunityKind));
	Write();
	InstallProcessManagement();
	
EndProcedure

&AtClient
Procedure CancelingObjectRecording(Val Notification)
	
	QueryText = NStr(
						"vi = 'Dữ liệu vẫn chưa được ghi lại.
						|Chỉ có thể thực hiện thao tác sau khi ghi lại.
						|Dữ liệu sẽ được ghi lại.';
						|ru = 'Данные еще не записаны.
						|Выполнение действия возможно только после записи.
						|Данные будут записаны.';
						|en = 'Data is not saved yet.
						|The action can be performed only after saving.
						|Data will be saved.'; fa = 'Data is not saved yet.
						|The action can be performed only after saving.
						|Data will be saved.';
						|it = 'I dati non sono ancora registrati.
						|L''esecuzione dell''azione è possibile solo dopo la registrazione.
						|I dati verranno registrati.';
						|pl = 'Dane nie zostały jeszcze zapisane.
						|Wykonanie działania jest możliwe tylko po zapisaniu danych.
						|Dane zostaną zapisane.';
						|tr = 'Veriler henüz kaydedilmedi.
						|İşlemin gerçekleştirilmesi sadece kaydedildikten sonra mümkündür.
						|Veriler kaydedilecektir.'");
	
	Response = Undefined;
	
	If Modified Then
		ShowQueryBox(New CallbackDescription("CancelingObjectRecordingCompletion", ThisObject, New Structure("Notification", Notification)), QueryText, QuestionDialogMode.OKCancel, , DialogReturnCode.Cancel);
		Return;
	Else
		RunCallback(Notification, Modified Or Not ValueIsFilled(Object.Ref));
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure CancelingObjectRecordingCompletion(QuestionResult, AdditionalParameters) Export
    
    Notification = AdditionalParameters.Notification;
    
    
    Response =  QuestionResult;
    
    If Response = DialogReturnCode.OK Then
        Write();
	Else
		Return;
    EndIf;
    
    RunCallback(Notification, Modified Or Not ValueIsFilled(Object.Ref));
    Return;

EndProcedure

&AtClient
Procedure InstallStageManagement()
	
	If ProcessSteps = Undefined Then
		Items.NextStage.Enabled  = False;
		Items.PreviousStage.Enabled = False;
	ElsIf Object.Status = PredefinedValue("Enum.OpportunityStatuses.InProgress") Then
		IndexOfCurrentStage = ProcessSteps.Find(SaleProcessStage);
		If IndexOfCurrentStage = Undefined Then
			IndexOfCurrentStage = 0;
			SaleProcessStage = ProcessSteps[0];
		EndIf;
		Items.NextStage.Enabled  = IndexOfCurrentStage < ProcessSteps.Count() - 1;
		Items.PreviousStage.Enabled = IndexOfCurrentStage > 0;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function SalesProcess(SalesOpportunityType, SalesOpportunity)
	
	DescriptionOfTransactionType = SalesOpportunitiesServer.GetDescriptionOfTransactionType(SalesOpportunityType);
	ProcessName = DescriptionOfTransactionType.Name;
	Query = New Query;
	QueryText = "
		|SELECT
		|	SalesProcess.Ref AS Process_
		|FROM
		|	&BusinessProcessName AS SalesProcess
		|WHERE
		|	SalesProcess.Started
		|	AND (NOT SalesProcess.Completed)
		|	AND SalesProcess.SubjectOf = &SalesOpportunity";		
	
	QueryText = StrReplace(QueryText, "&BusinessProcessName", "BusinessProcess." + ProcessName);
		
	Query.Text = QueryText;
	Query.SetParameter("SalesOpportunity", SalesOpportunity);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Process_;
	Else
		Return Undefined;
	EndIf;

EndFunction

&AtServerNoContext
Function ContactPersonSPartner(ContactPerson)

	Return Common.ObjectAttributeValue(ContactPerson,"Owner");

EndFunction

&AtServerNoContext
Function CurrentStep(Ref)

	Return SalesOpportunitiesServer.GetCurStage(Ref);

EndFunction

&AtClient
Procedure GoToProcessStage(Direction)
	
	IndexOfCurrentStage = ProcessSteps.Find(SaleProcessStage) + Direction;
	SaleProcessStage = ProcessSteps[IndexOfCurrentStage];
	InstallStageManagement();
	Modified = True;
	
EndProcedure

&AtServerNoContext
Function GetDefaultSalesTerms(Partner)
	
	Return SalesServer.GetDefaultSalesTerms(Partner);
	
EndFunction

&AtServer
Procedure SetDetailsHeaders()

	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	                                                   ThisObject, "Partner", NStr("vi = 'Đối tác';
																					|ru = 'Контрагент';
																					|en = 'Counterparty'; fa = 'طرف حساب';
																					|it = 'Controparte';
																					|pl = 'Counterparty';
																					|tr = 'Cari hesap'"));
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	                                                   ThisObject, "PartnerSRole", NStr("vi = 'Vai trò đối tác';
																						|ru = 'Роль контрагента';
																						|en = 'Counterparty role'; fa = 'Counterparty role';
																						|it = 'Ruolo del contraente';
																						|pl = 'Rola kontrahenta';
																						|tr = 'Cari hesap rolü'"));

EndProcedure

&AtClient
Procedure QuestionFixingLossOfTransactionAtEnd(QuestionResult, WriteParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		LostTransaction = True;
		ResponseToLossRecordingIsReceived = True;
		Write();
	EndIf;

EndProcedure

&AtServer
Procedure ManagingVisibilityOfCommandsOnServer()
	
	Items.WriteEmail1.Visible              = AccessRight("Insert", Metadata.Documents.OutgoingEmail);
	Items.Call.Visible                   = AccessRight("Insert", Metadata.Documents.PhoneCall);
	Items.PlanInteraction.Visible = AccessRight("Insert", Metadata.Documents.PlannedInteraction);
	Items.PlanMeeting.Visible        = AccessRight("Insert", Metadata.Documents.Meeting);
	Items.WriteSMS.Visible                 = AccessRight("Insert", Metadata.Documents.SMSMessage);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion
