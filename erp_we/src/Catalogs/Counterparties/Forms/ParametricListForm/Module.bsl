
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	PartnersAndCounterpartiesLocalization.SetPropertiesOfDynamicListOfCounterparties(ThisForm);
	
	CommonClientServer.SetDynamicListParameter(
		List,
		"RepresentationOfASeparateDivision",
		NStr("vi = 'Chi nhánh, văn phòng đại diện';
			|ru = 'Обособленное подразделение';
			|en = 'Branch office'; fa = 'شعبه';
			|it = 'Reparto esterno';
			|pl = 'Odrębny dział';
			|tr = 'Ayrı departman'"));
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	AvailableToAddPartners = AccessRight("Insert", Metadata.Catalogs.Partners);
	
	If Parameters.Property("FilterOfCounterparties") Then
		
		SettingsKey = "ParametricListForm" + Parameters.FilterOfCounterparties.UUID();
		LoadSettings();
		
		If TypeOf(Parameters.FilterOfCounterparties) = Type("CatalogRef.Partners") Then
			
			// consider the possibility of viewing by partner group
			Partner = Parameters.FilterOfCounterparties;
			SetListSelectionByPartnerServerParameter();
			
		EndIf;
		
	EndIf;
	
	CanBeEdited = AccessRight("Edit", Metadata.Catalogs.Counterparties);
	Items.FormChangeSelectedItems.Visible = CanBeEdited;
	Items.ListContextMenuChangeSelectedItems.Visible = CanBeEdited;

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	
	PartnersAndCounterpartiesLocalization.WhenCreatingParametricCounterpartyListFormOnServer(ThisForm, 
		Cancel,
		StandardProcessing);
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		ShouldSaveSettings();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "UpdateCatalogList" Then
		If Parameter.Property("FilterOfCounterparties")
			And TypeOf(Parameter.FilterOfCounterparties) = Type("CatalogRef.Partners")
			And Source = FormOwner Then
			
			If Parameter.FilterOfCounterparties = Partner Then
				Return;
			EndIf;
			Partner = Parameter.FilterOfCounterparties;
			SetListSelectionByPartnerServerParameter()
			
		Else
			Items.List.Refresh();
		EndIf;
		
	EndIf;
	
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ShowGroupOnChange(Item)

	SetPartnerSelection(ShowGroup);
	ThisForm.Modified = False;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.MainCounterparty Then
		
		CurrentData = Item.CurrentData;
		If CurrentData.BranchOffice 
			And Not ValueIsFilled(CurrentData.MainCounterparty)
			And AvailableToAddPartners Then
			
			StandardProcessing = False;
			
			FillParameters = New Structure;
			PartnersAndCounterpartiesLocalizationClientServer.AddParametersForHeadCounterparty(FillParameters, CurrentData);
			FillParameters.Insert("Counterparty", CurrentData.Ref);
			FillParameters.Insert("Partner",    CurrentData.Partner);
			FillParameters.Insert("UsePartnersAsCounterparties", UsePartnersAsCounterparties);
			
			Notification = New CallbackDescription("FillInTheHeadCounterpartyCompletion", ThisObject);
			PartnersAndCounterpartiesClient.FillInTheHeadCounterparty(ThisObject, FillParameters, True, Notification);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)

	If ShowGroup And (Not Copy) Then
		Cancel = True;
		StructureBase = New Structure("Partner", Partner);
		OpenForm(
			"Catalog.Counterparties.ObjectForm",
			New Structure("Basis",StructureBase));
	EndIf;

EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreatePartner(Command)
	
	GroupingType = Type("DynamicListGroupRow");
		
	If Items.List.CurrentRow = GroupingType Or Items.List.CurrentData = Undefined Then
		Return;
	EndIf;
	
	CounterpartyFoundation = New Structure;
	CounterpartyFoundation.Insert("Ref", Items.List.CurrentData.Ref);
	
	OpeningParameters = New Structure("CounterpartyFoundation", CounterpartyFoundation);
	
	OpenForm("Catalog.Partners.Form.WizardOfNew", OpeningParameters, ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.List);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands


&AtClient
Procedure MarkSelectedOnesWithDuplicates(Command)
	SearchAndReplaceDuplicatesMasterDataClient.MarkSelectedOnesWithDuplicates(Items.List);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	PartnersAndCounterparties.SetRegistrationOfHeadCounterpartyInList(ThisForm);

EndProcedure

&AtClient
Procedure SetPartnerSelection(InstallForGroup = True)
	
	TMCommonUseClientServer.GetDynamicListSelection(List).Items.Clear();
	
	If InstallForGroup Then
		
		// create a group element - selection by partner
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Partner",
			PartnerList,
			DataCompositionComparisonType.InList,
			,
			True);
		
	Else
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Partner",
			Partner,
			DataCompositionComparisonType.Equal,
			,
			True);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetPartnerSelectionServer(InstallForGroup = True)
	
	TMCommonUseClientServer.GetDynamicListSelection(List).Items.Clear();
	
	If InstallForGroup Then
		
		// create a group element - selection by partner
		CommonClientServer.SetDynamicListFilterItem(List, "Partner", PartnerList, DataCompositionComparisonType.InList,, True);
		
	Else
		
		CommonClientServer.SetDynamicListFilterItem(List, "Partner", Partner, DataCompositionComparisonType.Equal,, True);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetListSelectionByPartnerServerParameter()
	
	VisibilityOfPartnerCreationTeam = False;
	
	If AccessRight("Insert", Metadata.Catalogs.Partners)
		And (Partner = Catalogs.Partners.UnknownPartner 
		Or Partner = Catalogs.Partners.RetailCustomer) Then
		VisibilityOfPartnerCreationTeam = True;
	EndIf;
	
	PartnersAndCounterparties.FillInListOfPartnersWithParents(Partner,PartnerList);
	Items.ShowGroup.Visible = PartnerList.Count() > 1 ;
	SetPartnerSelectionServer(ShowGroup);

	Items.FormCreatePartner.Visible = VisibilityOfPartnerCreationTeam;
	
EndProcedure

&AtServer
Procedure ShouldSaveSettings()

	Var Settings;
	
	Settings = New Map;
	Settings.Insert("ShowGroup",ShowGroup);
	Settings.Insert("ByPartner", ByPartner);
	
	Common.CommonSettingsStorageSave("Catalogs.Counterparties", SettingsKey, Settings);

EndProcedure 

&AtServer
Procedure LoadSettings()

	SettingsValue = Common.CommonSettingsStorageLoad("Catalogs.Counterparties", SettingsKey);
	If TypeOf(SettingsValue) = Type("Map") Then
		ShowGroup = SettingsValue.Get("ShowGroup");
		ByPartner          = SettingsValue.Get("ByPartner");
	EndIf;

EndProcedure

&AtClient
Procedure FillInTheHeadCounterpartyCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected <> Undefined Then
		Items.List.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#Region Localization

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem


#EndRegion

