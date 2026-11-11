
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	If QuickFilterStructure <> Undefined Then
		QuickFilterStructure.Property("Organization", Organization);
	EndIf;
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListOfOrdersForDebitingFromStorage, "Organization", Organization, QuickFilterStructure);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	CustomizeWithLinkSeeAlso();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ReportOnVMIAdjustment" Then
		Items.ListOfOrdersForDebitingFromStorage.Refresh();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If QuickFilterStructure <> Undefined Then
		QuickFilterStructure.Property("Organization", Organization);
		Settings.Delete("Organization");
	Else
		Organization = Settings.Get("Organization");
	EndIf;
	
	ArrayOfLists = New Array;
	ArrayOfLists.Add("ListOfOrdersForDebitingFromStorage");
	
	FilterParameters = New Structure;
	FilterParameters.Insert("ListForm", ThisForm);
	FilterParameters.Insert("ArrayOfLists", ArrayOfLists);
	FilterParameters.Insert("ColumnName", "Organization");
	FilterParameters.Insert("Value", Organization);
	FilterParameters.Insert("Settings", Settings);
	
	ListSelectionsClientServer.SetSelectionsByListValueWhenLoadingFromSettings(FilterParameters, QuickFilterStructure);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		ListOfOrdersForDebitingFromStorage,
		"Organization",
		Organization,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Organization));
	
EndProcedure

&AtClient
Procedure VendorOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		ListOfOrdersForDebitingFromStorage,
		"Partner",
		Partner,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Partner));
		
EndProcedure

&AtClient
Procedure SeeAlsoInProgressURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization", Organization);
	
	LogParameters = New Structure;
	LogParameters.Insert("QuickFilterStructure", QuickFilterStructure);
	LogParameters.Insert("PurposeUseKey", "ReportOnVMIAdjustment");
	
	LogParameters.Insert("QuickFilterStructure", QuickFilterStructure);
	
	OpenForm(FormattedStringURL, LogParameters); 
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure IssueAWriteOffFromStorage(Command)
	
	CurrentData = Items.ListOfOrdersForDebitingFromStorage.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	NameOfReceiptForm = "Document.ReportOnVMIAdjustment.ObjectForm";
	
	Basis = New Structure("Organization, Partner, Counterparty, Contract");
	FillPropertyValues(Basis, CurrentData);
	If CurrentData.ContractType = PredefinedValue("Enum.ContractTypes.ReceiptForTolling2_5") Then
		Basis.Insert(
			"BusinessOperation",
			PredefinedValue("Enum.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider"));
	EndIf;
	FillParameters = New Structure("Basis", Basis);
	
	OpenForm(NameOfReceiptForm, FillParameters, ThisForm);
	
EndProcedure

&AtServer
Procedure CustomizeWithLinkSeeAlso()
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("PurposeUseKey", "ReportOnVMIAdjustment");
	
	ArrayCalculationManagersSeeAlsoInWork = New Array();
	ArrayCalculationManagersSeeAlsoInWork.Add("DataProcessor.LogOfPurchaseDocuments");
	
	SeeAlsoInProgress = TMCommonUse.CreateHyperlinkSeeAlsoIn(ArrayCalculationManagersSeeAlsoInWork, GenerationParameters);
	Items.SeeAlsoInProgress.Visible = ValueIsFilled(SeeAlsoInProgress);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	//
	
EndProcedure

#EndRegion
