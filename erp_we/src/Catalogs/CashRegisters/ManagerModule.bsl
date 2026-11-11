#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Gets the object's details that need to be blocked from being changed
//
// Returns:
//	Array - the blocked details of the object.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	Result.Add("CashCurrency");
	Result.Add("Owner");
	Result.Add("Warehouse");
	Result.Add("CashRegisterType");
	
	Return Result;
	
EndFunction

// This function defines the default fiscal Registrar.
//
// Returns the cash register of the KKM, if one cash register is found.
// Returns Undefined if the sales register is not found or there are more than one sales registers.
//
// Returns:
//	CatalogRef.CashRegisters - The found cash register of the KKM.
//
Function CashRegisterFiscalRegistrarByDefault() Export
	
	CashRegister = Undefined;
	
	Query = New Query(
	"SELECT TOP 2
	|	CashRegisters.Ref AS CashRegister
	|FROM
	|	Catalog.CashRegisters AS CashRegisters
	|WHERE
	|	CashRegisters.CashRegisterType = VALUE(Enum.CashRegisterTypes.FiscalCashRegisters)
	|");
	
	Selection = Query.Execute().Select();
	If Selection.Count() = 1 Then
		If Selection.Next() Then
			CashRegister = Selection.CashRegister;
		EndIf;
	EndIf;
	
	Return CashRegister;

EndFunction

// Determines whether the Cur cash register is specified in the settings of the CWP user or not
// 
// Returns:
//  Boolean - One or more Cash registers are specified in the CWP settings of the VCM
Function CashRegisterHasBeenSetUpForCWP() Export
	
	CashRegisterHasBeenSetUpForCWP = False;
	
	Query = New Query(
	"SELECT ALLOWED TOP 1
	|	CashRegisters.Ref AS CashRegister
	|FROM
	|	Catalog.CashRegisters AS CashRegisters
	|WHERE
	|	CashRegisters.CashRegisterType = VALUE(Enum.CashRegisterTypes.FiscalCashRegisters)
	|	AND 1 IN
	|			(SELECT
	|				1
	|			FROM
	|				Catalog.CWPSettings.CashRegisters AS T
	|			WHERE
	|				T.Ref.Workplace = &Workplace
	|				AND T.CashRegister = CashRegisters.Ref)
	|");
	Query.Parameters.Insert("Workplace", EquipmentManagerServerCall.GetClientSWorkplace());
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		CashRegisterHasBeenSetUpForCWP = True;
	EndIf;
	
	Return CashRegisterHasBeenSetUpForCWP;
	
EndFunction

// This function defines the default fiscal Registrar.
//
// Returns the cash register of the KKM, if one cash register is found.
// Returns Undefined if the sales register is not found or there are more than one sales registers.
//
// Returns:
//	CatalogRef.CashRegisters - The found cash register of the KKM.
//
Function CashRegisterCashRegisterFiscalRegistrarForCWP() Export
	
	CashRegister = Undefined;
	
	Query = New Query(
	"SELECT ALLOWED TOP 1
	|	CashRegisters.Ref AS CashRegister
	|INTO CashAccountCWPSettings
	|FROM
	|	Catalog.CashRegisters AS CashRegisters
	|WHERE
	|	CashRegisters.CashRegisterType = VALUE(Enum.CashRegisterTypes.FiscalCashRegisters)
	|	AND 1 IN
	|		(SELECT
	|			1
	|		FROM
	|			Catalog.CWPSettings.CashRegisters AS T
	|		WHERE
	|			T.Ref.Workplace = &Workplace
	|			AND T.CashRegister = CashRegisters.Ref)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED TOP 1
	|	CashRegisters.Ref AS CashRegister
	|INTO CashAccountsOfCashAccountList
	|FROM
	|	Catalog.CashRegisters AS CashRegisters
	|WHERE
	|	CashRegisters.CashRegisterType = VALUE(Enum.CashRegisterTypes.FiscalCashRegisters)
	|	AND NOT CashRegisters.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CashAccountCWPSettings.CashRegister AS CashRegister
	|FROM
	|	CashAccountCWPSettings AS CashAccountCWPSettings
	|
	|UNION ALL
	|
	|SELECT
	|	CashAccountsOfCashAccountList.CashRegister AS CashRegister
	|FROM
	|	CashAccountsOfCashAccountList AS CashAccountsOfCashAccountList
	|WHERE
	|	NOT 1 IN
	|		(SELECT
	|			1
	|		FROM
	|			CashAccountCWPSettings AS T)");
	
	Query.Parameters.Insert("Workplace", EquipmentManagerServerCall.GetClientSWorkplace());
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		CashRegister = Selection.CashRegister;
	EndIf;
	
	Return CashRegister;

EndFunction

// Determines whether at least one element (fiscal registrar) of the KKM Cash Register directory has been created or not
// 
// Returns:
//  Boolean - one or more fiscal registrars have been created
Function CashRegisterOfKKMIsCreatedInSystem() Export  
	
	CashRegisterOfKKMIsCreatedInSystem = False;
	
	Query = New Query(
	"SELECT TOP 1
	|	CashRegisters.Ref AS CashRegister
	|FROM
	|	Catalog.CashRegisters AS CashRegisters
	|WHERE
	|	CashRegisters.CashRegisterType = VALUE(Enum.CashRegisterTypes.FiscalCashRegisters)
	|	AND NOT CashRegisters.DeletionMark");     
	
	SetPrivilegedMode(True); 
	Selection = Query.Execute().Select(); 
	SetPrivilegedMode(False);
	
	If Selection.Next() Then
		CashRegisterOfKKMIsCreatedInSystem = True;
	EndIf;	
	
	Return CashRegisterOfKKMIsCreatedInSystem;        
	
EndFunction

// This function determines the CMC by connecting Equipment for the current RMK.
//
// Returns:
//	 CatalogRef.CashRegisters - The found cash register of the KKM.
//
Function CashDeskCashRegisterForPlugInEquipmentForCWP(Val Peripherals) Export
	
	CashRegister = Undefined;
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	CashRegisterCWPSettings.Ref AS Ref,
	|	CashRegisterCWPSettings.CashRegister AS CashRegister,
	|	CashRegisterCWPSettings.Peripherals AS Peripherals
	|FROM
	|	Catalog.CWPSettings.CashRegisters AS CashRegisterCWPSettings
	|WHERE
	|	CashRegisterCWPSettings.Ref.Workplace = &Workplace
	|	AND CashRegisterCWPSettings.Peripherals = &Peripherals
	|	AND NOT CashRegisterCWPSettings.Ref.DeletionMark";
	Query.Parameters.Insert("Workplace", EquipmentManagerServerCall.GetClientSWorkplace());
	Query.Parameters.Insert("Peripherals", Peripherals);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		CashRegister = Selection.CashRegister;
	EndIf;
	
	Return CashRegister;
	
EndFunction

// This function defines an offline checkout by default.
//
// Returns the cash register of the KKM, if one cash register is found.
// Returns Undefined if the sales register is not found or there are more than one sales registers.
//
// Returns:
//	CatalogRef.CashRegisters - The found cash register of the KKM.
//
Function OfflineCashRegisterCashRegisterByDefault() Export
	
	Query = New Query("
	|SELECT ALLOWED TOP 2
	|	CashRegisters.Ref AS CashRegister
	|FROM
	|	Catalog.CashRegisters AS CashRegisters
	|WHERE
	|	CashRegisters.CashRegisterType = VALUE(Enum.CashRegisterTypes.MobileCashRegister)
	|	AND NOT CashRegisters.DeletionMark
	|");
	
	Selection = Query.Execute().Select();
	If Selection.Count() = 1 
	   And Selection.Next()
	Then
		CashRegister = Selection.CashRegister;
	Else
		CashRegister = Undefined;
	EndIf;
	
	Return CashRegister;

EndFunction

// This function defines the default sales register.
//
// Returns the cash register of the KKM, if one cash register is found.
// Returns Undefined if the sales register is not found or there are more than one sales registers.
//
// Parameters:
//  Organization - CatalogRef.Companies - Selection by the owner (the organization that owns the Cash register cash account).
//
// Returns:
//	CatalogRef.CashRegisters - The found cash register of the KKM.
//
Function CashRegisterByDefault(Organization = Undefined) Export
	
	Query = New Query("
	|SELECT ALLOWED TOP 2
	|	CashRegisters.Ref AS CashRegister
	|FROM
	|	Catalog.CashRegisters AS CashRegisters
	|WHERE
	|	NOT CashRegisters.DeletionMark
	|	AND &OrganizationSelectionCriteria
	|");
	
	ReplacementTextSelectionCriteriaByOrganization = "TRUE";
	If ValueIsFilled(Organization) Then
		ReplacementTextSelectionCriteriaByOrganization = "CashRegisters.Owner = &Organization";
		Query.Parameters.Insert("Organization", Organization);
	EndIf;
	Query.Text = StrReplace(Query.Text, "&OrganizationSelectionCriteria", ReplacementTextSelectionCriteriaByOrganization);
	
	Selection = Query.Execute().Select();
	If Selection.Count() = 1 
	   And Selection.Next()
	Then
		CashRegister = Selection.CashRegister;
	Else
		CashRegister = Undefined;
	EndIf;
	
	Return CashRegister;

EndFunction

// The function defines the Cash register of the CWP by default for the cash register. We are looking for a Cash register with the fiscal registrar type 
// that is configured for the Cur workplace for the specified organization. If the second parameter 
// is set, this Cash register will be returned to this particular cashier if there is a setting for the Cur workplace.
//
// Parameters:
//  Organization - CatalogRef.Companies -
//  PreferredCashRegister - Undefined, CatalogRef.CashRegisters -
//
// Returns:
//  CatalogRef.CashRegisters, Undefined -
//
Function KKMCashRegisterIsFiscalCashRegisterByCompanyForCWPByDefault(Val Organization, Val PreferredCashRegister = Undefined) Export

	CashRegister = Undefined;
	
	CashRegisters = KKMCashRegistersAreRegisteredByCompanyForCWP(Organization, Enums.CashRegisterTypes.FiscalCashRegisters);
	If CashRegisters.Count() Then
		If ValueIsFilled(PreferredCashRegister) 
			And CashRegisters.Find(PreferredCashRegister) <> Undefined  Then
			CashRegister = PreferredCashRegister;
		Else
			CashRegister = CashRegisters[0];
		EndIf;
	EndIf;

	Return CashRegister;

EndFunction

// The function defines the configured Cash register cash registers configured for the Cur workplace, by the specified organization and type of cash register.
//
// Parameters:
//  Organization - CatalogRef.Companies -
//  CashRegisterType - Undefined, EnumRef.CashRegisterTypes, Array of EnumRef.CashRegisterTypes -
//
// Returns:
//  Array of CatalogRef.CashRegisters
//
Function KKMCashRegistersAreRegisteredByCompanyForCWP(Val Organization, Val CashRegisterType = Undefined) Export

	CashRegisters = New Array;

	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	CashRegisterCWPSettings.Ref AS Ref,
	|	CashRegisterCWPSettings.CashRegister AS CashRegister,
	|	CashRegisterCWPSettings.Peripherals AS Peripherals
	|FROM
	|	Catalog.CWPSettings.CashRegisters AS CashRegisterCWPSettings
	|WHERE
	|	CashRegisterCWPSettings.Ref.Workplace = &Workplace
	|	AND NOT CashRegisterCWPSettings.Ref.DeletionMark
	|	AND CashRegisterCWPSettings.CashRegister.Owner = &Organization
	|	AND &SelectionCriteriaByCashAccountType";
	
	ReplacementTextOfSelectionCriteriaByCashAccountType = "TRUE";
	If ValueIsFilled(CashRegisterType) Then
		ReplacementTextOfSelectionCriteriaByCashAccountType = "CashRegisterCWPSettings.CashRegister.CashRegisterType IN (&CashRegisterType)";
		Query.Parameters.Insert("CashRegisterType", CashRegisterType);
	EndIf;
	Query.Text = StrReplace(Query.Text, "&SelectionCriteriaByCashAccountType", ReplacementTextOfSelectionCriteriaByCashAccountType);
	
	Query.Parameters.Insert("Workplace", EquipmentManagerServerCall.GetClientSWorkplace());
	Query.Parameters.Insert("Organization", Organization);

	Selection = Query.Execute().Select();

	While Selection.Next() Do
		CashRegisters.Add(Selection.CashRegister);
	EndDo;

	Return CashRegisters;

EndFunction

// This function determines the currency of the selected cash register.
//
// Parameters:
//  CashRegister - CatalogRef.CashRegisters - Link to the KKM sales register.
//
// Returns:
//	Structure - Organization and Currency of the selected cash register:
//	 *Warehouse - CatalogRef.Warehouses, Undefined -
//	 *Organization - CatalogRef.Companies, Undefined -
//	 *PriceKind - CatalogRef.TypesOfPrices, Undefined -
//	 *PriceIncludesVAT - Boolean, Undefined -
//	 *Currency - CatalogRef.Currencies, Undefined -
//	 *CashRegisterType - EnumRef.CashRegisterTypes, Undefined -
//	 *ItinerantTrade - Boolean, Undefined -
//	 *Department - CatalogRef.BusinessStructure, Undefined -
//
Function CashRegisterDetails(CashRegister) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	CashRegisters.Warehouse AS Warehouse,
	|	CashRegisters.Owner AS Organization,
	|	CashRegisters.Warehouse.RetailPriceType AS PriceKind,
	|	CashRegisters.Warehouse.RetailPriceType.PriceIncludesVAT AS PriceIncludesVAT,
	|	CashRegisters.CashCurrency AS Currency,
	|	CashRegisters.CashRegisterType AS CashRegisterType,
	|	CashRegisters.ItinerantTrade AS ItinerantTrade,
	|	CashRegisters.Department AS Department
	|FROM
	|	Catalog.CashRegisters AS CashRegisters
	|WHERE
	|	CashRegisters.Ref = &CashRegister";
	
	Query.SetParameter("CashRegister", CashRegister);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Warehouse           = Selection.Warehouse;
		Organization     = Selection.Organization;
		PriceKind         = Selection.PriceKind;
		PriceIncludesVAT = Selection.PriceIncludesVAT;
		Currency          = Selection.Currency;
		CashRegisterType        = Selection.CashRegisterType;
		ItinerantTrade = Selection.ItinerantTrade;
		Department   = Selection.Department;
	Else
		Warehouse           = Undefined;
		Organization     = Undefined;
		PriceKind         = Undefined;
		PriceIncludesVAT = Undefined;
		Currency          = Undefined;
		CashRegisterType        = Undefined;
		ItinerantTrade = Undefined;
		Department   = Undefined;
	EndIf;
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Warehouse", Warehouse);
	AttributesStructure1.Insert("Organization", Organization);
	AttributesStructure1.Insert("PriceKind", PriceKind);
	AttributesStructure1.Insert("PriceIncludesVAT", PriceIncludesVAT);
	AttributesStructure1.Insert("Currency", Currency);
	AttributesStructure1.Insert("CashRegisterType", CashRegisterType);
	AttributesStructure1.Insert("ItinerantTrade", ItinerantTrade);
	AttributesStructure1.Insert("Department", Department);
	
	Return AttributesStructure1;

EndFunction

// This function retrieves the parameters of the cash register KKM.
//
// Parameters:
//  CashRegister - CatalogRef.CashRegisters - Cash registers.
//
// Returns:
//  Structure - with properties:
//   * DeviceID - String - Device ID.
//   * UseWithoutConnectingPeripherals - Boolean - Use without connecting equipment.
//   * ThisIsFiscalRegistrar - Boolean - A sign of the fiscal registrar.
//   * UseWarerooms - Boolean - a sign of the use of storage facilities.
//   * CashRegister - CatalogRef.CashRegisters - Cash registers.
//   * CWPSettings - CatalogRef.CWPSettings - Link to the RMK settings.
//
Function CashRegisterParameters(CashRegister) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ISNULL(CashRegisterCWPSettings.Ref, VALUE(Catalog.CWPSettings.EmptyRef)) AS CWPSettings,
	|	CASE
	|		WHEN CashRegisters.CashRegisterType = VALUE(Enum.CashRegisterTypes.FiscalCashRegisters)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsFiscalRegistrar,
	|	ISNULL(CashRegisterCWPSettings.Peripherals, VALUE(Catalog.Peripherals.EmptyRef)) AS DeviceID,
	|	CASE WHEN
	|		CashRegisterCWPSettings.Peripherals.EquipmentType = VALUE(Enum.PeripheralTypes.CREWithDataTransfer) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS DataTransferAvailable,
	|	ISNULL(CashRegisterCWPSettings.UseWithoutConnectingPeripherals, TRUE) AS UseWithoutConnectingPeripherals,
	|	CashRegisters.Ref                AS CashRegister,
	|	CashRegisters.CashCurrency AS Currency,
	|	CashRegisters.Owner              AS Organization,
	|	ISNULL(CashRegisters.Warehouse.UseWarerooms, FALSE) AS UseWarerooms,
	|	CASE WHEN ISNULL(CashRegisterCWPSettings.UseWithoutConnectingPeripherals, FALSE) THEN
	|		CashRegisters.SerialNumber
	|	ELSE
	|		CASE WHEN CashRegisterCWPSettings.Peripherals.SerialNumber <> """" THEN
	|			CashRegisterCWPSettings.Peripherals.SerialNumber
	|		ELSE
	|			CashRegisters.SerialNumber
	|		END
	|	END AS SerialNumber,
	|	CashRegisters.ItinerantTrade AS ItinerantTrade
	|FROM
	|	Catalog.CashRegisters AS CashRegisters
	|		LEFT JOIN Catalog.CWPSettings.CashRegisters AS CashRegisterCWPSettings
	|		ON (CashRegisterCWPSettings.CashRegister = CashRegisters.Ref)
	|			AND (CashRegisterCWPSettings.Ref.Workplace = &Workplace)
	|WHERE
	|	CashRegisters.Ref = &Ref";
	
	Query.SetParameter("Ref", CashRegister);
	Query.SetParameter("Workplace", EquipmentManagerServerCall.GetClientSWorkplace());
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	ReturnValue = New Structure;
	ReturnValue.Insert("DeviceID",                Catalogs.Peripherals.EmptyRef());
	ReturnValue.Insert("UseWithoutConnectingPeripherals", True);
	ReturnValue.Insert("ThisIsFiscalRegistrar",               False);
	ReturnValue.Insert("UseWarerooms",         False);
	ReturnValue.Insert("Organization",                            Catalogs.Companies.EmptyRef());
	ReturnValue.Insert("CashRegister",                               CashRegister);
	ReturnValue.Insert("Currency",                                 SettingsValueCached.DefaultBaseCurrency());
	ReturnValue.Insert("DataTransferAvailable",                 False);
	ReturnValue.Insert("CWPSettings",                           Catalogs.CWPSettings.EmptyRef());
	ReturnValue.Insert("SerialNumber",                          "");
	ReturnValue.Insert("ItinerantTrade",                     False);
	
	If Selection.Next() Then
		
		ReturnValue.DeviceID                = Selection.DeviceID;
		ReturnValue.UseWithoutConnectingPeripherals = Selection.UseWithoutConnectingPeripherals;
		ReturnValue.ThisIsFiscalRegistrar               = Selection.ThisIsFiscalRegistrar;
		ReturnValue.UseWarerooms         = Selection.UseWarerooms;
		ReturnValue.Organization                            = Selection.Organization;
		ReturnValue.CashRegister                               = Selection.CashRegister;
		ReturnValue.Currency                                 = Selection.Currency;
		ReturnValue.DataTransferAvailable                 = Selection.DataTransferAvailable;
		ReturnValue.CWPSettings                           = Selection.CWPSettings;
		ReturnValue.SerialNumber                          = Selection.SerialNumber;
		ReturnValue.ItinerantTrade                     = Selection.ItinerantTrade;
		
	EndIf;
	
	Return ReturnValue;
	
EndFunction

// Returns the names of attributes, which should not appear in the list of details of the processing Gruposeincentivos.
//
//	Returns:
//		Array - an array of the names of the details.
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array;
	NotAttributesToEdit.Add("Owner");
	NotAttributesToEdit.Add("CashCurrency");
	NotAttributesToEdit.Add("Warehouse");
	NotAttributesToEdit.Add("CashRegisterType");
	
	Return NotAttributesToEdit;
	
EndFunction

// Receives the balance of cash issued to the cash register of the cash register, but not yet received
//
// Parameters:
//    CashRegister - CatalogRef.CashRegisters - Link to the KKM sales register.
//
// Returns:
//    Number - the amount of funds to be received at the cash register of the KKM.
Function AmountToBeReceived(CashRegister) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	Cash.SumBalance AS ToReceive
	|FROM
	|	AccumulationRegister.CashInTransit.Balance(, Recipient = &CashRegister) AS Cash
	|";
	
	Query.SetParameter("CashRegister", CashRegister);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.ToReceive;
	Else
		Return 0;
	EndIf;
	
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
	|	ValueAllowed(Owner)
	|	AND ValueAllowed(Ref)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#EndIf
