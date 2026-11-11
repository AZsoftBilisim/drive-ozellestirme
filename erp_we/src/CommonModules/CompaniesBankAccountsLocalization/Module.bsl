
#Region Public

#Region EventHandlers

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure Filling(Object, FillingData, StandardProcessing) Export
	
	If GetFunctionalOption("UseBankFeedsExchange")
	And Not GetFunctionalOption("RFPaymentsSupport")  Then

		If FillingData = Undefined Then
			FillingData = New Structure;
		EndIf;
		
		FillingData.Insert("UseBankFeedsBankExchange", True);
		FillingData.Insert("UseBankClientDataExchange", False);
		
		Return;
	EndIf;
	
	
	Return;
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - CatalogObject.CompaniesBankAccounts - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array of String - Array of paths to the details to be checked for.
//
Procedure FillCheckProcessing(Object, Cancel, CheckedAttributes) Export
	
	
	Return;
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure BeforeWrite(Object, Cancel) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure OnWrite(Object, Cancel) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - CatalogObject - processed object
//  CopiedObject - CatalogObject - The source directory that is the source of copying.
//
Procedure OnCopy(Object, CopiedObject) Export
	
	If Object.AccountUnderStateContract Then
		Object.LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
		Object.PersonalAccountSection = "";
	EndIf;
	
	Object.AccountUnderStateContract = False;
	
EndProcedure

#EndRegion

#Region AttachableCommands

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	Return;
	
EndProcedure

#EndRegion

#Region Print

// Generates a printable form.
//
// Parameters:
//  ObjectsArray  - Array of CatalogRef.CompaniesBankAccounts - references to objects that should be printed;
//  PrintParameters - Structure - advanced print settings;
//  PrintFormsCollection - ValueTable - generated table documents (output parameter)
//  PrintObjects         - ValueList of CatalogRef.CompaniesBankAccounts - value - the object reference;
//                                            view - name of the area where the object was output (output parameter);
//  OutputParameters       - Structure       - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export


EndProcedure

#EndRegion

#EndRegion

#Region Private

#EndRegion
