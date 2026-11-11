
#Region Public

// Checks whether the cash shift is active. Activity means compliance with the following conditions:
// the cash shift is not closed, no more than 24 hours have passed since the opening of the cash shift.
//
// Parameters:
//  CashRegisterShift - DocumentRef.CashRegisterShift - Cash shift that needs to be checked for activity
//
// Returns:
//  Boolean - shift activity.
Function ShiftIsActive(CashRegisterShift) Export
	
	ShiftDescription = DescriptionOfCashShift(CashRegisterShift);
	
	If ShiftDescription = Undefined Then
		Return False;
	ElsIf ShiftDescription.Status = Enums.CashRegisterShiftStatuses.IsOpen
		And ShiftDescription.ExpirationDate_1 > CommonCEL.SessionDate() Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Checks whether the cash shift is closed.
//
// Parameters:
//  CashRegisterShift - DocumentRef.CashRegisterShift - Cash shift that needs to be checked for activity
//
// Returns:
//  Boolean - True - the shift is closed, False - the shift is not closed
Function ShiftClosed(CashRegisterShift) Export
	
	DescriptionOfLastShift = DescriptionOfCashShift(CashRegisterShift);
	
	If DescriptionOfLastShift = Undefined Then
		Return True;
	ElsIf Not DescriptionOfLastShift.Status = Enums.CashRegisterShiftStatuses.IsOpen Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Gets the details of the cash shift
//
// Parameters:
//  CashRegisterShift - DocumentRef.CashRegisterShift - Cash shift that needs to be checked for activity
//
// Returns:
//  Structure - Attributes of the cash shift. Contains the following Attributes:
//    *CashRegisterShift - DocumentRef.CashRegisterShift - Link to the cash shift
//    *FiscalDevice - CatalogRef.Peripherals - link to the device on which the shift is open
//    *CashRegisterShiftStart - Date - shift opening date
//    *CashRegisterShiftEnd - Date - closing date of the shift (if the shift was closed)
//    *ExpirationDate_1 - Date - on which the validity period of the shift ends (opening date + 24 hours)
//    *Organization - DefinedType.CompanyCEL - the organization specified in the Cash Exchange document
//    *Status - EnumRef.CashRegisterShiftStatuses - the status of the cash shift.
Function DescriptionOfCashShift(CashRegisterShift) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query();
	Query.Text =
	"SELECT ALLOWED TOP 1
	|	CashRegisterShift.Ref AS CashRegisterShift,
	|	CashRegisterShift.FiscalDevice,
	|	CashRegisterShift.CashRegisterShiftStart,
	|	CashRegisterShift.CashRegisterShiftEnd,
	|	DATEADD(CashRegisterShift.CashRegisterShiftStart, DAY, 1) AS ExpirationDate_1,
	|	CashRegisterShift.Organization,
	|	CashRegisterShift.Status
	|FROM
	|	Document.CashRegisterShift AS CashRegisterShift
	|WHERE
	|	CashRegisterShift.Ref = &CashRegisterShift";
	Query.SetParameter("CashRegisterShift", CashRegisterShift);
	Result = Query.Execute().Unload();
	
	If Result.Count() = 0 Then
		Return Undefined;
	Else
		ResultingStructure = New Structure();
		For Each ResultColumn In Result.Columns Do
			ResultingStructure.Insert(ResultColumn.Name, Result[0][ResultColumn.Name]);
		EndDo;
		Return ResultingStructure;
	EndIf;
	
EndFunction

// The fiscal device determines the status of the shift and checks its activity. Activity means compliance with the following conditions:
// - the cash shift is not closed no more than 24 hours have passed since the opening of the cash shift.
//
// Parameters:
//  FiscalDevice - CatalogRef.Peripherals - fiscal device for which you want to determine the activity shifts
//
// Returns:
//  Structure:
//    *IsOpen - Boolean - The truth - the shift is open, the lie - the shift is closed.
//    *Active - Boolean - True - the shift is open, False - the shift is closed, more than 24 hours have passed since the opening or has never been opened.
//    *CurReceiptNumber - Number - The current number of the KKT receipt.
// 
Function LastShiftStatus(FiscalDevice) Export
	
	If TypeOf(FiscalDevice) <> Type("CatalogRef.Peripherals") Then
		Return Undefined;
	EndIf;
	
	SetPrivilegedMode(True);
	
	OperationResult = New Structure();
	OperationResult.Insert("Active", False);
	OperationResult.Insert("IsOpen", False);
	OperationResult.Insert("CurReceiptNumber");
	OperationResult.Insert("ShiftNumber");
	OperationResult.Insert("CashRegisterShift");
	OperationResult.Insert("CREShiftNumber");
	OperationResult.Insert("ExpirationDate_1");
	   
	DescriptionOfLastShift = DescriptionOfLastCashShift(FiscalDevice);
	
	If Not (DescriptionOfLastShift = Undefined) Then
		OperationResult.IsOpen = DescriptionOfLastShift.Status = Enums.CashRegisterShiftStatuses.IsOpen; 
		OperationResult.Active = OperationResult.IsOpen And DescriptionOfLastShift.ExpirationDate_1 > CommonCEL.SessionDate();
		
		FiscalDeviceTypeOfEquipment = CommonCEL.ObjectAttributeValue(FiscalDevice, "EquipmentType");
		CashShiftLink = DescriptionOfLastShift.CashRegisterShift;
		POSShiftAttributes = CommonCEL.ObjectAttributesValues(CashShiftLink, "Number, CREShiftNumber");
		OperationResult.CashRegisterShift = CashShiftLink;
		OperationResult.ShiftNumber = POSShiftAttributes.Number;
		OperationResult.CREShiftNumber = POSShiftAttributes.CREShiftNumber;
		OperationResult.ExpirationDate_1 = DescriptionOfLastShift.ExpirationDate_1;
	EndIf;
	
	Return OperationResult;
	
EndFunction

// The fiscal device detects the last shift and checks whether it is closed.
//
// Parameters:
//  FiscalDevice - CatalogRef.Peripherals - fiscal device to determine whether a shift is closed
//
// Returns:
//  Boolean - True - the shift is closed or has never been opened, False - the shift is not closed
Function LastShiftClosed(FiscalDevice) Export
	
	DescriptionOfLastShift = DescriptionOfLastCashShift(FiscalDevice);
	
	If DescriptionOfLastShift = Undefined Then
		
		Return True;
		
	ElsIf Not DescriptionOfLastShift.Status = Enums.CashRegisterShiftStatuses.IsOpen Then
		
		Return True;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

// According to the fiscal device, it determines the last shift and receives its details.
//
// Parameters:
//  FiscalDevice - CatalogRef.Peripherals - fiscal device for which you want to determine the activity of the shift.
//
// Returns:
//  Structure - Attributes Of the cash shift, Undefined - if no shift was opened. Contains the following Attributes:
//    *CashRegisterShift - DocumentRef.CashRegisterShift - Link to the cash shift
//    *FiscalDevice - CatalogRef.Peripherals - link to the device on which the shift is open
//    *CashRegisterShiftStart - Date - shift opening date
//    *CashRegisterShiftEnd - Date - closing date of the shift (if the shift was closed)
//    *ExpirationDate_1 - Date - on which the validity period of the shift ends (opening date + 24 hours)
//    *Organization - DefinedType.CompanyCEL - the organization specified in the Cash Exchange document.
//    *Status - EnumRef.CashRegisterShiftStatuses - the status of the cash shift.
Function DescriptionOfLastCashShift(FiscalDevice) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query();
	Query.Text =
	"SELECT ALLOWED TOP 1
	|	CashRegisterShift.Ref AS CashRegisterShift,
    |    CashRegisterShift.FiscalDevice AS FiscalDevice,
    |    CashRegisterShift.CashRegisterShiftStart AS CashRegisterShiftStart,
    |    CashRegisterShift.CashRegisterShiftEnd AS CashRegisterShiftEnd,
	|	DATEADD(CashRegisterShift.CashRegisterShiftStart, DAY, 1) AS ExpirationDate_1,
    |    CashRegisterShift.Organization AS Organization,
    |    CashRegisterShift.Status AS Status
	|FROM
	|	Document.CashRegisterShift AS CashRegisterShift
	|WHERE
	|	CashRegisterShift.FiscalDevice = &FiscalDevice
	|	AND CashRegisterShift.Posted
	|
	|ORDER BY
    |    CashRegisterShift.CashRegisterShiftStart DESC,
    |    CashRegisterShift.CREShiftNumber DESC";
	If TypeOf(FiscalDevice) = Type("CatalogRef.Peripherals") Then
		Query.SetParameter("FiscalDevice", FiscalDevice);
	Else
		Query.SetParameter("CashRegister", FiscalDevice);
		Query.Text = StrReplace(Query.Text, "FiscalDevice", "CashRegister");
	EndIf;
	Result = Query.Execute().Unload();
	
	If Result.Count() = 0 Then
		Return Undefined;
	Else
		ResultingStructure = New Structure();
		For Each ResultColumn In Result.Columns Do
			ResultingStructure.Insert(ResultColumn.Name, Result[0][ResultColumn.Name]);
		EndDo;
		Return ResultingStructure;
	EndIf;
	
EndFunction

// Create a new cash shift.
//
// Parameters:
//  FiscalDevice - CatalogRef.Peripherals
//  CommandParameters - Structure
//
// Returns:
//  DocumentRef.CashRegisterShift
//
Function NewCashRegisterShift(FiscalDevice, CommandParameters) Export
	
	SetPrivilegedMode(True);
	
	CashShiftObject = Documents.CashRegisterShift.CreateDocument();
	CashShiftObject.Date = CommonCEL.SessionDate();
	CashShiftObject.FiscalDevice = FiscalDevice;
	CashShiftObject.CashRegisterShiftStart = CashShiftObject.Date;
	If TypeOf(FiscalDevice) = Type("CatalogRef.Peripherals") Then
		CashShiftObject.Organization = CommonCEL.ObjectAttributeValue(FiscalDevice, "Organization");
	Else
		CashShiftObject.Organization = FiscalDevice.Owner; 
		CashShiftObject.CashRegister = FiscalDevice;
		CashShiftObject.CREShiftNumber = 1;
	EndIf;
	CashShiftObject.Status = Enums.CashRegisterShiftStatuses.IsOpen;
	
	If CommandParameters <> Undefined Then 
		
		If CommandParameters.Property("AdditionalParameters")
			And CommandParameters.AdditionalParameters <> Undefined Then
			FillPropertyValues(CashShiftObject, CommandParameters.AdditionalParameters);
		EndIf;
		
		If CommandParameters.Property("FiscalDataStructure") Then
			FillPropertyValues(CashShiftObject, CommandParameters.FiscalDataStructure);
		EndIf;
		
		If CommandParameters.Property("FiscalDataXMLString") Then
			CashShiftObject.FDOnShiftEndClosing = New ValueStorage(CommandParameters.FiscalDataXMLString, New Deflation(9));
		EndIf;
		
	EndIf;
	
	CashShiftObject.Write(DocumentWriteMode.Posting);
	
	Return CashShiftObject.Ref;
	
EndFunction

// Close the previously opened cash shift.
//
// Parameters:
//  CommandParameters - Structure
//   * Cash Exchange - Document link.Cash Exchange
//
Procedure CloseRegisterShift(CommandParameters) Export
	
	SetPrivilegedMode(True);
	
	CashShiftObject = CommandParameters.CashRegisterShift.GetObject(); // DocumentObject.CashRegisterShift
	CashShiftObject.Status = Enums.CashRegisterShiftStatuses.Closed_;
	CashShiftObject.CashRegisterShiftEnd = CommonCEL.SessionDate();
	
	If CommandParameters.Property("FiscalDataStructure") Then
		FillPropertyValues(CashShiftObject, CommandParameters.FiscalDataStructure);
	EndIf;
	
	If CommandParameters.Property("FiscalDataXMLString") Then
		CashShiftObject.FDOnShiftEndClosing = New ValueStorage(CommandParameters.FiscalDataXMLString, New Deflation(9));
	EndIf;
	
	CashShiftObject.Write(DocumentWriteMode.Posting);
	
EndProcedure

#EndRegion