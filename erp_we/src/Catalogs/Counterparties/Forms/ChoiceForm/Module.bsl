
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
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

	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		
		ReadOnly = True;
		CommonClientServer.SetDynamicListFilterItem(List, "Partner", Catalogs.Partners.UnknownPartner, DataCompositionComparisonType.NotEqual);
		
	EndIf;
		
	If Parameters.Property("Filter")
		And Parameters.Filter.Property("Partner")
		And ValueIsFilled(Parameters.Filter.Partner) Then
		
		SettingsKey = "ParametricListForm" + Parameters.Filter.Partner.UUID();
		LoadSettings();
		
		Partner = Parameters.Filter.Partner;
		
		PartnersAndCounterparties.FillInListOfPartnersWithParents(Partner, PartnerList);
		
		Items.ShowGroup.Visible = PartnerList.Count() > 1 And ByPartner;
		
		If ValueIsFilled(Partner) Then
			FoundPartner = PartnerList.FindByValue(Partner);
			
			If FoundPartner <> Undefined Then
				If Parameters.Property("TitleByPartner") And Not IsBlankString(Parameters.TitleByPartner) Then
					PartnerHeaderPrefix = Parameters.TitleByPartner;
				Else
					PartnerHeaderPrefix = NStr("vi = 'Theo bạn hàng';
												|ru = 'По партнеру';
												|en = 'By partner'; fa = 'بر اساس شریک';
												|it = 'Secondo il partner';
												|pl = 'Wg partnera';
												|tr = 'İş ortağına göre'");
				EndIf;
				TitleText = NStr("vi = '%1 ""%2""';
								|ru = '%1 ""%2""';
								|en = '%1 ""%2""'; fa = '%1 ""%2""';
								|it = '%1 ""%2""';
								|pl = '%1 ""%2""';
								|tr = '%1 ""%2""'");
				TitleText = StringFunctionsClientServer.SubstituteParametersToString(TitleText, PartnerHeaderPrefix, FoundPartner.Presentation); 
			EndIf;
			
		EndIf;
		
		Items.ByPartner.Title = TitleText;
		
		Parameters.Filter.Delete("Partner");
		
		If ByPartner Then
			SetPartnerSelectionServer(ShowGroup And Items.ShowGroup.Visible);
		EndIf;
		
	Else
		Partner = Catalogs.Partners.EmptyRef();
		Items.ShowGroup.Visible = False;
		Items.ByPartner.Visible          = False;
	EndIf;
	
	If Parameters.Property("ExcludingCounterparty") Then
		CommonClientServer.SetDynamicListFilterItem(List, "Ref", Parameters.ExcludingCounterparty, DataCompositionComparisonType.NotEqual,
		                                                                        ,,DataCompositionSettingsItemViewMode.Inaccessible);
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	PartnersAndCounterpartiesLocalization.WhenCreatingCounterpartySelectionFormOnServer(ThisForm, Cancel, StandardProcessing);
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		ShouldSaveSettings();
	EndIf;
	
EndProcedure 

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ByPartnerOnChange(Item)

	ShowGroup = ByPartner;
	Items.ShowGroup.Visible = (PartnerList.Count() > 1 And ByPartner);
	If ByPartner Then
		SetPartnerSelection(ByPartner);
	Else
		CommonClientServer.DeleteDynamicListFilterGroupItems(List, "Partner");
	EndIf;

EndProcedure

&AtClient
Procedure ShowGroupOnChange(Item)

	SetPartnerSelection(ShowGroup); 

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If (Not Partner.IsEmpty()) And (Not Copy) Then
		
		Cancel = True;
		Basis = New Structure("Partner",Partner);
		ParametersStructure = New Structure("Basis", Basis);
		OpenForm("Catalog.Counterparties.ObjectForm",
			ParametersStructure,,,,,
			Undefined, 
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetPartnerSelection(InstallForGroup = True)
	
	TMCommonUseClientServer.GetDynamicListSelection(List).Items.Clear();
	
	If InstallForGroup Then
		// create a group element - selection by partner
		CommonClientServer.SetDynamicListFilterItem(List, "Partner", PartnerList, DataCompositionComparisonType.InList,, True);
	Else
		CommonClientServer.SetDynamicListFilterItem(List, "Partner", Partner, DataCompositionComparisonType.Equal,, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetPartnerSelectionServer(InstallForGroup = True)
	
	TMCommonUseClientServer.GetDynamicListSelection(List).Items.Clear();
	
	If InstallForGroup Then
		// create a group element - selection by partner
		CommonClientServer.SetDynamicListFilterItem(List, "Partner", PartnerList, DataCompositionComparisonType.InList,, True);
	Else
		CommonClientServer.SetDynamicListFilterItem(List, "Partner", Partner, DataCompositionComparisonType.Equal,,True);
	EndIf;

EndProcedure

&AtServer
Procedure ShouldSaveSettings()

	Var Settings;
	
	Settings = New Map;
	Settings.Insert("ShowGroup", ShowGroup);
	Settings.Insert("ByPartner", ByPartner);
	
	Common.CommonSettingsStorageSave("Catalogs.Counterparties", SettingsKey, Settings);

EndProcedure

&AtServer
Procedure LoadSettings()
	
	SettingsValue = Common.CommonSettingsStorageLoad("Catalogs.Counterparties", SettingsKey);
	If TypeOf(SettingsValue) = Type("Map") Then
		ShowGroup = SettingsValue.Get("ShowGroup");
		ByPartner          = SettingsValue.Get("ByPartner");
	Else
		ByPartner          = True;
		ShowGroup = False;
	EndIf;
	
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

#EndRegion

#Region FormCommandsEventHandlers

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion
