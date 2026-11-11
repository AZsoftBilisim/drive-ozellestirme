#Region Public

// See PrintManagementOverridable.OnDefinePrintSettings
Procedure OnDefinePrintSettings(Settings) Export
	
	
EndProcedure

// Defines configuration objects, in the manager modules of which the Add Print Command procedure is placed,
// which forms a list of print commands provided by this object.
// For the syntax of the Add Print Command procedure, see the documentation for the subsystem.
//
// Parameters:
//  ListOfObjects - Array - object managers with the add print Command procedure.
//
Procedure OnDefineObjectsWithPrintCommands(ListOfObjects) Export
	
EndProcedure

// See PrintManagementOverridable.BeforeAddPrintCommands
Procedure BeforeAddPrintCommands(FormName, PrintCommands, StandardProcessing) Export
	
	
EndProcedure

// Additional settings for the list of print commands in document logs.
//
// See PrintManagementOverridable.OnGetPrintCommandListSettings
//
Procedure OnGetPrintCommandListSettings(ListSettings) Export
	
	
EndProcedure

// Allows you to perform post-processing of printed forms during their formation.
// For example, you can insert the date when the printed form was created in the footer.
// Called after the Print procedure of the object's print Manager is completed, it has the same parameters.
//
// See PrintManagementOverridable.OnPrint
//
Procedure OnPrint(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export

	
EndProcedure

// Allows you to change the appearance and behavior of the form, for example, to place additional elements on it:
// information labels, buttons, hyperlinks, various settings, etc.
//
// See PrintManagementOverridable.PrintDocumentsOnCreateAtServer
//
Procedure PrintDocumentsOnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	
EndProcedure

// Adds information about the legal entity/individual
//
// Parameters:
//  FieldList - String - list of fields in the PrintForm Formation structure.Vedenyapina
//
Procedure AddInformationAboutLegalEntityToListOfFields(FieldList) Export
EndProcedure

// Generates information about the specified legal entity or individual.
// Information includes: name, address, phone number, Bank details.
//
// Parameters: 
//  InformationRecords - Structure - collected information.
//  Attributes - Structure - details of the legal Entity.
//  LegalEntityIndividual  - CatalogRef.Companies, CatalogRef.Counterparties - the organization or individual that information is collected about.
//  PeriodDate_ - Date - the date on which information about the legal Entity is selected.
//	CompanyIsMajorTaxpayer - Boolean - If the company is the largest taxpayer, fill in the checkpoint of the checkpoint of the largest.
//
Procedure AddInformationAboutLegalEntity(InformationRecords, Attributes, LegalEntityIndividual, PeriodDate_, CompanyIsMajorTaxpayer = False) Export
EndProcedure

// Adds information about the Bank account
//
// Parameters:
//  AccountAttributes - Structure - account details
//  InformationRecords - Structure - collected information.
//  BankAccount - CatalogRef.CompaniesBankAccounts - link to the invoice.
//
Procedure AddBankAccountInformation(AccountAttributes, InformationRecords, BankAccount) Export
EndProcedure
 
// Gets the name of the contact information type. 
//
// Parameters:
//  Object - CatalogRef -  contact information object.
//  AddressType - String - the type of the requested address. It can contain the following values:"", "Actual", "Registration", " Legal"
//  ContactInformationKind - String - name of the type of contact information (return value).
//
Procedure GetTypeOfContactInformation(Object, AddressType, ContactInformationKind = "Address") Export
EndProcedure

// Generates a format string according to the "Unified format of electronic banking messages" for displaying it as
// a QR code.
// 
// Parameters:
// 	StringText - String - Parameter that returns a string for generating a QR code.
// 	DocumentData  - Structure - Contains the values of the document fields.
// 
Procedure GenerateStringInFormatOfElectronicBankMessages(StringText, DocumentData) Export
EndProcedure

// Allows you to set additional settings for print commands.
//
// Parameters:
//   FullMetadataObjectName   - MetadataObject - which command sources are connected to
//   PrintCommands 		- See PrintManagement.CreatePrintCommandsCollection
//
Procedure OnReceivePrintCommands(FullMetadataObjectName, PrintCommands) Export
	
	
EndProcedure

#EndRegion

#Region Private

// See PrintFormGeneration.WhenFillingControlModules
Procedure WhenFillingControlModules(ControlModules) Export
EndProcedure

#EndRegion