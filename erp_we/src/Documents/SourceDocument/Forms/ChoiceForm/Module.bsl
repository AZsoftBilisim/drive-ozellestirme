#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	PrimaryDocumentTypeParameter = Undefined;
	If Parameters.Filter.Property("SourceDocumentType", PrimaryDocumentTypeParameter) Then
		ChoiceList = Items.FilterSourceDocumentType.ChoiceList;
		ChoiceList.Clear();
		If TypeOf(PrimaryDocumentTypeParameter) = Type("FixedArray") Then;
			For Each ArrayElement In PrimaryDocumentTypeParameter Do
				ChoiceList.Add(ArrayElement);
			EndDo;
		Else
			ChoiceList.Add(PrimaryDocumentTypeParameter);
		EndIf; 
		If ChoiceList.Count() = 1 Then
			SourceDocumentType = ChoiceList[0].Value;
			Items.FilterSourceDocumentType.Visible = False;
			AutoTitle = False;
			Title = String(SourceDocumentType);
		EndIf;
		Parameters.Filter.Delete("SourceDocumentType");
		
		SelectAccordingToSeller = SourceDocumentType = Enums.SourceDocumentTypes.PurchaseFromVendor
		                           Or SourceDocumentType = Enums.SourceDocumentTypes.PurchaseAdjustment;
		Items.FilterIncomingDocumentNumber.Visible = SelectAccordingToSeller;
		Items.FilterIncomingDocumentDate.Visible = SelectAccordingToSeller;
		
		If ValueIsFilled(SourceDocumentType) Then
			ListSelectionsClientServer.ChangeListSelectionElement(
				List, 
				"SourceDocumentType", 
				SourceDocumentType, 
				True,
				DataCompositionComparisonType.Equal);
		Else
			ListSelectionsClientServer.ChangeListSelectionElement(
				List, 
				"SourceDocumentType", 
				ChoiceList.Copy(), 
				True,
				DataCompositionComparisonType.InList);
		EndIf;
	EndIf;
	
	CounterpartyParameter = Undefined;
	If Parameters.Filter.Property("Counterparty", CounterpartyParameter) Then
		Counterparty = CounterpartyParameter;
		Items.FilterCounterparty.Visible = False;
		Parameters.Filter.Delete("Counterparty");
		
		ListSelectionsClientServer.ChangeListSelectionElement(
			List, 
			"Counterparty", 
			Counterparty, 
			ValueIsFilled(Counterparty),
			DataCompositionComparisonType.Equal);
			
	EndIf;
	
	PartnerParameter = Undefined;
	If Parameters.Filter.Property("Partner", PartnerParameter) Then
		Partner = PartnerParameter;
		Items.FilterPartner.Visible = False;
		Parameters.Filter.Delete("Partner");
		
		ListSelectionsClientServer.ChangeListSelectionElement(
			List, 
			"Partner", 
			Partner, 
			ValueIsFilled(Partner),
			DataCompositionComparisonType.Equal);
			
	EndIf;
	
	ParameterVATTaxation = Undefined;
	If Parameters.Filter.Property("VATTaxation", ParameterVATTaxation) Then
		VATTaxation = ParameterVATTaxation;
		TypeOfComparisonVATTaxation = DataCompositionComparisonType.Equal;
		If TypeOf(VATTaxation) = Type("ValueList") Then
			TypeOfComparisonVATTaxation = DataCompositionComparisonType.InList;
		EndIf;
		
		Parameters.Filter.Delete("VATTaxation");
		
		ListSelectionsClientServer.ChangeListSelectionElement(
			List, 
			"VATTaxation", 
			VATTaxation, 
			ValueIsFilled(VATTaxation),
			TypeOfComparisonVATTaxation);
			
	EndIf;

	DateParameter = Undefined;
	If Parameters.Filter.Property("Date", DateParameter) Then
		Date = DateParameter;
		Items.FilterDate.Visible = False; 
		Parameters.Filter.Delete("Date");
		
		ListSelectionsClientServer.ChangeListSelectionElement(
			List, 
			"Date", 
			EndOfDay(Date), 
			ValueIsFilled(Date),
			DataCompositionComparisonType.LessOrEqual);
			
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.List.CommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	SetPartnerSelectionParameters();
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure FilterSourceDocumentTypeOnChange(Item)
	
	FilterSourceDocumentTypeOnChangeServer()
	
EndProcedure

&AtClient
Procedure FilterCounterpartyOnChange(Item)
	
	ListSelectionsClientServer.ChangeListSelectionElement(
		List, 
		"Counterparty", 
		Counterparty, 
		ValueIsFilled(Counterparty),
		DataCompositionComparisonType.Equal);
		
EndProcedure

&AtClient
Procedure FilterNumberOnChange(Item)

	ListSelectionsClientServer.ChangeListSelectionElement(
		List, 
		"Number", 
		Number, 
		ValueIsFilled(Number),
		DataCompositionComparisonType.Contains);

EndProcedure

&AtClient
Procedure FilterDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ListSelectionsClientServer.ChangeListSelectionElement(
		List, 
		"Date", 
		BegOfDay(Date), 
		ValueIsFilled(Date),
		DataCompositionComparisonType.GreaterOrEqual);
		
	ListSelectionsClientServer.ChangeListSelectionElement(
		List, 
		"Date", 
		EndOfDay(Date), 
		ValueIsFilled(Date),
		DataCompositionComparisonType.LessOrEqual);

EndProcedure

&AtClient
Procedure FilterIncomingDocumentNumberOnChange(Item)

	ListSelectionsClientServer.ChangeListSelectionElement(
		List, 
		"IncomingDocumentNumber", 
		IncomingDocumentNumber, 
		ValueIsFilled(IncomingDocumentNumber),
		DataCompositionComparisonType.Contains);

EndProcedure

&AtClient
Procedure FilterIncomingDocumentDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ListSelectionsClientServer.ChangeListSelectionElement(
		List, 
		"IncomingDocumentDate", 
		BegOfDay(IncomingDocumentDate), 
		ValueIsFilled(IncomingDocumentDate),
		DataCompositionComparisonType.GreaterOrEqual);
	
	ListSelectionsClientServer.ChangeListSelectionElement(
		List, 
		"IncomingDocumentDate", 
		EndOfDay(IncomingDocumentDate), 
		ValueIsFilled(IncomingDocumentDate),
		DataCompositionComparisonType.LessOrEqual);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	If Copy Then
		Return;
	EndIf;
	
	Cancel = True;
	
	FillingValues = New Structure();
	If ValueIsFilled(SourceDocumentType) Then
		FillingValues.Insert("SourceDocumentType", SourceDocumentType);
	Else
		TypesArray = Items.FilterSourceDocumentType.ChoiceList.UnloadValues();
		FillingValues.Insert("SourceDocumentType", New FixedArray(TypesArray));
	EndIf;
	If ValueIsFilled(Partner) Then
		FillingValues.Insert("Partner", Partner);
	EndIf;
	If ValueIsFilled(Counterparty) Then
		FillingValues.Insert("Counterparty", Counterparty);
	EndIf;
	If ValueIsFilled(Number) Then
		FillingValues.Insert("Number", Number);
	EndIf;
	If ValueIsFilled(Date) Then
		FillingValues.Insert("Date", Date);
	EndIf;
	If ValueIsFilled(IncomingDocumentNumber) Then
		FillingValues.Insert("IncomingDocumentNumber", IncomingDocumentNumber);
	EndIf;
	If ValueIsFilled(IncomingDocumentDate) Then
		FillingValues.Insert("IncomingDocumentDate", IncomingDocumentDate);
	EndIf;
	For Each ElementSelection In List.Filter.Items Do
		If ElementSelection.Use
			And ElementSelection.ComparisonType = DataCompositionComparisonType.Equal Then
			FillingValues.Insert(ElementSelection.LeftValue, ElementSelection.RightValue);
		EndIf;
		If ElementSelection.LeftValue = New DataCompositionField("Organization")
			And TypeOf(ElementSelection.RightValue) = Type("ValueList")
			And ElementSelection.RightValue.Count() > 0 Then
			FillingValues.Insert("Organization", ElementSelection.RightValue[0].Value);
		EndIf;
	EndDo;
	
	FormParameters = New Structure("FillingValues", FillingValues);
	
	OpenForm("Document.SourceDocument.ObjectForm", FormParameters, ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

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
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure FilterPartnerOnChange(Item)
	
	FilterPartnerOnChangeServer();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FilterPartnerOnChangeServer()
	
	If Partner = Catalogs.Partners.OurEnterprise Then
		If TypeOf(Counterparty) <> Type("CatalogRef.Companies") Then
			Counterparty = Catalogs.Companies.EmptyRef();
		EndIf;
	Else
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	EndIf;
	
	ListSelectionsClientServer.ChangeListSelectionElement(
		List, 
		"Counterparty", 
		Counterparty, 
		ValueIsFilled(Counterparty),
		DataCompositionComparisonType.Equal);
		
	ListSelectionsClientServer.ChangeListSelectionElement(
		List, 
		"Partner", 
		Partner, 
		ValueIsFilled(Partner),
		DataCompositionComparisonType.Equal);
		
EndProcedure

&AtServer
Procedure SetPartnerSelectionParameters()
	
	ParametersArray = New Array;

	If SourceDocumentType = Enums.SourceDocumentTypes.PaymentFromCustomer
		 Or SourceDocumentType = Enums.SourceDocumentTypes.SaleToCustomer
		 Or SourceDocumentType = Enums.SourceDocumentTypes.SaleAdjustment Then
		ParametersArray.Add(New ChoiceParameter("Filter.Client", True));
	ElsIf SourceDocumentType = Enums.SourceDocumentTypes.PaymentToVendor
		 Or SourceDocumentType = Enums.SourceDocumentTypes.PurchaseFromVendor
		 Or SourceDocumentType = Enums.SourceDocumentTypes.PurchaseAdjustment Then
		ParametersArray.Add(New ChoiceParameter("Filter.Vendor", True));
	EndIf;

	If GetFunctionalOption("UseCustomerInvoiceIntercompany") Then
		ParametersArray.Add(New ChoiceParameter("SetSelectionByPartnerTypeAsOR", True));
		ParametersArray.Add(New ChoiceParameter("Filter.OurEnterprise", True));
	EndIf;

	Items.FilterPartner.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure

&AtServer
Procedure FilterSourceDocumentTypeOnChangeServer()
	
	If ValueIsFilled(SourceDocumentType) Then
		ListSelectionsClientServer.ChangeListSelectionElement(
			List, 
			"SourceDocumentType", 
			SourceDocumentType, 
			True,
			DataCompositionComparisonType.Equal);
	Else
		ListSelectionsClientServer.ChangeListSelectionElement(
			List, 
			"SourceDocumentType", 
			 Items.FilterSourceDocumentType.ChoiceList.Copy(), 
			True,
			DataCompositionComparisonType.InList);
	EndIf;
	
	SetPartnerSelectionParameters();
	
	SelectAccordingToSeller = SourceDocumentType = Enums.SourceDocumentTypes.PurchaseFromVendor
	                           Or SourceDocumentType = Enums.SourceDocumentTypes.PurchaseAdjustment;
	Items.FilterIncomingDocumentNumber.Visible = SelectAccordingToSeller;
	Items.FilterIncomingDocumentDate.Visible = SelectAccordingToSeller;
	
EndProcedure

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
	If Item.Name = "sh_ShamsiInput_F_Date" Then
		FilterDateOnChange(Items.FilterDate);
	ElsIf Item.Name = "sh_ShamsiInput_F_IncomingDocumentDate" Then
		FilterIncomingDocumentDateOnChange(Items.FilterIncomingDocumentDate);
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
