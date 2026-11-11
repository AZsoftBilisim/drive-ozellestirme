///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Generates and displays print forms.
// 
// Parameters:
//  PrintManagerName - String - Print manager for the objects to print.
//  TemplatesNames       - String - Print form IDs.
//  ObjectsArray     - AnyRef
//                     - Array of AnyRef - Print objects.
//  FormOwner      - ClientApplicationForm - Form where the printing is executed.
//  PrintParameters    - Structure - Arbitrary parameters to pass to the print manager.
//
// Example:
//   PrintManagementClient.ExecutePrintCommand("DataProcessor.PrintForm", "GoodsWriteOff", DocumentsForPrinting, ThisObject);
//
Procedure ExecutePrintCommand(PrintManagerName, TemplatesNames, ObjectsArray, FormOwner, PrintParameters = Undefined) Export
	
	If Not CheckPassedObjectsCount(ObjectsArray) Then
		Return;
	EndIf;
	
	ParameterName = "StandardSubsystems.Print.ExecutePrintCommand";
	PassedParametersList = ApplicationParameters[ParameterName];
	
	If PassedParametersList = Undefined Then
		PassedParametersList = New Array;
		ApplicationParameters[ParameterName] = PassedParametersList;
	EndIf;
	
	OpeningParameters = PrintManagementInternalClient.ParametersForOpeningPrintForm();
	OpeningParameters.PrintManagerName = PrintManagerName;
	OpeningParameters.TemplatesNames = TemplatesNames;
	OpeningParameters.CommandParameter = ObjectsArray;
	OpeningParameters.PrintParameters = PrintParameters;
	OpeningParameters.FormOwner = FormOwner;
	
	PassedParametersList.Add(OpeningParameters);
	
	AttachIdleHandler("ResumePrintCommandWithPassedParameters", 0.1, True);
	
EndProcedure

// Generates and outputs print forms to the printer.
//
// Parameters:
//  PrintManagerName - String - Print manager for the objects to print.
//  TemplatesNames       - String - Print form IDs.
//  ObjectsArray     - AnyRef
//                     - Array of AnyRef - Print objects.
//  PrintParameters    - Structure - Arbitrary parameters to pass to the print manager.
//
// Example:
//   PrintManagementClient.ExecutePrintToPrinterCommand("DataProcessor.PrintForm", "GoodsWriteOff", DocumentsForPrinting);
//
Procedure ExecutePrintToPrinterCommand(PrintManagerName, TemplatesNames, ObjectsArray, PrintParameters = Undefined) Export

	// Check the number of objects.
	If Not CheckPassedObjectsCount(ObjectsArray) Then
		Return;
	EndIf;
	
	// Generate spreadsheet documents.
#If ThickClientOrdinaryApplication Then
	PrintForms = PrintManagementServerCall.GeneratePrintFormsForQuickPrintOrdinaryApplication(
			PrintManagerName, TemplatesNames, ObjectsArray, PrintParameters);
	If Not PrintForms.Cancel Then
		PrintObjects = New ValueList;
		For Each PrintObject In PrintForms.PrintObjects Do
			PrintObjects.Add(PrintObject.Value, PrintObject.Key);
		EndDo;
		PrintForms.PrintObjects = PrintObjects;
	EndIf;
#Else
	PrintForms = PrintManagementServerCall.GeneratePrintFormsForQuickPrint(
			PrintManagerName, TemplatesNames, ObjectsArray, PrintParameters);
#EndIf
	
	If PrintForms.Cancel Then
		CommonClient.MessageToUser(NStr("vi = 'Không có quyền hiển thị mẫu in trên máy in, hãy liên hệ với người quản trị.';
										|ru = 'Нет прав для вывода печатной формы на принтер, обратитесь к администратору.';
										|en = 'Insufficient rights to print out the form. Contact your administrator.'; fa = 'Insufficient rights to print out the form. Contact your administrator.';
										|it = 'Non si dispone dell''autorizzazione per stampare il modulo di stampa dalla stampante, contattare l''amministratore.';
										|pl = 'Nie ma prawa dla wyprowadzenia formularzy wydruku na drukarkę, skontaktuj się z administratorem.';
										|tr = 'Yazdırma formunu yazıcıya gönderme yetkiniz yok. Yöneticinize başvurun.'"));
		Return;
	EndIf;
	
	// Print out.
	PrintSpreadsheetDocuments(PrintForms.SpreadsheetDocuments, PrintForms.PrintObjects);
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	If CommonClient.SubsystemExists("StandardSubsystems.SourceDocumentsOriginalsRecording") Then
		PrintList = New ValueList;
		For Each Template In PrintForms.SpreadsheetDocuments Do 
			PrintList.Add(TemplatesNames, Template.Presentation);
		EndDo;
	  	ModuleSourceDocumentsOriginalsAccountingClient = CommonClient.CommonModule("SourceDocumentsOriginalsRecordingClient");
		ModuleSourceDocumentsOriginalsAccountingClient.WriteOriginalsStatesAfterPrint(PrintForms.PrintObjects, PrintList);
	EndIf;
	// End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure

// Outputting spreadsheet documents to the printer.
//
// Parameters:
//  SpreadsheetDocuments           - ValueList - print forms.
//  PrintObjects                - ValueList - a correspondence between objects and names of spreadsheet document areas.
//  PrintInSets          - Boolean
//                               - Undefined - Not used (it's calculated automatically).
//  SetCopies    - Number - a number of each document set copies.
//
Procedure PrintSpreadsheetDocuments(SpreadsheetDocuments, PrintObjects, Val PrintInSets = Undefined, 
	Val SetCopies = 1) Export
	
	PrintInSets = SpreadsheetDocuments.Count() > 1;
	RepresentableDocumentBatch = PrintManagementServerCall.DocumentsPackage(SpreadsheetDocuments,
		PrintObjects, PrintInSets, SetCopies);
	RepresentableDocumentBatch.Print(PrintDialogUseMode.DontUse);
	
EndProcedure

// Executes interactive document posting before printing.
// If there are unposted documents, prompts the user to post them. Asks
// the user whether they want to continue if any of the documents are not posted and at the same time some of the documents are posted.
//
// Parameters:
//  CompletionProcedureDetails - CallbackDescription - Procedure to which the control needs to be passed after execution.
//                                                     Parameters of the called procedure:
//                                :
//                                  DocumentsList - Array - posted documents;
//                                  AdditionalParameters - a value specified when creating a notification
//                                                            object.
//  DocumentsList            - Array            - references to the documents that require posting.
//  Form                       - ClientApplicationForm  - a form the command is called from. The parameter
//                                                    is required to reread the form when the procedure
//                                                    is called from the object form.
//
Procedure CheckDocumentsPosting(CompletionProcedureDetails, DocumentsList, Form = Undefined) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CompletionProcedureDetails", CompletionProcedureDetails);
	AdditionalParameters.Insert("DocumentsList", DocumentsList);
	AdditionalParameters.Insert("Form", Form);
	
	ClearMessages();
	DocsPostInfoRecords = AttachableCommandsClient.DocsPostInfoRecords(DocumentsList);
	HasUnpostedDocuments = DocsPostInfoRecords.UnpostedDocuments.Count() > 0;
	If HasUnpostedDocuments Then
		AdditionalParameters.Insert("UnpostedDocuments", DocsPostInfoRecords.UnpostedDocuments);
		AdditionalParameters.Insert("HasPostingRight", DocsPostInfoRecords.HasPostingRight);
		PrintManagementInternalClient.CheckDocumentsPostedPostingDialog(AdditionalParameters);
	Else
		RunCallback(CompletionProcedureDetails, DocumentsList);
	EndIf;
	
EndProcedure

// Opens the PrintDocuments form for a spreadsheet document collection.
//
// Parameters:
//  PrintFormsCollection - Array of See NewPrintFormsCollection
//  PrintObjects - ValueList - See PrintManagementOverridable.OnPrint
//  AdditionalParameters - See PrintParameters
//                          - ClientApplicationForm - the form to print from;
//
Procedure PrintDocuments(PrintFormsCollection, Val PrintObjects = Undefined,
	AdditionalParameters = Undefined) Export
	
	PrintParameters = PrintParameters();
	
	FormOwner = Undefined;
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		FillPropertyValues(PrintParameters, AdditionalParameters);
		FormOwner = PrintParameters.FormOwner;
		PrintParameters.Delete("FormOwner");
	ElsIf TypeOf(AdditionalParameters) = Type("ClientApplicationForm") Then 
		FormOwner = AdditionalParameters; // For backward compatibility with version 3.0.2.
	EndIf;
	
	If PrintObjects = Undefined Then
		PrintObjects = New ValueList;
	EndIf;
	
	UniqueKey = String(New UUID);
	
	OpeningParameters = New Structure("PrintManagerName,TemplatesNames,CommandParameter,PrintParameters");
	OpeningParameters.CommandParameter = New Array;
	OpeningParameters.Insert("PrintFormsCollection", PrintFormsCollection);
	OpeningParameters.Insert("PrintObjects", PrintObjects);
	OpeningParameters.Insert("PrintParameters", PrintParameters);
	OpeningParameters.Insert("TemplatesNames", New Array);
	
	For Each PrintFormDetails In PrintFormsCollection Do
		OpeningParameters.TemplatesNames.Add(PrintFormDetails.TemplateName);
	EndDo;
	
	OpenForm("CommonForm.PrintDocuments", OpeningParameters, FormOwner, UniqueKey);
	
EndProcedure

// Constructor of the AdditionalParameters parameter of the PrintDocuments procedure.
//
//  Returns:
//   Structure - Additional parameters for opening a print form:
//    * FormOwner - ClientApplicationForm - a form from which the printing is executed.
//    * Title     - String - a title of the PrintDocuments form.
//
Function PrintParameters() Export
	
	Result = New Structure;
	Result.Insert("FormOwner");
	Result.Insert("FormCaption");
	
	Return Result;
	
EndFunction

// Constructor of the PrintFormsCollection parameter for procedures and functions in this module.
// See PrintDocuments
// See PrintFormDetails.
//
// Parameters:
//  IDs - String - Print form IDs.
//
// Returns:
//  Array - Collection of print form descriptions. The collection is designed for use as
//           the PrintFormsCollection parameter in other procedures of the client software interface of the subsystem.
//           To access collection items, use the PrintFormDetails function.
//
Function NewPrintFormsCollection(Val IDs) Export
	
	If TypeOf(IDs) = Type("String") Then
		IDs = StrSplit(IDs, ",");
	EndIf;
	
	Fields = PrintManagementClientServer.PrintFormsCollectionFieldsNames();
	AddedPrintForms = New Map;
	Result = New Array;
	
	For Each Id In IDs Do
		PrintForm = AddedPrintForms[Id];
		If PrintForm = Undefined Then
			PrintForm = New Structure(StrConcat(Fields, ","));
			PrintForm.TemplateName = Id;
			PrintForm.UpperCaseName = Upper(Id);
			PrintForm.Copies2 = 1;
			AddedPrintForms.Insert(Id, PrintForm);
			Result.Add(PrintForm);
		Else
			PrintForm.Copies2 = PrintForm.Copies2 + 1;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Returns description of the print form found in the collection.
// If the description does not exist, returns Undefined.
//
// Parameters:
//  PrintFormsCollection - Array of See NewPrintFormsCollection.
//  Id         - String - print form ID.
//
// Returns:
//  Structure - Print form details found in the print form collection:
//   * TemplateSynonym - String - a print form presentation;
//   * SpreadsheetDocument - SpreadsheetDocument - print form;
//   * Copies2 - Number - a number of copies to be printed;
//   * FullTemplatePath - String - used for quick access to print form template editing;
//   * PrintFormFileName - String - file name;
//                           - Map of KeyAndValue - Filenames for each object:
//                              ** Key - AnyRef - a reference to the print object;
//                              ** Value - String - file name;
//   * OfficeDocuments - Map of KeyAndValue - Collection of print forms in the format of office documents:
//                         ** Key - String - an address in the temporary storage of binary data of the print form;
//                         ** Value - String - a print form file name.
//
Function PrintFormDetails(PrintFormsCollection, Id) Export
	For Each PrintFormDetails In PrintFormsCollection Do
		If PrintFormDetails.UpperCaseName = Upper(Id) Then
			Return PrintFormDetails;
		EndIf;
	EndDo;
	Return Undefined;
EndFunction

// Opens a selection form of template opening mode.
//
Procedure SetActionOnChoosePrintFormTemplate() Export
	
	OpenForm("InformationRegister.UserPrintTemplates.Form.SelectTemplateOpeningMode");
	
EndProcedure

// Opens a form showing how to create a facsimile signature and a stamp.
Procedure ShowInstructionOnHowToCreateFacsimileSignatureAndSeal() Export
	
	ScanAvailable = False;
	If CommonClient.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperationsClient = CommonClient.CommonModule("FilesOperationsClient");
		ScanAvailable = ModuleFilesOperationsClient.ScanAvailable();
	EndIf;
	GenerationParameters = New Structure ("ScanAvailable", ScanAvailable);
	ExecutePrintCommand("InformationRegister.CommonSuppliedPrintTemplates", "GuideToCreateFacsimileAndStamp", 
		PredefinedValue("Catalog.MetadataObjectIDs.EmptyRef"), Undefined, GenerationParameters);
	
EndProcedure

// To be used in the procedures of the PrintManagementClientOverridable.PrintDocuments module<…>.
// Returns a collection of the current print form parameters in the "Print documents" form (CommonForm.PrintDocuments).
// 
// Parameters:
//  Form - ClientApplicationForm - PrintDocuments form passed in the Form parameter of the
//                             PrintManagementClientOverridable common module procedure.
//
// Returns:
//  FormDataCollectionItem - Settings of the current print form.
//
Function CurrentPrintFormSetup(Form) Export
	Result = Form.Items.PrintFormsSettings.CurrentData;
	If Result = Undefined And Form.PrintFormsSettings.Count() > 0 Then
		Result = Form.PrintFormsSettings[0];
	EndIf;
	Return Result;
EndFunction

// Determines the type of the PrintParameters parameter in print command handlers.
// 
// Returns:
//  Structure:
//   * Form - ClientApplicationForm - a form where printing is executed.
//   * PrintObjects - Array of AnyRef - objects by which print forms must be generated.
//   * Id - String - Print command ID. The print manager uses this ID to determine a print
//                              form to be generated.
//                              For example, "OrderInvoice".
//
//                              To print multiple print forms, you can specify all their
//                              IDs at once (as a comma-separated string or an array of strings), for example::
//                              "OrderInvoice,WarrantyLetter".
//
//                              To set a number of copies for a print form, duplicate its
//                              ID as many times as the number of copies you want
//                              generated. Consider that the order of print
//                              forms in the set matches the order of print form IDs
//                              specified in this parameter. For example (2 proforma invoices + 1 warranty letter):
//                              "OrderInvoice,OrderInvoice,WarrantyLetter".
//
//                              A print form ID can contain an alternative print
//                              manager if it is different from the print manager specified in the PrintManager parameter,
//                              for example: "OrderInvoice,DataProcessor.PrintForm.WarrantyLetter".
//
//                              In this example, WarrantyLetter is generated in the
//                              DataProcessor.PrintForm print manager and OrderInvoice is generated in the print manager specified in
//                              the PrintManager parameter.
//
//                   - Array - List of IDs of print commands.
//
//   * PrintManager - String           - (Optional) Name of the object whose manager module contains
//                                        the Print procedure that generates spreadsheet documents for this command.
//                                        Default value is a name of the object manager module.
//                                         For example, "Document.ProformaInvoice".
//
//   * Handler    - String            - (Optional) Command client handler
//                                        executed instead of the standard Print command handler. It is used,
//                                        for example, when the print form is generated on the client.
//                                        Format "<CommonModuleName>.<ProcedureName>" is used when the procedure is
//                                        in a common module.
//                                        The"<ProcedureName>" format is used when the procedure is placed
//                                        in the main form module of a report or a data processor specified in PrintManager.
//                                        For example:
//                                          PrintCommand.Handler = "StandardSubsystemsClient.PrintProformaInvoices";
//                                        An example of handler in the form module::
//                                          Generates a print form <print form presentation>.
//                                          //
//                                          
//                                          Parameters:
//                                          PrintParameters - Structure - Print form info.
//                                          * PrintObjects - Array - Array of selected object references.
//                                          * Form - ClientApplicationForm - Form, from which the
//                                          print command is called.
//                                          * AdditionalParameters - Structure - Additional print parameters.
//                                          Other structure keys match the columns of the PrintCommands table,
//                                          //
//                                          For more information, see the PrintManagement.CreatePrintCommandsCollection function.
//                                          
//                                          	&AtClient
//                                          Function <FunctionName>(PrintParameters) Export
//                                        Print handler.
//                                        EndFunction
//                                        Remember that the handler is called using the Calculate method,
//                                         so only a function can act as a handler.
//                                         The subsystem does not use the return value of the function.
//
//   * SkipPreview - Boolean           - (Optional) Flag indicating whether the documents must be sent to a printer without a preview.
//                                        If not specified, the print command opens the "Print documents" preview form.
//                                        
//
//   * SaveFormat - SpreadsheetDocumentFileType - (optional) used for quick saving of a print
//                                        form (without additional actions) to non-MXL formats.
//                                        If the parameter is not specified, the print form is saved to an MXL format.
//                                        For example, SpreadsheetDocumentFileType.PDF.
//
//                                        In this example, selecting a print command opens a PDF
//                                        document.
//
//   * FormCaption  - String          - (Optional) Arbitrary string overriding the standard header of the Print documents form.
//                                         For example, "Customizable set".
//                                         
//
//   * OverrideCopiesUserSetting - Boolean - (optional) shows whether the option to save or restore the number of copies selected by
//                                        user for printing in
//                                        the PrintDocuments form is to be disabled. If the parameter is not specified,
//                                        the option of saving or restoring settings will be applied upon opening the form.
//                                        PrintDocuments.
//
//   * AddExternalPrintFormsToSet - Boolean - (Optional) Shows whether the document set is to be supplemented
//                                        with all external print forms connected to the object
//                                        (the AdditionalReportsAndDataProcessors subsystem). If the parameter is not specified, external
//                                        print forms are not added to the set.
//   * FixedSet - Boolean    - (optional) shows whether users can change
//                                        the document set. If the parameter is not specified, the user can
//                                        exclude some print forms from the set in the PrintDocuments form and
//                                        change the number of copies.
//
//   * AdditionalParameters - Structure - (Optional) Arbitrary parameters to pass to the print manager.
//
//
Function DescriptionOfPrintParameters() Export
	
	Result = New Structure;
	Result.Insert("Form");
	Result.Insert("PrintObjects");
	Result.Insert("Id");
	Result.Insert("PrintManager");
	Result.Insert("Handler");
	Result.Insert("SkipPreview");
	Result.Insert("SaveFormat");
	Result.Insert("FormCaption");
	Result.Insert("OverrideCopiesUserSetting");
	Result.Insert("AddExternalPrintFormsToSet");
	Result.Insert("FixedSet");
	Result.Insert("AdditionalParameters");
	
	Result.Insert("DefaultPrintForm");
	Result.Insert("ReplaceDefaultPrintForm");
	Result.Insert("IDFromSet");
	Result.Insert("Id");
	Result.Insert("PrintFormDescription");
	
	Return Result;
	
EndFunction

#Region ObsoleteProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// Operations with office document templates.

//	This section contains interface functions (API) used for creating printed forms based on office
//	documents from MS Office (MS Word templates) and Open Office (OO Writer templates).
//
////////////////////////////////////////////////////////////////////////////////
//	
//	Data types used (defined by specific implementations):
//	RefPrintForm - Reference to the print form.
//	RefTemplate - Reference to the template.
//						Area  - Reference to an area within the print form or template (structure).
//						It is defined in the interface module based on the internal information.
//	AreaDetails - Details of the template area (see below).
//	FillingData - Either a structure or an array of structures (used for lists and tables).
//							AreaDetails - Structure that describes user-prepared areas of the template
////////////////////////////////////////////////////////////////////////////////
//	Key AreaName - Name of the area.
//	Key AreaTypeType -
//	Header
//							Footer
//							Shared3
//							TableRow
//							List
//

#Region InitializationAndLinkClosureFunctions

// Deprecated. Use PrintManagement.InitializePrintForm.
//
// Creates a connection to the output print form.
// Call this function before performing any actions on the form.
// The function does not work in any other browsers except for Internet Explorer.
// This function requires 1C:Enterprise Extension installed to operate in the web client.
//
// Parameters:
//  DocumentType            - String - Print form type: DOC or ODT.
//  TemplatePagesSettings - Map - Parameters from the structure returned by the InitializeTemplate function
//                                           (the parameter is obsolete, skip it and use the Template parameter).
//  Template                   - Structure - Result of the InitializeTemplate function.
//
// Returns:
//  Structure - New print form.
// 
Function InitializePrintForm(Val DocumentType, Val TemplatePagesSettings = Undefined, Template = Undefined) Export
	
	If Upper(DocumentType) = "DOC" Then
		Parameter = ?(Template = Undefined, TemplatePagesSettings, Template); // For backward compatibility purposes.
		PrintForm = PrintManagementMSWordClient.InitializeMSWordPrintForm(Parameter);
		PrintForm.Insert("Type", "DOC");
		PrintForm.Insert("LastOutputArea", Undefined);
		Return PrintForm;
	ElsIf Upper(DocumentType) = "ODT" Then
		PrintForm = PrintManagementOOWriterClient.InitializeOOWriterPrintForm(Template);
		PrintForm.Insert("Type", "ODT");
		PrintForm.Insert("LastOutputArea", Undefined);
		Return PrintForm;
	EndIf;
	
EndFunction

// Deprecated. Obsolete. Use PrintManagement.InitializeOfficeDocumentTemplate.
//
// Creates a COM connection with a template. This connection is used later for getting template areas (tags and
// tables).
// The function does not work in any other browsers except for Internet Explorer.
// This function requires 1C:Enterprise Extension installed to operate in the web client.
//
// Parameters:
//  BinaryTemplateData - BinaryData - Binary template data.
//  TemplateType            - String - Print form template type: DOC or ODT.
//  TemplateName            - String - Name to be used for creating a temporary template file.
//
// Returns:
//  Structure - Template.
//
Function InitializeOfficeDocumentTemplate(Val BinaryTemplateData, Val TemplateType, Val TemplateName = "") Export
	
	Template = Undefined;
	TempFileName = "";
	
#If WebClient Then
		If IsBlankString(TemplateName) Then
			TempFileName = String(New UUID) + "." + Lower(TemplateType);
		Else
			TempFileName = TemplateName + "." + Lower(TemplateType);
		EndIf;
#EndIf
	
	If Upper(TemplateType) = "DOC" Then
		Template = PrintManagementMSWordClient.GetMSWordTemplate(BinaryTemplateData, TempFileName);
		If Template <> Undefined Then
			Template.Insert("Type", "DOC");
		EndIf;
	ElsIf Upper(TemplateType) = "ODT" Then
		Template = PrintManagementOOWriterClient.GetOOWriterTemplate(BinaryTemplateData, TempFileName);
		If Template <> Undefined Then
			Template.Insert("Type", "ODT");
			Template.Insert("TemplatePagesSettings", Undefined);
		EndIf;
	EndIf;
	
	Return Template;
	
EndFunction

// Deprecated. Obsolete. Use the PrintManagement.ClearRefs procedure.
//
// Releases links in the created interface of connection with office application.
// Always call this procedure after the template is generated and the print form is displayed to a user.
//
// Parameters:
//  PrintForm     - Structure - a result of the InitializePrintForm and InitializeOfficeDocumentTemplate functions;
//  CloseApplication - Boolean    - True, if it is necessary to close the application.
//                                  Connection to the template must be closed when closing the application.
//                                  PrintForm does not need to be closed.
//
Procedure ClearRefs(PrintForm, Val CloseApplication = True) Export
	
	If PrintForm <> Undefined Then
		If PrintForm.Type = "DOC" Then
			PrintManagementMSWordClient.CloseConnection(PrintForm, CloseApplication);
		Else
			PrintManagementOOWriterClient.CloseConnection(PrintForm, CloseApplication);
		EndIf;
		PrintForm = Undefined;
	EndIf;
	
EndProcedure

#EndRegion

#Region PrintFormDisplayFunction

// Deprecated. It is not required anymore.
//
// Shows the generated document to a user.
//
// Parameters:
//  PrintForm - Structure - a result of the InitializePrintForm function.
//
Procedure ShowDocument(Val PrintForm) Export
	
	If PrintForm.Type = "DOC" Then
		PrintManagementMSWordClient.ShowMSWordDocument(PrintForm);
	ElsIf PrintForm.Type = "ODT" Then
		PrintManagementOOWriterClient.ShowOOWriterDocument(PrintForm);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Functions for getting template areas, outputting them to print forms,
// and filling their parameters.

// Deprecated. Obsolete. Use PrintManagement.TemplateArea.
//
// Gets a print form template area.
//
// Parameters:
//  RefToTemplate   - Structure - Print form template.
//  AreaDetails - Structure:
//   * AreaName - String -Area name.
//   * AreaTypeType - String - Area type: "Header", "Footer", "Common", "TableRow", "List".
//   
// Returns:
//  Structure - Template area.
//
Function TemplateArea(Val RefToTemplate, Val AreaDetails) Export
	
	Area = Undefined;
	If RefToTemplate.Type = "DOC" Then
		
		If		AreaDetails.AreaType = "Header" Then
			Area = PrintManagementMSWordClient.GetHeaderArea(RefToTemplate);
		ElsIf	AreaDetails.AreaType = "Footer" Then
			Area = PrintManagementMSWordClient.GetFooterArea(RefToTemplate);
		ElsIf	AreaDetails.AreaType = "Shared3" Then
			Area = PrintManagementMSWordClient.GetMSWordTemplateArea(RefToTemplate, AreaDetails.AreaName, 1, 0);
		ElsIf	AreaDetails.AreaType = "TableRow" Then
			Area = PrintManagementMSWordClient.GetMSWordTemplateArea(RefToTemplate, AreaDetails.AreaName);
		ElsIf	AreaDetails.AreaType = "List" Then
			Area = PrintManagementMSWordClient.GetMSWordTemplateArea(RefToTemplate, AreaDetails.AreaName, 1, 0);
		Else
			Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Chưa chỉ ra kiểu vùng hoặc đã chỉ ra sai: %1.';
																				|ru = 'Тип области не указан или указан некорректно: %1.';
																				|en = 'Area type is not specified or invalid: %1.'; fa = 'Area type is not specified or invalid: %1.';
																				|it = 'Tipo di area non indicata o indicata in maniera errata: %1.';
																				|pl = 'Rodzaj obszaru nie został podany lub jest podany niepoprawnie: %1.';
																				|tr = 'Alan tipi yanlış belirtilmemiş veya belirtilmemiş: %1.'"), AreaDetails.AreaType);
		EndIf;
		
		If Area <> Undefined Then
			Area.Insert("AreaDetails", AreaDetails);
		EndIf;
	ElsIf RefToTemplate.Type = "ODT" Then
		
		If		AreaDetails.AreaType = "Header" Then
			Area = PrintManagementOOWriterClient.GetHeaderArea(RefToTemplate);
		ElsIf	AreaDetails.AreaType = "Footer" Then
			Area = PrintManagementOOWriterClient.GetFooterArea(RefToTemplate);
		ElsIf	AreaDetails.AreaType = "Shared3"
				Or AreaDetails.AreaType = "TableRow"
				Or AreaDetails.AreaType = "List" Then
			Area = PrintManagementOOWriterClient.GetTemplateArea(RefToTemplate, AreaDetails.AreaName);
		Else
			Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Chưa chỉ ra kiểu vùng hoặc đã chỉ ra sai: %1.';
																				|ru = 'Тип области не указан или указан некорректно: %1.';
																				|en = 'Area type is not specified or invalid: %1.'; fa = 'Area type is not specified or invalid: %1.';
																				|it = 'Tipo di area non indicata o indicata in maniera errata: %1.';
																				|pl = 'Rodzaj obszaru nie został podany lub jest podany niepoprawnie: %1.';
																				|tr = 'Alan tipi yanlış belirtilmemiş veya belirtilmemiş: %1.'"), AreaDetails.AreaName);
		EndIf;
		
		If Area <> Undefined Then
			Area.Insert("AreaDetails", AreaDetails);
		EndIf;
	EndIf;
	
	Return Area;
	
EndFunction

// Deprecated. Obsolete. Use PrintManagement.AttachArea.
//
// Attaches an area to a template print form.
// The procedure is used upon output of a single area.
//
// Parameters:
//  PrintForm - See InitializePrintForm.
//  TemplateArea - See TemplateArea.
//  GoToNextRow1 - Boolean - True, if you need to add a line break after the area output.
//
Procedure AttachArea(Val PrintForm, Val TemplateArea, Val GoToNextRow1 = True) Export
	
	If TemplateArea = Undefined Then
		Return;
	EndIf;
	
	Try
		AreaDetails = TemplateArea.AreaDetails;
		
		If PrintForm.Type = "DOC" Then
			
			DerivedArea = Undefined;
			
			If		AreaDetails.AreaType = "Header" Then
				PrintManagementMSWordClient.AddHeader(PrintForm, TemplateArea);
			ElsIf	AreaDetails.AreaType = "Footer" Then
				PrintManagementMSWordClient.AddFooter(PrintForm, TemplateArea);
			ElsIf	AreaDetails.AreaType = "Shared3" Then
				DerivedArea = PrintManagementMSWordClient.AttachArea(PrintForm, TemplateArea, GoToNextRow1);
			ElsIf	AreaDetails.AreaType = "List" Then
				DerivedArea = PrintManagementMSWordClient.AttachArea(PrintForm, TemplateArea, GoToNextRow1);
			ElsIf	AreaDetails.AreaType = "TableRow" Then
				If PrintForm.LastOutputArea <> Undefined
				   And PrintForm.LastOutputArea.AreaType = "TableRow"
				   And Not PrintForm.LastOutputArea.GoToNextRow1 Then
					DerivedArea = PrintManagementMSWordClient.AttachArea(PrintForm, TemplateArea, GoToNextRow1, True);
				Else
					DerivedArea = PrintManagementMSWordClient.AttachArea(PrintForm, TemplateArea, GoToNextRow1);
				EndIf;
			Else
				Raise AreaTypeSpecifiedIncorrectlyText();
			EndIf;
			
			AreaDetails.Insert("Area", DerivedArea);
			AreaDetails.Insert("GoToNextRow1", GoToNextRow1);
			
			// Contains an area type and area borders (if required).
			PrintForm.LastOutputArea = AreaDetails;
			
		ElsIf PrintForm.Type = "ODT" Then
			If		AreaDetails.AreaType = "Header" Then
				PrintManagementOOWriterClient.AddHeader(PrintForm, TemplateArea);
			ElsIf	AreaDetails.AreaType = "Footer" Then
				PrintManagementOOWriterClient.AddFooter(PrintForm, TemplateArea);
			ElsIf	AreaDetails.AreaType = "Shared3"
					Or AreaDetails.AreaType = "List" Then
				PrintManagementOOWriterClient.SetMainCursorToDocumentBody(PrintForm);
				PrintManagementOOWriterClient.AttachArea(PrintForm, TemplateArea, GoToNextRow1);
			ElsIf	AreaDetails.AreaType = "TableRow" Then
				PrintManagementOOWriterClient.SetMainCursorToDocumentBody(PrintForm);
				PrintManagementOOWriterClient.AttachArea(PrintForm, TemplateArea, GoToNextRow1, True);
			Else
				Raise AreaTypeSpecifiedIncorrectlyText();
			EndIf;
			// Contains an area type and area borders (if required).
			PrintForm.LastOutputArea = AreaDetails;
		EndIf;
	Except
		ErrorMessage = TrimAll(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		ErrorMessage = ?(Right(ErrorMessage, 1) = ".", ErrorMessage, ErrorMessage + ".");
		ErrorMessage = ErrorMessage + " " + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể hiển thị vùng ""%1"" ra mẫu in từ khuôn in.';
				|ru = 'Невозможно вывести в печатную форму область ""%1"" из макета.';
				|en = 'Cannot output area ""%1"" from the template into the print form.'; fa = 'Cannot output area ""%1"" from the template into the print form.';
				|it = 'Cannot output area ""%1"" from the template into the print form.';
				|pl = 'Cannot output area ""%1"" from the template into the print form.';
				|tr = 'Şablondan ""%1"" bölgesini yazdırma formuna yazdırmak mümkün değil.'"),
			TemplateArea.AreaDetails.AreaName);
		Raise ErrorMessage;
	EndTry;
	
EndProcedure

// Deprecated. Obsolete. Use PrintManagement.FillParameters.
//
// Fills parameters of the print form area.
//
// Parameters:
//  PrintForm - Structure - Print form or a print form area.
//  Data - Structure - Autofill data.
//
Procedure FillParameters_(Val PrintForm, Val Data) Export
	
	AreaDetails = PrintForm.LastOutputArea; // See TemplateArea.AreaDetails
	
	If PrintForm.Type = "DOC" Then
		If		AreaDetails.AreaType = "Header" Then
			PrintManagementMSWordClient.FillHeaderParameters(PrintForm, Data);
		ElsIf	AreaDetails.AreaType = "Footer" Then
			PrintManagementMSWordClient.FillFooterParameters(PrintForm, Data);
		ElsIf	AreaDetails.AreaType = "Shared3"
				Or AreaDetails.AreaType = "TableRow"
				Or AreaDetails.AreaType = "List" Then
			PrintManagementMSWordClient.FillParameters_(AreaDetails.Area, Data);
		Else
			Raise AreaTypeSpecifiedIncorrectlyText();
		EndIf;
	ElsIf PrintForm.Type = "ODT" Then
		If		PrintForm.LastOutputArea.AreaType = "Header" Then
			PrintManagementOOWriterClient.SetMainCursorToHeader(PrintForm);
		ElsIf	PrintForm.LastOutputArea.AreaType = "Footer" Then
			PrintManagementOOWriterClient.SetMainCursorToFooter(PrintForm);
		ElsIf	AreaDetails.AreaType = "Shared3"
				Or AreaDetails.AreaType = "TableRow"
				Or AreaDetails.AreaType = "List" Then
			PrintManagementOOWriterClient.SetMainCursorToDocumentBody(PrintForm);
		EndIf;
		PrintManagementOOWriterClient.FillParameters_(PrintForm, Data);
	EndIf;
	
EndProcedure

// Deprecated. Obsolete. Use PrintManagement.AttachAreaAndFillParameters.
//
// Adds an area from a template to a print form, replacing the area parameters with the object data values.
// The procedure is used upon output of a single area.
//
// Parameters:
//  PrintForm - See InitializePrintForm.
//  TemplateArea - See TemplateArea.
//  Data - Structure - filling data.
//  GoToNextRow1 - Boolean - True, if you need to add a line break after the area output.
//
Procedure AttachAreaAndFillParameters(Val PrintForm, Val TemplateArea,
	Val Data, Val GoToNextRow1 = True) Export
	
	If TemplateArea <> Undefined Then
		AttachArea(PrintForm, TemplateArea, GoToNextRow1);
		FillParameters_(PrintForm, Data)
	EndIf;
	
EndProcedure

// Deprecated. Obsolete. Use PrintManagement.AttachAndFillCollection.
//
// Adds an area from a template to a print form, replacing
// the area parameters with the object data values.
// The procedure is used upon output of a single area.
//
// Parameters:
//  PrintForm - See InitializePrintForm.
//  TemplateArea - See TemplateArea
//  Data - Array - an item collection of the Structure type - object data.
//  GoToNextRow - Boolean - True, if you need to add a line break after the area output.
//
Procedure JoinAndFillCollection(Val PrintForm,
										Val TemplateArea,
										Val Data,
										Val GoToNextRow = True) Export
	If TemplateArea = Undefined Then
		Return;
	EndIf;
	
	AreaDetails = TemplateArea.AreaDetails;
	
	If PrintForm.Type = "DOC" Then
		If		AreaDetails.AreaType = "TableRow" Then
			PrintManagementMSWordClient.JoinAndFillTableArea(PrintForm, TemplateArea, Data, GoToNextRow);
		ElsIf	AreaDetails.AreaType = "List" Then
			PrintManagementMSWordClient.JoinAndFillSet(PrintForm, TemplateArea, Data, GoToNextRow);
		Else
			Raise AreaTypeSpecifiedIncorrectlyText();
		EndIf;
	ElsIf PrintForm.Type = "ODT" Then
		If		AreaDetails.AreaType = "TableRow" Then
			PrintManagementOOWriterClient.JoinAndFillCollection(PrintForm, TemplateArea, Data, True, GoToNextRow);
		ElsIf	AreaDetails.AreaType = "List" Then
			PrintManagementOOWriterClient.JoinAndFillCollection(PrintForm, TemplateArea, Data, False, GoToNextRow);
		Else
			Raise AreaTypeSpecifiedIncorrectlyText();
		EndIf;
	EndIf;
	
EndProcedure

// Deprecated. Obsolete. Use PrintManagement.InsertNewLineBreak.
//
// Inserts a line break as a newline character.
//
// Parameters:
//  PrintForm - See InitializePrintForm.
//
Procedure InsertBreakAtNewLine(Val PrintForm) Export
	
	If	  PrintForm.Type = "DOC" Then
		PrintManagementMSWordClient.InsertBreakAtNewLine(PrintForm);
	ElsIf PrintForm.Type = "ODT" Then
		PrintManagementOOWriterClient.InsertBreakAtNewLine(PrintForm);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region Internal

// Opens a template file import dialog box for editing it in an external application.
Procedure EditTemplateInExternalApplication(CallbackDescription, TemplateParameters1, Form) Export
	OpenForm("InformationRegister.UserPrintTemplates.Form.EditTemplate2", TemplateParameters1, Form, , , , CallbackDescription);
EndProcedure

// The SettingsForSaving parameter constructor of the PrintManagement.PrintToFile function.
// Defines a format and other settings of writing a spreadsheet document to file.
// 
// Returns:
//  Structure - Settings for writing a spreadsheet to a file:
//   * SaveFormats - Array - Collection of values of the SpreadsheetDocumentFileType type converted into String.
//   * PackToArchive   - Boolean - If True, one archive file with files of the specified formats will be created.
//   * TransliterateFilesNames - Boolean - If True, the names of the received files will be in Latin.
//   * SignatureAndSeal    - Boolean - If True and the spreadsheet being saved supports
//                                  signatures and stamps, they will be placed to saved files.
//
Function SettingsForSaving() Export
	
	Return PrintManagementClientServer.SettingsForSaving();
	
EndFunction

// Parameters:
//  Form - ClientApplicationForm
//  Command - FormCommand
//
Procedure SwitchLanguage(Form, Command) Export
	
	Parameters = New Structure;
	Parameters.Insert("Form", Form);
	ArrayOfLangWords = StrSplit(Command.Name, "_", False);
	ArrayOfLangWords.Delete(0);
	TheSelectedLanguage = StrConcat(ArrayOfLangWords, "_");
	
	Parameters.Insert("TheSelectedLanguage", TheSelectedLanguage);

	FormButton = Form.Items[Command.Name]; // FormButton
	Parameters.Insert("Title", Form.Items["Language_"+TheSelectedLanguage].Title);
	Parameters.Insert("FormButton", FormButton);
	Parameters.Insert("FormButtonAllActions", Form.Items.Find(Command.Name+"AllActions"));
	
	If Form.Modified Then
		CallbackDescription = New CallbackDescription("WhenSwitchingTheLanguage", ThisObject, Parameters);
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.OK, NStr("vi = 'Tiếp tục';
												|ru = 'Продолжить';
												|en = 'Continue'; fa = 'ادامه';
												|it = 'Continuare';
												|pl = 'Continue';
												|tr = 'Devam'"));
		Buttons.Add(DialogReturnCode.Cancel);
		
		QueryText = NStr("vi = 'Chưa ghi lại những thay đổi hiện tại của khuôn in. Tiếp tục?';
						|ru = 'Текущие изменения макета не записаны. Продолжить?';
						|en = 'Current template changes are not saved. Do you want to continue?'; fa = 'Current template changes are not saved. Do you want to continue?';
						|it = 'Le modifiche correnti del modello non sono state salvate. Continuare?';
						|pl = 'Bieżące zmiany makiety nie są zapisane. Kontynuować?';
						|tr = 'Mevcut şablon değişiklikleri kaydedilmedi. Devam edilsin mi?'");
		ShowQueryBox(CallbackDescription, QueryText, Buttons, , DialogReturnCode.Cancel);
	Else
		WhenSwitchingTheLanguage(DialogReturnCode.OK, Parameters);
	EndIf;
	
EndProcedure

Function AreaID(Area) Export
	
	Return PrintManagementClientServer.AreaID(Area);
	
EndFunction

// Returns:
//  Structure:
//   * FilesDetails1 - Array of Structure
//   * DirectoryName - String
//   * CompletionHandler - CallbackDescription
//   * IndexOf - Number
//   * Counter - Number
//   * FileName - String
//
Function FileNamePreparationOptions(FilesDetails1, DirectoryName, CompletionHandler) Export
	
	Result = New Structure;
	
	Result.Insert("FilesDetails1", FilesDetails1);
	Result.Insert("DirectoryName", DirectoryName);
	Result.Insert("CompletionHandler", CompletionHandler);
	Result.Insert("IndexOf", Undefined);
	Result.Insert("Counter", 1);
	Result.Insert("FileName", "");
	
	Return Result;
	
EndFunction

// Parameters:
//  PreparationParameters - See FileNamePreparationOptions
//
Procedure PrepareFileNamesToSaveToADirectory(PreparationParameters) Export
	
	FilesDetails1 = PreparationParameters.FilesDetails1;
	
	If PreparationParameters.IndexOf = Undefined Then
		For Each FileDetails In FilesDetails1 Do
			FileDetails.Presentation = PreparationParameters.DirectoryName + FileDetails.Presentation;
		EndDo;
		PreparationParameters.IndexOf = 0;
	EndIf;
	
	If PreparationParameters.IndexOf > FilesDetails1.UBound() Then
		RunCallback(PreparationParameters.CompletionHandler, FilesDetails1);
		Return;
	EndIf;
	
	FileDetails = FilesDetails1[PreparationParameters.IndexOf];
	File = New File(FileDetails.Presentation);
	If PreparationParameters.Counter > 1 Then
		File = New File(File.Path +  File.BaseName + " (" + PreparationParameters.Counter + ")" + File.Extension);
	EndIf;
	
	PreparationParameters.FileName = File.Name;
	CallbackDescription = New CallbackDescription("WhenCheckingTheExistenceOfAFile", ThisObject, PreparationParameters);
	File.BeginCheckingExistence(CallbackDescription);
	
EndProcedure

Procedure OnChangeTemplateSettings(Parameters, CallbackDescription) Export
	
	OpenForm("Catalog.PrintFormTemplates.Form.TemplateSettings",
		Parameters,
		ThisObject,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Before generating a print form, it checks whether the name of the default print form needs to be saved and
// displays a confirmation dialog. Based on the user's response, it modifies the returned "CommandDetails" parameter.
// After generating the print form, "CommandDetails" must be passed unchanged
// to the "PrintManagement.OnExecutePrintCommand" procedure to save the name.
// 
// Parameters:
//  Objects              - AnyRef
//                       - Array of AnyRef - Print objects.
//  CommandDetails      - Structure
//                       - Array of Structure - A return parameter.
//                                               The keys repeat the table rows. See PrintManagement.CreatePrintCommandsCollection.
//  CompletionHandler - CallbackDescription - Contains details of the procedure that will be called after the confirmation
//                         dialog for name replacement is closed, with parameters.:
//                           * Result               - Structure
//                                                     - Array of Structure - Modified "CommandDetails" parameter.
//                           * AdditionalParameters - Arbitrary - Additional notification parameters.
//  Example:
//		Procedure CallingCode()
//			CompletionHandler = New NotifyDescription("ResumeCallingCode", ThisObject, NotificationParameters);
//			PrintManagementClient.BeforeRunPrintCommand(Objects, CommandDetails, CompletionHandler);
//		EndProcedure
//		Procedure ResumeCallingCode(Result, AdditionalParameters) Export
//			CommandDetails = Result;
//		EndProcedure
//
Procedure BeforeStartExecutePrintCommand(Objects, CommandDetails, CompletionHandler) Export
	
	If TypeOf(Objects) <> Type("Array") Then
		ObjectsArray = CommonClientServer.ValueInArray(Objects);
	Else
		ObjectsArray = Objects;
	EndIf;
	
	If TypeOf(CommandDetails) = Type("Array") Then
		
		DefaultPrintFormsCount = 0;
		For Each Command In CommandDetails Do
			If Command.DefaultPrintForm Then
				DefaultPrintFormsCount = DefaultPrintFormsCount + 1;
				IndexOfSinglePrintForm = CommandDetails.Find(Command);
			EndIf;
		EndDo;
		
		If DefaultPrintFormsCount > 1 Then
			FormParameters = New Structure;
			FormParameters.Insert("PrintCommands", CommandDetails);
			FormParameters.Insert("ObjectsArray", ObjectsArray);
			
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("ObjectsArray", ObjectsArray);
			AdditionalParameters.Insert("CallbackDescription", CompletionHandler);
			AdditionalParameters.Insert("PrintCommands", CommandDetails);
			OnCloseNotifyDescription = New CallbackDescription(
				"AfterSelectDefaultPrintFormCommand", ThisObject, AdditionalParameters);
			
			OpenForm("CommonForm.SelectDefaultPrintForm",
				FormParameters, , , , , OnCloseNotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
			
		ElsIf DefaultPrintFormsCount = 1 Then
			BeforeStartExecutePrintCommandContinued(ObjectsArray, CommandDetails, CompletionHandler, IndexOfSinglePrintForm);
			
		Else
			RunCallback(CompletionHandler, CommandDetails);
			
		EndIf;
		
	Else
		CommandInArray = CommonClientServer.ValueInArray(CommandDetails);
		BeforeStartExecutePrintCommandContinued(ObjectsArray, CommandInArray, CompletionHandler)
	EndIf;
	
EndProcedure

// ACC:299-off - The routine was called from 1C:ERP.

// Generates and displays print forms or prints them out according to the command.
// 
// Parameters:
//  ObjectsArray        - Array of AnyRef - Print objects.
//  Commands               - Array of Structure - See CreatePrintCommand.
//  CompletionHandler  - CallbackDescription - Describes the procedure to be called before generating
//                                               print forms (unless the user canceled printing).:
//                         * Result               - Boolean - Always returns "True".
//                         * AdditionalParameters - Arbitrary - Additional notification parameters.
//  ToPrinter             - Boolean - If True, output the print forms to a printer. Otherwise, display on screen.
//  FixedSet - Boolean - If set to True, the number of document copies in the set cannot be changed.
//
Procedure RunPrintCommands(ObjectsArray, Commands, CompletionHandler, ToPrinter = False, FixedSet = False) Export
	
	If Not CheckPassedObjectsCount(ObjectsArray) Then
		Return;
	EndIf;
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("CompletionHandler", CompletionHandler);
	NotificationParameters.Insert("ObjectsArray", ObjectsArray);
	NotificationParameters.Insert("ToPrinter", ToPrinter);
	NotificationParameters.Insert("FixedSet", FixedSet);
	NotificationParameters.Insert("OverrideCopiesUserSetting", FixedSet);
	
	CallbackDescription = New CallbackDescription("ContinuePrintCommandExecution", ThisObject, NotificationParameters);
	BeforeStartExecutePrintCommand(ObjectsArray, Commands, CallbackDescription);
	
EndProcedure

// See PrintManagement.PrintToFile()
Procedure PrintToFile(PrintCommands, ListOfObjects, SettingsForSaving, CompletionHandler) Export
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("CompletionHandler", CompletionHandler);
	NotificationParameters.Insert("PrintCommands", PrintCommands);
	NotificationParameters.Insert("ListOfObjects", ListOfObjects);
	NotificationParameters.Insert("SettingsForSaving", SettingsForSaving);
	
	CallbackDescription = New CallbackDescription("ContinuePrintToFile", ThisObject, NotificationParameters); 
	BeforeStartExecutePrintCommand(ListOfObjects, PrintCommands, CallbackDescription);
	
EndProcedure

// Array element constructor for the second parameter of the "RunPrintCommands" procedure.
// 
// Returns:
//  Structure - Fields required to run the "RunPrintCommands" procedure
//
Function CreatePrintCommand() Export
	CommandTemplate = PrintManagementServerCall.CreatePrintCommand();
	Return CommandTemplate;
EndFunction

// ACC:299-on

#EndRegion

#Region Private

// Before executing a print command, check whether at least one object is passed as an empty array can be passed
// for commands that accept multiple objects.
//
Function CheckPassedObjectsCount(CommandParameter)
	
	If TypeOf(CommandParameter) = Type("Array") And CommandParameter.Count() = 0 Then
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

Function AreaTypeSpecifiedIncorrectlyText()
	Return NStr("vi = 'Chưa chỉ ra kiểu vùng hoặc đã chỉ ra sai.';
				|ru = 'Тип области не указан или указан некорректно.';
				|en = 'Area type is not specified or invalid.'; fa = 'Area type is not specified or invalid.';
				|it = 'Tipo di area non indicato o indicato in maniera errata';
				|pl = 'Rodzaj obszaru nie został podany lub jest podany niepoprawnie.';
				|tr = 'Alan tipi yanlış belirtilmemiş veya belirtilmemiş.'");
EndFunction

Procedure WhenSwitchingTheLanguage(Response, Parameters) Export
	
	If Response <> DialogReturnCode.OK Then
		Return
	EndIf;
	
	Form = Parameters.Form; // ClientApplicationForm - 
	Items = Form.Items;
	TheSelectedLanguage = Parameters.TheSelectedLanguage;
	Title = Parameters.Title;
	ProcessMoreActionsSubmenuItems = Parameters.FormButtonAllActions <> Undefined;
	
	Items.Language.Title = Title;
	FormButton = Parameters.FormButton;
	FormButtonAllActions = Parameters.FormButtonAllActions;
	
	IsEditorForm = StrStartsWith(Form.FormName, "CommonForm.Edit");
	
	If IsEditorForm Then
		IsTemplateCreated = Form.TemplateSavedLangs.FindByValue(Form.CurrentLanguage)<>Undefined;
	EndIf;
	
	LangSwitchFrom = Form.CurrentLanguage;
	
	Form.CurrentLanguage = TheSelectedLanguage;
	MenuLang = Items.Language;
	
	For Each LangButton In MenuLang.ChildItems Do
		If TypeOf(LangButton) = Type("FormButton") Then
			LangButton.Check = False;
			If FormButton.CommandName = "Add"+LangButton.CommandName Then
				LangButton.Visible = True;
				LangButton.Check = True;
			EndIf;
		EndIf;
	EndDo;
	
	If FormButton.Parent = MenuLang Then
		FormButton.Check = True;
	Else
		FormButton.Visible = False;
	EndIf;
	
	If ProcessMoreActionsSubmenuItems Then
		Items.LanguageAllActions.Title = Title;
		MenuLanguageAllActions = Items.LanguageAllActions;
	
		For Each LangButton In MenuLanguageAllActions.ChildItems Do
			If TypeOf(LangButton) = Type("FormButton") Then
				LangButton.Check = False;
				If FormButton.CommandName = "Add"+LangButton.CommandName Then
					LangButton.Visible = True;
					LangButton.Check = True;
				EndIf;
			EndIf;
		EndDo;
		
		If FormButtonAllActions.Parent = MenuLanguageAllActions Then
			FormButtonAllActions.Check = True;
		Else
			FormButtonAllActions.Visible = False;
		EndIf;

	EndIf;

	If IsEditorForm Then
				
		If Not IsTemplateCreated Then
			
			LangsToAdd = Items.LangsToAdd;
			For Each LangButton In LangsToAdd.ChildItems Do
				If StrEndsWith(LangButton.Name, LangSwitchFrom) Then
					LangButton.Visible = True;
					Break;
				EndIf;
			EndDo;
			
			For Each LangButton In MenuLang.ChildItems Do
				If TypeOf(LangButton) = Type("FormButton") Then
					If StrEndsWith(LangButton.Name, LangSwitchFrom) Then
						LangButton.Visible = False;
						LangButton.Check = False;
						Break;
					EndIf;
				EndIf;
			EndDo;
			
			If ProcessMoreActionsSubmenuItems Then
				LangsToAddAllActions = Items.LangsToAddAllActions;
				For Each LangButton In LangsToAddAllActions.ChildItems Do
					If TypeOf(LangButton) = Type("FormButton") Then
						If StrEndsWith(LangButton.CommandName, LangSwitchFrom) Then
							LangButton.Visible = True;
							Break;
						EndIf;
					EndIf;
				EndDo;
				
				For Each LangButton In MenuLanguageAllActions.ChildItems Do
					If TypeOf(LangButton) = Type("FormButton") Then
						If StrEndsWith(LangButton.CommandName, LangSwitchFrom) Then
							LangButton.Visible = False;
							LangButton.Check = False;
							Break;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
			
		EndIf;
	EndIf;
	
	Form.Modified = False;
	
	CallbackDescription = New CallbackDescription("Attachable_WhenSwitchingTheLanguage", Form);
	RunCallback(CallbackDescription, TheSelectedLanguage);
	
EndProcedure

// Parameters:
//  Exists - Boolean
//  PreparationParameters - See FileNamePreparationOptions
//
Procedure WhenCheckingTheExistenceOfAFile(Exists, PreparationParameters) Export
	
	If Exists Then
		PreparationParameters.Counter = PreparationParameters.Counter + 1;
	Else
		FileDetails = PreparationParameters.FilesDetails1[PreparationParameters.IndexOf];
		FileDetails.Presentation = PreparationParameters.FileName;
		PreparationParameters.Counter = 0;
		PreparationParameters.IndexOf = PreparationParameters.IndexOf + 1;
	EndIf;
	
	PrepareFileNamesToSaveToADirectory(PreparationParameters);
	
EndProcedure

Procedure GoToTemplate(TemplatePath) Export
	
	OpeningParameters = New Structure("TemplatePath", TemplatePath);
	OpenForm("InformationRegister.UserPrintTemplates.Form.PrintFormTemplates", OpeningParameters);
	
EndProcedure

Procedure AfterSelectDefaultPrintFormCommand(CommandIndex, AdditionalParameters) Export
	
	If CommandIndex <> Undefined Then
		
		SelectedCommand = AdditionalParameters.PrintCommands[CommandIndex];
		SelectedCommand.ReplaceDefaultPrintForm = True;
		SelectedCommand.DefaultPrintForm = False;
		
		BeforeStartExecutePrintCommandContinued(
			AdditionalParameters.ObjectsArray,
			AdditionalParameters.PrintCommands,
			AdditionalParameters.CallbackDescription,
			CommandIndex);
	EndIf;
	
EndProcedure

Async Procedure BeforeStartExecutePrintCommandContinued(ObjectsArray, Commands, CallbackDescription, CommandIndex = Undefined)
	
	If CommandIndex = Undefined Then
		CommandDetails = Commands[0];
	Else
		CommandDetails = Commands[CommandIndex];
	EndIf;
	
	If Not CommandDetails.DefaultPrintForm Then //This is a set.
		
		DefaultPrintFormsInSet = PrintManagementServerCall.DefaultPrintFormInSet(
			ObjectsArray, CommandDetails);
		
		NumberOfDefaultOnesInSet = DefaultPrintFormsInSet.Count();
		If NumberOfDefaultOnesInSet > 0 Then
			CommandDetails.DefaultPrintForm = True;
			FirstDefault = DefaultPrintFormsInSet[0];
			CommandDetails.IDFromSet = FirstDefault.Id;
			CommandDetails.PrintFormDescription = FirstDefault.PrintFormDescription;
		EndIf;
		
	EndIf;
	
	If CommandDetails.DefaultPrintForm
		And Not CommandDetails.ReplaceDefaultPrintForm
		And Not UsersClient.IsExternalUserSession() Then
		
		SavedDescriptions = PrintManagementServerCall.SavedDescriptions(ObjectsArray);
		HasSavedDescriptions = SavedDescriptions.Count();
		QueryText = "";
		AskAQuestion = False;
		
		For Each SavedDescription In SavedDescriptions Do
			If ValueIsFilled(SavedDescription.Id)
				And SavedDescription.Id <> PrintManagementClientServer.IDWithoutSpecialChars(CommandDetails.Id) Then
				AskAQuestion = True;
				Break;
			EndIf;
		EndDo;
		If AskAQuestion Then
			If SavedDescriptions.Count() = 1 Then
				FirstDescription = SavedDescriptions[0];
				QueryText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đối với chứng từ này, trước đó đã tạo mẫu in chính ""%1"", người dùng ""%2"", ngày tạo ""%3"". Bạn có muốn thay thế mẫu in chính đã lưu cho chứng từ này không?';
						|ru = 'По документу ранее уже была сформирована основная печатная форма ""%1"", пользователь ""%2"", дата формирования ""%3"". Заменить сохраненную основную печатную форму для документа?';
						|en = 'A default print form for this document has already been generated: %1, by %2, on %3. Replace the default print form for this document?'; fa = 'A default print form for this document has already been generated: %1, by %2, on %3. Replace the default print form for this document?';
						|it = 'A default print form for this document has already been generated: %1, by %2, on %3. Replace the default print form for this document?';
						|pl = 'A default print form for this document has already been generated: %1, by %2, on %3. Replace the default print form for this document?';
						|tr = 'Belge için ana yazdırma formu ""%1"", kullanıcı ""%2"", oluşturma tarihi ""%3"" zaten önceden oluşturulmuştu. Belge için kaydedilmiş ana yazdırma formu değiştirilsin mi?'"),
					FirstDescription.PrintFormDescription,
					FirstDescription.User,
					Format(FirstDescription.Date, "DLF=;"));
			Else
				QueryText = NStr("vi = 'Đối với một hoặc một số chứng từ được chọn, đã in mẫu in chính. Bạn có muốn thay thế mẫu in chính đã lưu cho các chứng từ này không?';
								|ru = 'По одному или нескольким из выбранных документов уже печаталась основная форма. Заменить сохраненную основную печатную форму для документов?';
								|en = 'A default print form has already been generated for one or more of the selected documents. Replace the default print form for these documents?'; fa = 'A default print form has already been generated for one or more of the selected documents. Replace the default print form for these documents?';
								|it = 'A default print form has already been generated for one or more of the selected documents. Replace the default print form for these documents?';
								|pl = 'A default print form has already been generated for one or more of the selected documents. Replace the default print form for these documents?';
								|tr = 'Seçili belgelerden bir veya birden fazlasına zaten bir temel form yazdırıldı. Belgeler için kayıtlı ana yazdırma formu değiştirilsin mi?'");
			EndIf;
		EndIf;
		
		If Not IsBlankString(QueryText) Then
			
			QuestionButtons = New ValueList;
			QuestionButtons.Add("Replace", NStr("vi = 'Thay thế';
												|ru = 'Заменить';
												|en = 'Replace'; fa = 'جایگزینی';
												|it = 'Sostituire';
												|pl = 'Replace';
												|tr = 'Değiştir'"));
			QuestionButtons.Add("NotReplace", NStr("vi = 'Không thay thế';
													|ru = 'Не заменять';
													|en = 'Do not replace'; fa = 'Do not replace';
													|it = 'Non sostituire';
													|pl = 'Nie zastępuj';
													|tr = 'Değiştirmemek'"));
			
			Response = Await DoQueryBoxAsync(QueryText, QuestionButtons);
			If Response = "Replace" Then
				CommandDetails.ReplaceDefaultPrintForm = True;
			ElsIf Response = Undefined Then
				Return;
			EndIf;
			
		Else
			If Not HasSavedDescriptions Then
				CommandDetails.ReplaceDefaultPrintForm = True;
			EndIf;
		EndIf;
	EndIf;
	
	If CommandIndex = Undefined Then
		RunCallback(CallbackDescription, Commands[0]);
	Else
		RunCallback(CallbackDescription, Commands);
	EndIf;
	
EndProcedure

Procedure ContinuePrintCommandExecution(Commands, AdditionalParameters) Export
	
	ParameterName = "StandardSubsystems.Print.ExecutePrintCommand";
	PassedParametersList = ApplicationParameters[ParameterName];
	
	If PassedParametersList = Undefined Then
		PassedParametersList = New Array;
		ApplicationParameters[ParameterName] = PassedParametersList;
	EndIf;
	
	RunCallback(AdditionalParameters.CompletionHandler, True);
	
	ObjectsArray = AdditionalParameters.ObjectsArray;
	PrintForms = PrintManagementServerCall.GeneratePrintForms(ObjectsArray, Commands);
			
	If AdditionalParameters.ToPrinter Then
		
		TemplatesNames = New ValueList;
		PrintFormsList = New ValueList;
		For Each PrintForm In PrintForms.PrintFormsCollection Do
			SpreadsheetDocument = PrintForm.SpreadsheetDocument;
			If (TypeOf(SpreadsheetDocument) = Type("SpreadsheetDocument")) And (SpreadsheetDocument.TableHeight <> 0) Then
				PrintFormsList.Add(SpreadsheetDocument, PrintForm.TemplateSynonym);
				TemplatesNames.Add(PrintForm.TemplateName, PrintForm.TemplateSynonym);
			EndIf;
		EndDo;
		
		PrintSpreadsheetDocuments(PrintFormsList, PrintForms.PrintObjects);
		
		// StandardSubsystems.SourceDocumentsOriginalsRecording
		If CommonClient.SubsystemExists("StandardSubsystems.SourceDocumentsOriginalsRecording") Then
			ModuleSourceDocumentsOriginalsAccountingClient = CommonClient.CommonModule("SourceDocumentsOriginalsRecordingClient");
			ModuleSourceDocumentsOriginalsAccountingClient.WriteOriginalsStatesAfterPrint(PrintForms.PrintObjects, TemplatesNames);
		EndIf;
		// End StandardSubsystems.SourceDocumentsOriginalsRecording
		
	Else
		OpeningParameters = PrintManagementInternalClient.ParametersForOpeningPrintForm();
		OpeningParameters.CommandParameter = ObjectsArray;
		OpeningParameters.PrintObjects = PrintForms.PrintObjects;
		OpeningParameters.PrintFormsCollection = PrintForms.PrintFormsCollection;
		OpeningParameters.OutputParameters = PrintForms.OutputParameters;
		
		PrintParameters = New Structure;
		PrintParameters.Insert("FixedSet", AdditionalParameters.FixedSet);
		PrintParameters.Insert("OverrideCopiesUserSetting", AdditionalParameters.OverrideCopiesUserSetting);
		OpeningParameters.PrintParameters = PrintParameters;
		
		PassedParametersList.Add(OpeningParameters);
		
		AttachIdleHandler("ResumePrintCommandWithPassedParameters", 0.1, True);
	EndIf;
	
EndProcedure

Procedure ContinuePrintToFile(Commands, AdditionalParameters) Export
	
	Result = PrintManagementServerCall.PrintToFile(
		Commands, AdditionalParameters.ListOfObjects, AdditionalParameters.SettingsForSaving);
	
	RunCallback(AdditionalParameters.CompletionHandler, Result);
	
EndProcedure

#EndRegion