//@strict-types

#Region Variables

&AtClient
Var Cached_Values; // See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues

&AtClient
Var AnalyticsOfCurrentProductLine; // See RebatesClientServer.StructureOfSavedProductLine

&AtClient
Var AnalyticsOfGoodsLineBeingModified; // See RebatesClientServer.StructureOfSavedProductLine

&AtClient
Var CurrentPropertyValue; // DefinedType.RebateItemPropertyTypes, Undefined

&AtClient
Var PropertyValueThatCanBeChanged; // DefinedType.RebateItemPropertyTypes, Undefined

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	ReadOnly = False;
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);
	
	ThereIsRightToChangeURB = AccessManagement.EditionAllowed(CurrentObject);
	
	OnCreatReadAtServer();
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	If Object.AccrueImmediately
	   And Items.DecorationCancelApproval.Visible Then
		
		Items.DecorationCancelApproval.Visible = Not PeriodClosingDates.DataChangesDenied(CurrentObject);
		
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ExchangePlans.MasterNode() <> Undefined Then
		
		ReadOnly = True;
		
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnCreatReadAtServer();
		
	EndIf;
	
	SetConditionalAppearance();
	SetHeader();
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	SkipCheckingChangesByStatus = CommonClientServer.StructureProperty(
		WriteParameters,
		"SkipCheckingChangesByStatus",
		False);
	CurrentObject.AdditionalProperties.Insert(
		"SkipCheckingChangesByStatus",
		SkipCheckingChangesByStatus);
	
	CurrentObject.AdditionalProperties.Insert(
		"SkipCheckingForAccrualRestrictionsIfThereAreNoChanges",
		False);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	// End StandardSubsystems.AttachableCommands
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
	DocumentCorrectionClient.AfterWrite(Object);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	ThereIsRightToChangeURB = AccessManagement.EditionAllowed(CurrentObject);
	
	FillInServiceDetailsForProductRange();
	FillInServiceAttributesOfAgreementsContracts();
	SetHeader();
	FillInAttributesOfCompositionAccordingToCondition();
	SetSettingsByStatus();
	RebatesClientServer.GenerateNamesOfRangesOfCalculationScales(ThisObject);
	RebatesServer.UpdateRowRangesOfAllGoods(Object, GoodsIndicator);
	RebatesServer.UpdateRowRangesOfAllProperties(Object, GoodsIndicator);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		
	EndIf;
	// End StandardSubsystems.Properties
	
	//@skip-check invocation-parameter-type-intersect
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	// StandardSubsystems.FilesOperations
	
	FilesOperationsClient.ShowConfirmationForClosingFormWithFiles(ThisObject, Cancel, Exit, Object.Ref);
	If Cancel Then
		Return;
	EndIf;
	
	// End StandardSubsystems.FilesOperations
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Async Procedure StatusOnChange(Item)
	
	ClearMessages();
	
	FillInSignOfAccruals();
	If CurrentStatus = PredefinedValue("Enum.RebatesDocumentStatuses.Approved")
	   And ThereAreAccruals Then
		
		SetSceneryTitlesWithHyperlinks();
		
		MessageText = NStr("vi = 'Đã tạo chứng từ tính toán. Cấm thay đổi thao tác thống nhất.';
							|ru = 'Созданы документы начисления. Изменение согласования запрещено.';
							|en = 'Accrual documents are created. Cannot edit the approval.'; fa = 'Accrual documents are created. Cannot edit the approval.';
							|it = 'Созданы документы начисления. Изменение согласования запрещено.';
							|pl = 'Accrual documents are created. Cannot edit the approval.';
							|tr = 'Tahakkuk belgeleri oluşturuldu. Anlaşma değiştirilemez.'");
		CommonClient.MessageToUser(MessageText,, "Object", "Status");
		Object.Status = CurrentStatus;
			
	ElsIf Object.Status = PredefinedValue("Enum.RebatesDocumentStatuses.Approved") Then
		
		QueryText = NStr("vi = 'Chứng từ sẽ được kết chuyển, tiếp tục?';
						|ru = 'Документ будет проведен, продолжить?';
						|en = 'The document will be posted, continue?'; fa = 'The document will be posted, continue?';
						|it = 'Документ будет проведен, продолжить?';
						|pl = 'The document will be posted, continue?';
						|tr = 'Belge kontrol edilecek, devam edilsin mi?'");
		Result = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
		
		If Result = DialogReturnCode.Yes Then
			
			ClearMessages();
			
			If Object.CorrectedDocument.IsEmpty() Then
				Object.ChainID = String(New UUID);
			EndIf;
			
			WriteParameters = New Structure;
			WriteParameters.Insert("SkipCheckingChangesByStatus", True);
			WriteParameters.Insert("WriteMode", DocumentWriteMode.Posting);
			WriteParameters.Insert("PostingMode", DocumentPostingMode.Regular);
			
			Try
				
				SuccessfullyConducted = Write(WriteParameters);
				If Not SuccessfullyConducted Then
					
					Object.Status = CurrentStatus;
					
				EndIf;
				
			Except
				
				Object.Status = CurrentStatus;
				ErrorText = NStr("vi = 'Khi kết chuyển chứng từ, đã xảy ra lỗi, chưa đặt trạng thái';
								|ru = 'При проведении документа возникли ошибки, статус не установлен';
								|en = 'Errors occurred when posting the document. The status is not set'; fa = 'Errors occurred when posting the document. The status is not set';
								|it = 'При проведении документа возникли ошибки, статус не установлен';
								|pl = 'Errors occurred when posting the document. The status is not set';
								|tr = 'Belgenin uygulanması esnasında hatalar oluştu, durum ayarlanamadı'");
				CommonClient.MessageToUser(ErrorText,, "Object.Status");
				Raise;
				
			EndTry;
			
			CurrentStatus = Object.Status;
			
			// StandardSubsystems.AttachableCommands
			AttachableCommandsClient.StartCommandUpdate(ThisObject);
			// End StandardSubsystems.AttachableCommands
			
		Else
			
			Object.Status = CurrentStatus;
			
		EndIf;
		
	Else
		
		CurrentStatus = Object.Status;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StatusClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure RebateKindOnChange(Item)
	
	ClearMessages();
	RebateKindOnChangeServer();
	
EndProcedure

&AtClient
Procedure AccrueImmediatelyOnChange(Item)
	
	Object.PartyCountDetails = PredefinedValue("Enum.ARAPAccountingDrilldownsOfRebatesParticipants.ByCounterpartyAndCustomer");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	ConfigureDependentFormElements("AccrueImmediately");
	
EndProcedure

&AtClient
Procedure PartyCountDetailsOnChange(Item)
	
	PartyCountDetailsOnChangeServer();
	
EndProcedure

&AtClient
Procedure ValidOnDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	BeginningOfActionLine = Format(Object.ValidOnDate, "DLF=D;");
	
EndProcedure

&AtClient
Procedure ValidToOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	EndOfActionWithLine = Format(Object.ValidTo, "DLF=D;");
	
EndProcedure

&AtClient
Procedure ConditionFrequencyOnChange(Item)
	
	SetAvailableListOfTimeFenceAccruals(ThisObject);
	
EndProcedure

&AtClient
Procedure FilterPartiesOnChange(Item)
	
	FilterPartiesOnChangeServer();
	
EndProcedure

&AtClient
Procedure FilterOfProducts_OnChange(Item)
	
	FilterOfProducts_OnChangeServer();
	
EndProcedure

&AtClient
Procedure SumPlanOnChange(Item)
	
	GenerateAmountsOfPlansAsLine(ThisObject); 
	
EndProcedure

&AtClient
Procedure RestrictAccrualOverPlanOnChange(Item)
	
	ConfigureDependentFormElements("RestrictAccrualOverPlan");
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	RebatesClientServer.GenerateNamesOfRangesOfCalculationScales(ThisObject);
	SetHeadersByCurrency();
	
EndProcedure

&AtClient
Procedure DecorationFixCompositionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	RefToProcess = "Commit";
	
	If FormattedStringURL = RefToProcess Then
		FixCompositionOfDocument();
	EndIf;
	
EndProcedure

&AtClient
Procedure DecorationIsToCancelFixationOfCompositionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	RefToProcess = "CancelCommit";
	
	If FormattedStringURL = RefToProcess Then
		CancelFixingCompositionOfDocument();
	EndIf;
	
EndProcedure

&AtClient
Procedure DecorationCancelApprovalURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	RefToProcess = "CancelApproval";
	
	If FormattedStringURL = RefToProcess Then
		CancelApproval();
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculationScaleTypeOnChange(Item)
	
	CalculationScaleTypeOnChangeServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCounterparties

&AtClient
Procedure CounterpartiesBeforeDeleteRow(Item, Cancel)
	
	CurrentData = Items.Counterparties.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.InitialString Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartiesAfterDeleteRow(Item)
	
	If Not DetailsByCounterpartyClient(Object.PartyCountDetails) Then
		
		EstablishSignsOfCalculationOfParticipantsPlan();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartiesOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.Counterparties.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Copy Then
		
		CurrentData.AmountPlanBeforeChange = 0;
		CurrentData.PlanIsNotSpecifiedBeforeChange = False;
		CurrentData.StartDateBeforeChange = Date(1, 1, 1);
		CurrentData.EndDateBeforeChange = Date(1, 1, 1);
		CurrentData.Canceled = False;
		CurrentData.InitialString = False;
		
		If Not DetailsByCounterpartyClient(Object.PartyCountDetails) Then
		
			EstablishSignsOfCalculationOfParticipantsPlan();
		
		EndIf;
			
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartiesCounterpartyOnChange(Item)
	
	CurrentData = Items.Counterparties.CurrentData;
	
	If (Object.AccrueImmediately
		  And PartyList = PredefinedValue("Enum.RebatesParticipants.Counterparties")
		  And CurrentData.Partner.IsEmpty())
	 Or Not DetailsByCounterpartyClient(Object.PartyCountDetails) Then
		
		IDCurrentRow = CurrentData.GetID();
		CounterpartiesCounterpartyOnChangeServer(IDCurrentRow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartiesPartnerOnChange(Item)
	
	CurrentData = Items.Counterparties.CurrentData;
	
	If (Object.AccrueImmediately
		  And PartyList = PredefinedValue("Enum.RebatesParticipants.Customers")
		  And CurrentData.Counterparty.IsEmpty())
	 Or Not DetailsByCounterpartyClient(Object.PartyCountDetails) Then
		
		IDCurrentRow = CurrentData.GetID();
		CounterpartiesPartnerOnChangeServer(IDCurrentRow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartiesCanceledOnChange(Item)
	
	CurrentData = Items.Counterparties.CurrentData;
	
	If CurrentData.Canceled Then
		
		CurrentData.SumPlan = 0;
		CurrentData.PlanIsNotSpecified = False;
		CurrentData.ValidOnDate = Date(1, 1, 1);
		CurrentData.ValidTo = Date(1, 1, 1);
		
	EndIf;
	
	If Not DetailsByCounterpartyClient(Object.PartyCountDetails) Then
		
		EstablishSignsOfCalculationOfParticipantsPlan();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCounterpartiesTIN

&AtClient
Procedure CounterpartiesTINBeforeDeleteRow(Item, Cancel)
	
	CurrentData = Items.CounterpartiesTIN.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.InitialString Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartiesTINOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.CounterpartiesTIN.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Copy Then
		
		CurrentData.AmountPlanBeforeChange = 0;
		CurrentData.StartDateBeforeChange = Date(1, 1, 1);
		CurrentData.EndDateBeforeChange = Date(1, 1, 1);
		CurrentData.Canceled = False;
		CurrentData.InitialString = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartiesTINCanceledOnChange(Item)
	
	CurrentData = Items.CounterpartiesTIN.CurrentData;
	
	If CurrentData.Canceled Then
		
		CurrentData.SumPlan = 0;
		CurrentData.ValidOnDate = Date(1, 1, 1);
		CurrentData.ValidTo = Date(1, 1, 1);
		
	EndIf;
	
EndProcedure
#EndRegion

#Region FormTableItemsEventHandlersPartnersSegments

&AtClient
Procedure PartnersSegmentsBeforeDeleteRow(Item, Cancel)
	
	CurrentData = Items.PartnersSegments.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.InitialString Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure PartnersSegmentsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.PartnersSegments.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Copy Then
		
		CurrentData.Canceled = False;
		CurrentData.InitialString = False;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersContractsTermsOfSales

&AtClient
Procedure ContractsTermsOfSalesOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.ContractsTermsOfSales.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Copy Then
		
		CurrentData.AmountPlanBeforeChange = 0;
		CurrentData.PlanIsNotSpecifiedBeforeChange = False;
		CurrentData.StartDateBeforeChange = Date(1, 1, 1);
		CurrentData.EndDateBeforeChange = Date(1, 1, 1);
		CurrentData.Canceled = False;
		CurrentData.InitialString = False;
		
		If DetailsByCounterparty(Object.PartyCountDetails)
		   And PartyList = PredefinedValue("Enum.RebatesParticipants.Contracts") Then
			
			EstablishSignsOfCalculationOfParticipantsPlan();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractsPartnerAgreementsOnChange(Item)
	
	CurrentData = Items.ContractsTermsOfSales.CurrentData;
	
	IDCurrentRow = CurrentData.GetID();
	ContractsPartnerAgreementsOnChangeServer(IDCurrentRow);
	
EndProcedure

&AtClient
Procedure ContractsAgreementsCounterpartyOnChange(Item)
	
	CurrentData = Items.ContractsTermsOfSales.CurrentData;
	
	IDCurrentRow = CurrentData.GetID();
	ContractsAgreementsCounterpartyOnChangeServer(IDCurrentRow);
	
EndProcedure

&AtClient
Procedure ContractsAgreementsContractStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.ContractsTermsOfSales.CurrentData; // FormDataCollectionItem: See Document.ConditionsOfCustomerRebates.Form.DocumentForm.Items.ContractsTermsOfSales
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("ContractType", PredefinedValue("Enum.ContractTypes.WithCustomer"));
	FilterStructure1.Insert("Organization", Object.Organization);
	If Not CurrentData.Counterparty.IsEmpty() Then
		FilterStructure1.Insert("Counterparty", CurrentData.Counterparty);
	EndIf;
	If Not CurrentData.Partner.IsEmpty() Then
		FilterStructure1.Insert("Partner", CurrentData.Partner);
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterStructure1);
	
	OpenForm("Catalog.CounterpartyContracts.ChoiceForm", FormParameters, Item);
	
EndProcedure

&AtClient
Procedure ContractsAgreementsContractOnChange(Item)
	
	CurrentData = Items.ContractsTermsOfSales.CurrentData;
	
	IDCurrentRow = CurrentData.GetID();
	ContractsAgreementsContractOnChangeServer(IDCurrentRow);
	
EndProcedure

&AtClient
Procedure ContractsAgreementsAgreementStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.ContractsTermsOfSales.CurrentData; // FormDataCollectionItem: See Document.ConditionsOfCustomerRebates.Form.DocumentForm.Items.ContractsTermsOfSales
	
	FormParameters = New Structure();
	FormParameters.Insert("DocumentDate", Date(1, 1, 1)); // We do not limit the choice of agreements by period
	FormParameters.Insert("OnlyStandard", False);
	FormParameters.Insert("OnlyUsedBySalesRepresentative", False);
	FormParameters.Insert("AllowSelectionOfInvalid", True);
	FormParameters.Insert("CurrentRow", CurrentData.Terms);
	FormParameters.Insert(
		"BusinessOperation",
		PredefinedValue("Enum.BusinessTransactions.SaleToCustomer"));
	
	If Not CurrentData.Partner.IsEmpty() Then
	
		FormParameters.Insert("Partner", CurrentData.Partner);
	
	EndIf;
	
	AdditionalSelection = New Structure;
	AdditionalSelection.Insert("Organization", Object.Organization);
	
	If Not CurrentData.Counterparty.IsEmpty() Then
	
		ArrayOfCounterparties = New Array; // Array of CatalogRef.Counterparties
		ArrayOfCounterparties.Add(CurrentData.Counterparty);
		ArrayOfCounterparties.Add(PredefinedValue("Catalog.Counterparties.EmptyRef"));
		AdditionalSelection.Insert("Counterparty", ArrayOfCounterparties);
	
	EndIf;
	
	FormParameters.Insert("Filter", AdditionalSelection);
	
	OpenForm("Catalog.TermsOfSale.ChoiceForm", FormParameters, Item);
	
EndProcedure

&AtClient
Procedure ContractsAgreementsAgreementOnChange(Item)
	
	CurrentData = Items.ContractsTermsOfSales.CurrentData;
	
	IDCurrentRow = CurrentData.GetID();
	ContractsAgreementsAgreementOnChangeServer(IDCurrentRow);
	
EndProcedure

&AtClient
Procedure ContractsTermsOfSalesCanceledOnChange(Item)
	
	CurrentData = Items.ContractsTermsOfSales.CurrentData;
	
	If CurrentData.Canceled Then
		
		CurrentData.SumPlan = 0;
		CurrentData.PlanIsNotSpecified = False;
		CurrentData.ValidOnDate = Date(1, 1, 1);
		CurrentData.ValidTo = Date(1, 1, 1);
		
	EndIf;
	
	If DetailsByCounterparty(Object.PartyCountDetails)
	   And PartyList = PredefinedValue("Enum.RebatesParticipants.Contracts") Then
		
		EstablishSignsOfCalculationOfParticipantsPlan(CurrentData.Counterparty);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractsTermsOfSalesBeforeDeleteRow(Item, Cancel)
	
	CurrentData = Items.ContractsTermsOfSales.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.InitialString Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractsTermsOfSalesAfterDeleteRow(Item)
	
	If DetailsByCounterparty(Object.PartyCountDetails)
	   And PartyList = PredefinedValue("Enum.RebatesParticipants.Contracts") Then
		
		EstablishSignsOfCalculationOfParticipantsPlan();
		
	EndIf
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsOnActivateRow(Item)
	
	CurrentData = Items.Goods.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	SaveAnalyticsOfProductLine(AnalyticsOfCurrentProductLine, CurrentData);
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData.InitialString Then
		Cancel = True;
	EndIf;
	
	If Not Cancel Then
		SaveAnalyticsOfProductLine(AnalyticsOfGoodsLineBeingModified, CurrentData);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	If Object.Goods.Count() = 0 Then
		Return;
	EndIf;
	
	If RebatesClientServer.ThisIsNumberByRanges(Object.CalculationScaleType, GoodsIndicator)
	   And Not AnalyticsOfGoodsLineBeingModified.Products.IsEmpty() Then
		
		UpdateGoodsRowRangesByGoods(AnalyticsOfGoodsLineBeingModified);
		
	EndIf;
	
	// Resetting the parameters
	AnalyticsOfCurrentProductLine = RebatesClientServer.StructureOfSavedProductLine();
	AnalyticsOfGoodsLineBeingModified = RebatesClientServer.StructureOfSavedProductLine();
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.Goods.CurrentData;
	
	If Copy Then
		
		CurrentData.StartDateBeforeChange = Date(1, 1, 1);
		CurrentData.EndDateBeforeChange = Date(1, 1, 1);
		CurrentData.Canceled = False;
		CurrentData.InitialString = False;
		
		CurrentData.QuantityPlanRangeBound = 0;
		CurrentData.RangeDesignation = "";
		
	EndIf;
	
	SaveAnalyticsOfProductLine(AnalyticsOfGoodsLineBeingModified, CurrentData);
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	If NewRow
	   And CancelEdit
	   And ChangedGoodsData Then
		
		If RebatesClientServer.ThisIsNumberByRanges(Object.CalculationScaleType, GoodsIndicator)
		   And Not AnalyticsOfGoodsLineBeingModified.Products.IsEmpty() Then
			
			UpdateGoodsRowRangesByGoods(AnalyticsOfGoodsLineBeingModified);
			
		EndIf;
		
	EndIf;
	
	// Resetting the parameters
	AnalyticsOfGoodsLineBeingModified = RebatesClientServer.StructureOfSavedProductLine();
	ChangedGoodsData = False;
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	IDCurrentRow = CurrentData.GetID();
	GoodsProductsOnChangeServer(
		IDCurrentRow,
		AnalyticsOfCurrentProductLine,
		AnalyticsOfGoodsLineBeingModified,
		Cached_Values);
	
	SaveAnalyticsOfProductLine(AnalyticsOfCurrentProductLine, CurrentData);
	ChangedGoodsData = True;
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	IDCurrentRow = CurrentData.GetID();
	GoodsCharacteristicOnChangeServer(
		IDCurrentRow,
		AnalyticsOfCurrentProductLine,
		AnalyticsOfGoodsLineBeingModified);
		
	SaveAnalyticsOfProductLine(AnalyticsOfCurrentProductLine, CurrentData);
	ChangedGoodsData = True;
	
EndProcedure

&AtClient
Procedure GoodsCanceledOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	IDCurrentRow = CurrentData.GetID();
	GoodsCanceledOnChangeServer(IDCurrentRow);
	
EndProcedure

&AtClient
Procedure ProductsQuantityPlanOnChange(Item)
	
	If RebatesClientServer.ThisIsNumberByRanges(Object.CalculationScaleType, GoodsIndicator) Then
		
		CurrentData = Items.Goods.CurrentData;
		
		IDCurrentRow = CurrentData.GetID();
		ProductsQuantityPlanOnChangeServer(IDCurrentRow);
		
	EndIf;
	
	ChangedGoodsData = True;
	
EndProcedure

&AtClient
Procedure ProductsStartOfActionOnChange(Item)
	
	If RebatesClientServer.ThisIsNumberByRanges(Object.CalculationScaleType, GoodsIndicator) Then
		
		CurrentData = Items.Goods.CurrentData;
		
		IDCurrentRow = CurrentData.GetID();
		ProductsStartOfActionOnChangeServer(IDCurrentRow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsExpirationDateOnChange(Item)
	
	If RebatesClientServer.ThisIsNumberByRanges(Object.CalculationScaleType, GoodsIndicator) Then
		
		CurrentData = Items.Goods.CurrentData;
		
		IDCurrentRow = CurrentData.GetID();
		ProductsExpirationDateOnChangeServer(IDCurrentRow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsBasePriceOnChange(Item)
	
	If RebatesClientServer.ThisIsNumberByRanges(Object.CalculationScaleType, GoodsIndicator) Then
		
		CurrentData = Items.Goods.CurrentData;
		
		IDCurrentRow = CurrentData.GetID();
		ProductsBasePriceOnChangeServer(IDCurrentRow);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoodsSegments

&AtClient
Procedure GoodsSegmentsBeforeDeleteRow(Item, Cancel)
	
	CurrentData = Items.GoodsSegments.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.InitialString Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsSegmentsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.GoodsSegments.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Copy Then
		
		CurrentData.Canceled = False;
		CurrentData.InitialString = False;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCalculationScales

&AtClient
Procedure CalculationScalesBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	If CheckingRangeBoundaryHasBeenCompleted
	 Or (NewRow
	      And CancelEdit) Then
		
		CheckingRangeBoundaryHasBeenCompleted = False;
		Return;
		
	EndIf;
	
	CurrentData = Items.CalculationScales.CurrentData;
	Value_Border = CurrentData.RangeFrom;
	ThisIsFirstLineByRanges =
		(Object.CalculationScaleType = 2
		 And CurrentData.LineNumber = 1);
	
	If Value_Border = 0
	   And Not ThisIsFirstLineByRanges Then
		
		Cancel = True;
		WarningOfNeedToFillInBorder();
		
	EndIf;
	
	If Not Cancel Then
		
		FilterParameters = New Structure;
		FilterParameters.Insert("RangeFrom", Value_Border);
		
		FoundRows = Object.CalculationScales.FindRows(FilterParameters);
		If FoundRows.Count() > 1 Then
			
			Cancel = True;
			WarningDoubleBorders(Value_Border);
		
		EndIf;
	
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculationScalesOnEditEnd(Item, NewRow, CancelEdit)
	
	CheckingRangeBoundaryHasBeenCompleted = False;
	RebatesClientServer.SetTitleOfCalculationScaleGroup(ThisObject);
	
EndProcedure

&AtClient
Procedure CalculationScalesRangeFromOnChange(Item)
	
	Cancel = False;
	CurrentData = Items.CalculationScales.CurrentData;
	Value_Border = CurrentData.RangeFrom;
	
	If Value_Border = 0 Then
		
		Cancel = True;
		WarningOfNeedToFillInBorder();
		
	EndIf;
	
	If Not Cancel Then
		
		FilterParameters = New Structure;
		FilterParameters.Insert("RangeFrom", Value_Border);
		
		FoundRows = Object.CalculationScales.FindRows(FilterParameters);
		If FoundRows.Count() > 1 Then
			
			Cancel = True;
			WarningDoubleBorders(Value_Border);
		
		EndIf;
		
	EndIf;
	
	If Not Cancel Then
		
		Object.CalculationScales.Sort("RangeFrom Asc");
		RebatesClientServer.GenerateNamesOfRangesOfCalculationScales(ThisObject);
		
	EndIf;
	
	CheckingRangeBoundaryHasBeenCompleted = True;
	
EndProcedure

&AtClient
Procedure CalculationScalesBeforeDeleteRow(Item, Cancel)
	
	CurrentData = Items.CalculationScales.CurrentData;
	
	If CurrentData.RangeFrom = 0
	   And Object.CalculationScaleType = 2 Then // For the sum indicator, this is by ranges
		
		// For ranges, you cannot delete the initial line
		Cancel = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculationScalesAfterDeleteRow(Item)
	
	RebatesClientServer.GenerateNamesOfRangesOfCalculationScales(ThisObject);
	RebatesClientServer.SetTitleOfCalculationScaleGroup(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProductProperties_

&AtClient
Procedure ProductProperties_OnActivateRow(Item)
	
	CurrentData = Items.ProductProperties_.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentPropertyValue = CurrentData.PropertyValue;
	
EndProcedure

&AtClient
Procedure ProductProperties_BeforeDeleteRow(Item, Cancel)
	
	CurrentData = Items.ProductProperties_.CurrentData;
	
	If CurrentData.InitialString Then
		Cancel = True;
	EndIf;
	
	If Not Cancel Then
		PropertyValueThatCanBeChanged = CurrentData.PropertyValue;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductProperties_AfterDeleteRow(Item)
	
	If Object.ProductProperties_.Count() = 0 Then
		Return;
	EndIf;
	
	If RebatesClientServer.ThisIsNumberByRanges(Object.CalculationScaleType, GoodsIndicator)
	   And PropertyValueThatCanBeChanged <> Undefined Then
		
		UpdatePropertyRowRangesByProperty(PropertyValueThatCanBeChanged);
		
	EndIf;
	
	// Resetting the parameters
	CurrentPropertyValue = Undefined;
	PropertyValueThatCanBeChanged = Undefined;
	
EndProcedure

&AtClient
Procedure ProductProperties_OnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.ProductProperties_.CurrentData;
	
	If Copy Then
		
		CurrentData.StartDateBeforeChange = Date(1, 1, 1);
		CurrentData.EndDateBeforeChange = Date(1, 1, 1);
		CurrentData.Canceled = False;
		CurrentData.InitialString = False;
		
		CurrentData.QuantityPlanRangeBound = 0;
		CurrentData.RangeDesignation = "";
		
	EndIf;
	
	PropertyValueThatCanBeChanged = CurrentData.PropertyValue;
	
EndProcedure

&AtClient
Procedure ProductProperties_OnEditEnd(Item, NewRow, CancelEdit)
	
	If NewRow
	   And CancelEdit
	   And ChangedPropertyData Then
		
		If RebatesClientServer.ThisIsNumberByRanges(Object.CalculationScaleType, GoodsIndicator)
		   And PropertyValueThatCanBeChanged <> Undefined Then
			
			UpdatePropertyRowRangesByProperty(PropertyValueThatCanBeChanged);
			
		EndIf;
		
	EndIf;
	
	// Resetting the parameters
	PropertyValueThatCanBeChanged = Undefined;
	ChangedPropertyData = False;
	
EndProcedure

&AtClient
Procedure ProductProperties_PropertyValueOnChange(Item)
	
	CurrentData = Items.ProductProperties_.CurrentData;
	
	IDCurrentRow = CurrentData.GetID();
	ProductProperties_PropertyValueOnChangeServer(
		IDCurrentRow,
		CurrentPropertyValue,
		PropertyValueThatCanBeChanged);
	
	CurrentPropertyValue = CurrentData.PropertyValue;
	ChangedPropertyData = True;
	
EndProcedure

&AtClient
Procedure ProductProperties_CanceledOnChange(Item)
	
	CurrentData = Items.ProductProperties_.CurrentData;
	
	IDCurrentRow = CurrentData.GetID();
	ProductProperties_CanceledOnChangeServer(IDCurrentRow);
	
EndProcedure

&AtClient
Procedure ProductProperties_CountPlanOnChange(Item)
	
	If RebatesClientServer.ThisIsNumberByRanges(Object.CalculationScaleType, GoodsIndicator) Then
		
		CurrentData = Items.ProductProperties_.CurrentData;
		
		IDCurrentRow = CurrentData.GetID();
		ProductProperties_CountPlanOnChangeServer(IDCurrentRow);
		
	EndIf;
	
	ChangedPropertyData = True;
	
EndProcedure

&AtClient
Procedure ProductProperties_ValidOnDateOnChange(Item)
	
	If RebatesClientServer.ThisIsNumberByRanges(Object.CalculationScaleType, GoodsIndicator) Then
		
		CurrentData = Items.ProductProperties_.CurrentData;
		
		IDCurrentRow = CurrentData.GetID();
		ProductProperties_ValidOnDateOnChangeServer(IDCurrentRow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductProperties_ValidToOnChange(Item)
	
	If RebatesClientServer.ThisIsNumberByRanges(Object.CalculationScaleType, GoodsIndicator) Then
		
		CurrentData = Items.ProductProperties_.CurrentData;
		
		IDCurrentRow = CurrentData.GetID();
		ProductProperties_ValidToOnChangeServer(IDCurrentRow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductProperties_BasePriceOnChange(Item)
	
	If RebatesClientServer.ThisIsNumberByRanges(Object.CalculationScaleType, GoodsIndicator) Then
		
		CurrentData = Items.ProductProperties_.CurrentData;
		
		IDCurrentRow = CurrentData.GetID();
		ProductProperties_BasePriceOnChangeServer(IDCurrentRow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductProperties_PropertyValueStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	CurrentData = Items.ProductProperties_.CurrentData;
	Items.ProductProperties_PropertyValue.ChooseType = Not ValueIsFilled(CurrentData.PropertyValue);
	
EndProcedure

&AtClient
Procedure ProductProperties_BeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	Items.ProductProperties_PropertyValue.ChooseType = Not Copy;
	RebatesClientServer.SetDefaultPropertyValueFormat(
		Items.ProductProperties_PropertyValue,
		AcceptablePropertyTypes);
	
EndProcedure

&AtClient
Procedure ProductProperties_PropertyValueChoiceProcessing(Item, ValueSelected, AdditionalData, ChoiceByAdding, StandardProcessing)
	
	If ValueSelected = Type("Number")
	 Or TypeOf(ValueSelected) = Type("Number") Then
		
		RebatesClientServer.SetNumberFormatProperties(Item, AcceptablePropertyTypes);
		
	ElsIf ValueSelected = Type("Date")
	 Or TypeOf(ValueSelected) = Type("Date") Then
		
		RebatesClientServer.SetDefaultPropertyValueFormat(Item, AcceptablePropertyTypes);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductProperties_OnActivateCell(Item)
	
	SetNumberFormat = False;
	If Item.CurrentItem = Items.ProductProperties_PropertyValue Then
		
		CurrentData = Items.ProductProperties_.CurrentData;
		
		If CurrentData <> Undefined
		   And TypeOf(CurrentData.PropertyValue) = Type("Number") Then
			
			SetNumberFormat = True;
			
		EndIf;
		
	EndIf;
	
	If SetNumberFormat Then
		
		RebatesClientServer.SetNumberFormatProperties(
			Items.ProductProperties_PropertyValue,
			AcceptablePropertyTypes);
		
	Else
		
		RebatesClientServer.SetDefaultPropertyValueFormat(
			Items.ProductProperties_PropertyValue,
			AcceptablePropertyTypes);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject, True);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject, True);

EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);
	
EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	CallbackDescription = New CallbackDescription("SetIntervalAfterEnd", ThisObject);
	
	TMCommonUseClient.EditPeriod(
		Object, 
		New Structure("StartDate, EndDate", "ValidOnDate", "ValidTo"),
		CallbackDescription);
		
EndProcedure

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

// End StandardSubsystems.Properties

// StandardSubsystems.AttachableCommands

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	
EndProcedure

// End StandardSubsystems.AttachableCommands

// StandardSubsystems.FilesOperations

&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	
	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
	
EndProcedure

// End StandardSubsystems.FilesOperations

// IntegrationWith1CDocumentManagementSubsystem

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure

// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Async Procedure FillInGoodsBonusPercentage(Command)
	
	SelectedRows = Items.Goods.SelectedRows; // Array of Number
	If SelectedRows.Count() > 0 Then
		
		ToolTip = NStr("vi = '% thưởng';
						|ru = '% бонуса';
						|en = 'Rebate %'; fa = 'Rebate %';
						|it = '% бонуса';
						|pl = 'Rebate %';
						|tr = '% bonus'");
		Qualifiers = New NumberQualifiers(4, 2, AllowedSign.Nonnegative);
		TypeOfPercentage = New TypeDescription("Number", Qualifiers);
		NewPercentage = 0;
		Result = Await InputValueAsync(NewPercentage, ToolTip, TypeOfPercentage); // Number, Undefined
		
		If Result <> Undefined Then
			
			For Each SelectedRow In SelectedRows Do
				
				RowOfGoods = Object.Goods.FindByID(SelectedRow);
				If RowOfGoods.Canceled
				 Or RowOfGoods.InitialString Then
					
					Continue;
					
				EndIf;
				RowOfGoods.Percent = Result;
				
			EndDo;
			
		EndIf;
		
	Else
		
		WarningText = NStr("vi = 'Chưa chọn dòng để điền.';
							|ru = 'Не выбраны строки для заполнения.';
							|en = 'Lines for filling are not selected.'; fa = 'Lines for filling are not selected.';
							|it = 'Не выбраны строки для заполнения.';
							|pl = 'Lines for filling are not selected.';
							|tr = 'Doldurulacak satırlar seçilmemiş.'");
		Await DoMessageBoxAsync(WarningText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DownloadCounterpartiesFromFile(Command)
	
	FieldDisplaySettings = New Structure;
	FieldDisplaySettings.Insert("Counterparty", Items.CounterpartiesCounterparty.Visible);
	FieldDisplaySettings.Insert("Partner", Items.CounterpartiesPartner.Visible);
	FieldDisplaySettings.Insert("SumPlan", Items.CounterpartiesSumPlan.Visible);
	FieldDisplaySettings.Insert("AmountBonus", Items.CounterpartiesAmountBonus.Visible);
	FieldDisplaySettings.Insert("Period", Items.CounterpartiesValidOnDate.Visible);
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "ConditionsOfCustomerRebates.Counterparties";
	ImportParameters.Title = HeaderOfCounterpartyUploadForm();
	ImportParameters.TemplateColumns = DescriptionOfColumnsInTemplateCounterparties(FieldDisplaySettings);
	AdditionalParameters = New Structure("FieldDisplaySettings", FieldDisplaySettings);
	ImportParameters.AdditionalParameters = AdditionalParameters;
	Notification = New CallbackDescription("DownloadCounterpartiesFromFileCompletion", ThisObject);
	ImportDataFromFileClient.ShowImportForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure DownloadCounterpartyTINFromFile(Command)
	
	FieldDisplaySettings = New Structure;
	FieldDisplaySettings.Insert("Period", Items.CounterpartiesTINValidOnDate.Visible);
	FieldDisplaySettings.Insert("SumPlan", Items.CounterpartiesTINSumPlan.Visible);
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "ConditionsOfCustomerRebates.CounterpartiesTIN";
	ImportParameters.Title = NStr("vi = 'Kết nhập MST đối tác từ tệp';
									|ru = 'Загрузка ИНН контрагентов из файла';
									|en = 'Import counterparty TINs from the file'; fa = 'Import counterparty TINs from the file';
									|it = 'Загрузка ИНН контрагентов из файла';
									|pl = 'Import counterparty TINs from the file';
									|tr = 'Dosyadan VKN''yi yükleme'");
	ImportParameters.TemplateColumns = DescriptionOfColumnsInTemplateCounterpartiesTIN(FieldDisplaySettings);
	AdditionalParameters = New Structure("FieldDisplaySettings", FieldDisplaySettings);
	ImportParameters.AdditionalParameters = AdditionalParameters;
	Notification = New CallbackDescription("DownloadCounterpartyTINFromFileCompletion", ThisObject);
	ImportDataFromFileClient.ShowImportForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure LoadGoodsSegmentsFromFile(Command)
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "ConditionsOfCustomerRebates.GoodsSegments";
	ImportParameters.Title = NStr("vi = 'Kết nhập phân khúc mặt hàng từ tệp';
									|ru = 'Загрузка сегментов товаров из файла';
									|en = 'Import goods segments from the file'; fa = 'Import goods segments from the file';
									|it = 'Загрузка сегментов товаров из файла';
									|pl = 'Import goods segments from the file';
									|tr = 'Dosyadan ürün segmentlerini yükleme'");
	ImportParameters.TemplateColumns = DescriptionOfColumnsInGoodsSegmentTemplate();
	ImportParameters.AdditionalParameters = New Structure;
	Notification = New CallbackDescription("LoadGoodsSegmentsFromFileCompletion", ThisObject);
	ImportDataFromFileClient.ShowImportForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure ImportGoodsFromFile(Command)
	
	ToDisplayPeriod = (Items.GoodsValidOnDate.Visible
						Or Items.GoodsValidTo.Visible);
	
	FieldDisplaySettings = New Structure;
	FieldDisplaySettings.Insert("Characteristic", UseItemVariants);
	FieldDisplaySettings.Insert("Period", ToDisplayPeriod);
	FieldDisplaySettings.Insert("CountPlan", Items.GoodsCountPlan.Visible);
	FieldDisplaySettings.Insert("BasePrice", Items.GoodsBasePrice.Visible);
	FieldDisplaySettings.Insert("Percent", Items.GoodsPercent.Visible);
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "ConditionsOfCustomerRebates.Goods";
	ImportParameters.Title = NStr("vi = 'Kết nhập hàng hóa từ tệp';
									|ru = 'Загрузка товаров из файла';
									|en = 'Import goods from the file'; fa = 'Import goods from the file';
									|it = 'Загрузка товаров из файла';
									|pl = 'Import goods from the file';
									|tr = 'Dosyadan ürünleri yükleme'");
	ImportParameters.TemplateColumns = DescriptionOfColumnsInGoodsTemplate(FieldDisplaySettings);
	AdditionalParameters = New Structure("FieldDisplaySettings", FieldDisplaySettings);
	ImportParameters.AdditionalParameters = AdditionalParameters;
	Notification = New CallbackDescription("ImportGoodsFromFileCompletion", ThisObject);
	ImportDataFromFileClient.ShowImportForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure DownloadPartnerSegmentsFromFile(Command)
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "ConditionsOfCustomerRebates.PartnersSegments";
	ImportParameters.Title = NStr("vi = 'Kết nhập phân khúc khách hàng từ tệp';
									|ru = 'Загрузка сегментов клиентов из файла';
									|en = 'Import customer segments from the file'; fa = 'Import customer segments from the file';
									|it = 'Загрузка сегментов клиентов из файла';
									|pl = 'Import customer segments from the file';
									|tr = 'Dosyadan müşteri segmentlerini yükleme'");
	ImportParameters.TemplateColumns = DescriptionOfColumnsInPartnerSegmentTemplate();
	ImportParameters.AdditionalParameters = New Structure;
	Notification = New CallbackDescription("DownloadPartnerSegmentsFromFileCompletion", ThisObject);
	ImportDataFromFileClient.ShowImportForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Async Procedure FillInGoodsQuantityPlan(Command)
	
	SelectedRows = Items.Goods.SelectedRows; // Array of Number
	If SelectedRows.Count() > 0 Then
		
		ToolTip = NStr("vi = 'Số lượng, dự tính';
						|ru = 'Кол-во, план';
						|en = 'Quantity, plan'; fa = 'مقدار، برنامه';
						|it = 'Кол-во, план';
						|pl = 'Quantity, plan';
						|tr = 'Miktar, plan'");
		Qualifiers = New NumberQualifiers(15, 3, AllowedSign.Nonnegative);
		TypeQuantityPlan = New TypeDescription("Number", Qualifiers);
		NewPlan = 0;
		Result = Await InputValueAsync(NewPlan, ToolTip, TypeQuantityPlan); // Number, Undefined
		
		If Result <> Undefined Then
			FillInGoodsQuantityPlanServer(Result, SelectedRows);
		EndIf;
		
	Else
		
		WarningText = NStr("vi = 'Chưa chọn dòng để điền.';
							|ru = 'Не выбраны строки для заполнения.';
							|en = 'Lines to populate are not selected.'; fa = 'Lines to populate are not selected.';
							|it = 'Не выбраны строки для заполнения.';
							|pl = 'Lines to populate are not selected.';
							|tr = 'Doldurulacak satırlar seçilmemiş.'");
		Await DoMessageBoxAsync(WarningText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInParticipantsBySegment(Command)
	
	ClosingNotification1 = New CallbackDescription("FillInParticipantsBySegmentCompletion", ThisObject);
	OpenForm(
		"Catalog.PartnersSegments.ChoiceForm",
		,
		ThisObject,
		,
		,
		,
		ClosingNotification1, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInGoodsBySegment(Command)
	
	ClosingNotification1 = New CallbackDescription("FillInGoodsBySegmentCompletion", ThisObject);
	OpenForm(
		"Catalog.ProductSegments.ChoiceForm",
		,
		ThisObject,
		,
		,
		,
		ClosingNotification1, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ArrangeGoodsByRange(Command)
	
	ArrangeGoodsByRangeAtServer();
	
EndProcedure

&AtClient
Procedure ArrangePropertyValuesByRange(Command)
	
	ArrangePropertyValuesByRangeAtServer();
	
EndProcedure

&AtClient
Procedure ImportPropertiesValuesfromFile(Command)
	
	ClearMessages();
	TypesArray = AcceptablePropertyTypes.Types(); // Array of Type
	
	If TypesArray.Count() = 1 Then 
		
		ValueType = TypesArray[0];
		InformationAboutSource = InformationAboutSourceOfValues(ValueType);
		InformationAboutSource.Insert("Type", AcceptablePropertyTypes);
		
		FieldDisplaySettings = New Structure;
		FieldDisplaySettings.Insert("Period", Items.ProductProperties_ValidOnDate.Visible);
		FieldDisplaySettings.Insert("CountPlan", Items.ProductProperties_CountPlan.Visible);
		FieldDisplaySettings.Insert("BasePrice", Items.ProductProperties_BasePrice.Visible);
		FieldDisplaySettings.Insert("Percent", Items.ProductProperties_Percent.Visible);
		
		ImportParameters = ImportDataFromFileClient.DataImportParameters();
		ImportParameters.FullTabularSectionName = "ConditionsOfCustomerRebates.ProductProperties_";
		ImportParameters.Title = NStr("vi = 'Kết nhập giá trị thuộc tính từ tệp';
										|ru = 'Загрузка значений свойств из файла';
										|en = 'Import property values from file'; fa = 'Import property values from file';
										|it = 'Import property values from file';
										|pl = 'Import property values from file';
										|tr = 'Özellik değerlerini dosyadan içe aktarma'");
		
		ImportParameters.TemplateColumns = DescriptionOfColumnsInTemplateItemProperties(
			FieldDisplaySettings,
			InformationAboutSource);
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("FieldDisplaySettings", FieldDisplaySettings);
		AdditionalParameters.Insert("ArePropertiesValues", True);
		AdditionalParameters.Insert("InformationAboutSource", InformationAboutSource);
		ImportParameters.AdditionalParameters = AdditionalParameters;
		
		Notification = New CallbackDescription("ImportPropertiesValuesfromFileCompletion", ThisObject);
		ImportDataFromFileClient.ShowImportForm(ImportParameters, Notification);
		
	Else
		
		MessageText = NStr("vi = 'Có thể kết nhập chỉ đối với kiểu thuộc tính không phức hợp của mặt hàng';
							|ru = 'Загрузка возможна только для несоставных типов свойства номенклатуры';
							|en = 'Import is only available for non-flexible item property types'; fa = 'Import is only available for non-flexible item property types';
							|it = 'Import is only available for non-flexible item property types';
							|pl = 'Import is only available for non-flexible item property types';
							|tr = 'İçe aktarma, sadece içeriği olmayan öğe özellik türleri için mümkündür'");
		CommonClient.MessageToUser(MessageText);
		
	EndIf;
		
EndProcedure

&AtClient
Async Procedure FillInPropertiesOfItemBonusPercentage(Command)
	
	SelectedRows = Items.ProductProperties_.SelectedRows; // Array of Number
	If SelectedRows.Count() > 0 Then
		
		ToolTip = NStr("vi = '% thưởng';
						|ru = '% бонуса';
						|en = 'Rebate %'; fa = 'Rebate %';
						|it = '% бонуса';
						|pl = 'Rebate %';
						|tr = '% bonus'");
		Qualifiers = New NumberQualifiers(4, 2, AllowedSign.Nonnegative);
		TypeOfPercentage = New TypeDescription("Number", Qualifiers);
		NewPercentage = 0;
		Result = Await InputValueAsync(NewPercentage, ToolTip, TypeOfPercentage); // Number, Undefined
		
		If Result <> Undefined Then
			
			For Each SelectedRow In SelectedRows Do
				
				ItemPropertiesString = Object.ProductProperties_.FindByID(SelectedRow);
				If Not ItemPropertiesString.Canceled
				   And Not ItemPropertiesString.InitialString Then
					
					ItemPropertiesString.Percent = Result;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	Else
		
		WarningText = NStr("vi = 'Chưa chọn dòng để điền.';
							|ru = 'Не выбраны строки для заполнения.';
							|en = 'Lines for filling are not selected.'; fa = 'Lines for filling are not selected.';
							|it = 'Не выбраны строки для заполнения.';
							|pl = 'Lines for filling are not selected.';
							|tr = 'Doldurulacak satırlar seçilmemiş.'");
		Await DoMessageBoxAsync(WarningText);
		
	EndIf;
	
EndProcedure

&AtClient
Async Procedure FillInItemPropertiesQuantityPlan(Command)
	
	SelectedRows = Items.ProductProperties_.SelectedRows; // Array of Number
	If SelectedRows.Count() > 0 Then
		
		ToolTip = NStr("vi = 'Số lượng, dự tính';
						|ru = 'Кол-во, план';
						|en = 'Quantity, plan'; fa = 'مقدار، برنامه';
						|it = 'Кол-во, план';
						|pl = 'Quantity, plan';
						|tr = 'Miktar, plan'");
		Qualifiers = New NumberQualifiers(15, 3, AllowedSign.Nonnegative);
		TypeQuantityPlan = New TypeDescription("Number", Qualifiers);
		NewPlan = 0;
		Result = Await InputValueAsync(NewPlan, ToolTip, TypeQuantityPlan); // Number, Undefined
		
		If Result <> Undefined Then
			
			For Each SelectedRow In SelectedRows Do
				
				ItemPropertiesString = Object.ProductProperties_.FindByID(SelectedRow);
				If Not ItemPropertiesString.Canceled
				   And Not ItemPropertiesString.InitialString Then
					
					ItemPropertiesString.CountPlan = Result;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	Else
		
		WarningText = NStr("vi = 'Chưa chọn dòng để điền.';
							|ru = 'Не выбраны строки для заполнения.';
							|en = 'Lines to populate are not selected.'; fa = 'Lines to populate are not selected.';
							|it = 'Не выбраны строки для заполнения.';
							|pl = 'Lines to populate are not selected.';
							|tr = 'Doldurulacak satırlar seçilmemiş.'");
		Await DoMessageBoxAsync(WarningText);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnCreatReadAtServer()
	
	CurrentStatus = Object.Status;
	
	FillInSignOfAccruals();
	FillInDataOfLastAdjustment();
	
	SetSceneryTitlesWithHyperlinks();
	
	FillInRebateKind(True);
	SetHeadersByCurrency();
	RebatesClientServer.GenerateNamesOfRangesOfCalculationScales(ThisObject);
	RebatesClientServer.SetTitleOfCalculationScaleGroup(ThisObject);
	RebatesServer.UpdateRowRangesOfAllGoods(Object, GoodsIndicator);
	RebatesServer.UpdateRowRangesOfAllProperties(Object, GoodsIndicator);
	SetUnchangedFieldSettingsByType();
	
	// Setting fix visibility
	ItemsNames = New Array; // Array of String
	ItemsNames.Add(Items.CounterpartiesAmountPlanBeforeChange.Name);
	ItemsNames.Add(Items.CounterpartiesStartDateBeforeChange.Name);
	ItemsNames.Add(Items.CounterpartiesEndDateBeforeChange.Name);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items, ItemsNames, "Visible", Object.Patch);
	
	CashServer.ManagingFormElementsWhenReadingCreatingOnServer(ThisObject);
	
	ItemArray = New Array; // Array of String
	ItemArray.Add(Items.SetDateInterval.Name);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items, ItemArray, "Visible", Not Object.Patch);
	
	ArrayOfValidTypes = New FixedArray(RebatesServer.SupportedItemTypes());
	ItemSelectionParameter = New ChoiceParameter("Filter.ItemsType", ArrayOfValidTypes);
	ProductSelectionParameters = CommonClientServer.ValueInArray(ItemSelectionParameter); // Array of ChoiceParameter
	Items.GoodsProducts.ChoiceParameters = New FixedArray(ProductSelectionParameters);
	
	SetAvailableListOfTimeFenceAccruals(ThisObject);
	FillInServiceDetailsForProductRange();
	
	BeginningOfActionLine = Format(Object.ValidOnDate, "DLF=D;");
	EndOfActionWithLine = Format(Object.ValidTo, "DLF=D;");
	GenerateAmountsOfPlansAsLine(ThisObject);
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	UseStandardAndIndividualTermsOfSalesWithCustomers = GetFunctionalOption("UseStandardAndIndividualTermsOfSalesWithCustomers");
	
	SetParticipantInformationSettings();
	FillInServiceAttributesOfAgreementsContracts();
	SetGoodsDetailsSettings();
	FillInAttributesOfCompositionAccordingToCondition();
	
	SetSettingsByStatus();
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure SetSettingsByStatus()
	
	If Object.Ref.IsEmpty() Then
		RightsChangeAvailable = True;
	Else
		RightsChangeAvailable = AccessManagement.EditionAllowed(Object.Ref);
	EndIf;
	
	Allowed1Update = Documents.ConditionsOfCustomerRebates.ChangeByStatusIsAllowed(Object.Status);
	VisibilityOfCancellationOfApproval = False;
	
	If Not Allowed1Update Then
		
		ReadOnly = True;
		
		VisibilityOfCancellationOfApproval = (RightsChangeAvailable
									   And Object.Status = Enums.RebatesDocumentStatuses.Approved);
		
	EndIf;
	
	CommonClientServer.SetFormItemProperty(
		Items,
		Items.DecorationCancelApproval.Name,
		"Visible",
		VisibilityOfCancellationOfApproval);
	
	SetVisibilityOfCommandsFixingComposition(ThisObject);
	
	If ReadOnly Then
		
		Items.Status.ChoiceList.Clear();
		Items.Status.ListChoiceMode = False;
		
	Else
		
		AllowedStatuses = Documents.ConditionsOfCustomerRebates.AllowedInstallationStatus();
		
		If AllowedStatuses.Count() > 0 Then
			
			Items.Status.ChoiceList.LoadValues(AllowedStatuses);
			Items.Status.ListChoiceMode = True;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAttributesOfCompositionAccordingToCondition()
	
	If Object.Posted Then
		
		ConditionData = Documents.ConditionsOfCustomerRebates.UpToDateData(Object.Ref);
		If ConditionData.ContentOfGoods = Enums.RebatesItems.ProductSegments
		 Or ConditionData.PartyList = Enums.RebatesParticipants.PartnersSegments
		 Or Not IsBlankString(ConditionData.ProductItemProperty) Then
			
			CompositionFixationIsAvailable = True;
			
		Else
			
			CompositionFixationIsAvailable = False;
			
		EndIf;
		
		CompositionOfSegmentsIsFixed = ConditionData.RecordingIsCompleted;
		
	Else
		
		CompositionFixationIsAvailable = False;
		CompositionOfSegmentsIsFixed = False;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityOfCommandsFixingComposition(Form)
	
	ArrayOfAllElements = New Array; // Array of String
	ArrayOfAllElements.Add(Form.Items.DecorationFixComposition.Name);
	ArrayOfAllElements.Add(Form.Items.DecorationIsToCancelFixationOfComposition.Name);
	
	ArrayOfVisible = New Array; // Array of String
	
	StatusAgreed =
		(Form.Object.Status = PredefinedValue("Enum.RebatesDocumentStatuses.Approved"));
	
	If StatusAgreed
	   And Form.ThereIsRightToChangeURB
	   And Form.CompositionFixationIsAvailable
	   And Not Form.CompositionOfSegmentsIsFixed Then
		
		ArrayOfVisible.Add(Form.Items.DecorationFixComposition.Name);
		
	EndIf;
	
	If StatusAgreed
	   And Form.ThereIsRightToChangeURB
	   And Form.CompositionFixationIsAvailable
	   And Form.CompositionOfSegmentsIsFixed Then
		
		ArrayOfVisible.Add(Form.Items.DecorationIsToCancelFixationOfComposition.Name);
		
	EndIf;
	
	TMCommonUseClientServer.SetVisibilityOfElementsByArray(
		Form.Items, ArrayOfAllElements, ArrayOfVisible);
	
	CommonClientServer.SetFormItemProperty(
		Form.Items,
		Form.Items.DecorationFixComposition.Name,
		"Enabled",
		True);
	
	CommonClientServer.SetFormItemProperty(
		Form.Items,
		Form.Items.DecorationIsToCancelFixationOfComposition.Name,
		"Enabled",
		True);
	
EndProcedure

&AtServer
Procedure SetSceneryTitlesWithHyperlinks()
	
	RebatesServer.SetSceneryTitlesWithHyperlinks(ThisObject);
	
EndProcedure

&AtClient
Async Procedure WarningOfNeedToFillInBorder()
	
	WarningText = NStr("vi = 'Cần đặt biên';
						|ru = 'Граница должна быть задана';
						|en = 'Specify the boundary'; fa = 'Specify the boundary';
						|it = 'Specify the boundary';
						|pl = 'Specify the boundary';
						|tr = 'Sınır ayarlanmalıdır'");
	Await DoMessageBoxAsync(WarningText);
	
	CurrentItem = Items.CalculationScalesRangeFrom;
	Items.CalculationScales.ChangeRow();
	
EndProcedure

&AtClient
Async Procedure WarningDoubleBorders(Value_Border)
	
	WarningTemplate = NStr("vi = 'Giá trị biên %1 đã có trong danh sách';
							|ru = 'Значение границы %1 уже есть в списке';
							|en = 'The list already has the %1 boundary value'; fa = 'The list already has the %1 boundary value';
							|it = 'The list already has the %1 boundary value';
							|pl = 'The list already has the %1 boundary value';
							|tr = '%1 sınır değeri listede zaten mevcut'");
	WarningText = StringFunctionsClientServer.SubstituteParametersToString(
		WarningTemplate,
		Format(Value_Border, "NFD=2; NZ=0"));
	Await DoMessageBoxAsync(WarningText);
	
	CurrentItem = Items.CalculationScalesRangeFrom;
	Items.CalculationScales.ChangeRow();
	
EndProcedure

#Region ConditionalAppearance

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	SetLayoutOfCounterpartiesTable();
	SetDesignOfCounterpartiesTINTable();
	SetLayoutOfContractAgreementsTable();
	SetLayoutOfGoodsTable();
	SetLayoutOfItemPropertiesTable();
	
	RebatesServer.SetDesignOfCalculationScaleTable(ConditionalAppearance);
	
	OrdersServer.SetAppearanceOfCanceledLine(
		ConditionalAppearance,
		Items.PartnersSegments,
		Items.PartnersSegmentsCanceled.Name);
	SetLayoutOfSourceLinesPartnerSegments();
	
	OrdersServer.SetAppearanceOfCanceledLine(
		ConditionalAppearance,
		Items.GoodsSegments,
		Items.GoodsSegmentsCanceled.Name);
	
	SetLayoutOfSourceLinesGoodsSegments();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfPeriod(FormTable, DateStartsAsString, LineEndDate)
	
	// Filling in the date from the header, if not specified in the lines
	
	KTCHPath = FormTable.DataPath;
	TableName = FormTable.Name;
	NameStartOfAction = TableName + "ValidOnDate";
	PathToBeginningOfAction = KTCHPath + ".ValidOnDate";
	NameEndOfAction = TableName + "ValidTo";
	PathToEndOfAction = KTCHPath + ".ValidTo";
	PathToCancelled = KTCHPath + ".Canceled";
	
	#Region ValidOnDate
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(NameStartOfAction);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToBeginningOfAction);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToCancelled);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", DateStartsAsString);
	Item.Appearance.SetParameterValue("HorizontalAlign", HorizontalAlign.Left);
	#EndRegion
	
	#Region ValidTo
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(NameEndOfAction);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToEndOfAction);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToCancelled);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", LineEndDate);
	Item.Appearance.SetParameterValue("HorizontalAlign", HorizontalAlign.Left);
	#EndRegion
	
EndProcedure

&AtServer
Procedure IssueCanceledLines(FormTable, ItemsNames = Undefined)
	
	KTCHPath = FormTable.DataPath;
	PathToCancelled = KTCHPath + ".Canceled";
	
	Item = ConditionalAppearance.Items.Add();
	
	For Each FieldName In ItemsNames Do
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FieldName);
		
	EndDo;
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Filter);
		
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToCancelled);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", "-");
	Item.Appearance.SetParameterValue("HorizontalAlign", HorizontalAlign.Center);
	
EndProcedure

&AtServer
Procedure SetLayoutOfSourceLinesPartnerSegments()
	
	DesignParameters = RebatesServer.NewParametersForDesignOfSourceLines();
	
	DesignParameters.SourceStringFields.Add(Items.PartnersSegmentsSegment.Name);
	
	RebatesServer.ArrangeFieldsAccordingToOriginalLines(
		ConditionalAppearance,
		Items.PartnersSegments,
		DesignParameters);
	
EndProcedure

&AtServer
Procedure SetLayoutOfSourceLinesGoodsSegments()
	
	DesignParameters = RebatesServer.NewParametersForDesignOfSourceLines();
	
	DesignParameters.SourceStringFields.Add(Items.GoodsSegmentsSegment.Name);
	
	RebatesServer.ArrangeFieldsAccordingToOriginalLines(
		ConditionalAppearance,
		Items.GoodsSegments,
		DesignParameters);
	
EndProcedure

#Region ConditionalAppearanceCounterparties

&AtServer
Procedure SetLayoutOfCounterpartiesTable()
	
	DataLayoutFieldStartDateInRow = New DataCompositionField("BeginningOfActionLine");
	DataLayoutFieldIsEndDateOfString = New DataCompositionField("EndOfActionWithLine");
	
	OrdersServer.SetAppearanceOfCanceledLine(
		ConditionalAppearance,
		Items.Counterparties,
		Items.CounterpartiesCanceled.Name);
	
	ItemsNames = New Array; // Array of String
	ItemsNames.Add(Items.CounterpartiesSumPlan.Name);
	ItemsNames.Add(Items.CounterpartiesValidOnDate.Name);
	ItemsNames.Add(Items.CounterpartiesValidTo.Name);
	IssueCanceledLines(Items.Counterparties, ItemsNames);
	
	SetDesignOfSourceLinesCounterparties();
	
	SetConditionalAppearanceOfPeriod(
		Items.Counterparties,
		DataLayoutFieldStartDateInRow,
		DataLayoutFieldIsEndDateOfString);
	
	SetRegistrationCounterpartiesCounterparty();
	SetRegistrationCounterpartiesPartner();
	SetRegistrationCounterpartiesAmountPlan();
	
EndProcedure

&AtServer
Procedure SetRegistrationCounterpartiesCounterparty()
	
	#Region RequiredFilling
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CounterpartiesCounterparty.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PartyList");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.RebatesParticipants.Customers;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AccrueImmediately");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
	#Region EmptyCounterparty
	EmptyCounterpartyString = NStr("vi = '<bất kỳ>';
									|ru = '<любой>';
									|en = '<any>'; fa = '<هر>';
									|it = '<любой>';
									|pl = '<any>';
									|tr = '<herhangi>'");
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CounterpartiesCounterparty.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PartyList");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.RebatesParticipants.Customers;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AccrueImmediately");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Counterparties.Counterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue(
		"TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	ConditionalAppearanceItem.Appearance.SetParameterValue(
		"Text", EmptyCounterpartyString);
	#EndRegion
	
EndProcedure

&AtServer
Procedure SetRegistrationCounterpartiesPartner()
	
	#Region RequiredFilling
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CounterpartiesPartner.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PartyList");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.RebatesParticipants.Counterparties;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AccrueImmediately");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
	#Region EmptyPartner
	EmptyPartnerString = NStr("vi = '<bất kỳ>';
								|ru = '<любой>';
								|en = '<any>'; fa = '<هر>';
								|it = '<любой>';
								|pl = '<any>';
								|tr = '<herhangi>'");
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CounterpartiesPartner.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PartyList");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.RebatesParticipants.Counterparties;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AccrueImmediately");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Counterparties.Partner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue(
		"TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	ConditionalAppearanceItem.Appearance.SetParameterValue(
		"Text", EmptyPartnerString);
	#EndRegion
	
EndProcedure

&AtServer
Procedure SetRegistrationCounterpartiesAmountPlan()
	
	DataLayoutFieldIsSumOfPlanByLine = New DataCompositionField("SumOfPlanByLine");
	DataLayoutFieldSumPlanByRowUnchanged = New DataCompositionField("AmountOfPlanByLineIsUnchanged");
	LineUpsOfParticipants = Enums.RebatesParticipants;
	
	#Region EmptyPlan
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CounterpartiesSumPlan.Name);
	
	Indicators = New ValueList; // ValueList of EnumRef.RebatesParticipants
	Indicators.Add(LineUpsOfParticipants.Counterparties);
	Indicators.Add(LineUpsOfParticipants.Customers);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PartyList");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = Indicators;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Counterparties.SumPlan");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Counterparties.PlanIsNotSpecified");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Counterparties.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", DataLayoutFieldIsSumOfPlanByLine);
	#EndRegion
	
	#Region PlanIsNotSpecified
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CounterpartiesSumPlan.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Counterparties.PlanIsNotSpecified");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", DataLayoutFieldSumPlanByRowUnchanged);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion
	
EndProcedure

&AtServer
Procedure SetDesignOfSourceLinesCounterparties()
	
	DesignParameters = RebatesServer.NewParametersForDesignOfSourceLines();
	
	DesignParameters.SourceStringFields.Add(Items.CounterpartiesCounterparty.Name);
	DesignParameters.SourceStringFields.Add(Items.CounterpartiesPartner.Name);
	
	DesignParameters.FieldsBeforeChanges.Add(Items.CounterpartiesAmountPlanBeforeChange.Name);
	DesignParameters.FieldsBeforeChanges.Add(Items.CounterpartiesStartDateBeforeChange.Name);
	DesignParameters.FieldsBeforeChanges.Add(Items.CounterpartiesEndDateBeforeChange.Name);
	
	RebatesServer.ArrangeFieldsAccordingToOriginalLines(
		ConditionalAppearance,
		Items.Counterparties,
		DesignParameters);
	
EndProcedure

#EndRegion

#Region ConditionalAppearanceOfCounterpartiesTIN

&AtServer
Procedure SetDesignOfCounterpartiesTINTable()
	
	DataLayoutFieldStartDateInRow = New DataCompositionField("BeginningOfActionLine");
	DataLayoutFieldIsEndDateOfString = New DataCompositionField("EndOfActionWithLine");
	
	OrdersServer.SetAppearanceOfCanceledLine(
		ConditionalAppearance,
		Items.CounterpartiesTIN,
		Items.CounterpartiesTINCanceled.Name);
	
	ItemsNames = New Array; // Array of String
	ItemsNames.Add(Items.CounterpartiesTINSumPlan.Name);
	ItemsNames.Add(Items.CounterpartiesTINValidOnDate.Name);
	ItemsNames.Add(Items.CounterpartiesTINValidTo.Name);
	IssueCanceledLines(Items.CounterpartiesTIN, ItemsNames);
	
	SetDesignOfInitialLinesOfCounterpartiesTIN();
	
	SetConditionalAppearanceOfPeriod(
		Items.CounterpartiesTIN,
		DataLayoutFieldStartDateInRow,
		DataLayoutFieldIsEndDateOfString);
	
	SetRegistrationOfCounterpartiesTINAmountPlan();
	
EndProcedure

&AtServer
Procedure SetRegistrationOfCounterpartiesTINAmountPlan()
	
	DataLayoutFieldIsSumOfPlanByLine = New DataCompositionField("SumOfPlanByLine");
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CounterpartiesTINSumPlan.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PartyList");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.RebatesParticipants.TIN;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CounterpartiesTIN.SumPlan");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CounterpartiesTIN.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", DataLayoutFieldIsSumOfPlanByLine);
	
EndProcedure

&AtServer
Procedure SetDesignOfInitialLinesOfCounterpartiesTIN()
	
	DesignParameters = RebatesServer.NewParametersForDesignOfSourceLines();
	
	DesignParameters.SourceStringFields.Add(Items.CounterpartiesTINTIN.Name);
	
	DesignParameters.FieldsBeforeChanges.Add(Items.CounterpartiesTINAmountPlanBeforeChange.Name);
	DesignParameters.FieldsBeforeChanges.Add(Items.CounterpartiesTINStartDateBeforeChange.Name);
	DesignParameters.FieldsBeforeChanges.Add(Items.CounterpartiesTINEndDateBeforeChange.Name);
	
	RebatesServer.ArrangeFieldsAccordingToOriginalLines(
		ConditionalAppearance,
		Items.CounterpartiesTIN,
		DesignParameters);
	
EndProcedure

#EndRegion

#Region ConditionalAppearanceContractsAgreements

&AtServer
Procedure SetLayoutOfContractAgreementsTable()
	
	DataLayoutFieldStartDateInRow = New DataCompositionField("BeginningOfActionLine");
	DataLayoutFieldIsEndDateOfString = New DataCompositionField("EndOfActionWithLine");
	
	OrdersServer.SetAppearanceOfCanceledLine(
		ConditionalAppearance,
		Items.ContractsTermsOfSales,
		Items.ContractsTermsOfSalesCanceled.Name);
	
	ItemsNames = New Array; // Array of String
	ItemsNames.Add(Items.ContractsTermsOfSalesSumPlan.Name);
	ItemsNames.Add(Items.ContractsTermsOfSalesValidOnDate.Name);
	ItemsNames.Add(Items.ContractsTermsOfSalesValidTo.Name);
	IssueCanceledLines(Items.ContractsTermsOfSales, ItemsNames);
	
	SetDesignOfSourceLinesContractsAgreements();
	
	SetConditionalAppearanceOfPeriod(
		Items.ContractsTermsOfSales,
		DataLayoutFieldStartDateInRow,
		DataLayoutFieldIsEndDateOfString);
	
	ToEstablishExecutionOfContractsAgreementsAmountPlan();
	EstablishExecutionOfContractsAgreementsCounterparty();
	ToEstablishExecutionOfContractsPartnerAgreements();
	EstablishExecutionOfContractsAgreementsContract();
	EstablishDesignOfContractAgreementsTypeOfAgreement();
	ToEstablishRegistrationOfContractsSalesAgreementsIndividualAccordingToStandard();
	
EndProcedure

&AtServer
Procedure SetDesignOfSourceLinesContractsAgreements()
	
	DesignParameters = RebatesServer.NewParametersForDesignOfSourceLines();
	
	DesignParameters.SourceStringFields.Add(Items.ContractsTermsOfSalesPartner.Name);
	DesignParameters.SourceStringFields.Add(Items.ContractsTermsOfSalesCounterparty.Name);
	DesignParameters.SourceStringFields.Add(Items.ContractsTermsOfSalesContract.Name);
	DesignParameters.SourceStringFields.Add(Items.ContractsTermsOfSalesTerms.Name);
	DesignParameters.SourceStringFields.Add(Items.ContractsTermsOfSalesSalesSpecialByStandard.Name);
	
	DesignParameters.FieldsBeforeChanges.Add(Items.ContractsTermsOfSalesAmountPlanBeforeChange.Name);
	DesignParameters.FieldsBeforeChanges.Add(Items.ContractsTermsOfSalesStartDateBeforeChange.Name);
	DesignParameters.FieldsBeforeChanges.Add(Items.ContractsTermsOfSalesEndDateBeforeChange.Name);
	
	RebatesServer.ArrangeFieldsAccordingToOriginalLines(
		ConditionalAppearance,
		Items.ContractsTermsOfSales,
		DesignParameters);
	
EndProcedure

&AtServer
Procedure ToEstablishExecutionOfContractsAgreementsAmountPlan()
	
	DataLayoutFieldIsSumOfPlanByLine = New DataCompositionField("SumOfPlanByLine");
	DataLayoutFieldSumPlanByRowUnchanged = New DataCompositionField("AmountOfPlanByLineIsUnchanged");
	LineUpsOfParticipants = Enums.RebatesParticipants;
	
	#Region EmptyPlan
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ContractsTermsOfSalesSumPlan.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PartyList");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = LineUpsOfParticipants.Contracts;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ContractsTermsOfSales.SumPlan");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ContractsTermsOfSales.PlanIsNotSpecified");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ContractsTermsOfSales.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", DataLayoutFieldIsSumOfPlanByLine);
	#EndRegion
	
	#Region PlanIsNotSpecified
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ContractsTermsOfSalesSumPlan.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ContractsTermsOfSales.PlanIsNotSpecified");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", DataLayoutFieldSumPlanByRowUnchanged);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion
	
EndProcedure

&AtServer
Procedure EstablishExecutionOfContractsAgreementsContract()
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ContractsTermsOfSalesContract.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Organization");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	LineSpecifyOrganization = NStr("vi = '<điền doanh nghiệp>';
									|ru = '<укажите организацию>';
									|en = '<specify the company>'; fa = '<specify the company>';
									|it = '<укажите организацию>';
									|pl = '<specify the company>';
									|tr = '<iş yerinizi belirtin>'");
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", LineSpecifyOrganization);
	
EndProcedure

&AtServer
Procedure EstablishExecutionOfContractsAgreementsCounterparty()
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ContractsTermsOfSalesCounterparty.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ContractsTermsOfSales.Counterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	StringForEveryone = NStr("vi = '<tất cả>';
							|ru = '<все>';
							|en = '<all>'; fa = '<همه>';
							|it = '<все>';
							|pl = '<wszystkie>';
							|tr = '<tümü>'");
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", StringForEveryone);
	
EndProcedure

&AtServer
Procedure ToEstablishExecutionOfContractsPartnerAgreements()
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ContractsTermsOfSalesPartner.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ContractsTermsOfSales.Partner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	StringForEveryone = NStr("vi = '<tất cả>';
							|ru = '<все>';
							|en = '<all>'; fa = '<همه>';
							|it = '<все>';
							|pl = '<wszystkie>';
							|tr = '<tümü>'");
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", StringForEveryone);
	
EndProcedure

&AtServer
Procedure EstablishDesignOfContractAgreementsTypeOfAgreement()
	
	#Region AgreementIsNotCompleted
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ContractsTermsOfSalesAgreementType.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ContractsTermsOfSales.Terms");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	TextNotFilledIn = NStr("vi = '<điền thỏa thuận>';
							|ru = '<укажите соглашение>';
							|en = '<specify the terms of sales>'; fa = '<specify the terms of sales>';
							|it = '<укажите соглашение>';
							|pl = '<specify the terms of sales>';
							|tr = '<anlaşmayı belirtin>'");
	Item.Appearance.SetParameterValue("Text", TextNotFilledIn);
	Item.Appearance.SetParameterValue("HorizontalAlign", HorizontalAlign.Center);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	#EndRegion
	
	#Region ModelAgreement
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ContractsTermsOfSalesAgreementType.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ContractsTermsOfSales.Terms");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ContractsTermsOfSales.ThisIsModelAgreement");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	TextStandart = NStr("vi = 'Chung';
						|ru = 'Типовое';
						|en = 'Standard'; fa = 'استاندارد';
						|it = 'Типовое';
						|pl = 'Typowa';
						|tr = 'Standart'");
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", TextStandart);
	#EndRegion
	
	#Region IndividualAgreement
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ContractsTermsOfSalesAgreementType.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ContractsTermsOfSales.Terms");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ContractsTermsOfSales.ThisIsModelAgreement");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	TextIndividual = NStr("vi = 'Riêng';
							|ru = 'Индивидуальное';
							|en = 'Individual'; fa = 'شخص حقیقی';
							|it = 'Индивидуальное';
							|pl = 'Indywidualna';
							|tr = 'Özelleştirilmiş'");
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", TextIndividual);
	#EndRegion
	
EndProcedure

&AtServer
Procedure ToEstablishRegistrationOfContractsSalesAgreementsIndividualAccordingToStandard()
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ContractsTermsOfSalesSalesSpecialByStandard.Name);
	
	OrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ContractsTermsOfSales.Terms");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	AndGroup = OrGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ContractsTermsOfSales.Terms");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ContractsTermsOfSales.ThisIsModelAgreement");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure
#EndRegion

#Region ConditionalAppearanceDesignOfItems

&AtServer
Procedure SetLayoutOfGoodsTable()
	
	DataLayoutFieldStartDateInRow = New DataCompositionField("BeginningOfActionLine");
	DataLayoutFieldIsEndDateOfString = New DataCompositionField("EndOfActionWithLine");
	
	RebatesServer.SetLayoutOfItemsTableCharacteristics(ThisObject);
	
	OrdersServer.SetAppearanceOfCanceledLine(
		ConditionalAppearance,
		Items.Goods,
		Items.GoodsCanceled.Name);
	
	ItemsNames = New Array; // Array of String
	ItemsNames.Add(Items.GoodsValidOnDate.Name);
	ItemsNames.Add(Items.GoodsValidTo.Name);
	IssueCanceledLines(Items.Goods, ItemsNames);
	
	RebatesServer.SetTableLayoutFieldNumberPlan(ConditionalAppearance, "Goods");
	RebatesServer.SetTableLayoutPercentageField(ConditionalAppearance, "Goods");
	
	SetLayoutOfSourceRowsOfItemsTable();
	
	SetConditionalAppearanceOfPeriod(
		Items.Goods,
		DataLayoutFieldStartDateInRow,
		DataLayoutFieldIsEndDateOfString);
	
EndProcedure

&AtServer
Procedure SetLayoutOfSourceRowsOfItemsTable()
	
	TableName = "Goods";
	DesignParameters = RebatesServer.NewParametersForDesignOfSourceLines();
	
	ProductsField = TableName + "Products";
	CharacteristicField = TableName + "Characteristic";
	NumberFieldPlan = TableName + "CountPlan";
	BasePriceField = TableName + "BasePrice";
	PercentageField = TableName + "Percent";
	
	DesignParameters.SourceStringFields.Add(ProductsField);
	DesignParameters.SourceStringFields.Add(CharacteristicField);
	DesignParameters.SourceStringFields.Add(NumberFieldPlan);
	DesignParameters.SourceStringFields.Add(BasePriceField);
	DesignParameters.SourceStringFields.Add(PercentageField);
	
	StartOfActionBeforeChangesField = TableName + "StartDateBeforeChange";
	EndOfActionBeforeChangesField = TableName + "EndDateBeforeChange";
	
	DesignParameters.FieldsBeforeChanges.Add(StartOfActionBeforeChangesField);
	DesignParameters.FieldsBeforeChanges.Add(EndOfActionBeforeChangesField);
	
	RebatesServer.ArrangeFieldsAccordingToOriginalLines(
		ConditionalAppearance,
		Items[TableName],
		DesignParameters);
	
EndProcedure

#EndRegion

#Region SetDesignOfItemProperties

&AtServer
Procedure SetLayoutOfItemPropertiesTable()
	
	DataLayoutFieldStartDateInRow = New DataCompositionField("BeginningOfActionLine");
	DataLayoutFieldIsEndDateOfString = New DataCompositionField("EndOfActionWithLine");
	
	OrdersServer.SetAppearanceOfCanceledLine(
		ConditionalAppearance,
		Items.ProductProperties_,
		Items.ProductProperties_Canceled.Name);
	
	ItemsNames = New Array; // Array of String
	ItemsNames.Add(Items.ProductProperties_ValidOnDate.Name);
	ItemsNames.Add(Items.ProductProperties_ValidTo.Name);
	IssueCanceledLines(Items.ProductProperties_, ItemsNames);
	
	RebatesServer.SetTableLayoutFieldNumberPlan(ConditionalAppearance, "ProductProperties_");
	RebatesServer.SetTableLayoutPercentageField(ConditionalAppearance, "ProductProperties_");
	RebatesServer.SetLayoutOfSourceRowsOfItemPropertiesTable(Items, ConditionalAppearance);
	
	SetConditionalAppearanceOfPeriod(
		Items.ProductProperties_,
		DataLayoutFieldStartDateInRow,
		DataLayoutFieldIsEndDateOfString);
	
EndProcedure

#EndRegion

#EndRegion

#Region EventHandlersForFormHeaderElementsAuxiliary

// Parameters:
//  Result - Undefined - Result
//  AdditionalParameters - Structure - advanced setting
// 
&AtClient
Procedure SetIntervalAfterEnd(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	BeginningOfActionLine = Format(Object.ValidOnDate, "DLF=D;");
	EndOfActionWithLine = Format(Object.ValidTo, "DLF=D;");
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	DetermineDocumentCurrency();
	SetHeadersByCurrency();
	
	Object.ContractsTermsOfSales.Clear();
	
	ConfigureDependentFormElementsOnServer("Organization");
	
EndProcedure

&AtServer
Procedure RebateKindOnChangeServer()
	
	FillInRebateKind();
	SetHeadersByCurrency();
	EstablishSignsOfCalculationOfParticipantsPlan();
	SetUnchangedFieldSettingsByType();
	
	FilterPartiesOnChangeServer(False);
	FilterOfProducts_OnChangeServer(False);
	SetAvailableListOfTimeFenceAccruals(ThisObject);
	
	CalculationByScale =
		(GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
		 And Object.CalculationScaleType <> 0);
	
	If GoodsIndicator <> Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
	 Or CalculationByScale Then
		
		Object.SumPlan = 0;
		
	EndIf;
	
	If GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.NotUsed
	 Or CalculationByScale Then
		
		Object.BonusPercent = 0;
		Object.RestrictAccrualOverPlan = False;
		
	EndIf;
	
	If GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum Then
		
		Object.BonusPercent = 0;
		
	EndIf;
	
	If Object.WithoutCalculation Then
		
		For Each ContractorsLine In Object.Counterparties Do
			
			ContractorsLine.SumPlan = 0;
			ContractorsLine.ValidOnDate = Date(1, 1, 1);
			ContractorsLine.ValidTo = Date(1, 1, 1);
			
		EndDo;
		
		Object.CounterpartiesTIN.Clear();
		Object.Goods.Clear();
		
	Else
		
		For Each ContractorsLine In Object.Counterparties Do
			
			ContractorsLine.AmountBonus = 0;
			
		EndDo;
		
		Object.AccrueImmediately = False;
		
	EndIf;
		
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure PartyCountDetailsOnChangeServer()
	
	EstablishSignsOfCalculationOfParticipantsPlan();
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure FilterPartiesOnChangeServer(Val ConfigureDependentElements = True)
	
	SetParticipantInformationSettings();
	
	ParametersOfParticipants = Documents.ConditionsOfCustomerRebates.ParametersForClearingParticipantsAttributes();
	ParametersOfParticipants.PartyList = PartyList;
	ParametersOfParticipants.FilterParties = Object.FilterParties;
	ParametersOfParticipants.GoodsIndicator = GoodsIndicator;
	Documents.ConditionsOfCustomerRebates.ClearUnusedDetailsOfParticipants(Object, ParametersOfParticipants);
	
	If ConfigureDependentElements Then
		
		ConfigureDependentFormElementsOnServer("FilterParties");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FilterOfProducts_OnChangeServer(Val ConfigureDependentElements = True)
	
	SetGoodsDetailsSettings();
	
	GoodsParameters = Documents.ConditionsOfCustomerRebates.ParametersForClearingGoodsAttributes();
	GoodsParameters.ContentOfGoods = ContentOfGoods;
	GoodsParameters.FilterOfProducts_ = Object.FilterOfProducts_;
	GoodsParameters.GoodsIndicator = GoodsIndicator;
	GoodsParameters.BaseOfCalculation = SalesCalculationBase;
	Documents.ConditionsOfCustomerRebates.ClearUnusedGoodsDetails(Object, GoodsParameters);
	
	If ConfigureDependentElements Then
		
		ConfigureDependentFormElementsOnServer("FilterOfProducts_");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CalculationScaleTypeOnChangeServer()
	
	If Object.CalculationScaleType = 0 Then
		
		Object.CalculationScales.Clear();
		
	EndIf;
	
	If GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Count Then
		
		Object.CalculationScales.Clear();
		
		If Object.CalculationScaleType = 0 Then // Progressive Scale
			
			RebatesServer.InitializeProgressiveScale(ThisObject, "Goods");
			RebatesServer.InitializeProgressiveScale(ThisObject, "ProductProperties_");
			
		EndIf;
		
		If Object.CalculationScaleType = 1 Then // By Ranges
			
			Object.RestrictAccrualOverPlan = False;
			RebatesServer.InitializeGoodsRanges(ThisObject);
			RebatesServer.InitializePropertyRanges(ThisObject);
			
		EndIf;
		
	EndIf;
	
	If GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum Then
		
		If Object.CalculationScaleType <> 0 Then // Not the only value
			
			Object.BonusPercent = 0;
			Object.SumPlan = 0;
			
		EndIf;
		
		If Object.CalculationScaleType = 1 Then // Progressive Scale
			
			FilterParameters = New Structure;
			FilterParameters.Insert("RangeFrom", 0);
			
			FoundRows = Object.CalculationScales.FindRows(FilterParameters);
			For Each ScaleLine In FoundRows Do
				Object.CalculationScales.Delete(ScaleLine);
			EndDo;
			
		EndIf;
		
		If Object.CalculationScaleType = 2 Then // Ranges
			
			Object.RestrictAccrualOverPlan = False;
			
			FilterParameters = New Structure;
			FilterParameters.Insert("RangeFrom", 0);
			
			FoundRows = Object.CalculationScales.FindRows(FilterParameters);
			If FoundRows.Count() = 0 Then
				
				Object.CalculationScales.Insert(0);
				RebatesClientServer.GenerateNamesOfRangesOfCalculationScales(ThisObject);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	ConfigureDependentFormElementsOnServer();
	RebatesClientServer.SetTitleOfCalculationScaleGroup(ThisObject);
	
EndProcedure

&AtClient
Procedure CancelApproval()
	
	FillInSignOfAccruals();
	
	If Not ThereAreAccruals Then
		
		Modified = True;
		ReadOnly = False;
		Object.Status = PredefinedValue("Enum.RebatesDocumentStatuses.Draft");
		CurrentStatus = Object.Status;
		SetSettingsByStatus();
		
		// StandardSubsystems.AttachableCommands
		AttachableCommandsClient.StartCommandUpdate(ThisObject);
		// End StandardSubsystems.AttachableCommands
		
	Else
		
		SetSceneryTitlesWithHyperlinks();
		
		MessageText = NStr("vi = 'Đã tạo chứng từ tính toán. Cấm hủy thống nhất.';
							|ru = 'Созданы документы начисления. Отмена согласования запрещена.';
							|en = 'Accrual documents are created. Cannot cancel the approval.'; fa = 'Accrual documents are created. Cannot cancel the approval.';
							|it = 'Созданы документы начисления. Отмена согласования запрещена.';
							|pl = 'Accrual documents are created. Cannot cancel the approval.';
							|tr = 'Tahakkuk belgeleri oluşturuldu. Anlaşma iptal edilemez.'");
		CommonClient.MessageToUser(MessageText,, "Object", "Status");
		
	EndIf;
	
EndProcedure

&AtClient
Async Procedure FixCompositionOfDocument()
	
	UpdateDataBeforeFixingComposition();
	If Not ThereIsAdjustmentOnApproval
	   And Not CompositionOfSegmentsIsFixed Then
		
		QueryText = NStr("vi = 'Ấn định thành phần?';
						|ru = 'Зафиксировать состав?';
						|en = 'Do you want to record the document?'; fa = 'Do you want to record the document?';
						|it = 'Do you want to record the document?';
						|pl = 'Do you want to record the document?';
						|tr = 'İçerik sabitlensin mi?'");
		Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
		
		If Response = DialogReturnCode.Yes Then
			
			CallbackOnCompletion = New CallbackDescription("FixCompositionOfDocumentCompletion", ThisObject);
			NotificationOfOperationIsInProgress = New CallbackDescription(
				"OfOperationsArePerformedToFixCompositionOfDocument",
				ThisObject);
			
			CommonClientServer.SetFormItemProperty(
				Items,
				Items.DecorationFixComposition.Name,
				"Enabled",
				False);
			
			RebatesClient.FixCompositionOfConditionsDocument(
				Object.Ref,
				ThisObject,
				CallbackOnCompletion,
				NotificationOfOperationIsInProgress);
			
		EndIf;
		
	Else
		
		If ThereIsAdjustmentOnApproval Then
			
			MessageText = NStr("vi = 'Không thể ấn định thành phần chứng từ: đã nhập điều chỉnh trong trạng thái ""Cần thống nhất"".';
								|ru = 'Невозможно зафиксировать состав документа: введена корректировка в статусе ""На согласовании"".';
								|en = 'Cannot record the document: an adjustment is registered in the ""Pending approval"" status.'; fa = 'Cannot record the document: an adjustment is registered in the ""Pending approval"" status.';
								|it = 'Cannot record the document: an adjustment is registered in the ""Pending approval"" status.';
								|pl = 'Cannot record the document: an adjustment is registered in the ""Pending approval"" status.';
								|tr = 'Belge içeriği sabitlenemiyor: ""Onay bekliyor"" durumunda düzeltme yapıldı.'");
			CommonClient.MessageToUser(MessageText);
			
		EndIf;
		
		SetVisibilityOfCommandsFixingComposition(ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Async Procedure CancelFixingCompositionOfDocument()
	
	UpdateDataBeforeCancelingFixationOfComposition();
	If Not ThereAreAccruals
	   And CompositionOfSegmentsIsFixed Then
		
		QueryText = NStr("vi = 'Hủy ấn định thành phần?';
						|ru = 'Отменить фиксацию состава?';
						|en = 'Do you want to cancel recording?'; fa = 'Do you want to cancel recording?';
						|it = 'Do you want to cancel recording?';
						|pl = 'Do you want to cancel recording?';
						|tr = 'İçeriğin sabitlenmesi iptal edilsin mi?'");
		Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
		
		If Response = DialogReturnCode.Yes Then
			
			CallbackOnCompletion = New CallbackDescription("CancelFixingCompositionOfDocumentCompletion", ThisObject);
			NotificationOfOperationIsInProgress = New CallbackDescription(
				"OfOperationsArePerformedToFixCompositionOfDocument",
				ThisObject);
			
			CommonClientServer.SetFormItemProperty(
				Items,
				Items.DecorationIsToCancelFixationOfComposition.Name,
				"Enabled",
				False);
			
			RebatesClient.CancelFixingCompositionOfConditionsDocument(
				Object.Ref,
				ThisObject,
				CallbackOnCompletion,
				NotificationOfOperationIsInProgress);
			
		EndIf;
		
	Else
		
		SetVisibilityOfCommandsFixingComposition(ThisObject);
		
	EndIf;
	
EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure FixCompositionOfDocumentCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		If Result.Status = "Error" Then
			
			StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
			
		Else
			
			CompositionOfSegmentsIsFixed = True;
			
		EndIf;
		
	EndIf;
	
	UpdateDataBeforeFixingComposition();
	SetVisibilityOfCommandsFixingComposition(ThisObject);
	
EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure CancelFixingCompositionOfDocumentCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		If Result.Status = "Error" Then
			
			StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
			
		Else
			
			CompositionOfSegmentsIsFixed = False;
			
		EndIf;
		
	Else
		FillInAttributesOfCompositionAccordingToCondition();
	EndIf;
	
	SetVisibilityOfCommandsFixingComposition(ThisObject);
	
EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure OfOperationsArePerformedToFixCompositionOfDocument(Result, AdditionalParameters) Export
	
	MessageText = NStr("vi = 'Theo chứng từ này đã thực hiện thao tác ấn định thành phần. Hãy thử lại sau.';
						|ru = 'По данному документу уже выполняются операции по фиксации состава. Попробуйте позже.';
						|en = 'Recording operations for the document are already in process. Try again later.'; fa = 'Recording operations for the document are already in process. Try again later.';
						|it = 'Recording operations for the document are already in process. Try again later.';
						|pl = 'Recording operations for the document are already in process. Try again later.';
						|tr = 'İçerik sabitleme işlemleri bu belgede hâlihazırda gerçekleştirilmektedir. Daha sonra tekrar deneyin.'");
	
	CommonClient.MessageToUser(MessageText);
	SetVisibilityOfCommandsFixingComposition(ThisObject);
	
EndProcedure

// Parameters:
//  Result - CatalogRef.ProductSegments, Undefined -
//  AdditionalParameters - Undefined
//
&AtClient
Procedure FillInGoodsBySegmentCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		SelectedSegment = Result;
		FillInGoodsBySegmentServer(SelectedSegment);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInGoodsBySegmentServer(Val Segment)
	
	GenerationMethod = Common.ObjectAttributeValue(Segment, "GenerationMethod");
	If GenerationMethod <> Enums.SegmentGenerationMethods.GenerateDynamically Then
		
		SelectionOfProducts_ = StaticSegmentGoods(Segment);
		
	Else
		
		SelectionOfProducts_ = DynamicSegmentGoods(Segment);
		
	EndIf;
	
	While SelectionOfProducts_.Next() Do
		
		LineProducts_ = Object.Goods.Add();
		FillPropertyValues(LineProducts_, SelectionOfProducts_);
		
	EndDo;
	
	FillInServiceDetailsForProductRange();
	
EndProcedure

#EndRegion

#Region EventHandlersForGoodsAuxiliaryTableElements

&AtServer
Procedure ProductsQuantityPlanOnChangeServer(Val IDCurrentRow)
	
	RowOfGoods = Object.Goods.FindByID(IDCurrentRow);
	
	FieldsNames = "Products, Characteristic, ItemVariantsAreUsed";
	
	LinesToUpload = CommonClientServer.ValueInArray(RowOfGoods);
	Table_For_Processing = Object.Goods.Unload(LinesToUpload, FieldsNames);
	RebatesServer.UpdateGoodsRowRangesByTable(Object, Table_For_Processing);
	
EndProcedure

&AtServer
Procedure GoodsCanceledOnChangeServer(Val IDCurrentRow)
	
	RowOfGoods = Object.Goods.FindByID(IDCurrentRow);
	
	If RowOfGoods.Canceled Then
		
		RowOfGoods.ValidOnDate = Date(1, 1, 1);
		RowOfGoods.ValidTo = Date(1, 1, 1);
		RowOfGoods.RangeDesignation = "";
		
	ElsIf RebatesClientServer.ThisIsNumberByRanges(Object.CalculationScaleType, GoodsIndicator) Then
		
		RebatesServer.FillInUniformDataOfGoodsLineRange(Object, IDCurrentRow, True);
		
	EndIf;
	
	FieldsNames = "Products, Characteristic, ItemVariantsAreUsed";
	
	LinesToUpload = CommonClientServer.ValueInArray(RowOfGoods);
	Table_For_Processing = Object.Goods.Unload(LinesToUpload, FieldsNames);
	RebatesServer.UpdateGoodsRowRangesByTable(Object, Table_For_Processing);
	
EndProcedure

&AtServer
Procedure ProductsBasePriceOnChangeServer(Val IDCurrentRow)
	
	RowOfGoods = Object.Goods.FindByID(IDCurrentRow);
	
	FilterParameters = New Structure;
	FilterParameters.Insert("Products", RowOfGoods.Products);
	FilterParameters.Insert("Characteristic", RowOfGoods.Characteristic);
	FilterParameters.Insert("Canceled", False);
	
	RebatesServer.UpdateSelectionTableField(
		Object.Goods,
		FilterParameters,
		RowOfGoods.BasePrice,
		"BasePrice",
		True);
	
EndProcedure

&AtServer
Procedure ProductsStartOfActionOnChangeServer(Val IDCurrentRow)
	
	RowOfGoods = Object.Goods.FindByID(IDCurrentRow);
	
	FilterParameters = New Structure;
	FilterParameters.Insert("Products", RowOfGoods.Products);
	FilterParameters.Insert("Characteristic", RowOfGoods.Characteristic);
	FilterParameters.Insert("Canceled", False);
	
	RebatesServer.UpdateSelectionTableField(
		Object.Goods,
		FilterParameters,
		RowOfGoods.ValidOnDate,
		"ValidOnDate");
	
EndProcedure

&AtServer
Procedure ProductsExpirationDateOnChangeServer(Val IDCurrentRow)
	
	RowOfGoods = Object.Goods.FindByID(IDCurrentRow);
	
	FilterParameters = New Structure;
	FilterParameters.Insert("Products", RowOfGoods.Products);
	FilterParameters.Insert("Characteristic", RowOfGoods.Characteristic);
	FilterParameters.Insert("Canceled", False);
	
	RebatesServer.UpdateSelectionTableField(
		Object.Goods,
		FilterParameters,
		RowOfGoods.ValidTo,
		"ValidTo");
	
EndProcedure

// Parameters:
//  IDCurrentRow - Number - Current row id
//  AnalyticsOfCurrentProductLine - See RebatesClientServer.StructureOfSavedProductLine
//  AnalyticsOfGoodsLineBeingModified - See RebatesClientServer.StructureOfSavedProductLine
//  Cached_Values - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
&AtServer
Procedure GoodsProductsOnChangeServer(Val IDCurrentRow, AnalyticsOfCurrentProductLine, AnalyticsOfGoodsLineBeingModified, Cached_Values)
	
	RowOfGoods = Object.Goods.FindByID(IDCurrentRow);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", RowOfGoods.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	BatchProcessingOfTablePartServer.ProcessTSString(
		RowOfGoods,
		StructureOfActions,
		Cached_Values);
	
	FillParameters = RebatesClientServer.ParametersForFillingInAnalyticsOfRowBeingModified();
	FillParameters.CalculationScaleType = Object.CalculationScaleType;
	FillParameters.GoodsIndicator = GoodsIndicator;
	FillParameters.Products = RowOfGoods.Products;
	FillParameters.Characteristic = RowOfGoods.Characteristic;
	FillParameters.ItemVariantsAreUsed = RowOfGoods.ItemVariantsAreUsed;
	
	RebatesClientServer.SaveAnalyticsOfProductLine(
		AnalyticsOfGoodsLineBeingModified, FillParameters);
	
	If RebatesClientServer.ThisIsNumberByRanges(Object.CalculationScaleType, GoodsIndicator)
	   And Not AnalyticsOfGoodsLineBeingModified.Products.IsEmpty() Then
		
		RebatesServer.FillInUniformDataOfGoodsLineRange(Object, IDCurrentRow);
		UpdateGoodsRowRangesByGoods(AnalyticsOfCurrentProductLine);
		UpdateGoodsRowRangesByGoods(AnalyticsOfGoodsLineBeingModified);
		
	EndIf;
	
EndProcedure

// Parameters:
//  IDCurrentRow - Number - Current row id
//  AnalyticsOfCurrentProductLine - See RebatesClientServer.StructureOfSavedProductLine
//  AnalyticsOfGoodsLineBeingModified - See RebatesClientServer.StructureOfSavedProductLine
//
&AtServer
Procedure GoodsCharacteristicOnChangeServer(Val IDCurrentRow, AnalyticsOfCurrentProductLine, AnalyticsOfGoodsLineBeingModified)
	
	RowOfGoods = Object.Goods.FindByID(IDCurrentRow);
	
	FillParameters = RebatesClientServer.ParametersForFillingInAnalyticsOfRowBeingModified();
	FillParameters.CalculationScaleType = Object.CalculationScaleType;
	FillParameters.GoodsIndicator = GoodsIndicator;
	FillParameters.Products = RowOfGoods.Products;
	FillParameters.Characteristic = RowOfGoods.Characteristic;
	FillParameters.ItemVariantsAreUsed = RowOfGoods.ItemVariantsAreUsed;
	
	RebatesClientServer.SaveAnalyticsOfProductLine(
		AnalyticsOfGoodsLineBeingModified, FillParameters);
	
	If RebatesClientServer.ThisIsNumberByRanges(Object.CalculationScaleType, GoodsIndicator)
	   And Not AnalyticsOfGoodsLineBeingModified.Products.IsEmpty() Then
		
		RebatesServer.FillInUniformDataOfGoodsLineRange(Object, IDCurrentRow);
		UpdateGoodsRowRangesByGoods(AnalyticsOfCurrentProductLine);
		UpdateGoodsRowRangesByGoods(AnalyticsOfGoodsLineBeingModified);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForTableElementsItemPropertiesAuxiliary

&AtServer
Procedure ProductProperties_CountPlanOnChangeServer(Val IDCurrentRow)
	
	PropertyRow = Object.ProductProperties_.FindByID(IDCurrentRow);
	
	FieldsNames = "PropertyValue";
	
	LinesToUpload = CommonClientServer.ValueInArray(PropertyRow);
	Table_For_Processing = Object.ProductProperties_.Unload(LinesToUpload, FieldsNames);
	RebatesServer.UpdateRangesOfPropertyRowsByTable(Object, Table_For_Processing);
	
EndProcedure

&AtServer
Procedure ProductProperties_CanceledOnChangeServer(Val IDCurrentRow)
	
	PropertyRow = Object.ProductProperties_.FindByID(IDCurrentRow);
	
	If PropertyRow.Canceled Then
		
		PropertyRow.ValidOnDate = Date(1, 1, 1);
		PropertyRow.ValidTo = Date(1, 1, 1);
		PropertyRow.RangeDesignation = "";
		
	ElsIf RebatesClientServer.ThisIsNumberByRanges(Object.CalculationScaleType, GoodsIndicator) Then
		
		RebatesServer.FillInUnifiedDataOfPropertyRowRange(Object, IDCurrentRow, True);
		
	EndIf;
	
	FieldsNames = "PropertyValue";
	
	LinesToUpload = CommonClientServer.ValueInArray(PropertyRow);
	Table_For_Processing = Object.ProductProperties_.Unload(LinesToUpload, FieldsNames);
	RebatesServer.UpdateRangesOfPropertyRowsByTable(Object, Table_For_Processing);
	
EndProcedure

&AtServer
Procedure ProductProperties_BasePriceOnChangeServer(Val IDCurrentRow)
	
	PropertyRow = Object.ProductProperties_.FindByID(IDCurrentRow);
	
	FilterParameters = New Structure;
	FilterParameters.Insert("PropertyValue", PropertyRow.PropertyValue);
	FilterParameters.Insert("Canceled", False);
	
	RebatesServer.UpdateSelectionTableField(
		Object.ProductProperties_,
		FilterParameters,
		PropertyRow.BasePrice,
		"BasePrice");
	
EndProcedure

&AtServer
Procedure ProductProperties_ValidOnDateOnChangeServer(Val IDCurrentRow)
	
	PropertyRow = Object.ProductProperties_.FindByID(IDCurrentRow);
	
	FilterParameters = New Structure;
	FilterParameters.Insert("PropertyValue", PropertyRow.PropertyValue);
	FilterParameters.Insert("Canceled", False);
	
	RebatesServer.UpdateSelectionTableField(
		Object.ProductProperties_,
		FilterParameters,
		PropertyRow.ValidOnDate,
		"ValidOnDate");
		
EndProcedure

&AtServer
Procedure ProductProperties_ValidToOnChangeServer(Val IDCurrentRow)
	
	PropertyRow = Object.ProductProperties_.FindByID(IDCurrentRow);
	
	FilterParameters = New Structure;
	FilterParameters.Insert("PropertyValue", PropertyRow.PropertyValue);
	FilterParameters.Insert("Canceled", False);
	
	RebatesServer.UpdateSelectionTableField(
		Object.ProductProperties_,
		FilterParameters,
		PropertyRow.ValidTo,
		"ValidTo");
	
EndProcedure

// Parameters:
//  IDCurrentRow - Number - Current row id
//  CurrentValue - DefinedType.RebateItemPropertyTypes
//  VariableValue - DefinedType.RebateItemPropertyTypes
//
&AtServer
Procedure ProductProperties_PropertyValueOnChangeServer(Val IDCurrentRow, CurrentValue, VariableValue)
	
	PropertyRow = Object.ProductProperties_.FindByID(IDCurrentRow);
	
	VariableValue = PropertyRow.PropertyValue;
	
	If RebatesClientServer.ThisIsNumberByRanges(Object.CalculationScaleType, GoodsIndicator)
	   And VariableValue <> Undefined Then
		
		RebatesServer.FillInUnifiedDataOfPropertyRowRange(Object, IDCurrentRow);
		UpdatePropertyRowRangesByProperty(CurrentValue);
		UpdatePropertyRowRangesByProperty(VariableValue);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForTableElementsContractorsAuxiliary

&AtServer
Procedure CounterpartiesCounterpartyOnChangeServer(Val IDCurrentRow)
	
	StringOfParticipants = Object.Counterparties.FindByID(IDCurrentRow);
	
	If Object.AccrueImmediately
	   And PartyList = Enums.RebatesParticipants.Counterparties
	   And StringOfParticipants.Partner.IsEmpty() Then
		
		NewPartner = PartnerByCounterparty(StringOfParticipants.Counterparty);
		StringOfParticipants.Partner = NewPartner;
		
	EndIf;
	
	ShouldDetailCalculation = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	If Object.PartyCountDetails <> ShouldDetailCalculation.ByCounterpartyAndCustomer Then
		
		EstablishSignsOfCalculationOfParticipantsPlan();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CounterpartiesPartnerOnChangeServer(Val IDCurrentRow)
	
	StringOfParticipants = Object.Counterparties.FindByID(IDCurrentRow);
	
	If Object.AccrueImmediately
	   And PartyList = Enums.RebatesParticipants.Customers
	   And StringOfParticipants.Counterparty.IsEmpty() Then
		
		NewCounterparty = CounterpartyByPartner(StringOfParticipants.Partner);
		StringOfParticipants.Counterparty = NewCounterparty;
		
	EndIf;
	
	ShouldDetailCalculation = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	If Object.PartyCountDetails <> ShouldDetailCalculation.ByCounterpartyAndCustomer Then
		
		EstablishSignsOfCalculationOfParticipantsPlan();
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function PartnerByCounterparty(Val Counterparty)
	
	Partner = Common.ObjectAttributeValue(Counterparty, "Partner");
	
	Return Partner;
	
EndFunction

&AtServerNoContext
Function CounterpartyByPartner(Val Partner)
	
	Counterparty = Catalogs.Counterparties.EmptyRef();
	
	Selection = SelectionOfCounterparties(Partner);
	If Selection.Count() = 1 Then
		
		Selection.Next();
		Counterparty = Selection.Ref;
		
	EndIf;
	
	Return Counterparty;
	
EndFunction

// Parameters:
//  Partner - CatalogRef.Partners - Partner
// 
// Returns:
//  QueryResultSelection:
//	* Ref - CatalogRef.Counterparties
//
&AtServerNoContext
Function SelectionOfCounterparties(Val Partner)
	
	Query = New	Query;
	QueryText =
	"SELECT ALLOWED TOP 2
	|	Counterparties.Ref AS Ref
	|FROM
	|	Catalog.Counterparties AS Counterparties
	|WHERE
	|	Counterparties.Partner = &Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED TOP 2
	|	ISNULL(Counterparties.Ref, VALUE(Catalog.Counterparties.EmptyRef)) AS Ref
	|FROM
	|	Catalog.Counterparties AS Counterparties
	|		LEFT JOIN Catalog.Partners AS Partners
	|		ON Counterparties.Partner = Partners.Parent
	|WHERE
	|	Partners.Ref = &Partner
	|	AND Partners.Parent <> VALUE(Catalog.Partners.EmptyRef)";
	Query.Text = QueryText;
	Query.SetParameter("Partner", Partner);
	
	Result = Query.ExecuteBatch();
	PartnerResults = Result[0];
	ResultForPartnerSParent = Result[1];
	
	If PartnerResults.IsEmpty() Then
		Return ResultForPartnerSParent.Select();
	Else
		Return PartnerResults.Select();
	EndIf;
	
EndFunction

// Parameters:
//  Result - CatalogRef.PartnersSegments, Undefined -
//  AdditionalParameters - Undefined
//
&AtClient
Procedure FillInParticipantsBySegmentCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		SelectedSegment = Result;
		FillInParticipantsBySegmentServer(SelectedSegment);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInParticipantsBySegmentServer(Val Segment)
	
	GenerationMethod = Common.ObjectAttributeValue(Segment, "GenerationMethod");
	If GenerationMethod <> Enums.SegmentGenerationMethods.GenerateDynamically Then
		
		SelectionOfPartners = StaticSegmentPartners(Segment);
		
	Else
		
		SelectionOfPartners = DynamicSegmentPartners(Segment);
		
	EndIf;
	
	While SelectionOfPartners.Next() Do
		
		ContractorsLine = Object.Counterparties.Add();
		FillPropertyValues(ContractorsLine, SelectionOfPartners);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region EventHandlersForTableElementsContractsAgreementsAuxiliary

&AtServer
Procedure ContractsAgreementsCounterpartyOnChangeServer(Val IDCurrentRow)
	
	StringOfParticipants = Object.ContractsTermsOfSales.FindByID(IDCurrentRow);
	
	If PartyList = PredefinedValue("Enum.RebatesParticipants.Contracts") Then
		
		CurContract = StringOfParticipants.Contract;
		FillInClearContract(StringOfParticipants);
		If CurContract <> StringOfParticipants.Contract Then
			
			ContractsAgreementsContractOnChangeServer(IDCurrentRow);
			
		EndIf;
		EstablishSignsOfCalculationOfParticipantsPlan(StringOfParticipants.Counterparty);
		
	ElsIf PartyList = PredefinedValue("Enum.RebatesParticipants.Terms1") Then
		
		CurrentAgreement = StringOfParticipants.Terms;
		FillInClearAgreement(StringOfParticipants);
		
		If CurrentAgreement <> StringOfParticipants.Terms Then
			
			ContractsAgreementsAgreementWhenServerChangesProcessString(IDCurrentRow);
			
		EndIf;
		EstablishSignsOfCalculationOfParticipantsPlan(StringOfParticipants.Counterparty);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ContractsPartnerAgreementsOnChangeServer(Val IDCurrentRow)
	
	StringOfParticipants = Object.ContractsTermsOfSales.FindByID(IDCurrentRow);
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(
		StringOfParticipants.Partner, StringOfParticipants.Counterparty);
	
	If PartyList = PredefinedValue("Enum.RebatesParticipants.Contracts") Then
		
		CurContract = StringOfParticipants.Contract;
		FillInClearContract(StringOfParticipants);
		If CurContract <> StringOfParticipants.Contract Then
			
			ContractsAgreementsContractOnChangeServer(IDCurrentRow);
			
		EndIf;
		EstablishSignsOfCalculationOfParticipantsPlan(StringOfParticipants.Counterparty);
		
	ElsIf PartyList = PredefinedValue("Enum.RebatesParticipants.Terms1") Then
		
		CurrentAgreement = StringOfParticipants.Terms;
		FillInClearAgreement(StringOfParticipants);
		
		If CurrentAgreement <> StringOfParticipants.Terms Then
			
			ContractsAgreementsAgreementWhenServerChangesProcessString(IDCurrentRow);
			
		EndIf;
		EstablishSignsOfCalculationOfParticipantsPlan(StringOfParticipants.Counterparty);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInClearContract(StringOfParticipants, OnlyValidOnes = True)
	
	If StringOfParticipants.Counterparty.IsEmpty()
	 Or StringOfParticipants.Partner.IsEmpty() Then
		
		StringOfParticipants.Contract = Catalogs.CounterpartyContracts.EmptyRef();
		Return;
		
	EndIf;
	
	Selection = RequestForAnalyticsContract(StringOfParticipants, OnlyValidOnes);
	If Selection.Count() = 0 Then
		
		StringOfParticipants.Contract = Catalogs.CounterpartyContracts.EmptyRef();
		
	ElsIf Selection.Count() = 1 Then
		
		Selection.Next();
		StringOfParticipants.Contract = Selection.Contract;
		
	ElsIf Selection.Count() > 2 Then
		
		StringOfParticipants.Contract = Catalogs.CounterpartyContracts.EmptyRef();
		
	Else
		
		NewContract = Catalogs.CounterpartyContracts.EmptyRef();
		NumberOfSimilar = 0;
		While Selection.Next() Do
			
			If Selection.Priority = 1 Then
				
				NewContract = Selection.Contract;
				Break;
				
			Else
				
				NumberOfSimilar = NumberOfSimilar + 1;
				NewContract = Selection.Contract;
				
			EndIf;
			
		EndDo;
		
		If NumberOfSimilar > 1 Then
			StringOfParticipants.Contract = Catalogs.CounterpartyContracts.EmptyRef();
		Else
			StringOfParticipants.Contract = NewContract;
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
//  StringOfParticipants - FormDataCollectionItem: See Document.ConditionsOfCustomerRebates.Form.DocumentForm.Items.ContractsTermsOfSales - A String of Participants
//  OnlyValidOnes - Boolean - select only valid Contracts
// 
// Returns:
//  QueryResultSelection:
//  * Priority - Number
//  * Contract - CatalogRef.CounterpartyContracts
//
&AtServer
Function RequestForAnalyticsContract(Val StringOfParticipants, OnlyValidOnes)
	
	Query = New Query;
	QueryText =
	"SELECT
	|	Data.Priority,
	|	Data.Contract
	|FROM
	|	(SELECT
	|		1 AS Priority,
	|		Contracts.Ref AS Contract
	|	FROM
	|		Catalog.CounterpartyContracts AS Contracts
	|	WHERE
	|		Contracts.Organization = &Organization
	|		AND Contracts.Counterparty = &Counterparty
	|		AND Contracts.Partner = &Partner
	|		AND NOT Contracts.DeletionMark
	|		AND Contracts.ContractType = VALUE(Enum.ContractTypes.WithCustomer)
	|		AND Contracts.Ref = &Contract
	|
	|	UNION ALL
	|
	|	SELECT TOP 2
	|		2 AS Priority,
	|		Contracts.Ref AS Contract
	|	FROM
	|		Catalog.CounterpartyContracts AS Contracts
	|	WHERE
	|		Contracts.Organization = &Organization
	|		AND Contracts.Counterparty = &Counterparty
	|		AND Contracts.Partner = &Partner
	|		AND NOT Contracts.DeletionMark
	|		AND Contracts.ContractType = VALUE(Enum.ContractTypes.WithCustomer)
	|		AND &OnlyValidOnes
	|		AND Contracts.Ref <> &Contract) AS Data
	|
	|ORDER BY
	|	Data.Priority";
	
	If OnlyValidOnes Then
		
		QueryText = StrReplace(
			QueryText,
			"&OnlyValidOnes",
			"Contracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)");
		
	Else
		
		QueryText = StrReplace(
			QueryText,
			"&OnlyValidOnes",
			"TRUE");
		
	EndIf;
	
	Query.Text = QueryText;
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Counterparty", StringOfParticipants.Counterparty);
	Query.SetParameter("Partner", StringOfParticipants.Partner);
	Query.SetParameter("Contract", StringOfParticipants.Contract);
	
	Return Query.Execute().Select();
	
EndFunction

&AtServer
Procedure FillInClearAgreement(StringOfParticipants, OnlyValidOnes = True)
	
	If StringOfParticipants.Partner.IsEmpty() Then
		
		StringOfParticipants.Terms = Catalogs.TermsOfSale.EmptyRef();
		Return;
		
	EndIf;
	
	Selection = RequestForAnalyticsAgreement(StringOfParticipants);
	If Selection.Count() = 0 Then
		
		StringOfParticipants.Terms = Catalogs.TermsOfSale.EmptyRef();
		
	ElsIf Selection.Count() = 1 Then
		
		Selection.Next();
		StringOfParticipants.Terms = Selection.Terms;
		StringOfParticipants.Counterparty = Selection.Counterparty;
		
	ElsIf Selection.Count() > 2 Then
		
		StringOfParticipants.Terms = Catalogs.TermsOfSale.EmptyRef();
		
	Else
		
		NewAgreement = Catalogs.TermsOfSale.EmptyRef();
		NumberOfSimilar = 0;
		While Selection.Next() Do
			
			If Selection.Priority = 1 Then
				
				NewAgreement = Selection.Terms;
				Break;
				
			Else
				
				NumberOfSimilar = NumberOfSimilar + 1;
				NewAgreement = Selection.Terms;
				Counterparty = Selection.Counterparty;
				
			EndIf;
			
		EndDo;
		
		If NumberOfSimilar > 1 Then
			
			StringOfParticipants.Terms = Catalogs.TermsOfSale.EmptyRef();
			
		Else
			
			StringOfParticipants.Terms = NewAgreement;
			StringOfParticipants.Counterparty = Counterparty;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
//  StringOfParticipants - FormDataCollectionItem: See Document.ConditionsOfCustomerRebates.Form.DocumentForm.Items.ContractsTermsOfSales - A String of Participants
// 
// Returns:
//  QueryResultSelection:
//  * Priority - Number -
//  * Terms - CatalogRef.TermsOfSale -
//  * Counterparty - CatalogRef.Counterparties - counterparty by agreement 
//
&AtServer
Function RequestForAnalyticsAgreement(Val StringOfParticipants)
	
	Query = New Query;
	QueryText =
	"SELECT
	|	Data.Priority AS Priority,
	|	Data.Terms AS Terms,
	|	Data.Terms.Counterparty AS Counterparty
	|FROM
	|	(SELECT
	|		1 AS Priority,
	|		Terms1.Ref AS Terms
	|	FROM
	|		Catalog.TermsOfSale AS Terms1
	|	WHERE
	|		Terms1.Organization IN (&Companies)
	|		AND Terms1.Counterparty = &Counterparty
	|		AND Terms1.Partner = &Partner
	|		AND NOT Terms1.DeletionMark
	|		AND NOT Terms1.Standard_
	|		AND Terms1.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|		AND Terms1.Ref = &Terms
	|
	|	UNION ALL
	|
	|	SELECT TOP 2
	|		2 AS Priority,
	|		Terms1.Ref AS Terms
	|	FROM
	|		Catalog.TermsOfSale AS Terms1
	|	WHERE
	|		Terms1.Organization IN (&Companies)
	|		AND Terms1.Counterparty IN (&Counterparties)
	|		AND Terms1.Partner IN (&Partners)
	|		AND Terms1.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
	|		AND NOT Terms1.DeletionMark
	|		AND NOT Terms1.Standard_
	|		AND Terms1.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|		AND Terms1.Ref <> &Terms) AS Data
	|
	|ORDER BY
	|	Data.Priority";
	
	Query.Text = QueryText;
	
	Companies = CommonClientServer.ValueInArray(Object.Organization); // Array of CatalogRef.Companies
	Companies.Add(Catalogs.Companies.EmptyRef());
	
	Counterparties = CommonClientServer.ValueInArray(StringOfParticipants.Counterparty); // Array of CatalogRef.Counterparties
	Counterparties.Add(Catalogs.Counterparties.EmptyRef());
	
	Partners = CommonClientServer.ValueInArray(StringOfParticipants.Partner); // Array of CatalogRef.Partners
	Partners.Add(Catalogs.Partners.EmptyRef());
	
	Query.SetParameter("Companies", Companies);
	Query.SetParameter("Counterparties", Counterparties);
	Query.SetParameter("Counterparty", StringOfParticipants.Counterparty);
	Query.SetParameter("Partners", Partners);
	Query.SetParameter("Partner", StringOfParticipants.Partner);
	Query.SetParameter("Terms", StringOfParticipants.Terms);
	
	Return Query.Execute().Select();
	
EndFunction

&AtServer	
Procedure ContractsAgreementsContractOnChangeServer(Val IDCurrentRow)
	
	StringOfParticipants = Object.ContractsTermsOfSales.FindByID(IDCurrentRow);
	
	If StringOfParticipants.Counterparty.IsEmpty()
	 Or StringOfParticipants.Partner.IsEmpty() Then
		
		ContractDetails_ = Common.ObjectAttributesValues(
			StringOfParticipants.Contract, "Counterparty, Partner");
		StringOfParticipants.Counterparty = ContractDetails_.Counterparty;
		StringOfParticipants.Partner = ContractDetails_.Partner;
		
	EndIf;
	
	EstablishSignsOfCalculationOfParticipantsPlan(StringOfParticipants.Counterparty);
	
EndProcedure

&AtServer
Procedure ContractsAgreementsAgreementOnChangeServer(Val IDCurrentRow)
	
	ContractsAgreementsAgreementWhenServerChangesProcessString(IDCurrentRow);
	
	StringOfParticipants = Object.ContractsTermsOfSales.FindByID(IDCurrentRow);
	
	If StringOfParticipants.ThisIsModelAgreement Then
		
		StringOfParticipants.Partner = Catalogs.Partners.EmptyRef();
		StringOfParticipants.Counterparty = Catalogs.Counterparties.EmptyRef();
		
	Else
		
		// Updating these lines by agreement (the counterparty may not be specified)
		
		ContractDetails_ = Common.ObjectAttributesValues(
			StringOfParticipants.Terms, "Counterparty, Partner");
		StringOfParticipants.Counterparty = ContractDetails_.Counterparty;
		StringOfParticipants.Partner = ContractDetails_.Partner;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ContractsAgreementsAgreementWhenServerChangesProcessString(Val IDCurrentRow)
	
	StringOfParticipants = Object.ContractsTermsOfSales.FindByID(IDCurrentRow);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInAgreementAttributeInTSLine", "Terms");
	
	CacheOfValues = Undefined;
	BatchProcessingOfTablePartServer.ProcessTSString(
		StringOfParticipants,
		StructureOfActions,
		CacheOfValues,
		Object.ContractsTermsOfSales);
	
EndProcedure

#EndRegion

#Region FormItemsManagement

&AtClient
Procedure ConfigureDependentFormElements(ChangedProps = "")
	
	CashClientServer.CustomizeFormElements(ThisObject, ChangedProps, FormAttributes(ThisObject));
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedProps = "")
	
	CashClientServer.CustomizeFormElements(ThisObject, ChangedProps, FormAttributes(ThisObject));
	
EndProcedure

&AtClientAtServerNoContext
Function FormAttributes(Form)
	
	FormAttributes = New Structure;
	FormAttributes.Insert("GoodsIndicator");
	FormAttributes.Insert("SalesCalculationBase");
	FormAttributes.Insert("ContentOfGoods");
	FormAttributes.Insert("PartyList");
	FormAttributes.Insert("ThereAreAccruals");
	FormAttributes.Insert("UseIndividualAgreements");
	FormAttributes.Insert("UseStandardAndIndividualTermsOfSalesWithCustomers");
	
	FillPropertyValues(FormAttributes, Form);
	
	Return FormAttributes;
	
EndFunction

&AtServer
Procedure SetUnchangedFieldSettingsByType()
	
	// Composition of the product selection list
	NewParameters = RebatesClientServer.NewParametersForAvailableGoodsSelections();
	NewParameters.WithoutCalculation = Object.WithoutCalculation;
	NewParameters.GoodsIndicator = GoodsIndicator;
	NewParameters.BaseOfCalculation = SalesCalculationBase;
	NewParameters.ContentOfGoods = ContentOfGoods;
	
	ChoiceArray = RebatesClientServer.AvailableListSelectionOfGoods(NewParameters);
	Items.FilterOfProducts_.ChoiceList.LoadValues(ChoiceArray);
	RebatesClientServer.CheckSetValueOfSelectionList(Object, "FilterOfProducts_", ChoiceArray);
	
	// Composition of the list of selection of participants
	NewParameters = RebatesClientServer.NewParametersOfAvailableSelectionsOfParticipants();
	NewParameters.WithoutCalculation = Object.WithoutCalculation;
	NewParameters.PartyList = PartyList;
	
	ChoiceArray = RebatesClientServer.AvailableListOfSelectionOfParticipants(NewParameters);
	Items.FilterParties.ChoiceList.LoadValues(ChoiceArray);
	RebatesClientServer.CheckSetValueOfSelectionList(Object, "FilterParties", ChoiceArray);
	
	// Setting visibility and only viewing fields
	ElementNamesVisibilityOfAll = New Array; // Array of String
	ElementNamesVisibilityOfAll.Add("Counterparties.AmountBonus");
	ElementNamesVisibilityOfAll.Add("AccrueImmediately");
	
	NamesOfVisibleElements = New Array; // Array of String
	ChoiceParameterLinks = New Array(); // Array of ChoiceParameterLink
	
	If PartyList = Enums.RebatesParticipants.Counterparties Then
		
		Items.Move(
			Items.CounterpartiesCounterparty,
			Items.Counterparties,
			Items.CounterpartiesPartner);
		
	ElsIf PartyList = Enums.RebatesParticipants.Customers Then
		
		Items.Move(
			Items.CounterpartiesPartner,
			Items.Counterparties,
			Items.CounterpartiesCounterparty);
		
		NewLink = New ChoiceParameterLink("Filter.Partner", "Items.Counterparties.CurrentData.Partner");
		ChoiceParameterLinks.Add(NewLink);
		
	EndIf;
	
	Items.CounterpartiesCounterparty.ChoiceParameterLinks = New FixedArray(ChoiceParameterLinks);
	
	If Object.WithoutCalculation Then
		
		CurrencyHeader_3 =  NStr("vi = 'Tiền tệ
								|thưởng lũy kế';
								|ru = 'Валюта
								|начисляемого бонуса';
								|en = 'Currency of the rebate
								|to accrue'; fa = 'Currency of the rebate
								|to accrue';
								|it = 'Валюта
								|начисляемого бонуса';
								|pl = 'Currency of the rebate
								|to accrue';
								|tr = 'Tahakkuk edilen bonusun
								|para birimi'");
		
		NamesOfVisibleElements.Add("AccrueImmediately");
		NamesOfVisibleElements.Add("Counterparties.AmountBonus");
		
	ElsIf SalesCalculationBase = Enums.RebateCalculationBases.RevenueBasePrices Then
		
		CurrencyHeader_3 = NStr("vi = 'Tiền tệ
							   |đơn giá cơ bản';
							   |ru = 'Валюта
							   |базовых цен';
							   |en = 'Base
							   |price currency'; fa = 'Base
							   |price currency';
							   |it = 'Валюта
							   |базовых цен';
							   |pl = 'Base
							   |price currency';
							   |tr = 'Baz alınan fiyat
							   |para birimi'");
		
	Else
		
		CurrencyHeader_3 = NStr("vi = 'Tiền tệ';
								|ru = 'Валюта';
								|en = 'Currency'; fa = 'ارز';
								|it = 'Валюта';
								|pl = 'Currency';
								|tr = 'Para birimi'");
		
	EndIf;
	
	Items.Currency.Title = CurrencyHeader_3;
	TMCommonUseClientServer.SetVisibilityOfElementsByArray(
		Items, ElementNamesVisibilityOfAll, NamesOfVisibleElements);
	
EndProcedure

&AtServer
Procedure SetParticipantInformationSettings()
	
	FieldTitle = "";
	If PartyList = Enums.RebatesParticipants.Counterparties Then
		
		FieldTitle = NStr("vi = 'Đối tác';
							|ru = 'Контрагенты';
							|en = 'Counterparties'; fa = 'طرف‌حساب‌ها';
							|it = 'Контрагенты';
							|pl = 'Counterparties';
							|tr = 'Cari hesaplar'");
		
	ElsIf PartyList = Enums.RebatesParticipants.Customers Then
		
		FieldTitle = NStr("vi = 'Khách hàng';
							|ru = 'Клиенты';
							|en = 'Customers'; fa = 'مشتریان';
							|it = 'Клиенты';
							|pl = 'Customers';
							|tr = 'Müşteriler'");
		
	ElsIf PartyList = Enums.RebatesParticipants.TIN Then 
		
		FieldTitle = NStr("vi = 'MST';
							|ru = 'ИНН';
							|en = 'TIN'; fa = 'شناسه مالیاتی';
							|it = 'ИНН';
							|pl = 'TIN';
							|tr = 'VKN'");
		
	ElsIf PartyList = Enums.RebatesParticipants.PartnersSegments Then
		
		FieldTitle = NStr("vi = 'Phân khúc
							 |khách hàng';
							 |ru = 'Сегменты
							 |клиентов';
							 |en = 'Customer
							 |segments'; fa = 'Customer
							 |segments';
							 |it = 'Сегменты
							 |клиентов';
							 |pl = 'Customer
							 |segments';
							 |tr = 'Müşteri
							 |segmentleri'");
	
	ElsIf PartyList = Enums.RebatesParticipants.Contracts Then
		
		FieldTitle = NStr("vi = 'Hợp đồng';
							|ru = 'Договоры';
							|en = 'Contracts'; fa = 'قراردادها';
							|it = 'Договоры';
							|pl = 'Contracts';
							|tr = 'Sözleşmeler'");
		
	ElsIf PartyList = Enums.RebatesParticipants.Terms1 Then
		
		FieldTitle = NStr("vi = 'Thỏa thuận';
							|ru = 'Соглашения';
							|en = 'Terms of sales'; fa = 'شرایط فروش';
							|it = 'Соглашения';
							|pl = 'Terms of sales';
							|tr = 'Anlaşmalar'");
		
	Else
		
		FieldTitle = NStr("vi = 'Người tham gia';
							|ru = 'Участники';
							|en = 'Participants'; fa = 'شرکت‌کنندگان';
							|it = 'Участники';
							|pl = 'Participants';
							|tr = 'Üyeler'");
		
	EndIf;
	
	CommonClientServer.SetFormItemProperty(
		Items, Items.FilterParties.Name, "Title", FieldTitle);
	
	SetCounterpartyTINPageSettings();
	SetMembersPageSettings();
	SetPartnerSegmentsPageSettings();
	SetSettingOfContractsAgreementsPage();
	
EndProcedure

&AtServer
Procedure SetMembersPageSettings()
	
	If PartyList <> Enums.RebatesParticipants.Counterparties
	   And PartyList <> Enums.RebatesParticipants.Customers Then
		Return;
	EndIf;
	
	PageHeader = RebatesClientServer.PageTitleBySettings(PartyList, Object.FilterParties);
	CommonClientServer.SetFormItemProperty(
		Items, Items.ParticipantsPage.Name, "Title", PageHeader);
	
EndProcedure

&AtServer
Procedure SetCounterpartyTINPageSettings()
	
	If PartyList <> Enums.RebatesParticipants.TIN Then
		Return;
	EndIf;
	
	PageHeader = RebatesClientServer.PageTitleBySettings(PartyList, Object.FilterParties);
	CommonClientServer.SetFormItemProperty(
		Items, Items.CounterpartyTINPage.Name, "Title", PageHeader);
	
EndProcedure

&AtServer
Procedure SetPartnerSegmentsPageSettings()
	
	If PartyList <> Enums.RebatesParticipants.PartnersSegments Then
		Return;
	EndIf;
	
	PageHeader = RebatesClientServer.PageTitleBySettings(PartyList, Object.FilterParties);
	CommonClientServer.SetFormItemProperty(
		Items, Items.PartnerSegmentsPage.Name, "Title", PageHeader);
	
EndProcedure

&AtServer
Procedure SetSettingOfContractsAgreementsPage()
	
	PageVisibility = False;
	
	If PartyList = Enums.RebatesParticipants.Contracts Then
		
		PageHeader = NStr("vi = 'Hợp đồng đã chọn';
							|ru = 'Выбранные договоры';
							|en = 'Selected contracts'; fa = 'Selected contracts';
							|it = 'Выбранные договоры';
							|pl = 'Selected contracts';
							|tr = 'Seçili sözleşmeler'");
		PageVisibility = True;
		
	ElsIf PartyList = Enums.RebatesParticipants.Terms1 Then
		
		PageHeader = NStr("vi = 'Thỏa thuận đã chọn';
							|ru = 'Выбранные соглашения';
							|en = 'Selected terms of sales'; fa = 'Selected terms of sales';
							|it = 'Выбранные соглашения';
							|pl = 'Selected terms of sales';
							|tr = 'Seçili anlaşmalar'");
		PageVisibility = True;
		
	EndIf;
	
	If PageVisibility Then
		
		CommonClientServer.SetFormItemProperty(
			Items, Items.ContractAgreementsPage.Name, "Title", PageHeader);
		
	EndIf;
	
	CommonClientServer.SetFormItemProperty(
		Items, Items.ContractAgreementsPage.Name, "Visible", PageVisibility);
	
EndProcedure

&AtServer
Procedure SetGoodsDetailsSettings()
	
	If ContentOfGoods = Enums.RebatesItems.ProductItemProperty Then
		
		Items.FilterOfProducts_.TitleLocation = FormItemTitleLocation.None;
		Items.FilterOfProducts_.MaxWidth = 12;
		Items.FilterOfProducts_.Width = 9;
		
	Else
		
		Items.FilterOfProducts_.TitleLocation = FormItemTitleLocation.Auto;
		Items.FilterOfProducts_.MaxWidth = 29;
		Items.FilterOfProducts_.Width = 0;
		
	EndIf;
	
	FieldTitle = "";
	If ContentOfGoods = Enums.RebatesItems.ProductSegments Then
		
		FieldTitle = NStr("vi = 'Phân khúc
							 |mặt hàng';
							 |ru = 'Сегменты
							 |товаров';
							 |en = 'Goods
							 |segments'; fa = 'Goods
							 |segments';
							 |it = 'Сегменты
							 |товаров';
							 |pl = 'Goods
							 |segments';
							 |tr = 'Ürün
							 |segmentleri'");
		
	Else
		
		FieldTitle = NStr("vi = 'Hàng hóa';
							|ru = 'Товары';
							|en = 'Goods'; fa = 'کالاها';
							|it = 'Товары';
							|pl = 'Goods';
							|tr = 'Ürünler'");
		
	EndIf;
	CommonClientServer.SetFormItemProperty(
		Items, Items.FilterOfProducts_.Name, "Title", FieldTitle);
	
	If ContentOfGoods =  Enums.RebatesItems.Products Then
		
		PageHeader = RebatesClientServer.PageTitleBySettings(ContentOfGoods, Object.FilterOfProducts_);
		CommonClientServer.SetFormItemProperty(
			Items, Items.GoodsPage.Name, "Title", PageHeader);
		
	ElsIf ContentOfGoods =  Enums.RebatesItems.ProductItemProperty Then
		
		PageHeader = RebatesClientServer.PageTitleBySettings(ContentOfGoods, Object.FilterOfProducts_);
		CommonClientServer.SetFormItemProperty(
			Items, Items.ItemPropertiesPage.Name, "Title", PageHeader);
		CommonClientServer.SetFormItemProperty(
			Items, Items.ProductProperties_PropertyValue.Name, "Title", ProductItemPropertyPresentation);
		
	ElsIf ContentOfGoods =  Enums.RebatesItems.ProductSegments Then
		
		PageHeader = RebatesClientServer.PageTitleBySettings(ContentOfGoods, Object.FilterOfProducts_);
		CommonClientServer.SetFormItemProperty(
			Items, Items.GoodsSegmentsPage.Name, "Title", PageHeader);
		
	EndIf;
	
EndProcedure

&AtServer
Function HeaderOfCounterpartyUploadForm()
	
	FormCaption = "";
	
	If PartyList = Enums.RebatesParticipants.Counterparties Then
		FormCaption = NStr("vi = 'Kết nhập đối tác từ tệp';
							|ru = 'Загрузка контрагентов из файла';
							|en = 'Import counterparties from file'; fa = 'Import counterparties from file';
							|it = 'Загрузка контрагентов из файла';
							|pl = 'Import counterparties from file';
							|tr = 'Dosyadan cari hesapları yükleme'");
	ElsIf PartyList = Enums.RebatesParticipants.Customers Then
		FormCaption = NStr("vi = 'Kết nhập khách hàng từ tệp';
							|ru = 'Загрузка клиентов из файла';
							|en = 'Import customers from file'; fa = 'Import customers from file';
							|it = 'Загрузка клиентов из файла';
							|pl = 'Import customers from file';
							|tr = 'Dosyadan müşteri yükleme'");
	EndIf;
	
	Return FormCaption;
	
EndFunction

#EndRegion

#Region DownloadingFromFiles

// Parameters:
//  ImportedDataAddress - String
//  AdditionalParameters - Structure
//
&AtClient
Procedure GoodsImportFromExternalFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ValueIsFilled(ImportedDataAddress) Then
		
		ClearMessages();
		GetUploadedProductsFromStorage(ImportedDataAddress);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(Val GoodsAddressInStorage)

	ItemsFromStorage = GetFromTempStorage(GoodsAddressInStorage);
	
	For Each RowOfGoods In ItemsFromStorage Do
		
		StringTSGoods = Object.Goods.Add();
		FillPropertyValues(StringTSGoods, RowOfGoods);
		
	EndDo;
	
	DeleteFromTempStorage(GoodsAddressInStorage);
	
EndProcedure

// Parameters:
//  ImportedDataAddress - String
//  AdditionalParameters - Structure
//
&AtClient
Procedure PartnerSegmentsCanBeDownloadedFromExternalFileEnd(ImportedDataAddress, AdditionalParameters) Export
	
	If ValueIsFilled(ImportedDataAddress) Then
		
		ClearMessages();
		GetUploadedPartnerSegmentsFromStorage(ImportedDataAddress);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure GetUploadedPartnerSegmentsFromStorage(Val GoodsAddressInStorage)

	SegmentsFromStorage = GetFromTempStorage(GoodsAddressInStorage);
	
	For Each StringOfSegments In SegmentsFromStorage Do
		TSLineSegmentsOfPartners = Object.PartnersSegments.Add();
		FillPropertyValues(TSLineSegmentsOfPartners, StringOfSegments);
	EndDo;
	
EndProcedure

&AtServer
Function DescriptionOfColumnsInTemplateCounterparties(FieldDisplaySettings)
	
	ColumnsNames = New Array; // Array of String
	If FieldDisplaySettings.SumPlan Then
		ColumnsNames.Add("SumPlan");
	EndIf;
	
	If FieldDisplaySettings.AmountBonus Then
		ColumnsNames.Add("AmountBonus");
	EndIf;
	
	If FieldDisplaySettings.Period Then
		
		ColumnsNames.Add("ValidOnDate");
		ColumnsNames.Add("ValidTo");
		
	EndIf;
	
	Columns = StrConcat(ColumnsNames, ",");
	
	TemplateColumns = ImportDataFromFile.GenerateColumnDetails(Object.Counterparties, Columns);
	
	ColumnNumber = 0;
	
	If PartyList = Enums.RebatesParticipants.Customers Then
		
		AddPartnerFieldsToCounterpartyUploadTemplate(FieldDisplaySettings, TemplateColumns, ColumnNumber);
		AddCounterpartyFieldsToCounterpartyUploadTemplate(FieldDisplaySettings, TemplateColumns, ColumnNumber);
		
	ElsIf PartyList = Enums.RebatesParticipants.Counterparties Then
		
		AddCounterpartyFieldsToCounterpartyUploadTemplate(FieldDisplaySettings, TemplateColumns, ColumnNumber);
		AddPartnerFieldsToCounterpartyUploadTemplate(FieldDisplaySettings, TemplateColumns, ColumnNumber);
		
	EndIf;
	
	HintAmount = NStr("vi = 'Hỗ trợ số 0 ở đầu, dấu chia cách phần nguyên và thập phân "","" và "".""';
						|ru = 'Поддерживаются лидирующие нули, а также разделители целой и дробной части "","" и "".""';
						|en = 'Leading zeros, integer and fraction dividers, "","", and ""."" are supported'; fa = 'Leading zeros, integer and fraction dividers, "","", and ""."" are supported';
						|it = 'Поддерживаются лидирующие нули, а также разделители целой и дробной части "","" и "".""';
						|pl = 'Leading zeros, integer and fraction dividers, "","", and ""."" are supported';
						|tr = 'Öndeki sıfırlara ilaveten tam sayı ve kesirli ayırıcılar olan “,” ve “.” desteklenir'");
	If FieldDisplaySettings.SumPlan Then
		
		ColumnNumber = ColumnNumber + 1;
		Column = ImportDataFromFileClientServer.TemplateColumn("SumPlan", TemplateColumns);
		Column.Position = ColumnNumber;
		Column.Title = NStr("vi = 'Số tiền, dự tính';
							|ru = 'Сумма, план';
							|en = 'Amount, plan'; fa = 'مبلغ، برنامه';
							|it = 'Сумма, план';
							|pl = 'Amount, plan';
							|tr = 'Tutar, plan'");
		Column.ToolTip = HintAmount;
		
	EndIf;
	
	If FieldDisplaySettings.AmountBonus Then
		
		ColumnNumber = ColumnNumber + 1;
		Column = ImportDataFromFileClientServer.TemplateColumn("AmountBonus", TemplateColumns);
		Column.Position = ColumnNumber;
		Column.Title = NStr("vi = 'Số tiền, thưởng';
							|ru = 'Сумма, бонус';
							|en = 'Amount, rebate'; fa = 'مبلغ، تخفیف برگشتی';
							|it = 'Сумма, бонус';
							|pl = 'Amount, rebate';
							|tr = 'Tutar, bonus'");
		Column.ToolTip = HintAmount;
		
	EndIf;
	
	If FieldDisplaySettings.Period Then
		
		DateHint = NStr("vi = 'Hỗ trợ định dạng ""DD.MM.YYYY"" hoặc ""DD/MM/YY""';
						|ru = 'Поддерживается формат в виде ""ДД.ММ.ГГГГ"" или ""ДД/ММ/ГГ""';
						|en = '""MM.DD.YYYY"" and ""MM/DD/YY"" formats are supported'; fa = '""MM.DD.YYYY"" and ""MM/DD/YY"" formats are supported';
						|it = 'Поддерживается формат в виде ""ДД.ММ.ГГГГ"" или ""ДД/ММ/ГГ""';
						|pl = '""MM.DD.YYYY"" and ""MM/DD/YY"" formats are supported';
						|tr = 'Desteklenen format, ""GG.AA.YYYY"" veya ""GG/AA/YYYY"" şeklindedir'");
		
		ColumnNumber = ColumnNumber + 1;
		Column = ImportDataFromFileClientServer.TemplateColumn("ValidOnDate", TemplateColumns);
		Column.Title = NStr("vi = 'Ngày đầu hiệu lực';
							|ru = 'Начало действия';
							|en = 'Valid from'; fa = 'معتبر از';
							|it = 'Начало действия';
							|pl = 'Początek działania';
							|tr = 'İşlem başlangıcı'");
		Column.ToolTip = DateHint;
		Column.Position = ColumnNumber;
		
		ColumnNumber = ColumnNumber + 1;
		Column = ImportDataFromFileClientServer.TemplateColumn("ValidTo", TemplateColumns);
		Column.Title = NStr("vi = 'Ngày hết hiệu lực';
							|ru = 'Окончание действия';
							|en = 'Valid to'; fa = 'معتبر تا';
							|it = 'Окончание действия';
							|pl = 'Zakończenie czynności';
							|tr = 'İşlem bitişi'");
		Column.ToolTip = DateHint;
		Column.Position = ColumnNumber;
		
	EndIf;
	
	Return TemplateColumns;
	
EndFunction

&AtServer
Procedure AddPartnerFieldsToCounterpartyUploadTemplate(FieldDisplaySettings, TemplateColumns, ColumnNumber)
	
	If FieldDisplaySettings.Partner Then
		
		GroupName = NStr("vi = 'Dữ liệu khách hàng';
						|ru = 'Данные клиента';
						|en = 'Customer data'; fa = 'داده‌های مشتری';
						|it = 'Данные клиента';
						|pl = 'Dane klienta';
						|tr = 'Müşteri verileri'");
		
		ColumnNumber = ColumnNumber + 1;
		TypeCode = Common.StringTypeDetails(11);
		ColumnTitle = NStr("vi = 'Mã khách hàng';
							|ru = 'Код клиента';
							|en = 'Customer code'; fa = 'Customer code';
							|it = 'Код клиента';
							|pl = 'Customer code';
							|tr = 'İstemci kodu'");
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("Code", TypeCode, ColumnTitle);
		Column.Position = ColumnNumber;
		Column.Parent = GroupName;
		TemplateColumns.Add(Column);
		
		ColumnNumber = ColumnNumber + 1;
		TypeNameOfPartner = Common.StringTypeDetails(100);
		ColumnTitle = NStr("vi = 'Khách hàng';
							|ru = 'Клиент';
							|en = 'Customer'; fa = 'مشتری';
							|it = 'Клиент';
							|pl = 'Customer';
							|tr = 'Müşteri'");
		Column = ImportDataFromFileClientServer.TemplateColumnDetails(
			"PartnerName_",
			TypeNameOfPartner,
			ColumnTitle);
		Column.Position = ColumnNumber;
		Column.Parent = GroupName;
		TemplateColumns.Add(Column);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AddCounterpartyFieldsToCounterpartyUploadTemplate(FieldDisplaySettings, TemplateColumns, ColumnNumber)
	
	If FieldDisplaySettings.Counterparty Then
		
		GroupName = "Counterparty";
		
		ColumnNumber = ColumnNumber + 1;
		TypeOfINN = Metadata.DefinedTypes.TIN.Type;
		ColumnTitle = NStr("vi = 'MST';
							|ru = 'ИНН';
							|en = 'TIN'; fa = 'شناسه مالیاتی';
							|it = 'ИНН';
							|pl = 'NIP';
							|tr = 'VKN'");
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("TIN", TypeOfINN, ColumnTitle);
		Column.Position = ColumnNumber;
		Column.Parent = GroupName;
		TemplateColumns.Add(Column);
		
		ColumnNumber = ColumnNumber + 1;
		TypeOfCheckpoint = Common.StringTypeDetails(9);
		ColumnTitle = NStr("vi = 'MĐK';
							|ru = 'КПП';
							|en = 'KPP'; fa = 'KPP';
							|it = 'КПП';
							|pl = 'KPE (Kod Przyczyny wniesienia do Ewidencji)';
							|tr = 'KPP'");
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("CRTR", TypeOfCheckpoint, ColumnTitle);
		Column.Position = ColumnNumber;
		Column.Parent = GroupName;
		TemplateColumns.Add(Column);
		
		ColumnNumber = ColumnNumber + 1;
		TypeNameOfCounterparty = Common.StringTypeDetails(250);
		ColumnTitle = NStr("vi = 'Đối tác';
							|ru = 'Контрагент';
							|en = 'Counterparty'; fa = 'طرف حساب';
							|it = 'Контрагент';
							|pl = 'Kontrahent';
							|tr = 'Cari hesap'");
		Column = ImportDataFromFileClientServer.TemplateColumnDetails(
			"CounterpartyName_",
			TypeNameOfCounterparty,
			ColumnTitle);
		Column.Position = ColumnNumber;
		Column.Parent = GroupName;
		TemplateColumns.Add(Column);
		
	EndIf;
	
EndProcedure

// Parameters:
//  ImportedDataAddress - String, Undefined - Address of uploaded data
//  AdditionalParameters - Arbitrary - 
//
&AtClient
Procedure DownloadCounterpartiesFromFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ImportedDataAddress = Undefined Then
		Return;
	EndIf;
	
	DownloadCounterpartiesFromFileOnServer(ImportedDataAddress);
	
EndProcedure

// Parameters:
//  ImportedDataAddress - String - Address of uploaded data
//
&AtServer
Procedure DownloadCounterpartiesFromFileOnServer(ImportedDataAddress)
	
	ImportedData = GetFromTempStorage(ImportedDataAddress);
	
	LinesAdded = False;
	For Each TableRow In ImportedData Do
		
		NewRow = Object.Counterparties.Add();
		FillPropertyValues(NewRow, TableRow);
		
		LinesAdded = True;
		
	EndDo;
	
	If LinesAdded Then
		Modified = True;
	EndIf;
	
EndProcedure

&AtServer
Function DescriptionOfColumnsInTemplateCounterpartiesTIN(FieldDisplaySettings)
	
	ColumnsNames = New Array; // Array of String
	ColumnsNames.Add("TIN");
	If FieldDisplaySettings.SumPlan Then
		ColumnsNames.Add("SumPlan");
	EndIf;
	
	If FieldDisplaySettings.Period Then
		
		ColumnsNames.Add("ValidOnDate");
		ColumnsNames.Add("ValidTo");
		
	EndIf;
	
	Columns = StrConcat(ColumnsNames, ",");
	
	TemplateColumns = ImportDataFromFile.GenerateColumnDetails(Object.CounterpartiesTIN, Columns);
	
	Column = ImportDataFromFileClientServer.TemplateColumn("TIN", TemplateColumns);
	Column.IsRequiredInfo = True;
	
	If FieldDisplaySettings.SumPlan Then
		
		Column = ImportDataFromFileClientServer.TemplateColumn("SumPlan", TemplateColumns);
		Column.Title = NStr("vi = 'Số tiền, dự tính';
							|ru = 'Сумма, план';
							|en = 'Amount, plan'; fa = 'مبلغ، برنامه';
							|it = 'Сумма, план';
							|pl = 'Amount, plan';
							|tr = 'Tutar, plan'");
		Column.ToolTip = NStr("vi = 'Hỗ trợ số 0 ở đầu, dấu chia cách phần nguyên và thập phân "","" và "".""';
								|ru = 'Поддерживаются лидирующие нули, а также разделители целой и дробной части "","" и "".""';
								|en = 'Leading zeros, integer and fraction dividers, "","", and ""."" are supported'; fa = 'Leading zeros, integer and fraction dividers, "","", and ""."" are supported';
								|it = 'Поддерживаются лидирующие нули, а также разделители целой и дробной части "","" и "".""';
								|pl = 'Leading zeros, integer and fraction dividers, "","", and ""."" are supported';
								|tr = 'Öndeki sıfırlara ilaveten tam sayı ve kesirli ayırıcılar olan “,” ve “.” desteklenir'");
		
	EndIf;
	
	If FieldDisplaySettings.Period Then
		
		DateHint = NStr("vi = 'Hỗ trợ định dạng ""DD.MM.YYYY"" hoặc ""DD/MM/YY""';
						|ru = 'Поддерживается формат в виде ""ДД.ММ.ГГГГ"" или ""ДД/ММ/ГГ""';
						|en = '""MM.DD.YYYY"" and ""MM/DD/YY"" formats are supported'; fa = '""MM.DD.YYYY"" and ""MM/DD/YY"" formats are supported';
						|it = 'Поддерживается формат в виде ""ДД.ММ.ГГГГ"" или ""ДД/ММ/ГГ""';
						|pl = '""MM.DD.YYYY"" and ""MM/DD/YY"" formats are supported';
						|tr = 'Desteklenen format, ""GG.AA.YYYY"" veya ""GG/AA/YYYY"" şeklindedir'");
		Column = ImportDataFromFileClientServer.TemplateColumn("ValidOnDate", TemplateColumns);
		Column.Title = NStr("vi = 'Ngày đầu hiệu lực';
							|ru = 'Начало действия';
							|en = 'Valid from'; fa = 'معتبر از';
							|it = 'Начало действия';
							|pl = 'Początek działania';
							|tr = 'İşlem başlangıcı'");
		Column.ToolTip = DateHint;
		
		Column = ImportDataFromFileClientServer.TemplateColumn("ValidTo", TemplateColumns);
		Column.Title = NStr("vi = 'Ngày hết hiệu lực';
							|ru = 'Окончание действия';
							|en = 'Valid to'; fa = 'معتبر تا';
							|it = 'Окончание действия';
							|pl = 'Zakończenie czynności';
							|tr = 'İşlem bitişi'");
		Column.ToolTip = DateHint;
		
	EndIf;
	
	Return TemplateColumns;
	
EndFunction

// Parameters:
//  ImportedDataAddress - String, Undefined - Address of uploaded data
//  AdditionalParameters - Structure - advanced setting
//
&AtClient
Procedure DownloadCounterpartyTINFromFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ImportedDataAddress = Undefined Then
		Return;
	EndIf;
	
	DownloadCounterpartyINNFromFileOnServer(ImportedDataAddress);
	
EndProcedure

// Parameters:
//  ImportedDataAddress - String -
//
&AtServer
Procedure DownloadCounterpartyINNFromFileOnServer(ImportedDataAddress)
	
	ImportedData = GetFromTempStorage(ImportedDataAddress);
	
	LinesAdded = False;
	For Each TableRow In ImportedData Do
		
		NewRow = Object.CounterpartiesTIN.Add();
		FillPropertyValues(NewRow, TableRow);
		
		LinesAdded = True;
		
	EndDo;
	
	If LinesAdded Then
		Modified = True;
	EndIf;
	
EndProcedure

&AtServer
Function DescriptionOfColumnsInGoodsSegmentTemplate()
	
	TemplateColumns = ImportDataFromFile.GenerateColumnDetails(Object.GoodsSegments, "Segment");
	
	TypeCode = Common.StringTypeDetails(11);
	ColumnTitle = NStr("vi = 'Mã';
						|ru = 'Код';
						|en = 'Code'; fa = 'کد';
						|it = 'Код';
						|pl = 'Code';
						|tr = 'Kod'");
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Code", TypeCode, ColumnTitle);
	Column.Parent = "Segment";
	Column.Position = 1;
	TemplateColumns.Add(Column);
	
	TypeSegmentName = Common.StringTypeDetails(50);
	ColumnTitle = NStr("vi = 'Phân khúc';
						|ru = 'Сегмент';
						|en = 'Segment'; fa = 'بخش';
						|it = 'Сегмент';
						|pl = 'Segment';
						|tr = 'Segment'");
	Column = ImportDataFromFileClientServer.TemplateColumnDetails(
		"Segment_Name",
		TypeSegmentName,
		ColumnTitle);
	Column.Parent = "Segment";
	Column.Position = 2;
	TemplateColumns.Add(Column);
	
	ImportDataFromFileClientServer.DeleteTemplateColumn("Segment", TemplateColumns);
	
	Return TemplateColumns;
	
EndFunction

// Parameters:
//  ImportedDataAddress - String, Undefined - Address of uploaded data
//  AdditionalParameters - Structure - advanced setting
//
&AtClient
Procedure LoadGoodsSegmentsFromFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ImportedDataAddress = Undefined Then
		Return;
	EndIf;
	
	LoadGoodsSegmentsFromFileOnServer(ImportedDataAddress);
	
EndProcedure

// Parameters:
//  ImportedDataAddress - String, Undefined - Address of uploaded data
//
&AtServer
Procedure LoadGoodsSegmentsFromFileOnServer(ImportedDataAddress)
	
	ImportedData = GetFromTempStorage(ImportedDataAddress);
	
	LinesAdded = False;
	For Each TableRow In ImportedData Do
		
		NewRow = Object.GoodsSegments.Add();
		FillPropertyValues(NewRow, TableRow);
		
		LinesAdded = True;
		
	EndDo;
	
	If LinesAdded Then
		Modified = True;
	EndIf;
	
EndProcedure

&AtServer
Function DescriptionOfColumnsInGoodsTemplate(FieldDisplaySettings)
	
	ColumnsNames = New Array; // Array of String
	If FieldDisplaySettings.Period Then
		
		ColumnsNames.Add("ValidOnDate");
		ColumnsNames.Add("ValidTo");
		
	EndIf;
	
	If FieldDisplaySettings.CountPlan Then
		ColumnsNames.Add("CountPlan");
	EndIf;
	
	If FieldDisplaySettings.BasePrice Then
		ColumnsNames.Add("BasePrice");
	EndIf;
	
	If FieldDisplaySettings.Percent Then
		ColumnsNames.Add("Percent");
	EndIf;
	
	Columns = StrConcat(ColumnsNames, ",");
	
	TemplateColumns = ImportDataFromFile.GenerateColumnDetails(Object.Goods, Columns);
	
	ColumnNumber = 0;
	
	GroupNameItem = NStr("vi = 'Mặt hàng';
						|ru = 'Номенклатура';
						|en = 'Items'; fa = 'اقلام';
						|it = 'Номенклатура';
						|pl = 'Items';
						|tr = 'Öğeler'");
	
	ColumnNumber = ColumnNumber + 1;
	TypeBarcode = Common.StringTypeDetails(200);
	ColumnTitle = NStr("vi = 'Mã vạch';
						|ru = 'Штрихкод';
						|en = 'Barcode'; fa = 'بارکد';
						|it = 'Штрихкод';
						|pl = 'Kod kreskowy';
						|tr = 'Barkod'");
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Barcode", TypeBarcode, ColumnTitle);
	Column.Position = ColumnNumber;
	Column.Group = GroupNameItem;
	Column.Parent = GroupNameItem;
	TemplateColumns.Add(Column);
	
	ColumnNumber = ColumnNumber + 1;
	TypeCode = Common.StringTypeDetails(11);
	ColumnTitle = NStr("vi = 'Mã';
						|ru = 'Код';
						|en = 'Code'; fa = 'کد';
						|it = 'Код';
						|pl = 'Kod';
						|tr = 'Kod'");
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Code", TypeCode, ColumnTitle);
	Column.Position = ColumnNumber;
	Column.Group = GroupNameItem;
	Column.Parent = GroupNameItem;
	TemplateColumns.Add(Column);
	
	ColumnNumber = ColumnNumber + 1;
	TypeArticle = Common.StringTypeDetails(50);
	ColumnTitle = NStr("vi = 'Mã hiệu';
						|ru = 'Артикул';
						|en = 'Item ID'; fa = 'شناسه قلم';
						|it = 'Артикул';
						|pl = 'Artykuł';
						|tr = 'Ürün kodu'");
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("SKU", TypeArticle, ColumnTitle);
	Column.Position = ColumnNumber;
	Column.Group = GroupNameItem;
	Column.Parent = GroupNameItem;
	TemplateColumns.Add(Column);
	
	ColumnNumber = ColumnNumber + 1;
	TypeNameOfItem = Common.StringTypeDetails(100);
	ColumnTitle = NStr("vi = 'Mặt hàng';
						|ru = 'Номенклатура';
						|en = 'Items'; fa = 'اقلام';
						|it = 'Номенклатура';
						|pl = 'Produkt';
						|tr = 'Öğe'");
	Column = ImportDataFromFileClientServer.TemplateColumnDetails(
		"NomenclatureName",
		TypeNameOfItem,
		ColumnTitle);
	Column.Position = ColumnNumber;
	Column.Group = GroupNameItem;
	Column.Parent = GroupNameItem;
	TemplateColumns.Add(Column);
	
	If FieldDisplaySettings.Characteristic Then
		
		ColumnNumber = ColumnNumber + 1;
		TypeNameCharacteristics = Common.StringTypeDetails(150);
		ColumnTitle = NStr("vi = 'Đặc tính';
							|ru = 'Характеристика';
							|en = 'Variant'; fa = 'گونه';
							|it = 'Характеристика';
							|pl = 'Charakterystyka';
							|tr = 'Varyant'");
		Column = ImportDataFromFileClientServer.TemplateColumnDetails(
			"CharacteristicName",
			TypeNameCharacteristics,
			ColumnTitle);
		Column.Position = ColumnNumber;
		Column.Parent = "Characteristic";
		TemplateColumns.Add(Column);
		
	EndIf;
	
	HintTextNumber =
		NStr("vi = 'Hỗ trợ số 0 ở đầu, dấu chia cách phần nguyên và thập phân "","" và "".""';
			|ru = 'Поддерживаются лидирующие нули, а также разделители целой и дробной части "","" и "".""';
			|en = 'Leading zeros, integer and fraction dividers, "","", and ""."" are supported'; fa = 'Leading zeros, integer and fraction dividers, "","", and ""."" are supported';
			|it = 'Поддерживаются лидирующие нули, а также разделители целой и дробной части "","" и "".""';
			|pl = 'Leading zeros, integer and fraction dividers, "","", and ""."" are supported';
			|tr = 'Öndeki sıfırlara ilaveten tam sayı ve kesirli ayırıcılar olan “,” ve “.” desteklenir'");
	If FieldDisplaySettings.CountPlan Then
		
		ColumnNumber = ColumnNumber + 1;
		Column = ImportDataFromFileClientServer.TemplateColumn("CountPlan", TemplateColumns);
		Column.Title = NStr("vi = 'Số lượng, dự tính';
							|ru = 'Кол-во, план';
							|en = 'Quantity, plan'; fa = 'مقدار، برنامه';
							|it = 'Кол-во, план';
							|pl = 'Quantity, plan';
							|tr = 'Miktar, plan'");
		Column.ToolTip = HintTextNumber;
		Column.Position = ColumnNumber;
		
	EndIf;
	
	If FieldDisplaySettings.BasePrice Then
		
		ColumnNumber = ColumnNumber + 1;
		Column = ImportDataFromFileClientServer.TemplateColumn("BasePrice", TemplateColumns);
		Column.Title = NStr("vi = 'Đơn giá cơ bản';
							|ru = 'Базовая цена';
							|en = 'Base price'; fa = 'قیمت پایه';
							|it = 'Базовая цена';
							|pl = 'Base price';
							|tr = 'Baz alınan fiyat'");
		Column.ToolTip = HintTextNumber;
		Column.Position = ColumnNumber;
		
	EndIf;
	
	If FieldDisplaySettings.Percent Then
		
		ColumnNumber = ColumnNumber + 1;
		Column = ImportDataFromFileClientServer.TemplateColumn("Percent", TemplateColumns);
		Column.Title = NStr("vi = 'Thưởng, %';
							|ru = 'Бонус, %';
							|en = 'Rebate, %'; fa = 'تخفیف حجمی، درصد';
							|it = 'Бонус, %';
							|pl = 'Rebate, %';
							|tr = 'Bonus, %'");
		Column.ToolTip = HintTextNumber;
		Column.Position = ColumnNumber;
		
	EndIf;
	
	If FieldDisplaySettings.Period Then
		
		DateHint = NStr("vi = 'Hỗ trợ định dạng ""DD.MM.YYYY"" hoặc ""DD/MM/YY""';
						|ru = 'Поддерживается формат в виде ""ДД.ММ.ГГГГ"" или ""ДД/ММ/ГГ""';
						|en = '""MM.DD.YYYY"" and ""MM/DD/YY"" formats are supported'; fa = '""MM.DD.YYYY"" and ""MM/DD/YY"" formats are supported';
						|it = 'Поддерживается формат в виде ""ДД.ММ.ГГГГ"" или ""ДД/ММ/ГГ""';
						|pl = '""MM.DD.YYYY"" and ""MM/DD/YY"" formats are supported';
						|tr = 'Desteklenen format, ""GG.AA.YYYY"" veya ""GG/AA/YYYY"" şeklindedir'");
		
		ColumnNumber = ColumnNumber + 1;
		Column = ImportDataFromFileClientServer.TemplateColumn("ValidOnDate", TemplateColumns);
		Column.Title = NStr("vi = 'Ngày đầu hiệu lực';
							|ru = 'Начало действия';
							|en = 'Valid from'; fa = 'معتبر از';
							|it = 'Начало действия';
							|pl = 'Początek działania';
							|tr = 'İşlem başlangıcı'");
		Column.ToolTip = DateHint;
		Column.Position = ColumnNumber;
		
		ColumnNumber = ColumnNumber + 1;
		Column = ImportDataFromFileClientServer.TemplateColumn("ValidTo", TemplateColumns);
		Column.Title = NStr("vi = 'Ngày hết hiệu lực';
							|ru = 'Окончание действия';
							|en = 'Valid to'; fa = 'معتبر تا';
							|it = 'Окончание действия';
							|pl = 'Zakończenie czynności';
							|tr = 'İşlem bitişi'");
		Column.ToolTip = DateHint;
		Column.Position = ColumnNumber;
		
	EndIf;
	
	Return TemplateColumns;
	
EndFunction

&AtServer
Function DescriptionOfColumnsInPartnerSegmentTemplate()
	
	TemplateColumns = ImportDataFromFile.GenerateColumnDetails(Object.PartnersSegments, "Segment");
	
	TypeCode = Common.StringTypeDetails(11);
	ColumnTitle = NStr("vi = 'Mã';
						|ru = 'Код';
						|en = 'Code'; fa = 'کد';
						|it = 'Код';
						|pl = 'Code';
						|tr = 'Kod'");
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Code", TypeCode, ColumnTitle);
	Column.Parent = "Segment";
	Column.Position = 1;
	TemplateColumns.Add(Column);
	
	TypeSegmentName = Common.StringTypeDetails(50);
	ColumnTitle = NStr("vi = 'Phân khúc';
						|ru = 'Сегмент';
						|en = 'Segment'; fa = 'بخش';
						|it = 'Сегмент';
						|pl = 'Segment';
						|tr = 'Segment'");
	Column = ImportDataFromFileClientServer.TemplateColumnDetails(
		"Segment_Name",
		TypeSegmentName,
		ColumnTitle);
	Column.Parent = "Segment";
	Column.Position = 2;
	TemplateColumns.Add(Column);
	
	ImportDataFromFileClientServer.DeleteTemplateColumn("Segment", TemplateColumns);
	
	Return TemplateColumns;
	
EndFunction

// Parameters:
//  ImportedDataAddress - String, Undefined - Address of uploaded data
//  AdditionalParameters - Structure - advanced setting
//
&AtClient
Procedure ImportGoodsFromFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ImportedDataAddress = Undefined Then
		Return;
	EndIf;
	
	UploadProductsFromFileOnServer(ImportedDataAddress);
	
EndProcedure

// Parameters:
//  ImportedDataAddress - String -
//
&AtServer
Procedure UploadProductsFromFileOnServer(ImportedDataAddress)
	
	ImportedData = GetFromTempStorage(ImportedDataAddress);
	
	LinesAdded = False;
	For Each TableRow In ImportedData Do
		
		NewRow = Object.Goods.Add();
		FillPropertyValues(NewRow, TableRow);
		
		LinesAdded = True;
		
	EndDo;
	
	If LinesAdded Then
		
		FillInServiceDetailsForProductRange();
		Modified = True;
		
	EndIf;
	
EndProcedure

// Parameters:
//  ImportedDataAddress - String, Undefined -
//  AdditionalParameters - Arbitrary -
//
&AtClient
Procedure DownloadPartnerSegmentsFromFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ImportedDataAddress = Undefined Then
		Return;
	EndIf;
	
	DownloadPartnerSegmentsFromFileOnServer(ImportedDataAddress);
	
EndProcedure

&AtServer
Procedure DownloadPartnerSegmentsFromFileOnServer(ImportedDataAddress)
	
	ImportedData = GetFromTempStorage(ImportedDataAddress);
	
	LinesAdded = False;
	For Each TableRow In ImportedData Do
		
		NewRow = Object.PartnersSegments.Add();
		FillPropertyValues(NewRow, TableRow);
		
		LinesAdded = True;
		
	EndDo;
	
	If LinesAdded Then
		Modified = True;
	EndIf;
	
EndProcedure

&AtServer
Function InformationAboutSourceOfValues(Type)
	
	InformationRecords = New Structure;
	InformationRecords.Insert("ProductItemPropertyPresentation", ProductItemPropertyPresentation);
	InformationRecords.Insert("Name", "");
	InformationRecords.Insert("FullName", "");
	InformationRecords.Insert("Synonym", "");
	InformationRecords.Insert("NumberLength", 0);
	InformationRecords.Insert("IsNumber", False);
	InformationRecords.Insert("IsDate", False);
	InformationRecords.Insert("IsCatalog", False);
	InformationRecords.Insert("IsDocument", False);
	InformationRecords.Insert("IsChartOfCharacteristicTypes", False);
	InformationRecords.Insert("IsEnum", False);
	InformationRecords.Insert("CodeLength", 0);
	InformationRecords.Insert("DescriptionLength", 0);
	InformationRecords.Insert("ContainsGroups", False);
	InformationRecords.Insert("NumberLength", 0);
	
	If Type = Type("Number") Then
		
		InformationRecords.IsNumber = True;
		
	ElsIf Type = Type("Date") Then
		
		InformationRecords.IsDate = True;
		
	Else
		
		MetadataObject = Metadata.FindByType(Type);
		
		InformationRecords.Name = MetadataObject.Name;
		InformationRecords.FullName = MetadataObject.FullName();
		InformationRecords.Synonym = MetadataObject.Synonym;
		InformationRecords.IsCatalog = Catalogs.AllRefsType().ContainsType(Type);
		InformationRecords.IsDocument = Documents.AllRefsType().ContainsType(Type);
		InformationRecords.IsChartOfCharacteristicTypes = ChartsOfCharacteristicTypes.AllRefsType().ContainsType(Type);
		InformationRecords.IsEnum = Enums.AllRefsType().ContainsType(Type);
		
		If InformationRecords.IsCatalog Then
			
			FillPropertyValues(InformationRecords, MetadataObject, "CodeLength, DescriptionLength");
			InformationRecords.ContainsGroups = MetadataObject.Hierarchical
				And (MetadataObject.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems);
			
		EndIf;
		
		If InformationRecords.IsDocument Then
			
			FillPropertyValues(InformationRecords, MetadataObject, "NumberLength");
			
		EndIf;
		
	EndIf;
	
	Return InformationRecords;
	
EndFunction

// Parameters:
//  ImportedDataAddress - String, Undefined - Address of uploaded data
//  AdditionalParameters - Structure - advanced setting
//
&AtClient
Procedure ImportPropertiesValuesfromFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ImportedDataAddress = Undefined Then
		Return;
	EndIf;
	
	LoadPropertyValuesFromFileAtServer(ImportedDataAddress);
	
EndProcedure

// Parameters:
//  ImportedDataAddress - String -
//
&AtServer
Procedure LoadPropertyValuesFromFileAtServer(ImportedDataAddress)
	
	ImportedData = GetFromTempStorage(ImportedDataAddress);
	
	LinesAdded = False;
	For Each TableRow In ImportedData Do
		
		NewRow = Object.ProductProperties_.Add();
		FillPropertyValues(NewRow, TableRow);
		LinesAdded = True;
		
	EndDo;
	
	If LinesAdded Then
		Modified = True;
	EndIf;
	
EndProcedure

&AtServer
Function DescriptionOfColumnsInTemplateItemProperties(FieldDisplaySettings, InformationAboutSource)
	
	ColumnsNames = New Array; // Array of String
	If FieldDisplaySettings.Period Then
		
		ColumnsNames.Add("ValidOnDate");
		ColumnsNames.Add("ValidTo");
		
	EndIf;
	
	If FieldDisplaySettings.CountPlan Then
		ColumnsNames.Add("CountPlan");
	EndIf;
	
	If FieldDisplaySettings.BasePrice Then
		ColumnsNames.Add("BasePrice");
	EndIf;
	
	If FieldDisplaySettings.Percent Then
		ColumnsNames.Add("Percent");
	EndIf;
	
	Columns = StrConcat(ColumnsNames, ",");
	
	TemplateColumns = ImportDataFromFile.GenerateColumnDetails(Object.Goods, Columns);
	HintNumber = NStr("vi = 'Hỗ trợ số 0 ở đầu, dấu chia cách phần nguyên và thập phân "","" và "".""';
						|ru = 'Поддерживаются лидирующие нули, а также разделители целой и дробной части "","" и "".""';
						|en = 'Leading zeros, integer and fraction dividers, "","", and ""."" are supported'; fa = 'Leading zeros, integer and fraction dividers, "","", and ""."" are supported';
						|it = 'Поддерживаются лидирующие нули, а также разделители целой и дробной части "","" и "".""';
						|pl = 'Leading zeros, integer and fraction dividers, "","", and ""."" are supported';
						|tr = 'Öndeki sıfırlara ilaveten tam sayı ve kesirli ayırıcılar olan “,” ve “.” desteklenir'");
	DateHint = NStr("vi = 'Hỗ trợ định dạng ""DD.MM.YYYY"" hoặc ""DD/MM/YY""';
					|ru = 'Поддерживается формат в виде ""ДД.ММ.ГГГГ"" или ""ДД/ММ/ГГ""';
					|en = '""MM.DD.YYYY"" and ""MM/DD/YY"" formats are supported'; fa = '""MM.DD.YYYY"" and ""MM/DD/YY"" formats are supported';
					|it = 'Поддерживается формат в виде ""ДД.ММ.ГГГГ"" или ""ДД/ММ/ГГ""';
					|pl = '""MM.DD.YYYY"" and ""MM/DD/YY"" formats are supported';
					|tr = 'Desteklenen format, ""GG.AA.YYYY"" veya ""GG/AA/YYYY"" şeklindedir'");
	ColumnHeaderPropertyValues = InformationAboutSource.ProductItemPropertyPresentation;
	GroupName = ColumnHeaderPropertyValues;
	ParentName = "PropertyValue";
	
	ColumnNumber = 0;
	DescriptionLength = 100;
	
	ToDisplayGroup = False;
	
	If (InformationAboutSource.IsCatalog
	      Or InformationAboutSource.IsChartOfCharacteristicTypes)
	     And InformationAboutSource.CodeLength > 0 Then
		
		CodeLength = InformationAboutSource.CodeLength;
		ColumnNumber = ColumnNumber + 1;
		TypeCode = Common.StringTypeDetails(CodeLength);
		ColumnTitle = NStr("vi = 'Mã';
							|ru = 'Код';
							|en = 'Code'; fa = 'کد';
							|it = 'Code';
							|pl = 'Code';
							|tr = 'Kod'");
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("Code", TypeCode, ColumnTitle);
		Column.Position = ColumnNumber;
		Column.Group = GroupName;
		Column.Parent = ParentName;
		Column.Width = 20;
		TemplateColumns.Add(Column);
		DescriptionLength = InformationAboutSource.DescriptionLength;
		ToDisplayGroup = True;
		
	ElsIf InformationAboutSource.IsDocument Then
		
		ColumnNumber = ColumnNumber + 1;
		Type = Common.DateTypeDetails(DateFractions.DateTime);
		ColumnTitle = NStr("vi = 'Ngày chứng từ';
							|ru = 'Дата документа';
							|en = 'Document date'; fa = 'تاریخ سند';
							|it = 'Data del documento';
							|pl = 'Data dokumentu';
							|tr = 'Belge tarihi'");
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("Date", Type, ColumnTitle);
		Column.Position = ColumnNumber;
		Column.IsRequiredInfo = True;
		Column.ToolTip = DateHint;
		Column.Group = GroupName;
		Column.Parent = ParentName;
		Column.Width = 20;
		TemplateColumns.Add(Column);
		
		ColumnHeaderPropertyValues = NStr("vi = 'Số chứng từ';
											|ru = 'Номер документа';
											|en = 'Document number'; fa = 'شماره سند';
											|it = 'Numero del documento';
											|pl = 'Numer dokumentu';
											|tr = 'Belge numarası'");
		DescriptionLength = InformationAboutSource.NumberLength;
		ToDisplayGroup = True;
		
	EndIf;
	
	ColumnNumber = ColumnNumber + 1;
	
	If InformationAboutSource.IsNumber Then
		PropertyType1 = InformationAboutSource.Type;
	ElsIf InformationAboutSource.IsDate Then
		PropertyType1 = InformationAboutSource.Type;
	Else
		PropertyType1 = Common.StringTypeDetails(DescriptionLength);
	EndIf;
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails(
		ParentName,
		PropertyType1,
		ColumnHeaderPropertyValues);
	Column.Position = ColumnNumber;
	If InformationAboutSource.IsDocument Then
		Column.IsRequiredInfo = True;
	EndIf; 
	If ToDisplayGroup Then
		Column.Group = GroupName;
	EndIf;
	Column.Parent = ParentName;
	Column.Width = 35;
	TemplateColumns.Add(Column);
	
	If FieldDisplaySettings.CountPlan Then
		
		ColumnNumber = ColumnNumber + 1;
		Column = ImportDataFromFileClientServer.TemplateColumn("CountPlan", TemplateColumns);
		Column.Title = NStr("vi = 'Số lượng, dự tính';
							|ru = 'Кол-во, план';
							|en = 'Quantity, plan'; fa = 'مقدار، برنامه';
							|it = 'Кол-во, план';
							|pl = 'Quantity, plan';
							|tr = 'Miktar, plan'");
		Column.ToolTip = HintNumber;
		Column.Position = ColumnNumber;
		
	EndIf;
	
	If FieldDisplaySettings.BasePrice Then
		
		ColumnNumber = ColumnNumber + 1;
		Column = ImportDataFromFileClientServer.TemplateColumn("BasePrice", TemplateColumns);
		Column.Title = NStr("vi = 'Đơn giá cơ bản';
							|ru = 'Базовая цена';
							|en = 'Base price'; fa = 'قیمت پایه';
							|it = 'Базовая цена';
							|pl = 'Base price';
							|tr = 'Baz alınan fiyat'");
		Column.ToolTip = HintNumber;
		Column.Position = ColumnNumber;
		
	EndIf;
	
	If FieldDisplaySettings.Percent Then
		
		ColumnNumber = ColumnNumber + 1;
		Column = ImportDataFromFileClientServer.TemplateColumn("Percent", TemplateColumns);
		Column.Title = NStr("vi = 'Thưởng, %';
							|ru = 'Бонус, %';
							|en = 'Rebate, %'; fa = 'تخفیف حجمی، درصد';
							|it = 'Бонус, %';
							|pl = 'Rebate, %';
							|tr = 'Bonus, %'");
		Column.ToolTip = HintNumber;
		Column.Position = ColumnNumber;
		
	EndIf;
	
	If FieldDisplaySettings.Period Then
		
		ColumnNumber = ColumnNumber + 1;
		Column = ImportDataFromFileClientServer.TemplateColumn("ValidOnDate", TemplateColumns);
		Column.Title = NStr("vi = 'Ngày đầu hiệu lực';
							|ru = 'Начало действия';
							|en = 'Valid from'; fa = 'معتبر از';
							|it = 'Начало действия';
							|pl = 'Początek działania';
							|tr = 'Eylem başlangıcı'");
		Column.ToolTip = DateHint;
		Column.Position = ColumnNumber;
		
		ColumnNumber = ColumnNumber + 1;
		Column = ImportDataFromFileClientServer.TemplateColumn("ValidTo", TemplateColumns);
		Column.Title = NStr("vi = 'Ngày hết hiệu lực';
							|ru = 'Окончание действия';
							|en = 'Valid to'; fa = 'معتبر تا';
							|it = 'Окончание действия';
							|pl = 'Zakończenie czynności';
							|tr = 'Eylem bitişi'");
		Column.ToolTip = DateHint;
		Column.Position = ColumnNumber;
		
	EndIf; 
	
	Return TemplateColumns;
	
EndFunction

#EndRegion

#Region Other

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtClientAtServerNoContext
Function DetailsByCounterpartyClient(PartyCountDetails)
	
	Return PartyCountDetails = PredefinedValue("Enum.ARAPAccountingDrilldownsOfRebatesParticipants.ByCounterpartyAndCustomer");
	
EndFunction

&AtClientAtServerNoContext
Function DetailsByCounterparty(PartyCountDetails)
	
	Return PartyCountDetails = PredefinedValue("Enum.ARAPAccountingDrilldownsOfRebatesParticipants.ByCounterparty");
	
EndFunction

&AtServer
Procedure SetHeader()
	
	AutoTitle = False;
	Title = RebatesServer.DocumentTitle(
		Object.Ref, Object.Number, Object.Date, Object.Patch);
	
EndProcedure

&AtServer
Procedure FillInRebateKind(OnlyCache = False)
	
	AttributesArray = New Array; // Array of String
	
	If Not OnlyCache Then
		
		AttributesArray.Add("WithoutCalculation");
		AttributesArray.Add("ConditionFrequency");
		AttributesArray.Add("AccrualFrequency");
		AttributesArray.Add("PartyCountDetails");
		AttributesArray.Add("FilterOfProducts_");
		AttributesArray.Add("FilterParties");
		
	EndIf;
	
	AttributesArray.Add("GoodsIndicator");
	AttributesArray.Add("SalesCalculationBase");
	AttributesArray.Add("ContentOfGoods");
	AttributesArray.Add("PartyList");
	AttributesArray.Add("ProductItemProperty");
	
	KindAttributes = Common.ObjectAttributesValues(Object.RebateKind, AttributesArray);
	
	If Not OnlyCache Then
		
		Object.CalculationScales.Clear();
		Object.WithoutCalculation = KindAttributes.WithoutCalculation;
		If Not Object.WithoutCalculation Then
			
			Object.AccrueImmediately = False;
			
		EndIf;
		
		Object.ConditionFrequency = KindAttributes.ConditionFrequency;
		Object.AccrualFrequency = KindAttributes.AccrualFrequency;
		Object.PartyCountDetails = KindAttributes.PartyCountDetails;
		Object.FilterParties = KindAttributes.FilterParties;
		Object.FilterOfProducts_ = KindAttributes.FilterOfProducts_;
		Object.CalculationScaleType = 0;
		
	EndIf;
	
	GoodsIndicator = KindAttributes.GoodsIndicator;
	SalesCalculationBase = KindAttributes.SalesCalculationBase;
	ContentOfGoods = KindAttributes.ContentOfGoods;
	PartyList = KindAttributes.PartyList;
	
	RebatesClientServer.FillInValidOptionsForCalculationScales(Items.CalculationScaleType, GoodsIndicator);
	RebatesClientServer.SetTitleOfCalculationScaleGroup(ThisObject);
	
	#Region ProductItemProperty
	If ContentOfGoods = Enums.RebatesItems.ProductItemProperty Then
		
		CheckResult = RebatesServer.ItemPropertyVerificationData(KindAttributes.ProductItemProperty);
		ProductItemProperty = CheckResult.Property;
		ProductItemPropertyPresentation = CheckResult.Title;
		
		ValueSelectionParameters = New Array; // Array of ChoiceParameter
		AcceptablePropertyTypes = New TypeDescription();
		
		If CheckResult.AllowedToUse Then
			
			ValueType = CheckResult.ValueType;
			AcceptablePropertyTypes = RebatesServer.AllowedValueTypesItemProperties(ValueType);
			Items.ProductProperties_PropertyValue.TypeRestriction = AcceptablePropertyTypes;
			Items.ProductProperties_PropertyValue.ChooseType = True;
			RebatesClientServer.SetDefaultPropertyValueFormat(
				Items.ProductProperties_PropertyValue,
				AcceptablePropertyTypes);
			
			If ValueIsFilled(ProductItemProperty) Then
				
				NewFilter = New ChoiceParameter("Filter.Owner", ProductItemProperty);
				ValueSelectionParameters.Add(NewFilter);
				
			EndIf;
			
			If Not OnlyCache
			   And ContentOfGoods = Enums.RebatesItems.ProductItemProperty Then
				
				For Each TSRow In Object.ProductProperties_ Do
					
					//@skip-check statement-type-change
					TSRow.PropertyValue = AcceptablePropertyTypes.AdjustValue(TSRow.PropertyValue);
					
				EndDo;
				RebatesServer.UpdateRowRangesOfAllProperties(Object, GoodsIndicator);
				
			EndIf;
			
		Else
			
			RebatesServer.ReportItemPropertiesError(CheckResult, "RebateKind");
			
		EndIf;
		
		Items.ProductProperties_PropertyValue.ChoiceParameters =
			New FixedArray(ValueSelectionParameters);
		
	EndIf;
	#EndRegion
	
	If Not OnlyCache Then
		
		DetermineDocumentCurrency();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure EstablishSignsOfCalculationOfParticipantsPlan(ChangedMember = Undefined)
	
	ParametersOfParticipants = Documents.ConditionsOfCustomerRebates.ParametersForClearingParticipantsAttributes();
	ParametersOfParticipants.PartyList = PartyList;
	ParametersOfParticipants.FilterParties = Object.FilterParties;
	ParametersOfParticipants.GoodsIndicator = GoodsIndicator;
	Documents.ConditionsOfCustomerRebates.EstablishSignsOfCalculationOfParticipantsPlan(
		Object, ParametersOfParticipants, ChangedMember);
	
EndProcedure

&AtServer
Procedure DetermineDocumentCurrency()
	
	If SalesCalculationBase = Enums.RebateCalculationBases.RevenueLocalAccounting
	   And Not Object.Organization.IsEmpty() Then
		
		Object.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		
	ElsIf SalesCalculationBase = Enums.RebateCalculationBases.RevenueManagementAccounting Then
		
		Object.Currency = Constants.ManagementAccountingCurrency.Get();
		
	ElsIf SalesCalculationBase = Enums.RebateCalculationBases.RevenueBasePrices Then
		
		Object.Currency = Catalogs.Currencies.GetDefaultCurrency();
		
	ElsIf Object.WithoutCalculation
			And GetFunctionalOption("NotUseMultipleCurrencies") Then
		
		Object.Currency = Catalogs.Currencies.GetDefaultCurrency();
		
	Else
		
		Object.Currency = Catalogs.Currencies.EmptyRef();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetHeadersByCurrency()
	
	#Region SumPlan
	If SalesCalculationBase = Enums.RebateCalculationBases.RevenueARAPAccounting
	 Or Object.Currency.IsEmpty() Then
		
		AmountHeaderPlan = NStr("vi = 'Số tiền, dự tính';
								|ru = 'Сумма, план';
								|en = 'Amount, plan'; fa = 'مبلغ، برنامه';
								|it = 'Сумма, план';
								|pl = 'Amount, plan';
								|tr = 'Tutar, plan'");
		
	Else
		
		AmountTemplatePlan = NStr("vi = 'Số tiền, dự tính (%1)';
									|ru = 'Сумма, план (%1)';
									|en = 'Amount, plan (%1)'; fa = 'Amount, plan (%1)';
									|it = 'Сумма, план (%1)';
									|pl = 'Amount, plan (%1)';
									|tr = 'Tutar, plan (%1)'");
		AmountHeaderPlan = StrTemplate(AmountTemplatePlan, Object.Currency);
		
	EndIf;
	
	Items.CounterpartiesTINSumPlan.Title = AmountHeaderPlan;
	Items.CounterpartiesSumPlan.Title = AmountHeaderPlan;
	#EndRegion
	
	#Region AmountBonus
	If Object.Currency.IsEmpty() Then
		
		AmountHeaderPlan = NStr("vi = 'Số tiền, thưởng';
								|ru = 'Сумма, бонус';
								|en = 'Amount, rebate'; fa = 'مبلغ، تخفیف برگشتی';
								|it = 'Сумма, бонус';
								|pl = 'Amount, rebate';
								|tr = 'Tutar, bonus'");
		
	Else
		
		AmountTemplatePlan = NStr("vi = 'Số tiền, thưởng (%1)';
									|ru = 'Сумма, бонус (%1)';
									|en = 'Amount, rebate (%1)'; fa = 'Amount, rebate (%1)';
									|it = 'Сумма, бонус (%1)';
									|pl = 'Amount, rebate (%1)';
									|tr = 'Tutar, bonus (%1)'");
		AmountHeaderPlan = StrTemplate(AmountTemplatePlan, Object.Currency);
		
	EndIf;
	
	Items.CounterpartiesAmountBonus.Title = AmountHeaderPlan;
	#EndRegion
	
	#Region BasePrice
	If SalesCalculationBase <> Enums.RebateCalculationBases.RevenueBasePrices
	 Or Object.Currency.IsEmpty() Then
		
		TitleBasePrice = NStr("vi = 'Đơn giá cơ bản';
								|ru = 'Базовая цена';
								|en = 'Base price'; fa = 'قیمت پایه';
								|it = 'Базовая цена';
								|pl = 'Base price';
								|tr = 'Baz alınan fiyat'");
		
	Else
		
		BasicPriceTemplate = NStr("vi = 'Đơn giá cơ bản (%1)';
									|ru = 'Базовая цена (%1)';
									|en = 'Base price (%1)'; fa = 'Base price (%1)';
									|it = 'Базовая цена (%1)';
									|pl = 'Base price (%1)';
									|tr = 'Baz alınan fiyat (%1)'");
		TitleBasePrice = StrTemplate(BasicPriceTemplate, Object.Currency);
		
	EndIf;
	
	Items.GoodsBasePrice.Title = TitleBasePrice;
	#EndRegion
	
EndProcedure

// Set an available list of the time fence of accruals
// 
// Parameters:
//  Form - See Document.ConditionsOfCustomerRebates.Form.DocumentForm
//
&AtClientAtServerNoContext
Procedure SetAvailableListOfTimeFenceAccruals(Form)
	
	Object = Form.Object;
	
	FilterParameters = RebatesClientServer.NewParametersOfAvailableAccrualTimeFences();
	FilterParameters.ConditionFrequency = Object.ConditionFrequency;
	FilterParameters.GoodsIndicator = Form.GoodsIndicator;
	
	ChoiceArray = RebatesClientServer.AvailableListOfTimeFenceOfAccruals(FilterParameters);
	Form.Items.AccrualFrequency.ChoiceList.LoadValues(ChoiceArray);
	RebatesClientServer.CheckSetValueOfSelectionList(Object, "AccrualFrequency", ChoiceArray);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert(
		"FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert(
		"FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert(
		"FillInArticleAttribute",
		New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.Goods, ParametersForFillingInBankingDetails);
	
EndProcedure

&AtServer
Procedure FillInServiceAttributesOfAgreementsContracts()
	
	If PartyList = Enums.RebatesParticipants.Terms1 Then
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInAgreementAttributeInTSLine", "Terms");
		
		BatchProcessingOfTablePartServer.TreatTS(Object.ContractsTermsOfSales, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInSignOfAccruals()
	
	If Object.CorrectedDocument.IsEmpty() Then
		
		If Object.Ref.IsEmpty()
		 Or Object.AccrueImmediately Then
			
			ThereAreAccruals = False;
			
		Else
			
			MaxDate = RebatesServer.LimitOfAccrualsOfClients(Object.Ref);
			ThereAreAccruals = (MaxDate <> Date(1, 1, 1));
			
		EndIf;
		
	Else
		
		MaxDate = RebatesServer.LimitOfAccrualsOfClients(Object.CorrectedDocument);
		ThereAreAccruals = (MaxDate <> Date(1, 1, 1));
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDataOfLastAdjustment()
	
	ThereIsAdjustmentOnApproval = False;
	If Not Object.Ref.IsEmpty() Then
		
		ThereIsAdjustmentOnApproval = RebatesServer.ThereIsAdjustmentOnApproval(Object.Ref);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateDataBeforeFixingComposition()
	
	FillInDataOfLastAdjustment();
	If ThereIsAdjustmentOnApproval Then
		
		SetSceneryTitlesWithHyperlinks();
		
	EndIf;
	FillInAttributesOfCompositionAccordingToCondition();
	
EndProcedure

&AtServer
Procedure UpdateDataBeforeCancelingFixationOfComposition()
	
	FillInSignOfAccruals();
	If ThereAreAccruals Then
		SetSceneryTitlesWithHyperlinks();
	EndIf;
	FillInAttributesOfCompositionAccordingToCondition();
	
EndProcedure

&AtClientAtServerNoContext
Procedure GenerateAmountsOfPlansAsLine(Form)
	
	Form.SumOfPlanByLine = Format(Form.Object.SumPlan, "NFD=2; NZ=-;");
	
	AmountTemplate = "<%1>";
	Form.AmountOfPlanByLineIsUnchanged = StrTemplate(AmountTemplate, Form.SumOfPlanByLine);
	
EndProcedure

&AtServerNoContext
Function StaticSegmentPartners(Segment)
	
	QueryText =
	"SELECT
	|	SegmentPartners.Partner AS Partner
	|FROM
	|	InformationRegister.SegmentPartners AS SegmentPartners
	|WHERE
	|	SegmentPartners.Segment = &Segment
	|	AND SegmentPartners.Partner.Client
	|
	|ORDER BY
	|	Partner";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Segment", Segment);
	Selection = Query.Execute().Select();
	
	Return Selection;
	
EndFunction

&AtServerNoContext
Function DynamicSegmentPartners(Segment)
	
	SegmentData = DynamicPartnerSegmentTable(Segment);
	
	QueryText =
	"SELECT DISTINCT
	|	CAST(SegmentData.ListItem AS Catalog.Partners) AS Partner
	|INTO TT_SegmentsPartners
	|FROM
	|	&SegmentData AS SegmentData
	|
	|INDEX BY
	|	Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SegmentsPartners.Partner AS Partner
	|FROM
	|	TT_SegmentsPartners AS SegmentsPartners
	|WHERE
	|	SegmentsPartners.Partner.Client
	|
	|ORDER BY
	|	Partner";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("SegmentData", SegmentData);
	Selection = Query.Execute().Select();
	
	Return Selection;
	
EndFunction

// Parameters:
//  Segment - CatalogRef.PartnersSegments
// 
// Returns:
//  ValueTable:
//  * ListItem - CatalogRef.Partners
//
&AtServerNoContext
Function DynamicPartnerSegmentTable(Segment)
	
	TableOfSegment = SegmentsServer.ListOfDCSElements(Segment);
	Return TableOfSegment;
	
EndFunction

&AtServerNoContext
Function StaticSegmentGoods(Segment)
	
	QueryText =
	"SELECT
	|	SegmentProducts.Products AS Products,
	|	SegmentProducts.Characteristic AS Characteristic
	|FROM
	|	InformationRegister.SegmentProducts AS SegmentProducts
	|WHERE
	|	SegmentProducts.Segment = &Segment
	|	AND SegmentProducts.Products.ItemsType IN (&SupportedItemTypes)
	|
	|ORDER BY
	|	Products,
	|	Characteristic";
	
	ItemsTypes = RebatesServer.SupportedItemTypes();
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Segment", Segment);
	Query.SetParameter("SupportedItemTypes", ItemsTypes);
	Selection = Query.Execute().Select();
	
	Return Selection;
	
EndFunction

&AtServerNoContext
Function DynamicSegmentGoods(Segment)
	
	SegmentData = DynamicItemSegmentTable(Segment);
	
	QueryText =
	"SELECT DISTINCT
	|	CAST(SegmentData.ListItem AS Catalog.Products) AS Products,
	|	SegmentData.ElementCharacteristics AS Characteristic
	|INTO TT_ItemOfSegments
	|FROM
	|	&SegmentData AS SegmentData
	|
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_ItemOfSegments.Products AS Products,
	|	TT_ItemOfSegments.Characteristic AS Characteristic
	|FROM
	|	TT_ItemOfSegments AS TT_ItemOfSegments
	|WHERE
	|	TT_ItemOfSegments.Products.ItemsType IN (&SupportedItemTypes)
	|
	|ORDER BY
	|	Products,
	|	Characteristic";
	
	ItemsTypes = RebatesServer.SupportedItemTypes();
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("SegmentData", SegmentData);
	Query.SetParameter("SupportedItemTypes", ItemsTypes);
	Selection = Query.Execute().Select();
	
	Return Selection;
	
EndFunction

// Parameters:
//  Segment - CatalogRef.ProductSegments
// 
// Returns:
//  ValueTable:
//  * ListItem - CatalogRef.Products
//  * ElementCharacteristics - CatalogRef.ItemsCharacteristics
//
&AtServerNoContext
Function DynamicItemSegmentTable(Segment)
	
	TableOfSegment = SegmentsServer.ListOfDCSElements(Segment);
	Return TableOfSegment;
	
EndFunction

&AtServer
Procedure FillInGoodsQuantityPlanServer(Val Value, Val SelectedRows)
	
	ThisIsNumberByRanges = RebatesClientServer.ThisIsNumberByRanges(Object.CalculationScaleType, GoodsIndicator);
	ArrayOfRowsToBeProcessed = New Array; // Array of FormDataCollectionItem
	
	For Each SelectedRow In SelectedRows Do
		
		RowOfGoods = Object.Goods.FindByID(SelectedRow);
		If RowOfGoods.InitialString Then
			Continue;
		EndIf;
		
		RowOfGoods.CountPlan = Value;
		
		If ThisIsNumberByRanges Then
			ArrayOfRowsToBeProcessed.Add(RowOfGoods);
		EndIf;
		
	EndDo;
	
	If ThisIsNumberByRanges Then
		
		ReadyForProcessing_ = Object.Goods.Unload(ArrayOfRowsToBeProcessed);
		RebatesServer.UpdateGoodsRowRangesByTable(Object, ReadyForProcessing_);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region WorkingWithPropertyRanges

// Parameters:
//  PropertyValue - DefinedType.RebateItemPropertyTypes
//
&AtServer
Procedure UpdatePropertyRowRangesByProperty(PropertyValue)
	
	RebatesServer.UpdatePropertyRowRangesByProperty(Object, PropertyValue);
	
EndProcedure

#EndRegion

#Region WorkingWithItemRanges

&AtClient
Procedure SaveAnalyticsOfProductLine(DimensionProductLines_2, CurrentData)
	
	FillParameters = RebatesClientServer.ParametersForFillingInAnalyticsOfRowBeingModified();
	FillParameters.CalculationScaleType = Object.CalculationScaleType;
	FillParameters.GoodsIndicator = GoodsIndicator;
	FillParameters.Products = CurrentData.Products;
	FillParameters.Characteristic = CurrentData.Characteristic;
	FillParameters.ItemVariantsAreUsed = CurrentData.ItemVariantsAreUsed;
	
	RebatesClientServer.SaveAnalyticsOfProductLine(
		DimensionProductLines_2, FillParameters);
	
EndProcedure

// Parameters:
//  AnalyticsOfGoodsLineBeingModified - See RebatesClientServer.StructureOfSavedProductLine
//
&AtServer
Procedure UpdateGoodsRowRangesByGoods(AnalyticsOfGoodsLineBeingModified)
	
	RebatesServer.UpdateGoodsRowRangesByGoods(
		Object,
		AnalyticsOfGoodsLineBeingModified.Products,
		AnalyticsOfGoodsLineBeingModified.Characteristic);
	
EndProcedure

&AtServer
Procedure ArrangeGoodsByRangeAtServer()
	
	If Not RebatesClientServer.ThisIsNumberByRanges(Object.CalculationScaleType, GoodsIndicator)
	 Or Object.Goods.Count() = 0 Then
		Return;
	EndIf;
	Columns = "Products, Characteristic, CountPlan, InitialString Desc";
	Object.Goods.Sort(Columns, New CompareValues);
	
EndProcedure

&AtServer
Procedure ArrangePropertyValuesByRangeAtServer()

	If Not RebatesClientServer.ThisIsNumberByRanges(Object.CalculationScaleType, GoodsIndicator)
	 Or Object.ProductProperties_.Count() = 0 Then
		Return;
	EndIf;
	Columns = "PropertyValue, CountPlan, InitialString Desc";
	Object.ProductProperties_.Sort(Columns, New CompareValues);
	
EndProcedure

#EndRegion

#Region StandardSubsystems_PlugInCommands

// StandardSubsystems.AttachableCommands

// The Attachable one continues to execute the Commands on the server.
// 
// Parameters:
//  ExecutionParameters - Structure -
//  AdditionalParameters - Structure -
//
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region StandardSubsystems_Properties

// StandardSubsystems.Properties
&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
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

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_ValidOnDate" Then
		ValidOnDateOnChange(Items.ValidOnDate);
	ElsIf Item.Name = "sh_ShamsiInput_ValidTo" Then
		ValidToOnChange(Items.ValidTo);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
