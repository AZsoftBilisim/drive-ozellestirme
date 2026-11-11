#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// This function determines the details of the selected acquiring terminal.
//
// Parameters:
//    POSTerminal - CatalogRef.POSTerminals - Link to the acquiring terminal.
//
// Returns:
//    Structure - Attributes of the acquiring terminal:
//    	* AcquiringContract - CatalogRef.AcquiringContracts - The acquiring contract
//    	* Organization - CatalogRef.Companies - Organization
//    	* Acquirer - CatalogRef.Counterparties - Acquirer
//    	* Currency - CatalogRef.Currencies - Currency
//    	* EnableCreatingCashIssueWithoutPaymentRequest - Boolean - Indicates whether refunds are allowed without submitting requests for
//    		spending funds.
//
Function GetDetailsOfAcquiringTerminal(POSTerminal) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	POSTerminals.Owner AS AcquiringContract,
	|	POSTerminals.Owner.Organization AS Organization,
	|	POSTerminals.Owner.Counterparty AS Acquirer,
	|	POSTerminals.Owner.BankAccount.CashCurrency AS Currency,
	|	POSTerminals.EnableCreatingCashIssueWithoutPaymentRequest
	|FROM
	|	Catalog.POSTerminals AS POSTerminals
	|WHERE
	|	POSTerminals.Ref = &POSTerminal
	|";
	
	Query.SetParameter("POSTerminal", POSTerminal);
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("AcquiringContract", Catalogs.AcquiringContracts.EmptyRef());
	AttributesStructure1.Insert("Organization", Catalogs.Companies.EmptyRef());
	AttributesStructure1.Insert("Acquirer", Catalogs.Counterparties.EmptyRef());
	AttributesStructure1.Insert("Currency", Catalogs.Currencies.EmptyRef());
	AttributesStructure1.Insert("EnableCreatingCashIssueWithoutPaymentRequest", False);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FillPropertyValues(AttributesStructure1, Selection);
	EndIf;
	
	Return AttributesStructure1;
	
EndFunction

// This function determines the acquiring terminal for the selected organization and / or acquiring agreement.
//
// Returns an acquiring terminal if one acquiring terminal is found.
// Returns an empty link if the acquiring terminal is not found or there are more than one acquiring terminals.
//
// Parameters:
//    Organization - CatalogRef.Companies - The selected organization.
//    Contract - CatalogRef.AcquiringContracts - The selected Contract for connecting to the payment system.
//
// Returns:
//    CatalogRef.POSTerminals - The acquiring terminal found.
//
Function DefaultPOSTerminal(Organization = Undefined, Contract = Undefined) Export
	
	Query = New Query("
	|SELECT ALLOWED TOP 2
	|	POSTerminals.Ref AS POSTerminal
	|FROM
	|	Catalog.POSTerminals AS POSTerminals
	|WHERE
	|	NOT POSTerminals.DeletionMark
	|	AND (POSTerminals.Owner.Organization = &Organization
	|		OR &Organization = UNDEFINED)
	|	AND (POSTerminals.Owner = &Contract
	|		OR &Contract = UNDEFINED)
	|");
	
	Query.SetParameter("Organization", ?(ValueIsFilled(Organization), Organization, Undefined));
	Query.SetParameter("Contract", ?(ValueIsFilled(Contract), Contract, Undefined));
	
	Selection = Query.Execute().Select();
	If Selection.Count()=1 And Selection.Next() Then
		POSTerminal = Selection.POSTerminal;
	Else
		POSTerminal = Catalogs.POSTerminals.EmptyRef();
	EndIf;
	
	Return POSTerminal;
	
EndFunction

// Returns the acquiring terminal for the connected equipment
// 
// Parameters:
//  Workplace - CatalogRef.Workplaces - Job
//  DeviceID - CatalogRef.Peripherals - Device ID
// 
// Returns:
//  Undefined, CatalogRef.POSTerminals - Acquiring terminal for connected equipment
Function AcquiringTerminalForConnectedEquipment(Workplace, DeviceID) Export
	
	Workplace = EquipmentManagerServerCall.CustomerWorkplace();
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	CWPSettingsPOSTerminals.POSTerminal AS POSTerminal
	|FROM
	|	Catalog.CWPSettings.POSTerminals AS CWPSettingsPOSTerminals
	|WHERE
	|	CWPSettingsPOSTerminals.Ref.Workplace = &Workplace
	|	AND CWPSettingsPOSTerminals.Peripherals = &DeviceID
	|";
	Query.SetParameter("Workplace", Workplace);
	Query.SetParameter("EquipmentWorkplace", Workplace);
	Query.SetParameter("DeviceID", DeviceID);
	
	QuerySelection = Query.Execute().Select();
	
	If QuerySelection.Next() Then
		Return QuerySelection.POSTerminal;
	EndIf;
	
	Return Undefined;
	
EndFunction
	
// The function determines the acquiring terminals for the transferred organization and workplace and returns their CWP settings.
//
// Parameters:
//    Organization - CatalogRef.Companies - The organization to return descriptions of billing terminals for.
//    Workplace - CatalogRef.Workplaces - Cur current workplace.
//    UsePeripherals - Boolean -
//
// Returns:
//    ValueList of Structure:
//    	* Ref - CatalogRef.POSTerminals - 
//    	* Peripherals - CatalogRef.Peripherals - 
//    	* UseWithoutConnectingPeripherals - Boolean -
//    	* DoNotAskForCardNumber - Boolean -
//
Function ParametersOfAcquiringTerminalsByOrganization(Organization, Workplace, UsePeripherals) Export

	POSTerminals = New ValueList;
	
	Query = New Query("
	|SELECT
	|	POSTerminals.POSTerminal AS Ref,
	|	POSTerminals.UseWithoutConnectingPeripherals AS UseWithoutConnectingPeripherals,
	|	POSTerminals.DoNotAskForCardNumber AS DoNotAskForCardNumber,
	|	POSTerminals.Peripherals AS Peripherals,
	|	POSTerminals.CREPeripherals AS CREPeripherals
	|FROM
	|	Catalog.CWPSettings.POSTerminals AS POSTerminals
	|WHERE
	|	POSTerminals.Ref.Workplace = &Workplace
	|	AND ((POSTerminals.Peripherals <> VALUE(Catalog.Peripherals.EmptyRef)
	|		AND POSTerminals.Peripherals.Workplace = &EquipmentWorkplace)
	|		OR POSTerminals.UseWithoutConnectingPeripherals)
	|	AND POSTerminals.POSTerminal.Owner.BankAccount.Owner = &Organization
	|");
	
	Query.SetParameter("Workplace", Workplace);
	Query.SetParameter("Organization",  Organization);
	If UsePeripherals Then
		Query.SetParameter("EquipmentWorkplace", Workplace);
	Else
		Query.SetParameter("EquipmentWorkplace", Catalogs.Workplaces.EmptyRef());
	EndIf;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		POSTerminal = New Structure;
		POSTerminal.Insert("Ref",                                 Selection.Ref);
		POSTerminal.Insert("Peripherals",               Selection.Peripherals);
		POSTerminal.Insert("CREPeripherals",            Selection.CREPeripherals);
		POSTerminal.Insert("UseWithoutConnectingPeripherals", Selection.UseWithoutConnectingPeripherals);
		POSTerminal.Insert("DoNotAskForCardNumber",                Selection.DoNotAskForCardNumber);
		
		POSTerminals.Add(POSTerminal);
		
	EndDo;
	
	Return POSTerminals;
	
EndFunction

// The function returns the equipment ET with the sign to verify that theinaetprisacrity of the caseload
// 
// Parameters:
//  CREPeripherals - CatalogRef.Peripherals - Link to connect to the CCT
// 
// Returns:
//  Array of CatalogRef.Peripherals - equipment et.
//
Function PlugInEquipmentOfAcquiringTerminalForReconciliationOfTotals(CREPeripherals) Export 
	
	Workplace = EquipmentManagerServerCall.CustomerWorkplace();
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	CWPSettingsPOSTerminals.Peripherals AS Peripherals
	|FROM
	|	Catalog.CWPSettings.POSTerminals AS CWPSettingsPOSTerminals
	|WHERE
	|	CWPSettingsPOSTerminals.Ref.Workplace = &Workplace
	|	AND CWPSettingsPOSTerminals.CREPeripherals = &CREPeripherals
	|	AND CWPSettingsPOSTerminals.ReconcileTotalsAtPOSTerminalUponShiftEndClosing
	|	AND Peripherals.DeviceIsInUse
	|	AND Peripherals.DeletionMark = FALSE";
	Query.SetParameter("Workplace", Workplace);
	Query.SetParameter("CREPeripherals", CREPeripherals);
	
	QuerySelection = Query.Execute().Select();
	
	ConnectedTerminals = New Array;
	While QuerySelection.Next() Do
		ConnectedTerminals.Add(QuerySelection.Peripherals);
	EndDo;
	
	Return ConnectedTerminals;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	IsFolder OR
	|	ValueAllowed(Owner.Organization)
	|	AND( ValueAllowed(Ref)
	|	) ";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Description");
	Fields.Add("Code");
	Fields.Add("IsFolder");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	If Not Data.IsFolder
		And ValueIsFilled(Data.Code) And TrimAll(Data.Code) <> "0" Then
		Presentation = TrimAll(Data.Code) + ", " + TrimAll(Data.Description);
	Else
		Presentation = TrimAll(Data.Description);
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Get blocked object Attributes.
// 
// Returns:
//  Array of String - Get blocked object Attributes
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	Result.Add("Partner");
	Result.Add("Contract");
	Result.Add("BankAccount");
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf
