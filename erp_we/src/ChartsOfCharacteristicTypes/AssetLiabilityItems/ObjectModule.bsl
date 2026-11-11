#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	If Not CopiedObject.IsFolder Then
		NameOfBudgetDataSource = "";
		AllocationOfLongTermAssetsAndLiabilities = False;
		NotOwnedControlledValues = False;
		DataSource = "";
		Filterdata_ = Undefined;
		SettingObjectSource = "";
		SelectingConfigurationObjects = Undefined;
		DetailedSettingsSource = "";
		FunctionalOptionLinks = Undefined;
		LedgerAccountsInEntrySettings = False;
		FunctionalOptions.Clear();
		ManResources.Clear();
		LocalResources.Clear();
		ShaftResources.Clear();
		ResourcesQuantity.Clear();
		PathsToExtdimensionData.Clear();
		
		If ChartsOfCharacteristicTypes.AssetLiabilityItems.ThisIsObjectOfFinancialAccounting(CopiedObject) Then
			Parent = Undefined;
			LongDesc = "";
		EndIf;
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") And FillingData.Property("AssetLiability") Then
		AssetLiability = FillingData.AssetLiability;
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not IsFolder Then
		WithoutDimension = ValueType = New TypeDescription("EnumRef.AssetAndLiabilityItemsWithoutDimension");
	EndIf;
	
EndProcedure

Procedure OnReadPresentationsAtServer() Export
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#EndIf
