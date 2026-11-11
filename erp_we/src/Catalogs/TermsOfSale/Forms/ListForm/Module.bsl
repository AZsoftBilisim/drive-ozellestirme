
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	TMCommonUse.CustomizePeripherals(ThisForm);
	
	List.Parameters.SetParameterValue("UpdateDate", BegOfDay(CurrentSessionDate()));
	List.Parameters.SetParameterValue("Partner",          Parameters.Partner);
	
	CommonClientServer.SetDynamicListFilterItem(List, "PartnerSelection_", Parameters.Partner, DataCompositionComparisonType.Equal,, True);
	
	If ValueIsFilled(Parameters.Partner) Then
		Title = NStr("vi = 'Thỏa thuận với khách hàng';
					|ru = 'Соглашения с клиентом';
					|en = 'Terms of sales'; fa = 'شرایط فروش';
					|it = 'Accordi con il cliente';
					|pl = 'Umowa z klientem';
					|tr = 'Satış koşulları'");
	EndIf;
	
	AvailableToCreateIndividualAgreements = UserRightsCached.ModificationOfIndividualAgreements();
	Items.ListCreateAgreement.Visible = AvailableToCreateIndividualAgreements;
	Items.SetStatusValid.Visible = AvailableToCreateIndividualAgreements;
	Items.SetTheStatusNotAgreed.Visible = AvailableToCreateIndividualAgreements;
	Items.SetClosedStatus.Visible = AvailableToCreateIndividualAgreements;
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	Parameters.Filter.Property("BusinessOperation", BusinessOperation);
	
	ListSelectionsClientServer.FillInSelectionSelectionListByRelevance(Items.FilterValidityPeriod.ChoiceList);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Manager", Manager, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByRelevanceWhenCreatingOnServer(List, Relevance, Items.FilterValidityPeriod.ChoiceList, EventDate, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByRegularityWhenCreatingOnServer(List, Regularity, QuickFilterStructure);

	If ListSelectionsClientServer.YouNeedToSelectByStateWhenCreatingOnServer(State, QuickFilterStructure) Then
		CommonClientServer.SetDynamicListFilterItem(List, "State", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
	EndIf;
	
	If QuickFilterStructure <> Undefined Then
		QuickFilterStructure.Property("AgreementType",    AgreementType);
	EndIf;
	CommonClientServer.SetDynamicListParameter(List,"Standard_", NStr("vi = 'Chung';
																		|ru = 'Типовое';
																		|en = 'Standard'; fa = 'استاندارد';
																		|it = 'Accordo tipo';
																		|pl = 'Typowa';
																		|tr = 'Standart'"));
	CommonClientServer.SetDynamicListParameter(List,"Individual_3", NStr("vi = 'Riêng';
																		|ru = 'Индивидуальное';
																		|en = 'Individual'; fa = 'شخص حقیقی';
																		|it = 'Accordi individuali';
																		|pl = 'Indywidualna';
																		|tr = 'Özelleştirilmiş'"));

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	SetAvailabilityOfCommandsForExternalUser();	
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");

EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	UseStandardTermsOfSalesWithCustomers			= GetFunctionalOption("UseStandardTermsOfSalesWithCustomers");
	UseCustomerTermsOfSales	= GetFunctionalOption("UseCustomerTermsOfSales");
	
	If UseStandardTermsOfSalesWithCustomers And Not UseCustomerTermsOfSales Then
		AgreementType = "Standard_";
		
	ElsIf Not UseStandardTermsOfSalesWithCustomers And UseCustomerTermsOfSales Then
		AgreementType = "Individual_3";
		
	Else
		If QuickFilterStructure = Undefined Then
			
			AgreementType    = Settings.Get("AgreementType");
			
		Else
			If Not QuickFilterStructure.Property("AgreementType") Then
				AgreementType = Settings.Get("AgreementType");
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Settings.Delete("AgreementType");
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Manager", Manager, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByRelevanceWhenLoadingFromSettings(List, Relevance, Items.FilterValidityPeriod.ChoiceList, EventDate, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByRegularityWhenLoadingFromSettings(List, Regularity, QuickFilterStructure, Settings);

	If ListSelectionsClientServer.YouNeedToSelectByStateWhenLoadingFromSettings(State, QuickFilterStructure, Settings) Then
		CommonClientServer.SetDynamicListFilterItem(List, "State", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(List, "AgreementType", AgreementType, DataCompositionComparisonType.Equal,, ValueIsFilled(AgreementType));

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterStateOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "State", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
	
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Manager", Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));
	
EndProcedure

&AtClient
Procedure AgreementTypeOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "AgreementType", AgreementType, DataCompositionComparisonType.Equal,, ValueIsFilled(AgreementType));
	
EndProcedure

&AtClient
Procedure FilterValidityPeriodOnChange(Item)
	
	ListSelectionsClientServer.WhenChangingRelevanceSelection(List, Relevance, EventDate, Items.FilterValidityPeriod.ChoiceList);
	
EndProcedure

&AtClient
Procedure FilterValidityPeriodClearing(Item, StandardProcessing)
	
	ListSelectionsClientServer.WhenClearingSelectionByRelevance(List, Relevance, EventDate, StandardProcessing);
	
EndProcedure

&AtClient
Procedure FilterValidityPeriodChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	TMCommonUseClient.WhenSelectingRelevanceSelection(
		ValueSelected, 
		StandardProcessing, 
		ThisForm,
		List, 
		"Relevance",
		"FilterValidityPeriod",
		"EventDate");
	
EndProcedure

&AtClient
Procedure RegularityOnChange(Item)
	
	ListSelectionsClientServer.SetSelectionInListByRegularity(List, Regularity);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetTheStatusNotAgreed(Command)
	
	SalesClient.EstablishStatusOfAgreementsWithCustomersNotAgreed(Items.List);

EndProcedure

&AtClient
Procedure SetStatusValid(Command)
	
	SalesClient.SetStatusOfAgreementsWithClientsValid(Items.List);
	
EndProcedure

&AtClient
Procedure SetClosedStatus(Command)
	
	SalesClient.SetStatusOfCustomerAgreementsClosed(Items.List);
	
EndProcedure

&AtClient
Procedure CreateAgreement(Command)
	
	FillingValues = New Structure("Partner", Parameters.Partner);
	FillingValues.Insert("BusinessOperation", BusinessOperation);
	OpenForm("Catalog.TermsOfSale.ObjectForm", New Structure("FillingValues", FillingValues));
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetAvailabilityOfCommandsForExternalUser()
	
	ItemArray = New Array();
	ItemArray.Add("PriceGroupsFillInThePriceViewOfTheSelectedLinesPriceGroups");
	ItemArray.Add("GoodsPopulateAPriceTypeOfTheSelectedLinesGoods");
	ItemArray.Add("SetDateInterval");
	
	CommandsAvailability = AccessRight("Update", Metadata.Catalogs.TermsOfSale);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", CommandsAvailability);
	
EndProcedure

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Catalog.TermsOfSale.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Items.List.CurrentRow = ReferencesArrray[0];
		ShowValue(Undefined, ReferencesArrray[0]);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
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

#EndRegion
