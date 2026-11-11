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
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If ExchangePlans.MasterNode() <> Undefined Then
		
		ReadOnly = True;
		
	EndIf;
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnCreatReadAtServer();
		
	EndIf;
	
	SetConditionalAppearance();
	SetHeader();
	SetAvailabilityOfContractField();
	
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
	SetHeader();
	FillInAttributesOfCompositionAccordingToCondition();
	SetSettingsByStatus();
	FillInServiceDataByAgreement();
	SetCurrentProviderDataPageAfterRecording();
	SetAvailabilityOfContractField();
	UpdateCalculationsBasedOnTermsOfRebatesAreClosed();
	UpdateSettlementStatuses();
	
	RebatesClientServer.GenerateNamesOfRangesOfCalculationScales(ThisObject);
	RebatesServer.UpdateRowRangesOfAllGoods(Object, GoodsIndicator);
	RebatesServer.UpdateRowRangesOfAllProperties(Object, GoodsIndicator);
	
	ConfigureDependentFormElementsOnServer();
	
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
	
	If Object.Status = PredefinedValue("Enum.RebatesDocumentStatuses.Approved") Then
		
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
	
	If Object.BonusType = PredefinedValue("Enum.VendorRebateTypes.Balance")
	   And Not ValueIsFilled(Object.DateOfRemainingGoods)
	   And Object.AccrueImmediately Then
		
		Object.DateOfRemainingGoods = Object.Date;
		
	EndIf;
	
	If Object.AccrueImmediately
	   And Object.BonusType = PredefinedValue("Enum.VendorRebateTypes.Balance") Then
		
		DisplayBasement = True;
		TitleOfFillInCommand = NStr("vi = 'Điền số lượng';
									|ru = 'Заполнить количество';
									|en = 'Fill in quantity'; fa = 'Fill in quantity';
									|it = 'Заполнить количество';
									|pl = 'Fill in quantity';
									|tr = 'Miktarı doldur'");
		TitleGoodsQuantityPlan = NStr("vi = 'Số lượng';
										|ru = 'Количество';
										|en = 'Quantity'; fa = 'مقدار';
										|it = 'Количество';
										|pl = 'Quantity';
										|tr = 'Miktar'");
		Object.Warehouses.Clear();
		Object.SelectionOfWarehouses_ = PredefinedValue("Enum.RebatesLists.All");
		
		For Each TSRow In Object.Goods Do
		
			TSRow.AmountBonus = TSRow.CountPlan * TSRow.BonusPerUnit;
		
		EndDo;
		
	Else
		
		DisplayBasement = False;
		TitleGoodsQuantityPlan = NStr("vi = 'Số lượng, dự tính';
										|ru = 'Кол-во, план';
										|en = 'Quantity, plan'; fa = 'مقدار، برنامه';
										|it = 'Кол-во, план';
										|pl = 'Quantity, plan';
										|tr = 'Miktar, plan'");
		TitleOfFillInCommand = NStr("vi = 'Điền số lượng, dự tính...';
									|ru = 'Заполнить кол-во, план...';
									|en = 'Fill in quantity, plan...'; fa = 'تکمیل مقدار، برنامه...';
									|it = 'Заполнить кол-во, план...';
									|pl = 'Fill in quantity, plan...';
									|tr = 'Miktar, plan kısmını doldur...'");
		
		For Each TSRow In Object.Goods Do
		
			TSRow.AmountBonus = 0;
		
		EndDo;
	
	EndIf;
	
	Items.Goods.Footer = DisplayBasement;
	Items.GoodsCountPlan.Title = TitleGoodsQuantityPlan;
	Items.GoodsFillInQuantityPlan.Title = TitleOfFillInCommand;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	ConfigureDependentFormElements("AccrueImmediately");
	
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
Procedure SelectionOfWarehouses_OnChange(Item)

	SelectionOfWarehouses_OnChangeServer();

EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	RebatesClientServer.GenerateNamesOfRangesOfCalculationScales(ThisObject);
	CurrencyOnChangeServer();
	
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
Procedure ModeMultipleVendorsOnChange(Item)
	
	SetCurrentProviderDataPage();
	ConfigureDependentFormElements("ModeMultipleVendors");
	
EndProcedure

&AtClient
Procedure RestrictAccrualOverPlanOnChange(Item)
	
	ConfigureDependentFormElements("RestrictAccrualOverPlan");

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
Procedure CounterpartyStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	VendorData = SupplierDataToFillIn(ContractsAreUsed, Object);
	CounterpartyStartChoiceCompletion(VendorData, Item);
	
EndProcedure

&AtClient
Procedure  PartnerStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	VendorData = SupplierDataToFillIn(ContractsAreUsed, Object);
	PartnerStartChoiceCompletion(VendorData, Item);
	
EndProcedure

&AtClient
Procedure ContractStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	VendorData = SupplierDataToFillIn(ContractsAreUsed, Object);
	ContractStartChoiceCompletion(VendorData, Item);
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	VendorData = SupplierDataToFillIn(ContractsAreUsed, Object);
	TermsStartChoiceCompletion(VendorData, Item);
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	If CurrentCounterparty <> Object.Counterparty Then
		
		Object.Contract = PredefinedValue("Catalog.CounterpartyContracts.EmptyRef");
		CurrentCounterparty = Object.Counterparty;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	If CurPartner = Object.Partner Then
		
		Return;
		
	EndIf;
		
	If Not (Object.BonusType = PredefinedValue("Enum.VendorRebateTypes.Purchases")
			 And Object.Partner = PredefinedValue("Catalog.Partners.EmptyRef")) Then
	
		Object.Contract = PredefinedValue("Catalog.CounterpartyContracts.EmptyRef");
	
	EndIf;
	
	Object.Terms = PredefinedValue("Catalog.TermsOfPurchaseFromVendors.EmptyRef");
	ContractsAreUsed = True;
	CurPartner = Object.Partner;
	
	VendorData = SupplierDataToFillIn(ContractsAreUsed, Object);
	PartnerWhenChangesAreMadeOnServer(VendorData);
	
	Object.Counterparty = VendorData.Counterparty;
	Object.Partner = VendorData.Partner;
	Object.Contract = VendorData.Contract;
	Object.Terms = VendorData.Terms;
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	If ValueIsFilled(Object.Contract) Then
		
		VendorData = SupplierDataToFillIn(ContractsAreUsed, Object);
		AgreementWhenModifiedOnServer(VendorData);
		
		Object.Counterparty = VendorData.Counterparty;
		Object.Partner = VendorData.Partner;
		Object.Contract = VendorData.Contract;
		Object.Terms = VendorData.Terms;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	If ValueIsFilled(Object.Terms) Then
		
		VendorData = SupplierDataToFillIn(ContractsAreUsed, Object);
		ChangeAgreementOnServer(VendorData);
		
		Object.Counterparty = VendorData.Counterparty;
		Object.Partner = VendorData.Partner;
		Object.Contract = VendorData.Contract;
		Object.Terms = VendorData.Terms;
		
		ContractsAreUsed = VendorData.ContractsAreUsed;
		
	Else
		
		ContractsAreUsed = True;
		
	EndIf;
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"Contract",
		"ReadOnly",
		Not ContractsAreUsed);
	
EndProcedure

&AtClient
Procedure DecorationDecorationStateOfCalculations(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "OpenReport" Then
		
		FormParameters = New Structure;
		FormParameters.Insert("VariantKey", "StatementOnDeferredExpensedContextOfCondition");
		FormParameters.Insert("CommandParameter", Object.Ref);
		FormParameters.Insert("GenerateOnOpen", True);
		FormParameters.Insert("ReportOptionsCommandsVisibility", False);
		
		OpenForm("Report.VendorRebateStatement.Form", FormParameters, ThisObject, False);
		
	Else
		
		ClearMessages();
		CloseResumeCalculations(FormattedStringURL);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculationScaleTypeOnChange(Item)
	
	CalculationScaleTypeOnChangeServer();
	
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
	
	CurrentData = Items.Goods.CurrentData;
	
	If Object.AccrueImmediately
	   And Object.BonusType = PredefinedValue("Enum.VendorRebateTypes.Balance") Then
		
		CurrentData.AmountBonus = CurrentData.CountPlan * CurrentData.BonusPerUnit;
		
	EndIf;
	
	If RebatesClientServer.ThisIsNumberByRanges(Object.CalculationScaleType, GoodsIndicator) Then
		
		IDCurrentRow = CurrentData.GetID();
		ProductsQuantityPlanOnChangeServer(IDCurrentRow);
		
	EndIf;
	
	ChangedGoodsData = True
	
EndProcedure

&AtClient
Procedure GoodsBonusPerUnitOnChange(Item)

	If Object.AccrueImmediately
	   And Object.BonusType = PredefinedValue("Enum.VendorRebateTypes.Balance") Then
	
		CurrentData = Items.Goods.CurrentData;
		CurrentData.AmountBonus = CurrentData.CountPlan * CurrentData.BonusPerUnit;
	
	EndIf;

EndProcedure

&AtClient
Procedure GoodsAmountBonusOnChange(Item)

	If Object.AccrueImmediately
	   And Object.BonusType = PredefinedValue("Enum.VendorRebateTypes.Balance") Then
	
		CurrentData = Items.Goods.CurrentData;
	
		If CurrentData.CountPlan = 0 Then
			CurrentData.BonusPerUnit = CurrentData.AmountBonus;
		Else
			CurrentData.BonusPerUnit = Round(CurrentData.AmountBonus / CurrentData.CountPlan, 2);
		EndIf;
	
	EndIf;

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

#Region FormTableItemsEventHandlersVendors

&AtClient
Procedure VendorsBeforeDeleteRow(Item, Cancel)
	
	CurrentData = Items.Vendors.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.InitialString Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure VendorsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.Vendors.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If NewRow
	   And Not Copy Then
		
		CurrentData.ContractsAreUsed = True;
		
	EndIf;
	
	If Copy Then
		
		CurrentData.StartDateBeforeChange = Date(1, 1, 1);
		CurrentData.EndDateBeforeChange = Date(1, 1, 1);
		CurrentData.Canceled = False;
		CurrentData.InitialString = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure VendorsOnActivateRow(Item)
	
	CurrentData = Items.Vendors.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentCounterparty = CurrentData.Counterparty;
	CurPartner = CurrentData.Partner;
	
EndProcedure

&AtClient
Procedure VendorsCanceledOnChange(Item)
	
	CurrentData = Items.Vendors.CurrentData;
	
	If CurrentData.Canceled Then
		
		CurrentData.ValidOnDate = Date(1, 1, 1);
		CurrentData.ValidTo = Date(1, 1, 1);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure VendorsCounterpartyStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.Vendors.CurrentData;
	VendorData = SupplierDataToFillIn(CurrentData.ContractsAreUsed, CurrentData);
	CounterpartyStartChoiceCompletion(VendorData, Item);
	
EndProcedure

&AtClient
Procedure VendorsPartnerStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.Vendors.CurrentData;
	VendorData = SupplierDataToFillIn(CurrentData.ContractsAreUsed, CurrentData);
	PartnerStartChoiceCompletion(VendorData, Item);
	
EndProcedure

&AtClient
Procedure VendorsContractStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.Vendors.CurrentData;
	VendorData = SupplierDataToFillIn(CurrentData.ContractsAreUsed, CurrentData);
	ContractStartChoiceCompletion(VendorData, Item);
	
EndProcedure

&AtClient
Procedure VendorsTermsStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.Vendors.CurrentData;
	VendorData = SupplierDataToFillIn(CurrentData.ContractsAreUsed, CurrentData);
	TermsStartChoiceCompletion(VendorData, Item);
	
EndProcedure

&AtClient
Procedure VendorsCounterpartyOnChange(Item)
	
	CurrentData = Items.Vendors.CurrentData;
	
	If CurrentCounterparty <> CurrentData.Counterparty Then
		
		CurrentData.Contract = PredefinedValue("Catalog.CounterpartyContracts.EmptyRef");
		CurrentCounterparty = CurrentData.Counterparty;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure VendorsPartnerOnChange(Item)
	
	CurrentData = Items.Vendors.CurrentData;
	
	If CurPartner = CurrentData.Partner Then
		
		Return;
		
	EndIf;
		
	If Not (Object.BonusType = PredefinedValue("Enum.VendorRebateTypes.Purchases")
			 And CurrentData.Partner = PredefinedValue("Catalog.Partners.EmptyRef")) Then
		
		CurrentData.Contract = PredefinedValue("Catalog.CounterpartyContracts.EmptyRef");
		
	EndIf;
	
	CurrentData.Terms = PredefinedValue("Catalog.TermsOfPurchaseFromVendors.EmptyRef");
	CurrentData.ContractsAreUsed = True;
	CurPartner = CurrentData.Partner;
	
	VendorData = SupplierDataToFillIn(CurrentData.ContractsAreUsed, CurrentData);
	PartnerWhenChangesAreMadeOnServer(VendorData);
	FillPropertyValues(CurrentData, VendorData);
	
EndProcedure

&AtClient
Procedure VendorsTermsOnChange(Item)
	
	CurrentData = Items.Vendors.CurrentData;
	
	If ValueIsFilled(CurrentData.Terms) Then
		
		VendorData = SupplierDataToFillIn(CurrentData.ContractsAreUsed, CurrentData);
		ChangeAgreementOnServer(VendorData);
		FillPropertyValues(CurrentData, VendorData);
		
	Else
		
		CurrentData.ContractsAreUsed = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure VendorsContractOnChange(Item)
	
	CurrentData = Items.Vendors.CurrentData;
	
	If ValueIsFilled(CurrentData.Contract) Then
		
		VendorData = SupplierDataToFillIn(CurrentData.ContractsAreUsed, CurrentData);
		AgreementWhenModifiedOnServer(VendorData);
		FillPropertyValues(CurrentData, VendorData);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCustomerCounterparties

&AtClient
Procedure CustomerCounterpartiesBeforeDeleteRow(Item, Cancel)

	CurrentData = Items.CustomerCounterparties.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.InitialString Then
		Cancel = True;
	EndIf;

EndProcedure

&AtClient
Procedure CustomerCounterpartiesOnStartEdit(Item, NewRow, Copy)

	CurrentData = Items.CustomerCounterparties.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Copy Then
		
		CurrentData.StartDateBeforeChange = Date(1, 1, 1);
		CurrentData.EndDateBeforeChange = Date(1, 1, 1);
		CurrentData.Canceled = False;
		CurrentData.InitialString = False;
		
	EndIf;

EndProcedure

&AtClient
Procedure CustomerCounterpartiesCanceledOnChange(Item)

	CurrentData = Items.CustomerCounterparties.CurrentData;
	
	If CurrentData.Canceled Then
		
		CurrentData.ValidOnDate = Date(1, 1, 1);
		CurrentData.ValidTo = Date(1, 1, 1);
		
	EndIf;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersClientsCounterpartiesTIN

&AtClient
Procedure ClientsCounterpartiesTINBeforeDeleteRow(Item, Cancel)

	CurrentData = Items.ClientsCounterpartiesTIN.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.InitialString Then
		Cancel = True;
	EndIf;

EndProcedure

&AtClient
Procedure ClientsCounterpartiesTINOnStartEdit(Item, NewRow, Copy)

	CurrentData = Items.ClientsCounterpartiesTIN.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Copy Then
		
		CurrentData.StartDateBeforeChange = Date(1, 1, 1);
		CurrentData.EndDateBeforeChange = Date(1, 1, 1);
		CurrentData.Canceled = False;
		CurrentData.InitialString = False;
		
	EndIf;

EndProcedure

&AtClient
Procedure ClientsCounterpartiesTINCanceledOnChange(Item)

	CurrentData = Items.ClientsCounterpartiesTIN.CurrentData;
	
	If CurrentData.Canceled Then
		
		CurrentData.ValidOnDate = Date(1, 1, 1);
		CurrentData.ValidTo = Date(1, 1, 1);
		
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
	Value_Border = CurrentData.RangeFrom; // Number
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
Procedure ImportGoodsFromFile(Command)
	
	ClearMessages();
	
	ToDisplayPeriod = (Items.GoodsValidOnDate.Visible
					Or Items.GoodsValidTo.Visible);
	
	FieldDisplaySettings = New Structure;
	FieldDisplaySettings.Insert("Characteristic", UseItemVariants);
	FieldDisplaySettings.Insert("Period", ToDisplayPeriod);
	FieldDisplaySettings.Insert("CountPlan", Items.GoodsCountPlan.Visible);
	FieldDisplaySettings.Insert("BasePrice", Items.GoodsBasePrice.Visible);
	FieldDisplaySettings.Insert("Percent", Items.GoodsPercent.Visible);
	FieldDisplaySettings.Insert("AmountBonus", Items.GoodsAmountBonus.Visible);
	FieldDisplaySettings.Insert("BonusPerUnit", Items.GoodsBonusPerUnit.Visible);
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "ConditionsOfVendorRebates.Goods";
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
Procedure LoadGoodsSegmentsFromFile(Command)
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "ConditionsOfVendorRebates.GoodsSegments";
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
Procedure DownloadTINFromFile(Command)
	
	FieldDisplaySettings = New Structure;
	FieldDisplaySettings.Insert("Period", Items.ClientsCounterpartiesTINValidOnDate.Visible);
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "ConditionsOfVendorRebates.ClientsCounterpartiesTIN";
	ImportParameters.Title = NStr("vi = 'Kết nhập MST từ tệp';
									|ru = 'Загрузка ИНН из файла';
									|en = 'Import TIN from the file'; fa = 'Import TIN from the file';
									|it = 'Загрузка ИНН из файла';
									|pl = 'Import TIN from the file';
									|tr = 'Dosyadan VKN yükleme'");
	ImportParameters.TemplateColumns = DescriptionOfColumnsInTINTemplate(FieldDisplaySettings);
	AdditionalParameters = New Structure("FieldDisplaySettings", FieldDisplaySettings);
	ImportParameters.AdditionalParameters = AdditionalParameters;
	Notification = New CallbackDescription("DownloadCounterpartyTINFromFileCompletion", ThisObject);
	ImportDataFromFileClient.ShowImportForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure DownloadClientsCounterpartiesFromFile(Command)
	
	FieldDisplaySettings = New Structure;
	FieldDisplaySettings.Insert("Period", Items.CustomerCounterpartiesValidOnDate.Visible);
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "ConditionsOfVendorRebates.CustomerCounterparties";
	ImportParameters.Title = NStr("vi = 'Kết nhập đối tác từ tệp';
									|ru = 'Загрузка контрагентов из файла';
									|en = 'Import counterparties from the file'; fa = 'Import counterparties from the file';
									|it = 'Загрузка контрагентов из файла';
									|pl = 'Import counterparties from the file';
									|tr = 'Dosyadan cari hesapları yükleme'");
	ImportParameters.TemplateColumns = DescriptionOfColumnsInTemplateCounterparties(FieldDisplaySettings);
	AdditionalParameters = New Structure("FieldDisplaySettings", FieldDisplaySettings);
	ImportParameters.AdditionalParameters = AdditionalParameters;
	Notification = New CallbackDescription("DownloadCounterpartiesFromFileCompletion", ThisObject);
	ImportDataFromFileClient.ShowImportForm(ImportParameters, Notification);
	
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
				If Not RowOfGoods.Canceled
				   And Not RowOfGoods.InitialString Then
					
					RowOfGoods.Percent = Result;
					
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
Procedure ArrangeGoodsByRange(Command)
	
	ArrangeGoodsByRangeAtServer();
	
EndProcedure

&AtClient
Procedure ArrangePropertyValuesByRange(Command)
	
	ArrangePropertyValuesByRangeAtServer();
	
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
		ImportParameters.FullTabularSectionName = "ConditionsOfVendorRebates.ProductProperties_";
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
							|en = 'Import is only available for non-flexible types of item property'; fa = 'Import is only available for non-flexible types of item property';
							|it = 'Import is only available for non-flexible types of item property';
							|pl = 'Import is only available for non-flexible types of item property';
							|tr = 'İçe aktarma, sadece içeriği olmayan öğe özellik türleri için mümkündür'");
		CommonClient.MessageToUser(MessageText);
		
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
	RebatesClientServer.GenerateNamesOfRangesOfCalculationScales(ThisObject);
	RebatesClientServer.SetTitleOfCalculationScaleGroup(ThisObject);
	RebatesServer.UpdateRowRangesOfAllGoods(Object, GoodsIndicator);
	RebatesServer.UpdateRowRangesOfAllProperties(Object, GoodsIndicator);
	SetHeadersByCurrency();
	SetUnchangedFieldSettingsByType();
	
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
	UseContractsWithVendors = GetFunctionalOption("UseContractsWithVendors");
	UseTermsOfPurchases = GetFunctionalOption("UseTermsOfPurchases");
	UseSeveralWarehouses = GetFunctionalOption("UseSeveralWarehouses");
	
	CurrentCompany = Object.Organization;
	CurrentRebateKind = Object.RebateKind;
	CurrentCurrency = Object.Currency;
	CurrentCounterparty = Object.Counterparty;
	CurPartner = Object.Partner;
	
	SetSupplierInformationSettings();
	ContractsAreUsed = True;
	FillInServiceDataByAgreement();
	PeriodOfValidityOfSupplierSTermsBeforeChange();
	
	SetParticipantInformationSettings();
	SetGoodsDetailsSettings();
	SetWarehouseInformationSettings();
	FillInAttributesOfCompositionAccordingToCondition();
	
	SetSettingsByStatus();
	UpdateCalculationsBasedOnTermsOfRebatesAreClosed();
	UpdateSettlementStatuses();
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure SetSettingsByStatus()
	
	If Object.Ref.IsEmpty() Then
		RightsChangeAvailable = True;
	Else
		RightsChangeAvailable = AccessManagement.EditionAllowed(Object.Ref);
	EndIf;
	
	Allowed1Update = Documents.ConditionsOfVendorRebates.ChangeByStatusIsAllowed(Object.Status);
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
	
	Items.ModeMultipleVendors.ReadOnly = ReadOnly;
	
	If ReadOnly Then
		
		Items.Status.ChoiceList.Clear();
		Items.Status.ListChoiceMode = False;
		
	Else
		
		AllowedStatuses = Documents.ConditionsOfVendorRebates.AllowedInstallationStatus();
		
		If AllowedStatuses.Count() > 0 Then
			
			Items.Status.ChoiceList.LoadValues(AllowedStatuses);
			Items.Status.ListChoiceMode = True;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAttributesOfCompositionAccordingToCondition()
	
	If Object.Posted Then
		
		ConditionData = Documents.ConditionsOfVendorRebates.UpToDateData(Object.Ref);
		CompositionFixationIsAvailable =
			(ConditionData.ContentOfGoods = Enums.RebatesItems.ProductSegments
		 Or Not IsBlankString(ConditionData.ProductItemProperty));
		
		CompositionOfSegmentsIsFixed = ConditionData.RecordingIsCompleted;
		
	Else
		
		CompositionFixationIsAvailable = False;
		CompositionOfSegmentsIsFixed = False;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityOfCommandsToFixComposition(Form)
	
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

&AtServer
Procedure UpdateCalculationsBasedOnTermsOfRebatesAreClosed()
	
	PerformUpdates = True;
	If Not Object.Patch Then
		
		TermDocument = Object.Ref;
		PerformUpdates = Not Object.Ref.IsEmpty();
		
	Else
		
		TermDocument = Object.CorrectedDocument;
		
	EndIf;
	
	If PerformUpdates Then
		
		SettlementsUnderTermsOfRebatesAreClosed = 
			Documents.ConditionsOfVendorRebates.SettlementsUnderTermsOfRebatesAreClosed(TermDocument);
			
	EndIf;
		
EndProcedure

&AtServer
Procedure UpdateSettlementStatuses()
	
	OpenReport = "OpenReport";
	ResumeCloseCalculations = "";
	PerformUpdates = True;
	
	If Not Object.Patch Then
			
		TermDocument = Object.Ref;
		PerformUpdates = Not Object.Ref.IsEmpty();
		
	Else
		
		TermDocument = Object.CorrectedDocument;
		
	EndIf;
	
	If Not PerformUpdates Then
		
		Items.DecorationSettlementState.Visible = False;
		Return;
		
	EndIf;
	
	If SettlementsUnderTermsOfRebatesAreClosed Then
		
		TitleTemplate1 = NStr("vi = '<a href=""%1"">Tính toán</a> theo điều kiện điểm thưởng bị đóng <a href=""%2"">(cập nhật tính toán)</a>';
								|ru = '<a href=""%1"">Расчеты</a> по условиям бонусов закрыты <a href=""%2"">(возобновить расчеты)</a>';
								|en = '<a href=""%1"">Settlements</a> on the rebate conditions are closed<a href=""%2"">(resume settlements)</a>'; fa = '<a href=""%1"">Settlements</a> on the rebate conditions are closed<a href=""%2"">(resume settlements)</a>';
								|it = '<a href=""%1"">Расчеты</a> по условиям бонусов закрыты <a href=""%2"">(возобновить расчеты)</a>';
								|pl = '<a href=""%1"">Settlements</a> on the rebate conditions are closed<a href=""%2"">(resume settlements)</a>';
								|tr = 'Bonus şartları <a href=""%1"">muhasebeleri</a> kapatıldı <a href=""%2"">(muhasebeleri devam ettir)</a>'");
		ResumeCloseCalculations = "ResumeCalculations";
		
	Else
		
		SettlementStatus = Documents.ConditionsOfVendorRebates.StatusOfCalculationsOfConditionsDocument(TermDocument);
		
		If SettlementStatus.AccruedBonusesAreFullyActivated Then
			
			TitleTemplate1 = NStr("vi = '<a href=""%1"">Điểm thưởng đã tính</a>đã kích hoạt/ghi giảm đầy đủ <a href=""%2"">(xác nhận đóng hạch toán)</a>';
									|ru = '<a href=""%1"">Начисленные бонусы</a> полностью актированы/списаны <a href=""%2"">(подтвердить закрытие расчетов)</a>';
									|en = '<a href=""%1"">Accrued rebates</a> are fully activated/written off <a href=""%2"">(confirm settlement closing)</a>'; fa = '<a href=""%1"">Accrued rebates</a> are fully activated/written off <a href=""%2"">(confirm settlement closing)</a>';
									|it = '<a href=""%1"">Начисленные бонусы</a> полностью актированы/списаны <a href=""%2"">(подтвердить закрытие расчетов)</a>';
									|pl = '<a href=""%1"">Accrued rebates</a> are fully activated/written off <a href=""%2"">(confirm settlement closing)</a>';
									|tr = '<a href=""%1"">Tahakkuk edilen bonuslar</a> tamamen etkinleştirildi/silindi <a href=""%2"">(uzlaştırma kapanışını onayla)</a>'");
			
		ElsIf SettlementStatus.AccrualIsExpected Then
			
			TitleTemplate1 = NStr("vi = '<a href=""%1"">Dự tính</a> tính điểm thưởng <a href=""%2"">(đóng hạch toán)</a>';
									|ru = '<a href=""%1"">Ожидается</a> начисление бонусов <a href=""%2"">(закрыть расчеты)</a>';
									|en = '<a href=""%1"">Rebate accrual</a> is expected <a href=""%2"">(close settlements)</a>'; fa = '<a href=""%1"">Rebate accrual</a> is expected <a href=""%2"">(close settlements)</a>';
									|it = '<a href=""%1"">Ожидается</a> начисление бонусов <a href=""%2"">(закрыть расчеты)</a>';
									|pl = '<a href=""%1"">Rebate accrual</a> is expected <a href=""%2"">(close settlements)</a>';
									|tr = '<a href=""%1"">Beklenen</a> bonus tahakkuku <a href=""%2"">(muhasebeleri kapat)</a>'");
			
		ElsIf SettlementStatus.ActIsExpected Then
			
			TitleTemplate1 = NStr("vi = '<a href=""%1"">Dự tính</a> biên bản thưởng của nhà cung cấp <a href=""%2"">(đóng tính toán)</a>';
									|ru = '<a href=""%1"">Ожидается</a> акт премии от поставщика <a href=""%2"">(закрыть расчеты)</a>';
									|en = '<a href=""%1"">Expected</a> the vendor bonus certificate <a href=""%2"">(close settlements)</a>'; fa = '<a href=""%1"">Expected</a> the vendor bonus certificate <a href=""%2"">(close settlements)</a>';
									|it = '<a href=""%1"">Ожидается</a> акт премии от поставщика <a href=""%2"">(закрыть расчеты)</a>';
									|pl = '<a href=""%1"">Expected</a> the vendor bonus certificate <a href=""%2"">(close settlements)</a>';
									|tr = '<a href=""%1"">Beklenen</a> bonus tahakkuku eylemi <a href=""%2"">(muhasebeleri kapat)</a>'");
			
		ElsIf SettlementStatus.RepaymentIsMoreThanAccrual Then
			
			TitleTemplate1 = NStr("vi = '<a href=""%1"">Đã kích hoạt/đã ghi giảm</a> nhiều hơn đã tính <a href=""%2"">(đóng tính toán)</a>';
									|ru = '<a href=""%1"">Актировано/списано</a> больше, чем начислено <a href=""%2"">(закрыть расчеты)</a>';
									|en = '<a href=""%1"">Activated/written off</a> more than accrued <a href=""%2"">(close settlements)</a>'; fa = '<a href=""%1"">Activated/written off</a> more than accrued <a href=""%2"">(close settlements)</a>';
									|it = '<a href=""%1"">Актировано/списано</a> больше, чем начислено <a href=""%2"">(закрыть расчеты)</a>';
									|pl = '<a href=""%1"">Activated/written off</a> more than accrued <a href=""%2"">(close settlements)</a>';
									|tr = 'Tahakkuk ettirilenden daha fazla <a href=""%1"">aktifleştirilen/kayıttan düşülen</a> <a href=""%2"">(muhasebeyi kapat)</a>'");
			
		Else
			
			TitleTemplate1 = NStr("vi = '<a href=""%1"">Trạng thái hạch toán khác nhau</a> theo tiền tệ khác nhau <a href=""%2"">(đóng hạch toán)</a>';
									|ru = '<a href=""%1"">Разные состояния расчетов</a> по разным валютам <a href=""%2"">(закрыть расчеты)</a>';
									|en = '<a href=""%1"">Different settlement states</a> for different currencies <a href=""%2"">(close settlements)</a>'; fa = '<a href=""%1"">Different settlement states</a> for different currencies <a href=""%2"">(close settlements)</a>';
									|it = '<a href=""%1"">Разные состояния расчетов</a> по разным валютам <a href=""%2"">(закрыть расчеты)</a>';
									|pl = '<a href=""%1"">Different settlement states</a> for different currencies <a href=""%2"">(close settlements)</a>';
									|tr = '<a href=""%1"">Farklı para birimleri </a>için farklı muhasebe durumları <a href=""%2"">(muhasebeyi kapat)</a>'");
			
		EndIf;
		
		ResumeCloseCalculations = "CloseCalculations";
		ConditionsDocumentIsRegistered = SettlementStatus.ConditionsDocumentIsRegistered;
		Items.DecorationSettlementState.Visible = ConditionsDocumentIsRegistered;
		
	EndIf;
	
	TitleText = StringFunctionsClientServer.SubstituteParametersToString(
		TitleTemplate1,
		OpenReport,
		ResumeCloseCalculations);
	Items.DecorationSettlementState.Title = StringFunctions.FormattedString(TitleText);
	
EndProcedure

&AtServer
Procedure CloseResumeCalculations(Val CommandByLine)
	
	UpdateCalculationsBasedOnTermsOfRebatesAreClosed();
	
	CloseCalculations = (CommandByLine = "CloseCalculations");
	
	If CloseCalculations <> SettlementsUnderTermsOfRebatesAreClosed Then
		
		If Not Object.Patch Then
			TermDocument = Object.Ref;
		Else
			TermDocument = Object.CorrectedDocument;
		EndIf;
		
		TermsDocuments = New Array; // Array of DocumentRef.ConditionsOfVendorRebates
		TermsDocuments.Add(TermDocument);
		
		ResultOfStatusChange = InformationRegisters.CompletedConditionsOfVendorRebates.ChangeStatusOfCalculations(
			TermsDocuments,
			CloseCalculations);
		
		HasErrors = ResultOfStatusChange.HasErrors;
		ErrorInfo = ResultOfStatusChange.ErrorInfo;
		
		If HasErrors Then
			
			Common.MessageToUser(ErrorInfo, ThisObject);
			
		Else
			
			SettlementsUnderTermsOfRebatesAreClosed = Not SettlementsUnderTermsOfRebatesAreClosed;
			
		EndIf;
		
	EndIf;
	
	UpdateSettlementStatuses();
	
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
							|tr = '%1  sınır değeri zaten listede'");
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
	
	SetLayoutOfVendorsTable();
	SetLayoutOfCounterpartiesTable();
	ToEstablishDesignOfTableOfTINOfCounterpartiesOfClients();
	SetLayoutOfGoodsTable();
	SetLayoutOfItemPropertiesTable();
	RebatesServer.SetDesignOfCalculationScaleTable(ConditionalAppearance);
	
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
		Items.CustomerCounterparties,
		Items.CustomerCounterpartiesCanceled.Name);
	
	ItemsNames = New Array; // Array of String
	ItemsNames.Add(Items.CustomerCounterpartiesValidOnDate.Name);
	ItemsNames.Add(Items.CustomerCounterpartiesValidTo.Name);
	IssueCanceledLines(Items.CustomerCounterparties, ItemsNames);
	
	SetDesignOfSourceLinesCounterpartiesOfClients();
	
	SetConditionalAppearanceOfPeriod(
		Items.CustomerCounterparties,
		DataLayoutFieldStartDateInRow,
		DataLayoutFieldIsEndDateOfString);
	
	ToEstablishRegistrationOfCounterpartiesOfClientsCounterparty();
	
EndProcedure

&AtServer
Procedure ToEstablishRegistrationOfCounterpartiesOfClientsCounterparty()
	
	#Region RequiredFilling
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CustomerCounterpartiesCounterparty.Name);
	
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
									|tr = '<herhangi biri>'");
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CustomerCounterpartiesCounterparty.Name);
	
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
Procedure SetDesignOfSourceLinesCounterpartiesOfClients()
	
	DesignParameters = RebatesServer.NewParametersForDesignOfSourceLines();
	
	DesignParameters.SourceStringFields.Add(Items.CustomerCounterpartiesCounterparty.Name);
	
	DesignParameters.FieldsBeforeChanges.Add(Items.CustomerCounterpartiesStartDateBeforeChange.Name);
	DesignParameters.FieldsBeforeChanges.Add(Items.CustomerCounterpartiesEndDateBeforeChange.Name);
	
	RebatesServer.ArrangeFieldsAccordingToOriginalLines(
		ConditionalAppearance,
		Items.CustomerCounterparties,
		DesignParameters);
	
EndProcedure

#EndRegion

#Region ConditionalAppearanceOfTINOfCounterpartiesOfClients

&AtServer
Procedure ToEstablishDesignOfTableOfTINOfCounterpartiesOfClients()
	
	DataLayoutFieldStartDateInRow = New DataCompositionField("BeginningOfActionLine");
	DataLayoutFieldIsEndDateOfString = New DataCompositionField("EndOfActionWithLine");
	
	OrdersServer.SetAppearanceOfCanceledLine(
		ConditionalAppearance,
		Items.ClientsCounterpartiesTIN,
		Items.ClientsCounterpartiesTINCanceled.Name);
	
	ItemsNames = New Array; // Array of String
	ItemsNames.Add(Items.ClientsCounterpartiesTINValidOnDate.Name);
	ItemsNames.Add(Items.ClientsCounterpartiesTINValidTo.Name);
	IssueCanceledLines(Items.ClientsCounterpartiesTIN, ItemsNames);
	
	SetDesignOfInitialLinesOfINNOfCounterpartiesOfClients();
	
	SetConditionalAppearanceOfPeriod(
		Items.ClientsCounterpartiesTIN,
		DataLayoutFieldStartDateInRow,
		DataLayoutFieldIsEndDateOfString);
	
EndProcedure

&AtServer
Procedure SetDesignOfInitialLinesOfINNOfCounterpartiesOfClients()
	
	DesignParameters = RebatesServer.NewParametersForDesignOfSourceLines();
	
	DesignParameters.SourceStringFields.Add(Items.ClientsCounterpartiesTINTIN.Name);
	
	DesignParameters.FieldsBeforeChanges.Add(Items.ClientsCounterpartiesTINStartDateBeforeChange.Name);
	DesignParameters.FieldsBeforeChanges.Add(Items.ClientsCounterpartiesTINEndDateBeforeChange.Name);
	
	RebatesServer.ArrangeFieldsAccordingToOriginalLines(
		ConditionalAppearance,
		Items.ClientsCounterpartiesTIN,
		DesignParameters);
	
EndProcedure

#EndRegion

#Region SetDesignOfGoods

&AtServer
Procedure SetLayoutOfGoodsTable()
	
	DataLayoutFieldStartDateInRow = New DataCompositionField("BeginningOfActionLine");
	DataLayoutFieldIsEndDateOfString = New DataCompositionField("EndOfActionWithLine");
	
	RebatesServer.SetLayoutOfItemsTableCharacteristics(ThisObject, True);
	
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
	FieldBonusPerUnit = TableName + "BonusPerUnit";
	
	DesignParameters.SourceStringFields.Add(ProductsField);
	DesignParameters.SourceStringFields.Add(CharacteristicField);
	DesignParameters.SourceStringFields.Add(NumberFieldPlan);
	DesignParameters.SourceStringFields.Add(BasePriceField);
	DesignParameters.SourceStringFields.Add(PercentageField);
	DesignParameters.SourceStringFields.Add(FieldBonusPerUnit);
	
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

#Region ConditionalAppearanceSuppliers

&AtServer
Procedure SetLayoutOfVendorsTable()
	
	DataLayoutFieldStartDateInRow = New DataCompositionField("BeginningOfActionLine");
	DataLayoutFieldIsEndDateOfString = New DataCompositionField("EndOfActionWithLine");
	
	OrdersServer.SetAppearanceOfCanceledLine(
		ConditionalAppearance,
		Items.Vendors,
		Items.VendorsCanceled.Name);
	
	ItemsNames = New Array; // Array of String
	ItemsNames.Add(Items.VendorsValidOnDate.Name);
	ItemsNames.Add(Items.VendorsValidTo.Name);
	IssueCanceledLines(Items.Vendors, ItemsNames);
	
	SetDesignOfSourceLinesVendors();
	
	SetConditionalAppearanceOfPeriod(
		Items.Vendors,
		DataLayoutFieldStartDateInRow,
		DataLayoutFieldIsEndDateOfString);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("VendorsContract");
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.Vendors.Terms");
	Filter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.Vendors.ContractsAreUsed");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtServer
Procedure SetDesignOfSourceLinesVendors()
	
	DesignParameters = RebatesServer.NewParametersForDesignOfSourceLines();
	
	DesignParameters.SourceStringFields.Add(Items.VendorsCounterparty.Name);
	DesignParameters.SourceStringFields.Add(Items.VendorsPartner.Name);
	DesignParameters.SourceStringFields.Add(Items.VendorsContract.Name);
	DesignParameters.SourceStringFields.Add(Items.VendorsTerms.Name);
	
	DesignParameters.FieldsBeforeChanges.Add(Items.VendorsStartDateBeforeChange.Name);
	DesignParameters.FieldsBeforeChanges.Add(Items.VendorsEndDateBeforeChange.Name);
	
	RebatesServer.ArrangeFieldsAccordingToOriginalLines(
		ConditionalAppearance,
		Items.Vendors,
		DesignParameters);
	
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
	
	If Object.Organization.IsEmpty()
	 Or Object.Currency.IsEmpty()
	 Or BaseOfCalculation = Enums.RebateCalculationBases.PurchaseAmountLocalAccounting
	 Or BaseOfCalculation = Enums.RebateCalculationBases.RevenueLocalAccounting Then
		
		DetermineDocumentCurrency();
		
	EndIf;
	
	SetHeadersByCurrency();
	UpdateSupplierContractAgreementsAccordingToHeaderData();
	SetAvailabilityOfContractField();
	ConfigureDependentFormElementsOnServer("Organization");
	
EndProcedure

&AtServer
Procedure RebateKindOnChangeServer()
	
	FillInRebateKind();
	SetHeadersByCurrency();
	UpdateSupplierContractAgreementsAccordingToHeaderData();
	SetAvailabilityOfContractField();
	SetUnchangedFieldSettingsByType();
	
	FilterPartiesOnChangeServer(False);
	FilterOfProducts_OnChangeServer(False);
	SelectionOfWarehouses_OnChangeServer(False);
	SetAvailableListOfTimeFenceAccruals(ThisObject);
	
	If Object.BonusType = Enums.VendorRebateTypes.Balance Then
		
		Object.SelectionOfWarehouses_ = Enums.RebatesLists.All;
		Object.ValidOnDate = Date(1, 1, 1);
		Object.ValidTo = Date(1, 1, 1);
		
	Else
		
		Object.SelectionOfWarehouses_ = Enums.RebatesLists.EmptyRef();
		Object.DateOfRemainingGoods = Date(1, 1, 1);
		
	EndIf;
	
	If Object.BonusType <> Enums.VendorRebateTypes.Purchases Then
		
		Object.Vendors.Clear();
		Object.ModeMultipleVendors = False;
		Object.Terms = Catalogs.TermsOfPurchaseFromVendors.EmptyRef();
		
	EndIf;
	
	If GoodsIndicator <> Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum Then
		
		Object.SumPlan = 0;
		
	EndIf;
	
	If GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.NotUsed Then
		
		Object.BonusPercent = 0;
		Object.RestrictAccrualOverPlan = False;
		
	EndIf;
	
	If GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum Then
		
		Object.BonusPercent = 0;
		
	EndIf;
	
	If Object.WithoutCalculation Then
		
		For Each ContractorsLine In Object.CustomerCounterparties Do
			
			ContractorsLine.ValidOnDate = Date(1, 1, 1);
			ContractorsLine.ValidTo = Date(1, 1, 1);
			
		EndDo;
		
		Object.ClientsCounterpartiesTIN.Clear();
		Object.Goods.Clear();
		Object.GoodsSegments.Clear();
		Object.Warehouses.Clear();
		Object.Vendors.Clear();
		
	Else
		
		Object.AccrueImmediately = False;
		
	EndIf;
	
	Object.AmountBonus = 0;
	Items.Goods.Footer = (Object.AccrueImmediately
		And Object.BonusType = PredefinedValue("Enum.VendorRebateTypes.Balance"));
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure FilterPartiesOnChangeServer(Val ConfigureDependentElements = True)
	
	SetParticipantInformationSettings();
	
	ParametersOfParticipants = Documents.ConditionsOfVendorRebates.ParametersForClearingParticipantsAttributes();
	ParametersOfParticipants.PartyList = PartyList;
	ParametersOfParticipants.FilterParties = Object.FilterParties;
	Documents.ConditionsOfVendorRebates.ClearUnusedDetailsOfParticipants(Object, ParametersOfParticipants);
	
	If ConfigureDependentElements Then
		
		ConfigureDependentFormElementsOnServer("FilterParties");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FilterOfProducts_OnChangeServer(Val ConfigureDependentElements = True)
	
	SetGoodsDetailsSettings();
	
	GoodsParameters = Documents.ConditionsOfVendorRebates.ParametersForClearingGoodsAttributes();
	GoodsParameters.ContentOfGoods = ContentOfGoods;
	GoodsParameters.FilterOfProducts_ = Object.FilterOfProducts_;
	GoodsParameters.GoodsIndicator = GoodsIndicator;
	GoodsParameters.BaseOfCalculation = BaseOfCalculation;
	GoodsParameters.BonusType = Object.BonusType;
	GoodsParameters.AccrueImmediately = Object.AccrueImmediately;
	Documents.ConditionsOfVendorRebates.ClearUnusedGoodsDetails(Object, GoodsParameters);
	
	If ConfigureDependentElements Then
		
		ConfigureDependentFormElementsOnServer("FilterOfProducts_");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SelectionOfWarehouses_OnChangeServer(Val ConfigureDependentElements = True)
	
	WarehousesParameters = Documents.ConditionsOfVendorRebates.ParametersForClearingWarehouseAttributes();
	WarehousesParameters.SelectionOfWarehouses_ = Object.SelectionOfWarehouses_;
	Documents.ConditionsOfVendorRebates.ClearUnusedAttributesOfWarehouses(Object, WarehousesParameters);
	
	SetWarehouseInformationSettings();
	
	If ConfigureDependentElements Then
		
		ConfigureDependentFormElementsOnServer("SelectionOfWarehouses_");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer()
	
	SetHeadersByCurrency();
	
	If CurrentCurrency <> Object.Currency Then
		
		UpdateSupplierContractAgreementsAccordingToHeaderData();
		
	EndIf;
	
	If Not Object.ModeMultipleVendors Then
		
		CommonClientServer.SetFormItemProperty(
			Items,
			"Contract",
			"ReadOnly",
			Not ContractsAreUsed);
		
	EndIf;
	
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
	
	ConfigureDependentFormElements("Status");
	
EndProcedure

&AtClient
Async Procedure FixCompositionOfDocument()
	
	UpdateDataBeforeFixingComposition();
	If Not ThereIsAdjustmentOnApproval
	   And Not CompositionOfSegmentsIsFixed Then
		
		QueryText = NStr("vi = 'Ấn định thành phần của chứng từ?';
						|ru = 'Зафиксировать состав документа?';
						|en = 'Do you want to record the document?'; fa = 'Do you want to record the document?';
						|it = 'Do you want to record the document?';
						|pl = 'Do you want to record the document?';
						|tr = 'Belgenin içeriği sabitlensin mi?'");
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
			
			MessageText = NStr("vi = 'Không thể ấn định thành phần phân khúc: đã nhập điều chỉnh trong trạng thái ""Cần thống nhất"".';
								|ru = 'Невозможно зафиксировать состав документа: введена корректировка в статусе ""На согласовании"".';
								|en = 'Cannot record the document: an adjustment is registered in the ""Pending approval"" status.'; fa = 'Cannot record the document: an adjustment is registered in the ""Pending approval"" status.';
								|it = 'Cannot record the document: an adjustment is registered in the ""Pending approval"" status.';
								|pl = 'Cannot record the document: an adjustment is registered in the ""Pending approval"" status.';
								|tr = 'Belge içeriği içeriği sabitlenemiyor: ""Onay bekliyor"" durumunda düzeltme yapıldı.'");
			CommonClient.MessageToUser(MessageText);
			
		EndIf;
		
		SetAvailabilityOfCommandsToFixComposition(ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Async Procedure CancelFixingCompositionOfDocument()
	
	UpdateDataBeforeCancelingFixationOfComposition();
	If Not ThereAreAccruals
	   And CompositionOfSegmentsIsFixed Then
		
		QueryText = NStr("vi = 'Hủy ấn định thành phần?';
						|ru = 'Отменить фиксацию состава документа?';
						|en = 'Do you want to cancel document recording?'; fa = 'Do you want to cancel document recording?';
						|it = 'Do you want to cancel document recording?';
						|pl = 'Do you want to cancel document recording?';
						|tr = 'Belge içeriğinin sabitlenmesi iptal edilsin mi?'");
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
		
		SetAvailabilityOfCommandsToFixComposition(ThisObject);
		
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
	SetAvailabilityOfCommandsToFixComposition(ThisObject);
	
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
	
	SetAvailabilityOfCommandsToFixComposition(ThisObject);
	ConfigureDependentFormElements();
	
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
	SetAvailabilityOfCommandsToFixComposition(ThisObject);
	
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
	FormAttributes.Insert("BaseOfCalculation");
	FormAttributes.Insert("ContentOfGoods");
	FormAttributes.Insert("PartyList");
	FormAttributes.Insert("ThereAreAccruals");
	FormAttributes.Insert("ThereIsRightToChangeURB");
	FormAttributes.Insert("CompositionFixationIsAvailable");
	FormAttributes.Insert("CompositionOfSegmentsIsFixed");
	FormAttributes.Insert("ContractsAreUsed");
	FormAttributes.Insert("UseSeveralWarehouses");
	
	FillPropertyValues(FormAttributes, Form);
	
	Return FormAttributes;
	
EndFunction

&AtServer
Procedure SetUnchangedFieldSettingsByType()
	
	// Composition of the product selection list
	FilterParameters = RebatesClientServer.NewParametersForAvailableGoodsSelections();
	FilterParameters.WithoutCalculation = Object.WithoutCalculation;
	FilterParameters.GoodsIndicator = GoodsIndicator;
	FilterParameters.BaseOfCalculation = BaseOfCalculation;
	FilterParameters.ContentOfGoods = ContentOfGoods;
	FilterParameters.BonusType = Object.BonusType;
	
	ChoiceArray = RebatesClientServer.AvailableListSelectionOfGoods(FilterParameters);
	Items.FilterOfProducts_.ChoiceList.LoadValues(ChoiceArray);
	RebatesClientServer.CheckSetValueOfSelectionList(Object, "FilterOfProducts_", ChoiceArray);
	
	// Composition of the list of selection of participants
	NewParameters = RebatesClientServer.NewParametersOfAvailableSelectionsOfParticipants();
	NewParameters.WithoutCalculation = Object.WithoutCalculation;
	NewParameters.PartyList = PartyList;
	
	ChoiceArray = RebatesClientServer.AvailableListOfSelectionOfParticipants(NewParameters);
	Items.FilterParties.ChoiceList.LoadValues(ChoiceArray);
	RebatesClientServer.CheckSetValueOfSelectionList(Object, "FilterParties", ChoiceArray);
	
	SetGoodsDetailsSettings();
	
	TitleGoodsQuantityPlan = NStr("vi = 'Số lượng, dự tính';
									|ru = 'Кол-во, план';
									|en = 'Quantity, plan'; fa = 'مقدار، برنامه';
									|it = 'Кол-во, план';
									|pl = 'Quantity, plan';
									|tr = 'Miktar, plan'");
	TitleOfFillInCommand = NStr("vi = 'Điền số lượng, dự tính...';
								|ru = 'Заполнить кол-во, план...';
								|en = 'Fill in quantity, plan...'; fa = 'تکمیل مقدار، برنامه...';
								|it = 'Заполнить кол-во, план...';
								|pl = 'Fill in quantity, plan...';
								|tr = 'Miktar, plan kısmını doldur...'");
	
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
		
	ElsIf BaseOfCalculation = Enums.RebateCalculationBases.RevenueBasePrices
		  Or BaseOfCalculation = Enums.RebateCalculationBases.PurchaseAmountBasePrices Then
		
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
	
	If Object.BonusType = Enums.VendorRebateTypes.Balance
	   And Object.AccrueImmediately Then
		
		TitleOfFillInCommand = NStr("vi = 'Điền số lượng';
									|ru = 'Заполнить количество';
									|en = 'Fill in quantity'; fa = 'Fill in quantity';
									|it = 'Заполнить количество';
									|pl = 'Fill in quantity';
									|tr = 'Miktarı doldur'");
		TitleGoodsQuantityPlan = NStr("vi = 'Số lượng';
										|ru = 'Количество';
										|en = 'Quantity'; fa = 'مقدار';
										|it = 'Количество';
										|pl = 'Quantity';
										|tr = 'Miktar'");
		
	EndIf;
	
	Items.GoodsCountPlan.Title = TitleGoodsQuantityPlan;
	Items.GoodsFillInQuantityPlan.Title = TitleOfFillInCommand;
	Items.Currency.Title = CurrencyHeader_3;
	
EndProcedure

&AtServer
Procedure SetParticipantInformationSettings()
	
	FieldTitle = "";
	PageName = "";
	PageHeader = "";
	
	If PartyList = Enums.RebatesParticipants.Counterparties Then
		
		FieldTitle = NStr("vi = 'Đối tác
							 |khách hàng';
							 |ru = 'Контрагенты
							 |клиентов';
							 |en = 'Customers''
							 |counterparties'; fa = 'Customers''
							 |counterparties';
							 |it = 'Контрагенты
							 |клиентов';
							 |pl = 'Customers''
							 |counterparties';
							 |tr = 'Müşteri
							 |cari hesapları'");
		PageHeader = RebatesClientServer.PageTitleBySettings(
			PartyList, Object.FilterParties, True);
		PageName = Items.CustomerCounterpartiesPage.Name;
		
	ElsIf PartyList = Enums.RebatesParticipants.TIN Then
		
		FieldTitle = NStr("vi = 'MST khách hàng';
							|ru = 'ИНН клиентов';
							|en = 'Customer TIN'; fa = 'Customer TIN';
							|it = 'ИНН клиентов';
							|pl = 'Customer TIN';
							|tr = 'Müşteri VKN''si'");
		PageHeader = RebatesClientServer.PageTitleBySettings(
			PartyList, Object.FilterParties, True);
		PageName = Items.ClientContractorsTINPage.Name;
		
	Else
		
		FieldTitle = NStr("vi = 'Người tham gia';
							|ru = 'Участники';
							|en = 'Parties'; fa = 'طرفین';
							|it = 'Участники';
							|pl = 'Parties';
							|tr = 'Üyeler'");
		
	EndIf;
	
	CommonClientServer.SetFormItemProperty(
		Items, Items.FilterParties.Name, "Title", FieldTitle);
	CommonClientServer.SetFormItemProperty(
		Items, PageName, "Title", PageHeader);
	
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
		
	ElsIf ContentOfGoods =  Enums.RebatesItems.ProductSegments Then
		
		PageHeader = RebatesClientServer.PageTitleBySettings(ContentOfGoods, Object.FilterOfProducts_);
		CommonClientServer.SetFormItemProperty(
			Items, Items.GoodsSegmentsPage.Name, "Title", PageHeader);
		
	ElsIf ContentOfGoods =  Enums.RebatesItems.ProductItemProperty Then
		
		PageHeader = RebatesClientServer.PageTitleBySettings(ContentOfGoods, Object.FilterOfProducts_);
		CommonClientServer.SetFormItemProperty(
			Items, Items.ItemPropertiesPage.Name, "Title", PageHeader);
		CommonClientServer.SetFormItemProperty(
			Items, Items.ProductProperties_PropertyValue.Name, "Title", ProductItemPropertyPresentation);
		
	EndIf;
	
	Items.Goods.Footer = (Object.AccrueImmediately
		And Object.BonusType = PredefinedValue("Enum.VendorRebateTypes.Balance"));
	
EndProcedure

&AtServer
Procedure SetWarehouseInformationSettings()
	
	PageHeader = RebatesClientServer.PageTitleWarehouses(Object.SelectionOfWarehouses_);
	
	CommonClientServer.SetFormItemProperty(
			Items, Items.WarehousesPage.Name, "Title", PageHeader);
	
EndProcedure

&AtServer
Procedure SetSupplierInformationSettings()
	
	If Object.BonusType = Enums.VendorRebateTypes.Purchases Then
		
		If Object.ModeMultipleVendors Then
			
			Items.VendorDataPages.CurrentPage = Items.VendorsDataPage;
			
		Else
			
			Items.VendorDataPages.CurrentPage = Items.VendorDataPage;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetCurrentProviderDataPage()
	
	If Object.BonusType <> PredefinedValue("Enum.VendorRebateTypes.Purchases") Then
		Return;
	EndIf;
	
	If Not Object.ModeMultipleVendors Then
		
		SwitchingIsAllowed = ModeSwitchingIsAllowed();
		
		If Not SwitchingIsAllowed Then
			
			Object.ModeMultipleVendors = True;
			
		Else
			
			Items.VendorDataPages.CurrentPage = Items.VendorDataPage;
			
			If Object.Vendors.Count() = 1 Then
				
				VendorString = Object.Vendors[0];
				ContractsAreUsed = VendorString.ContractsAreUsed;
				VendorData = SupplierDataToFillIn(ContractsAreUsed, VendorString);
				
			Else
				
				ContractsAreUsed = True;
				VendorData = SupplierDataToFillIn();
				
			EndIf;
			
			Object.Counterparty = VendorData.Counterparty;
			Object.Partner = VendorData.Partner;
			Object.Contract = VendorData.Contract;
			Object.Terms = VendorData.Terms;
			CurrentCounterparty = Object.Counterparty;
			CurPartner = Object.Partner;
			
			Object.Vendors.Clear(); 
			
			If Not Object.Patch Then
				
				CommonClientServer.SetFormItemProperty(
					Items,
					"Contract",
					"ReadOnly",
					Not ContractsAreUsed);
				
			EndIf;
			
		EndIf;
		
	Else
		
		If (ValueIsFilled(Object.Counterparty)
		 Or ValueIsFilled(Object.Partner)
		 Or ValueIsFilled(Object.Contract)
		 Or ValueIsFilled(Object.Terms)) Then
		
			VendorString = Object.Vendors.Add();
			VendorData = SupplierDataToFillIn(ContractsAreUsed, Object);
			FillPropertyValues(VendorString, VendorData);
			
			If Object.Patch  Then
				
				VendorString.InitialString = True;
				VendorString.StartDateBeforeChange = VendorStartOfActionBeforeChanges;
				VendorString.EndDateBeforeChange = VendorExpirationBeforeChanges;
				
			EndIf;
			
		EndIf;
		
		CurrentCounterparty = Object.Counterparty;
		CurPartner = Object.Partner;
		
		Items.VendorDataPages.CurrentPage = Items.VendorsDataPage;
		
	EndIf;
	
EndProcedure

&AtClient
Function ModeSwitchingIsAllowed()
	
	ClearMessages();
	
	If Object.Vendors.Count() = 0 Then
		
		SwitchingIsAllowed = True;
		
	ElsIf Object.Vendors.Count() > 1 Then
		
		MessageText = NStr("vi = 'Chuyển sang chế độ ""Không phân chia"" là không thể nếu có nhiều hơn một dòng được nhập vào dữ liệu của nhà cung cấp';
							|ru = 'Переключение в режим ""Без разбиения"" невозможно, если в данных поставщика введено более одной строки';
							|en = 'Cannot switch to ""Without split"" mode if more than one row is entered in the vendor data'; fa = 'Cannot switch to ""Without split"" mode if more than one row is entered in the vendor data';
							|it = 'Переключение в режим ""Без разбиения"" невозможно, если в данных поставщика введено более одной строки';
							|pl = 'Cannot switch to ""Without split"" mode if more than one row is entered in the vendor data';
							|tr = 'Eğer tedarikçi verilerinde birden fazla satır girilmiş ise, ""Bölünmesiz"" moduna geçilemez'");
		CommonClient.MessageToUser(MessageText,, "Vendors", "Object");
		SwitchingIsAllowed = False;
		
	Else
		
		CurrentRow = Object.Vendors[0];
		Field = CommonClientServer.PathToTabularSection(
			"Vendors", 1, "LineNumber");
		
		If CurrentRow.Canceled Then
			
			MessageText = NStr("vi = 'Chuyển sang chế độ ""Không phân chia"" là không thể, nếu đã hủy bỏ tất cả các dòng';
								|ru = 'Переключение в режим ""Без разбиения"" невозможно, если все строки отменены';
								|en = 'Cannot switch to ""Without split"" mode if all rows are canceled'; fa = 'Cannot switch to ""Without split"" mode if all rows are canceled';
								|it = 'Переключение в режим ""Без разбиения"" невозможно, если все строки отменены';
								|pl = 'Cannot switch to ""Without split"" mode if all rows are canceled';
								|tr = 'Eğer tüm satırlar iptal edilirse ""Bölünme olmadan"" moduna geçilemez'");
			CommonClient.MessageToUser(MessageText,, Field, "Object");
			SwitchingIsAllowed = False;
			
		Else
			
			DateEmpty = Date(1, 1, 1);
			If CurrentRow.ValidOnDate = DateEmpty Then
				CurrentStartDate = Object.ValidOnDate
			Else
				CurrentStartDate = CurrentRow.ValidOnDate;
			EndIf;
				
			If CurrentRow.ValidTo = DateEmpty Then
				CurrentEndDate = Object.ValidTo;
			Else
				CurrentEndDate = CurrentRow.ValidTo;
			EndIf;
			
			SwitchingIsAllowed = (CurrentStartDate = Object.ValidOnDate
				And CurrentEndDate = Object.ValidTo);
			If Not SwitchingIsAllowed Then
				
				MessageText = NStr("vi = 'Chuyển sang chế độ ""Không phân chia"" là không thể"", nếu kỳ hiệu lực trong dòng không khớp với kỳ hiệu lực của chứng từ';
									|ru = 'Переключение в режим ""Без разбиения"" невозможно, если период действия в строке не совпадает с периодом действия документа';
									|en = 'Cannot switch to ""Without split"" mode if the validity period in the row does not match the validity period of the document'; fa = 'Cannot switch to ""Without split"" mode if the validity period in the row does not match the validity period of the document';
									|it = 'Переключение в режим ""Без разбиения"" невозможно, если период действия в строке не совпадает с периодом действия документа';
									|pl = 'Cannot switch to ""Without split"" mode if the validity period in the row does not match the validity period of the document';
									|tr = 'Satırdaki geçerlilik süresi belgenin eylem süresi ile çakışmadığı sürece, ""Bölme olmadan"" moduna geçilemez'");
				CommonClient.MessageToUser(MessageText,, Field, "Object");
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return SwitchingIsAllowed;
	
EndFunction

&AtServer
Procedure SetCurrentProviderDataPageAfterRecording()
	
	If Object.BonusType <> PredefinedValue("Enum.VendorRebateTypes.Purchases") Then
		Return;
	EndIf;
	
	If Object.ModeMultipleVendors Then
		
		Items.VendorDataPages.CurrentPage = Items.VendorsDataPage;
		
	Else
		
		Items.VendorDataPages.CurrentPage = Items.VendorsDataPage;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

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
		AttributesArray.Add("BonusType");
		AttributesArray.Add("ConditionFrequency");
		AttributesArray.Add("AccrualFrequency");
		AttributesArray.Add("FilterOfProducts_");
		AttributesArray.Add("FilterParties");
		
	EndIf;
	
	AttributesArray.Add("GoodsIndicator");
	AttributesArray.Add("BaseOfCalculation");
	AttributesArray.Add("ContentOfGoods");
	AttributesArray.Add("PartyList");
	AttributesArray.Add("ProductItemProperty");
	
	KindAttributes = Common.ObjectAttributesValues(Object.RebateKind, AttributesArray);
	
	If Not OnlyCache Then
		
		Object.WithoutCalculation = KindAttributes.WithoutCalculation;
		If Not Object.WithoutCalculation Then
			
			Object.AccrueImmediately = False;
			
		EndIf;
		
		Object.BonusType = KindAttributes.BonusType;
		Object.ConditionFrequency = KindAttributes.ConditionFrequency;
		Object.AccrualFrequency = KindAttributes.AccrualFrequency;
		Object.FilterParties = KindAttributes.FilterParties;
		Object.FilterOfProducts_ = KindAttributes.FilterOfProducts_;
		Object.CalculationScaleType = 0;
		
	EndIf;
	
	GoodsIndicator = KindAttributes.GoodsIndicator;
	BaseOfCalculation = KindAttributes.BaseOfCalculation;
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
Procedure DetermineDocumentCurrency()
	
	IndicatorAmountOfSettlements = 
		(GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
		 And (BaseOfCalculation = Enums.RebateCalculationBases.RevenueARAPAccounting
		    Or BaseOfCalculation = Enums.RebateCalculationBases.PurchaseAmountARAPAccounting));
	
	If Not Object.Organization.IsEmpty()
	   And (BaseOfCalculation = Enums.RebateCalculationBases.PurchaseAmountLocalAccounting
		  Or BaseOfCalculation = Enums.RebateCalculationBases.RevenueLocalAccounting) Then
		
		Object.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		
	ElsIf Object.WithoutCalculation
		  Or Object.BonusType = Enums.VendorRebateTypes.Balance
		  Or (BaseOfCalculation <> Enums.RebateCalculationBases.RevenueARAPAccounting
		       And BaseOfCalculation <> Enums.RebateCalculationBases.PurchaseAmountARAPAccounting)
		  Or IndicatorAmountOfSettlements Then
		
		If Object.Currency.IsEmpty() Then
			Object.Currency = Catalogs.Currencies.GetDefaultCurrency();
		EndIf;
		
	Else
		
		Object.Currency = Catalogs.Currencies.EmptyRef();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetHeadersByCurrency()
	
	If Object.Currency.IsEmpty() Then
		NameOfCurrency = "";
	Else
		NameOfCurrency = Common.ObjectAttributeValue(Object.Currency, "Description");
	EndIf;
	
	#Region AmountBonus
	
	If Object.Currency.IsEmpty() Then
		
		TitleAmountBonus = NStr("vi = 'Thưởng, số tiền';
								|ru = 'Бонус, сумма';
								|en = 'Bonus, amount'; fa = 'Bonus, amount';
								|it = 'Бонус, сумма';
								|pl = 'Bonus, amount';
								|tr = 'Bonus, tutar'");
		TitleBonusPerUnit = NStr("vi = 'Thưởng cho đơn vị';
								|ru = 'Бонус за единицу';
								|en = 'Bonus per unit'; fa = 'پاداش به ازای هر واحد';
								|it = 'Бонус за единицу';
								|pl = 'Bonus per unit';
								|tr = 'Birim bonus'");
		
	Else
		
		TemplateBonusAmount = NStr("vi = 'Thưởng, số tiền (%1)';
									|ru = 'Бонус, сумма (%1)';
									|en = 'Bonus, amount (%1)'; fa = 'Bonus, amount (%1)';
									|it = 'Бонус, сумма (%1)';
									|pl = 'Bonus, amount (%1)';
									|tr = 'Bonus, tutar (%1)'");
		TitleAmountBonus = StringFunctionsClientServer.SubstituteParametersToString(
			TemplateBonusAmount,
			NameOfCurrency);
			
		TemplateBonusPerUnit = NStr("vi = 'Thưởng cho đơn vị (%1)';
									|ru = 'Бонус за единицу (%1)';
									|en = 'Bonus per unit (%1)'; fa = 'Bonus per unit (%1)';
									|it = 'Бонус за единицу (%1)';
									|pl = 'Bonus per unit (%1)';
									|tr = 'Birim bonus (%1)'");
		TitleBonusPerUnit = StringFunctionsClientServer.SubstituteParametersToString(
			TemplateBonusPerUnit,
			NameOfCurrency);
		
	EndIf;
	
	Items.GoodsAmountBonus.Title = TitleAmountBonus;
	Items.GoodsBonusPerUnit.Title = TitleBonusPerUnit;
	#EndRegion
	
	#Region BasePrice
	If BaseOfCalculation <> Enums.RebateCalculationBases.RevenueBasePrices
	   And BaseOfCalculation <> Enums.RebateCalculationBases.PurchaseAmountBasePrices
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
		TitleBasePrice = StringFunctionsClientServer.SubstituteParametersToString(
			BasicPriceTemplate,
			NameOfCurrency);
		
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
	FilterParameters.BonusType = Object.BonusType;
	
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
Procedure FillInSignOfAccruals()
	
	If Object.CorrectedDocument.IsEmpty() Then
		
		If Object.Ref.IsEmpty()
		 Or Object.AccrueImmediately Then
			
			ThereAreAccruals = False;
			
		Else
			
			MaxDate = RebatesServer.LimitOfSupplierCharges(Object.Ref);
			ThereAreAccruals = (MaxDate <> Date(1, 1, 1));
			
		EndIf;
		
	Else
		
		MaxDate = RebatesServer.LimitOfSupplierCharges(Object.CorrectedDocument);
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
	ConfigureDependentFormElementsOnServer();
	
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
	
	Form.SumOfPlanByLine = Format(Form.Object.SumPlan, "NFD=2;");
	
	AmountTemplate = "<%1>";
	Form.AmountOfPlanByLineIsUnchanged = StrTemplate(AmountTemplate, Form.SumOfPlanByLine);
	
EndProcedure

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
Procedure PeriodOfValidityOfSupplierSTermsBeforeChange()
	
	If Not Object.Patch
	   And Object.BonusType <> Enums.VendorRebateTypes.Purchases
	   And Not Object.ModeMultipleVendors Then
		
		Return;
		
	EndIf;
	
	Query = New Query;
	Query.SetParameter("TermDocument", Object.CorrectedDocument);
	Query.Text = 
	"SELECT
	|	VendorRebatesVendors.ValidOnDate,
	|	VendorRebatesVendors.ValidTo
	|FROM
	|	InformationRegister.VendorRebatesVendors AS VendorRebatesVendors
	|WHERE
	|	VendorRebatesVendors.TermDocument = &TermDocument";
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		
		Selection = Result.Select();
		Selection.Next();
		VendorStartOfActionBeforeChanges = Selection.ValidOnDate;
		VendorExpirationBeforeChanges = Selection.ValidTo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInGoodsQuantityPlanServer(Val Value, Val SelectedRows)
	
	TheseAreGoodsByRanges = RebatesClientServer.ThisIsNumberByRanges(Object.CalculationScaleType, GoodsIndicator);
	ArrayOfRowsToBeProcessed = New Array; // Array of FormDataCollectionItem
	RecalculateBonusAmount =
		(Object.BonusType = PredefinedValue("Enum.VendorRebateTypes.Balance")
		 And Object.AccrueImmediately);
	
	For Each SelectedRow In SelectedRows Do
		
		RowOfGoods = Object.Goods.FindByID(SelectedRow);
		If RowOfGoods.InitialString Then
			Continue;
		EndIf;
		
		RowOfGoods.CountPlan = Value;
		
		If RecalculateBonusAmount Then
			RowOfGoods.AmountBonus = RowOfGoods.CountPlan * RowOfGoods.BonusPerUnit;
		EndIf;
		
		If TheseAreGoodsByRanges Then
			ArrayOfRowsToBeProcessed.Add(RowOfGoods);
		EndIf;
		
	EndDo;
	
	If TheseAreGoodsByRanges Then
		
		ReadyForProcessing_ = Object.Goods.Unload(ArrayOfRowsToBeProcessed);
		RebatesServer.UpdateGoodsRowRangesByTable(Object, ReadyForProcessing_);
		
	EndIf;
	
EndProcedure

#Region EventHandlersOnChangesOfCounterpartiesPartnersVendorsAuxiliary

&AtServer
Procedure PartnerWhenChangesAreMadeOnServer(VendorData)
	
	If ValueIsFilled(VendorData.Partner) Then
		
		VendorData.Counterparty = CounterpartyByPartner(VendorData.Partner);
		
	EndIf;
	
	CurPartner = VendorData.Partner;
	CurrentCounterparty = VendorData.Counterparty;
	
	SetAvailabilityOfContractField();
	
EndProcedure

&AtServer
Procedure ChangeAgreementOnServer(VendorData)
	
	If Not ValueIsFilled(VendorData.Terms) Then
		
		Return;
		
	EndIf;
		
	Terms = VendorData.Terms;
	DetailsOfAgreement = "Counterparty, Partner, ContractsAreUsed";
	Attributes = Common.ObjectAttributesValues(Terms, DetailsOfAgreement);
	VendorData.Partner = Attributes.Partner;
	VendorData.ContractsAreUsed = Attributes.ContractsAreUsed;
	
	If ValueIsFilled(Attributes.Counterparty) Then
		
		VendorData.Counterparty = Attributes.Counterparty;
		
	EndIf;
	
	If Not VendorData.ContractsAreUsed Then
		
		VendorData.Contract = Catalogs.CounterpartyContracts.EmptyRef();
		
	EndIf;
	
	CurPartner = VendorData.Partner;
	CurrentCounterparty = VendorData.Counterparty;
	
EndProcedure

&AtServer
Procedure AgreementWhenModifiedOnServer(VendorData)
	
	If Not ValueIsFilled(VendorData.Contract) Then
		
		Return;
		
	EndIf;
		
	Contract = VendorData.Contract;
	Attributes = Common.ObjectAttributesValues(Contract, "Counterparty, Partner");
	VendorData.Partner = Attributes.Partner;
	VendorData.Counterparty = Attributes.Counterparty;
	
	CurPartner = VendorData.Partner;
	CurrentCounterparty = VendorData.Counterparty;
	
EndProcedure

// Parameters:
//  Partner - CatalogRef.Partners
// 
// Returns:
//  CatalogRef.Counterparties
//
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
	|	Counterparties.Ref AS Ref
	|FROM
	|	Catalog.Counterparties AS Counterparties
	|		LEFT JOIN Catalog.Partners AS Partners
	|		ON Counterparties.Partner = Partners.Parent
	|WHERE
	|	ISNULL(Partners.Ref, VALUE(Catalog.Partners.EmptyRef)) = &Partner
	|	AND ISNULL(Partners.Parent, VALUE(Catalog.Partners.EmptyRef)) <> VALUE(Catalog.Partners.EmptyRef)";
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

#EndRegion

#Region VendorData

&AtServer
Procedure SetAvailabilityOfContractField()
	
	If Object.ModeMultipleVendors
	 Or Object.Patch
	 Or Not UseContractsWithVendors Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.Terms) Then
		
		ContractsAreUsed = True;
		
	EndIf;
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"Contract",
		"ReadOnly",
		Not ContractsAreUsed);
	
EndProcedure

&AtClient
Procedure CounterpartyStartChoiceCompletion(VendorData, Item)
	
	FilterStructure1 = New Structure;
	If ValueIsFilled(VendorData.Partner) Then
		
		FilterStructure1.Insert("Partner", VendorData.Partner);
		
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterStructure1);
	FormParameters.Insert("CurrentRow", VendorData.Counterparty);
	
	OpenForm("Catalog.Counterparties.Form.ChoiceForm", FormParameters, Item);
	
EndProcedure

&AtClient
Procedure PartnerStartChoiceCompletion(VendorData, Item)
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Vendor", True);
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterStructure1);
	
	If ValueIsFilled(VendorData.Counterparty) Then
		
		FormParameters.Insert("Counterparty", VendorData.Counterparty);
		
	EndIf;
	
	FormParameters.Insert("CurrentRow", VendorData.Partner);
	
	OpenForm("Catalog.Partners.Form.ChoiceForm", FormParameters, Item);
	
EndProcedure

&AtClient
Procedure ContractStartChoiceCompletion(VendorData, Item)
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Organization", Object.Organization);
	FilterStructure1.Insert("DeletionMark", False);
	
	ContractTypes = RebatesClientServer.TypesOfProcurementContracts();
	FilterStructure1.Insert("ContractType", New FixedArray(ContractTypes));
	
	If ValueIsFilled(VendorData.Counterparty) Then
		
		FilterStructure1.Insert("Counterparty", VendorData.Counterparty);
		
	EndIf;
	
	If GoodsIndicator = PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.Sum")
	   And BaseOfCalculation = PredefinedValue("Enum.RebateCalculationBases.PurchaseAmountARAPAccounting") Then
		
		FilterStructure1.Insert("ARAPCurrency", Object.Currency);
		
	EndIf;
	
	If ValueIsFilled(VendorData.Partner) Then
		
		FilterStructure1.Insert("Partner", VendorData.Partner);
		
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterStructure1);
	
	FormParameters.Insert("CurrentRow", VendorData.Contract);
	
	OpenForm("Catalog.CounterpartyContracts.Form.ChoiceForm", FormParameters, Item);
	
EndProcedure

&AtClient
Procedure TermsStartChoiceCompletion(VendorData, Item)
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("DeletionMark", False);
	
	ArrayOfBusinessTransactions = RebatesClientServer.BusinessProcurementOperations();
	FilterStructure1.Insert("BusinessOperation", New FixedArray(ArrayOfBusinessTransactions));
	
	CompanyArray = New Array; // Array of CatalogRef.Companies
	CompanyArray.Add(Object.Organization);
	CompanyArray.Add(PredefinedValue("Catalog.Companies.EmptyRef"));
	FilterStructure1.Insert("Organization", New FixedArray(CompanyArray));
	
	If ValueIsFilled(VendorData.Counterparty) Then
		
		ArrayOfCounterparties = New Array; // Array of CatalogRef.Counterparties
		ArrayOfCounterparties.Add(VendorData.Counterparty);
		ArrayOfCounterparties.Add(PredefinedValue("Catalog.Counterparties.EmptyRef"));
		FilterStructure1.Insert("Counterparty", New FixedArray(ArrayOfCounterparties));
		
	EndIf;
	
	If ValueIsFilled(VendorData.Partner) Then
		
		FilterStructure1.Insert("Partner", VendorData.Partner);
		
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterStructure1);
	FormParameters.Insert("AllowSelectionOfInvalid", True);
	FormParameters.Insert("DocumentDate", Date(1, 1, 1)); // We do not limit the choice of agreements by period
	FormParameters.Insert("CurrentRow", VendorData.Terms);
	
	OpenForm("Catalog.TermsOfPurchaseFromVendors.Form.ChoiceForm", FormParameters, Item);
	
EndProcedure

// Parameters:
//  ContractsAreUsed - Boolean
//  SourceOfFilling - Data formelementcollection, data formstructure: See Document.ConditionsOfVendorRebates.Form.DocumentForm.Items.Vendors
//                     - See Document.ConditionsOfVendorRebates.Form.DocumentForm.Object
// 
// Returns:
//  Structure - Supplier Data To Fill In:
// * Counterparty - CatalogRef.Counterparties - 
// * Partner - CatalogRef.Partners - 
// * Contract - CatalogRef.CounterpartyContracts - 
// * Terms - CatalogRef.TermsOfPurchaseFromVendors - 
// * ContractsAreUsed - Boolean -
// 
&AtClientAtServerNoContext
Function SupplierDataToFillIn(ContractsAreUsed = True, SourceOfFilling = Undefined)
	
	Counterparty = PredefinedValue("Catalog.Counterparties.EmptyRef");
	Partner = PredefinedValue("Catalog.Partners.EmptyRef");
	Contract = PredefinedValue("Catalog.CounterpartyContracts.EmptyRef");
	Terms = PredefinedValue("Catalog.TermsOfPurchaseFromVendors.EmptyRef");
	
	VendorData = New Structure;
	VendorData.Insert("Counterparty", Counterparty);
	VendorData.Insert("Partner", Partner);
	VendorData.Insert("Contract", Contract);
	VendorData.Insert("Terms", Terms);
	VendorData.Insert("ContractsAreUsed", True);
	
	If SourceOfFilling <> Undefined Then
		
		VendorData.Counterparty = SourceOfFilling.Counterparty;
		VendorData.Partner = SourceOfFilling.Partner;
		VendorData.Contract = SourceOfFilling.Contract;
		VendorData.Terms = SourceOfFilling.Terms;
		VendorData.ContractsAreUsed = ContractsAreUsed;
		
	EndIf;
	
	Return VendorData;
	
EndFunction

&AtServer
Procedure FillInServiceDataByAgreement()
	
	If (Not ValueIsFilled(Object.Terms)
		  And Not Object.ModeMultipleVendors)
	 Or (Not Object.ModeMultipleVendors
		  And Object.Patch)
	 Or Not UseTermsOfPurchases Then
		
		Return;
		
	EndIf;
	
	Field = "ContractsAreUsed";
	If Not Object.ModeMultipleVendors Then
		
		ContractsAreUsed = Common.ObjectAttributeValue(Object.Terms, Field);
		
	Else
		
		RowFilter = New Structure("InitialString", False);
		Column = "Terms";
		Terms1 = Object.Vendors.Unload(RowFilter, Column).UnloadColumn(Column); // Array of CatalogRef.TermsOfPurchaseFromVendors
		
		FilterByAgreement = New Structure;
		FilterByAgreement.Insert("Terms", Catalogs.TermsOfPurchaseFromVendors.EmptyRef());
		
		AttributesOfAgreements = Common.ObjectsAttributesValues(Terms1, Field);
		
		For Each CurrentVendorData In Object.Vendors Do
			
			CurrentAgreement = CurrentVendorData.Terms;
			
			If AttributesOfAgreements[CurrentAgreement] = Undefined Then
				
				CurrentVendorData.ContractsAreUsed = True;
				
			Else
				
				AttributeValue = AttributesOfAgreements[CurrentAgreement].ContractsAreUsed;
				CurrentVendorData.ContractsAreUsed = AttributeValue;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Function UpdatingOfContractAgreementsIsRequired()
	
	Update_ = True;
	
	If (Not UseContractsWithVendors
	   And Not UseTermsOfPurchases)
	 Or (CurrentCompany = Object.Organization
	   And CurrentRebateKind = Object.RebateKind
	   And CurrentCurrency = Object.Currency) Then
		
		Update_ = False;
		
	ElsIf GoodsIndicator <> Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
	   And BaseOfCalculation <> Enums.RebateCalculationBases.PurchaseAmountARAPAccounting
	   And CurrentCompany = Object.Organization Then
		
		Update_ = False;
		
	EndIf;
	
	CurrentCompany = Object.Organization;
	CurrentRebateKind = Object.RebateKind;
	CurrentCurrency = Object.Currency;
	
	Return Update_;
	
EndFunction

&AtServer
Procedure UpdateSupplierContractAgreementsAccordingToHeaderData()
	
	If Not UpdatingOfContractAgreementsIsRequired() Then
		
		Return;
		
	EndIf;
	
	CurrencySelection_2 = False;
	If GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
	   And BaseOfCalculation = Enums.RebateCalculationBases.PurchaseAmountARAPAccounting Then
		
		CurrencySelection_2 = True;
		
	EndIf;
	
	If Not Object.ModeMultipleVendors Then
		
		CheckTable = New ValueTable;
		CheckTable.Columns.Add("LineNumber", New TypeDescription("Number"));
		CheckTable.Columns.Add("Counterparty", New TypeDescription("CatalogRef.Counterparties"));
		CheckTable.Columns.Add("Partner", New TypeDescription("CatalogRef.Partners"));
		CheckTable.Columns.Add("Contract", New TypeDescription("CatalogRef.CounterpartyContracts"));
		CheckTable.Columns.Add("Terms", New TypeDescription("CatalogRef.TermsOfPurchaseFromVendors"));
		CheckTable.Columns.Add("ValidOnDate", New TypeDescription("Date"));
		CheckTable.Columns.Add("ValidTo", New TypeDescription("Date"));
		VendorData = SupplierDataToFillIn(ContractsAreUsed, Object);
		FillPropertyValues(CheckTable.Add(), VendorData);
		
	Else
		
		CheckTable = Object.Vendors.Unload();
		
	EndIf;
	
	Updated_Data = UpdatedSupplierData(CurrencySelection_2, CheckTable);
	
	If Not Object.ModeMultipleVendors Then
		
		Object.Counterparty = Updated_Data[0].Counterparty;
		Object.Partner = Updated_Data[0].Partner;
		Object.Contract = Updated_Data[0].Contract;
		Object.Terms = Updated_Data[0].Terms;
		ContractsAreUsed = Updated_Data[0].ContractsAreUsed;
		
	Else
		
		Object.Vendors.Load(Updated_Data);
		
	EndIf;
	
EndProcedure

// Parameters:
//  CurrencySelection_2 - Boolean - Currency Selection
//  CheckTable - ValueTable - Validation table:
// * LineNumber - Number
// * Counterparty - CatalogRef.Counterparties
// * Partner - CatalogRef.Partners
// * Contract - CatalogRef.CounterpartyContracts
// * Terms - CatalogRef.TermsOfPurchaseFromVendors
// * ValidOnDate - Date
// * ValidTo - Date
// 
// Returns:
//  ValueTable - ValueTable:
// * LineNumber - Number
// * Counterparty - CatalogRef.Counterparties
// * Partner - CatalogRef.Partners
// * Contract - CatalogRef.CounterpartyContracts
// * Terms - CatalogRef.TermsOfPurchaseFromVendors
// * ValidOnDate - Date
// * ValidTo - Date,
// * ContractsAreUsed - Boolean
//
&AtServer
Function UpdatedSupplierData(CurrencySelection_2, CheckTable)
	
	CompanyArray = New Array; // Array of CatalogRef.Companies
	CompanyArray.Add(Object.Organization);
	CompanyArray.Add(Catalogs.Companies.EmptyRef());
	
	Query = New Query;
	Query.SetParameter("CheckTable", CheckTable);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("CompanyArray", CompanyArray);
	Query.SetParameter("CurrencySelection_2", CurrencySelection_2);
	Query.SetParameter("Currency", Object.Currency);
	
	QueryText =
	"SELECT
	|	CheckTable.LineNumber AS LineNumber,
	|	CheckTable.Counterparty AS Counterparty,
	|	CheckTable.Partner AS Partner,
	|	CheckTable.Contract AS Contract,
	|	CheckTable.Terms AS Terms,
	|	CheckTable.ValidOnDate AS ValidOnDate,
	|	CheckTable.ValidTo AS ValidTo
	|INTO TT_CheckTable
	|FROM
	|	&CheckTable AS CheckTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CheckTable.LineNumber AS LineNumber,
	|	CheckTable.Counterparty AS Counterparty,
	|	CheckTable.Partner AS Partner,
	|	CheckTable.Contract AS Contract,
	|	CheckTable.Terms AS Terms,
	|	CheckTable.ValidOnDate AS ValidOnDate,
	|	CheckTable.ValidTo AS ValidTo,
	|	ISNULL(CounterpartyContracts.Organization, VALUE(Catalog.Companies.EmptyRef)) AS OrganizationOfContract,
	|	ISNULL(CounterpartyContracts.ARAPCurrency, VALUE(Catalog.Currencies.EmptyRef)) AS ContractCurrency,
	|	ISNULL(TermsOfPurchaseFromVendors.Organization, VALUE(Catalog.Companies.EmptyRef)) AS CompanyAgreements,
	|	ISNULL(TermsOfPurchaseFromVendors.ContractsAreUsed, TRUE) AS ContractsAreUsed
	|INTO TT_ValidationTableWithValidationData
	|FROM
	|	TT_CheckTable AS CheckTable
	|		LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchaseFromVendors
	|		ON CheckTable.Terms = TermsOfPurchaseFromVendors.Ref
	|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|		ON CheckTable.Contract = CounterpartyContracts.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ValidationTableWithValidationData.LineNumber AS LineNumber,
	|	ValidationTableWithValidationData.Counterparty AS Counterparty,
	|	ValidationTableWithValidationData.Partner AS Partner,
	|	ValidationTableWithValidationData.ValidOnDate AS ValidOnDate,
	|	ValidationTableWithValidationData.ValidTo AS ValidTo,
	|	ValidationTableWithValidationData.ContractsAreUsed AS ContractsAreUsed,
	|	CASE
	|		WHEN ValidationTableWithValidationData.OrganizationOfContract <> &Organization
	|			THEN VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|		WHEN &CurrencySelection_2
	|				AND ValidationTableWithValidationData.ContractCurrency <> &Currency
	|			THEN VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|		ELSE ValidationTableWithValidationData.Contract
	|	END AS Contract,
	|	CASE
	|		WHEN NOT ValidationTableWithValidationData.CompanyAgreements IN (&CompanyArray)
	|			THEN VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)
	|		ELSE ValidationTableWithValidationData.Terms
	|	END AS Terms
	|FROM
	|	TT_ValidationTableWithValidationData AS ValidationTableWithValidationData
	|
	|ORDER BY
	|	LineNumber";
	
	Query.Text = QueryText;
	Updated_Data = Query.Execute().Unload();
	Return Updated_Data;
	
EndFunction

#EndRegion

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

#Region DownloadingFromFiles

&AtServer
Function DescriptionOfColumnsInGoodsTemplate(Val FieldDisplaySettings)
	
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
	
	If FieldDisplaySettings.AmountBonus Then
		ColumnsNames.Add("AmountBonus");
	EndIf;
	
	If FieldDisplaySettings.BonusPerUnit Then
		ColumnsNames.Add("BonusPerUnit");
	EndIf;
	
	Columns = StrConcat(ColumnsNames, ",");
	
	TemplateColumns = ImportDataFromFile.GenerateColumnDetails(Object.Goods, Columns);
	
	ColumnNumber = 0;
	
	GroupNameItem = NStr("vi = 'Mặt hàng';
						|ru = 'Номенклатура';
						|en = 'Items'; fa = 'اقلام';
						|it = 'Номенклатура';
						|pl = 'Items';
						|tr = 'Öğe'");
	
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
						|pl = 'Pozycja';
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
							|tr = 'Özellik'");
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
		Column.Title = Items.GoodsCountPlan.Title;
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
							|en = 'Bonus, %'; fa = 'پاداش، درصد';
							|it = 'Бонус, %';
							|pl = 'Bonus, %';
							|tr = 'Bonus, %'");
		Column.ToolTip = HintTextNumber;
		Column.Position = ColumnNumber;
		
	EndIf;
	
	If FieldDisplaySettings.BonusPerUnit Then
		
		ColumnNumber = ColumnNumber + 1;
		Column = ImportDataFromFileClientServer.TemplateColumn("BonusPerUnit", TemplateColumns);
		Column.Title = NStr("vi = 'Thưởng cho đơn vị';
							|ru = 'Бонус за единицу';
							|en = 'Rebate per unit'; fa = 'Rebate per unit';
							|it = 'Бонус за единицу';
							|pl = 'Rebate per unit';
							|tr = 'Birim bonus'");
		Column.ToolTip = HintTextNumber;
		Column.Position = ColumnNumber;
		
	EndIf;
	
	If FieldDisplaySettings.AmountBonus Then
		
		ColumnNumber = ColumnNumber + 1;
		Column = ImportDataFromFileClientServer.TemplateColumn("AmountBonus", TemplateColumns);
		Column.Title = NStr("vi = 'Thưởng, số tiền';
							|ru = 'Бонус, сумма';
							|en = 'Rebate, amount'; fa = 'Rebate, amount';
							|it = 'Бонус, сумма';
							|pl = 'Rebate, amount';
							|tr = 'Bonus, tutar'");
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
Procedure UploadProductsFromFileOnServer(Val ImportedDataAddress)
	
	ImportedData = GetFromTempStorage(ImportedDataAddress); // ValueTable
	
	CalculateAmounts = (Object.BonusType = PredefinedValue("Enum.VendorRebateTypes.Balance")
								And Object.AccrueImmediately);
	
	LinesAdded = False;
	For LineNumber = 1 To ImportedData.Count() Do
		
		TableRow = ImportedData[LineNumber - 1];
		NewRow = Object.Goods.Add();
		FillPropertyValues(NewRow, TableRow);
		
		AmountsAreFilledIn = (NewRow.BonusPerUnit <> 0
						And NewRow.AmountBonus <> 0);
		
		If CalculateAmounts Then
			
			If AmountsAreFilledIn Then
				
				CheckAmountsInUploadedLine(NewRow, LineNumber);
				
			Else
				
				CalculateAmountsInLoadedLine(NewRow);
				
			EndIf;
			
		Else
			NewRow.AmountBonus = 0;
		EndIf;
		
		LinesAdded = True;
		
	EndDo;
	
	If LinesAdded Then
		
		FillInServiceDetailsForProductRange();
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure CalculateAmountsInLoadedLine(TSRow)
	
	If TSRow.BonusPerUnit = 0 Then
		
		If TSRow.CountPlan = 0 Then
			TSRow.BonusPerUnit = TSRow.AmountBonus;
		Else
			TSRow.BonusPerUnit = Round(TSRow.AmountBonus / TSRow.CountPlan, 2);
		EndIf;
		
	ElsIf TSRow.AmountBonus = 0 Then
		
		TSRow.AmountBonus = TSRow.BonusPerUnit * TSRow.CountPlan;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckAmountsInUploadedLine(TSRow, LineNumber)
	
	BonusAmountIsCalculated = TSRow.BonusPerUnit * TSRow.CountPlan;
	
	If TSRow.AmountBonus <> BonusAmountIsCalculated Then
		
		MessageTemplate = NStr("vi = 'Giá trị số tiền thưởng không khớp với hạch toán (%1)';
								|ru = 'Значение суммы бонуса не совпадает с расчетным (%1)';
								|en = 'Rebate amount does not match the calculated one (%1)'; fa = 'Rebate amount does not match the calculated one (%1)';
								|it = 'Значение суммы бонуса не совпадает с расчетным (%1)';
								|pl = 'Rebate amount does not match the calculated one (%1)';
								|tr = 'Bonus tutarının değeri hesaplanan değer ile eşleşmiyor (%1)'");
		EstimatedAmountByLine = Format(BonusAmountIsCalculated, "NFD=2; NZ=0;");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, EstimatedAmountByLine);
		PathToField = CommonClientServer.PathToTabularSection("Goods", LineNumber, "AmountBonus");
		Common.MessageToUser(MessageText,, PathToField, "Object");
		
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
Procedure LoadGoodsSegmentsFromFileOnServer(Val ImportedDataAddress)
	
	ImportedData = GetFromTempStorage(ImportedDataAddress);
	
	For Each TableRow In ImportedData Do
		
		NewRow = Object.GoodsSegments.Add();
		FillPropertyValues(NewRow, TableRow);
		
	EndDo;
	
EndProcedure

&AtServer
Function DescriptionOfColumnsInTINTemplate(Val FieldDisplaySettings)
	
	ColumnsNames = New Array; // Array of String
	ColumnsNames.Add("TIN");
	If FieldDisplaySettings.Period Then
		
		ColumnsNames.Add("ValidOnDate");
		ColumnsNames.Add("ValidTo");
		
	EndIf;
	
	Columns = StrConcat(ColumnsNames, ",");
	
	TemplateColumns = ImportDataFromFile.GenerateColumnDetails(Object.ClientsCounterpartiesTIN, Columns);
	
	Column = ImportDataFromFileClientServer.TemplateColumn("TIN", TemplateColumns);
	Column.IsRequiredInfo = True;
	
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
							|tr = 'Eylem başlangıcı'");
		Column.ToolTip = DateHint;
		
		Column = ImportDataFromFileClientServer.TemplateColumn("ValidTo", TemplateColumns);
		Column.Title = NStr("vi = 'Ngày hết hiệu lực';
							|ru = 'Окончание действия';
							|en = 'Valid to'; fa = 'معتبر تا';
							|it = 'Окончание действия';
							|pl = 'Zakończenie czynności';
							|tr = 'Eylem bitişi'");
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
Procedure DownloadCounterpartyINNFromFileOnServer(Val ImportedDataAddress)
	
	ImportedData = GetFromTempStorage(ImportedDataAddress);
	
	For Each TableRow In ImportedData Do
		
		NewRow = Object.ClientsCounterpartiesTIN.Add();
		FillPropertyValues(NewRow, TableRow);
		
	EndDo;
	
EndProcedure

&AtServer
Function DescriptionOfColumnsInTemplateCounterparties(Val FieldDisplaySettings)
	
	ColumnsNames = New Array; // Array of String
	If FieldDisplaySettings.Period Then
		
		ColumnsNames.Add("ValidOnDate");
		ColumnsNames.Add("ValidTo");
		
	EndIf;
	
	Columns = StrConcat(ColumnsNames, ",");
	
	TemplateColumns = ImportDataFromFile.GenerateColumnDetails(Object.CustomerCounterparties, Columns);
	
	ColumnNumber = 0;
	
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
						|tr = 'Neden Kodu'");
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

// Parameters:
//  ImportedDataAddress - String, Undefined - Address of uploaded data
//  AdditionalParameters - Structure - advanced setting
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
Procedure DownloadCounterpartiesFromFileOnServer(Val ImportedDataAddress)
	
	ImportedData = GetFromTempStorage(ImportedDataAddress);
	
	For Each TableRow In ImportedData Do
		
		NewRow = Object.CustomerCounterparties.Add();
		FillPropertyValues(NewRow, TableRow);
		
	EndDo;
	
EndProcedure

&AtServer
Function InformationAboutSourceOfValues(Type)
	
	InformationRecords = New Structure;
	InformationRecords.Insert("ProductItemPropertyPresentation", ProductItemPropertyPresentation);
	InformationRecords.Insert("Name", "");
	InformationRecords.Insert("FullName", "");
	InformationRecords.Insert("Synonym", "");
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
							|en = 'Bonus, %'; fa = 'پاداش، درصد';
							|it = 'Бонус, %';
							|pl = 'Bonus, %';
							|tr = 'Bonus, %'");
		Column.ToolTip = HintNumber;
		Column.Position = ColumnNumber;
		
	EndIf;
	
	If FieldDisplaySettings.Period Then
		
		ColumnNumber = ColumnNumber + 1;
		Column = ImportDataFromFileClientServer.TemplateColumn("ValidOnDate", TemplateColumns);
		Column.Title = NStr("vi = 'Ngày đầu hiệu lực';
							|ru = 'Начало действия';
							|en = 'Start date'; fa = 'تاریخ شروع';
							|it = 'Начало действия';
							|pl = 'Początek działania';
							|tr = 'Eylem başlangıcı'");
		Column.ToolTip = DateHint;
		Column.Position = ColumnNumber;
		
		ColumnNumber = ColumnNumber + 1;
		Column = ImportDataFromFileClientServer.TemplateColumn("ValidTo", TemplateColumns);
		Column.Title = NStr("vi = 'Ngày hết hiệu lực';
							|ru = 'Окончание действия';
							|en = 'End date'; fa = 'تاریخ پایان';
							|it = 'Окончание действия';
							|pl = 'Zakończenie czynności';
							|tr = 'Eylem bitişi'");
		Column.ToolTip = DateHint;
		Column.Position = ColumnNumber;
		
	EndIf; 
	
	Return TemplateColumns;
	
EndFunction

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
